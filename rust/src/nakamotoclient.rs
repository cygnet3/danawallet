use std::{
    collections::HashMap,
    net,
    path::PathBuf,
    str::FromStr,
    sync::atomic::{AtomicBool, Ordering},
    thread::{self, sleep, JoinHandle},
    time::{Duration, Instant},
};

use anyhow::{Error, Result};
use bitcoin::{
    hashes::Hash,
    hex::{DisplayHex, FromHex},
    secp256k1::{All, PublicKey, Scalar, Secp256k1, SecretKey},
    XOnlyPublicKey,
};
use electrum_client::ElectrumApi;
use lazy_static::lazy_static;
use log::info;
use nakamoto::{
    chain::{filter::BlockFilter, BlockHash, Transaction},
    client::{self, traits::Handle as _, Client, Config, Domain, Handle},
    common::bitcoin::{
        network::constants::ServiceFlags, psbt::serialize::Deserialize, OutPoint, TxOut,
    },
    net::poll::Waker,
};
use once_cell::sync::OnceCell;
use sp_client::silentpayments::receiving::Receiver;

use crate::{
    // constants::SyncStatus,
    electrumclient,
    stream::{
        send_amount_update, send_nakamoto_run, send_scan_progress, send_sync_progress,
        ScanProgress, SyncStatus,
    },
};

use sp_client::spclient::{OutputSpendStatus, OwnedOutput, SpClient};

const ORDERING: Ordering = Ordering::SeqCst;

lazy_static! {
    static ref NAKAMOTO_RUN: AtomicBool = AtomicBool::new(false);
    static ref NAKAMOTO_CONFIG: OnceCell<Config> = OnceCell::new();
}

pub fn setup(network: String, path: String) -> Result<()> {
    let mut cfg = Config::new(
        client::Network::from_str(&network).map_err(|_| Error::msg("Invalid network"))?,
    );

    cfg.root = PathBuf::from(format!("{}/db", path));
    cfg.domains = vec![Domain::IPV4];
    info!("cfg.root = {:?}", cfg.root);

    match NAKAMOTO_CONFIG.set(cfg) {
        Ok(_) => (),
        Err(_) => {
            info!("NAKAMOTO_CONFIG already set");
        }
    }
    Ok(())
}

pub fn start_nakamoto_client() -> Result<(Handle<Waker>, JoinHandle<()>)> {
    if NAKAMOTO_RUN
        .compare_exchange(false, true, ORDERING, ORDERING)
        .is_err()
    {
        return Err(Error::msg("Nakamoto client is already running"));
    }

    send_nakamoto_run(NAKAMOTO_RUN.load(ORDERING));

    let cfg = NAKAMOTO_CONFIG.wait().clone();
    // Create a client using the above network reactor.
    type Reactor = nakamoto::net::poll::Reactor<net::TcpStream>;
    let client = Client::<Reactor>::new()?;
    let handle = client.handle();

    let join_handle = thread::spawn(|| {
        client.run(cfg).unwrap();
    });

    Ok((handle, join_handle))
}

pub fn stop_nakamoto_client(handle: Handle<Waker>, join_handle: JoinHandle<()>) -> Result<()> {
    NAKAMOTO_RUN.store(false, ORDERING);
    send_nakamoto_run(NAKAMOTO_RUN.load(ORDERING));
    handle.shutdown()?;
    join_handle
        .join()
        .map_err(|_e| Error::msg("Failed to join thread"))?;
    Ok(())
}
pub fn sync_blockchain(mut handle: Handle<Waker>) -> Result<()> {
    handle.set_timeout(Duration::from_secs(10));

    if let Err(_) = handle.wait_for_peers(1, ServiceFlags::NETWORK) {
        return Err(Error::msg("Can't connect to peers"));
    }

    let mut last_height = 0;

    loop {
        let peer_count = handle.get_peers(ServiceFlags::NETWORK)?;
        if peer_count.is_empty() {
            continue;
        };
        let (height, header, _) = handle.get_tip()?;
        send_sync_progress(SyncStatus {
            peer_count: peer_count.len() as u32,
            blockheight: height,
            bestblockhash: header.block_hash().to_string(),
        });
        if last_height == 0 || last_height < height {
            last_height = height;
            sleep(Duration::from_secs(2));
            continue;
        }
        break;
    }

    Ok(())
}

pub fn clean_db() -> Result<()> {
    // Check that nakamoto isn't running
    if NAKAMOTO_RUN.load(ORDERING) {
        return Err(Error::msg(
            "Nakamoto is still running, wait for it to complete first",
        ));
    }

    let cfg = NAKAMOTO_CONFIG.wait().clone();
    std::fs::remove_dir_all(cfg.root).map_err(Error::new)
}

pub fn scan_blocks(
    mut handle: Handle<Waker>,
    mut n_blocks_to_scan: u32,
    mut sp_client: SpClient,
) -> anyhow::Result<()> {
    let electrum_client = electrumclient::create_electrum_client()?;

    handle.set_timeout(Duration::from_secs(10));

    if let Err(_) = handle.wait_for_peers(1, ServiceFlags::COMPACT_FILTERS) {
        return Err(Error::msg("Can't find peers with compact filters service"));
    }

    info!("scanning blocks");

    let secp = Secp256k1::new();
    let filterchannel = handle.filters();
    let blkchannel = handle.blocks();

    let mut last_scan = sp_client.last_scan;
    let tip_height = handle.get_tip()?.0 as u32;

    // 0 means scan to tip
    if n_blocks_to_scan == 0 {
        n_blocks_to_scan = tip_height - last_scan;
    }

    info!("last_scan: {:?}", last_scan);

    let start = last_scan + 1;
    let end = if last_scan + n_blocks_to_scan <= tip_height {
        last_scan + n_blocks_to_scan
    } else {
        tip_height
    };

    if start > end {
        return Ok(());
    }

    info!("start: {} end: {}", start, end);
    handle.request_filters(start as u64..=end as u64)?;

    let mut tweak_data_map = electrum_client.sp_tweaks(start as usize)?;

    let scan_key_scalar = Scalar::from(sp_client.get_scan_key());
    let sp_receiver = sp_client.sp_receiver.clone();
    let start_time: Instant = Instant::now();

    for n in start..=end {
        if n % 10 == 0 || n == end {
            send_scan_progress(ScanProgress {
                start,
                current: n,
                end,
            });
        }

        let (blkfilter, blkhash, blkheight) = filterchannel.recv()?;

        let spk2secret = match tweak_data_map.remove(&(blkheight as u32)) {
            Some(tweak_data_vec) => {
                last_scan = last_scan.max(blkheight as u32);
                get_script_to_secret_map(&sp_receiver, tweak_data_vec, &scan_key_scalar, &secp)?
            }
            None => HashMap::new(),
        };

        // check if new possible outputs are payments to us
        let candidate_spks: Vec<&[u8; 34]> = spk2secret.keys().collect();

        // check if owned inputs are spent
        let owned_spks: Vec<Vec<u8>> = sp_client
            .list_outpoints()
            .iter()
            .filter_map(|x| {
                if x.spend_status == OutputSpendStatus::Unspent {
                    let script = hex::decode(&x.script).unwrap();
                    Some(script)
                } else {
                    None
                }
            })
            .collect();

        let matched = check_block(blkfilter, blkhash, candidate_spks, owned_spks)?;

        if matched {
            handle.request_block(&blkhash)?;
            let blk = blkchannel.recv()?.0;

            // scan block for new outputs, and add them to our list
            let owned = scan_block_outputs(&sp_receiver, &blk.txdata, blkheight, spk2secret)?;
            if !owned.is_empty() {
                let owned = owned
                    .into_iter()
                    .map(|(outpoint, owned)| (nakamoto_outpoint_to_bitcoin(outpoint), owned))
                    .collect();
                sp_client.extend_owned(owned);
                send_amount_update(sp_client.get_spendable_amt());

                send_scan_progress(ScanProgress {
                    start,
                    current: n,
                    end,
                });
            }

            // search inputs and mark as mined
            let inputs_found = scan_block_inputs(&sp_client, blk.txdata)?;
            if !inputs_found.is_empty() {
                for outpoint in inputs_found {
                    sp_client.mark_outpoint_mined(
                        nakamoto_outpoint_to_bitcoin(outpoint),
                        bitcoin::BlockHash::from_str(&blkhash.to_lower_hex_string())?,
                    )?;
                }
                send_amount_update(sp_client.get_spendable_amt());

                send_scan_progress(ScanProgress {
                    start,
                    current: n,
                    end,
                });
            }
        }
    }

    // time elapsed for the scan
    info!(
        "Scan complete in {} seconds",
        start_time.elapsed().as_secs()
    );

    // update last_scan height
    sp_client.update_last_scan(last_scan);
    sp_client.save_to_disk()
}

// Check if this block contains relevant transactions
fn check_block(
    blkfilter: BlockFilter,
    blkhash: BlockHash,
    candidate_spks: Vec<&[u8; 34]>,
    owned_spks: Vec<Vec<u8>>,
) -> Result<bool> {
    // check output scripts
    let mut scripts_to_match: Vec<_> = candidate_spks.into_iter().map(|spk| spk.as_ref()).collect();

    // check input scripts
    scripts_to_match.extend(owned_spks.iter().map(|spk| spk.as_slice()));

    // note: match will always return true for an empty query!
    if !scripts_to_match.is_empty() {
        Ok(blkfilter.match_any(&blkhash, &mut scripts_to_match.into_iter())?)
    } else {
        Ok(false)
    }
}

fn get_script_to_secret_map(
    sp_receiver: &Receiver,
    tweak_data_vec: Vec<String>,
    scan_key_scalar: &Scalar,
    secp: &Secp256k1<All>,
) -> Result<HashMap<[u8; 34], PublicKey>> {
    let mut res = HashMap::new();
    let shared_secrets: Result<Vec<PublicKey>> = tweak_data_vec
        .into_iter()
        .map(|s| {
            let x = PublicKey::from_str(&s).map_err(Error::new)?;
            x.mul_tweak(secp, scan_key_scalar).map_err(Error::new)
        })
        .collect();
    let shared_secrets = shared_secrets?;

    for shared_secret in shared_secrets {
        let spks = sp_receiver.get_spks_from_shared_secret(&shared_secret)?;

        for spk in spks.into_values() {
            res.insert(spk, shared_secret);
        }
    }
    Ok(res)
}

// possible block has been found, scan the block
fn scan_block_outputs(
    sp_receiver: &Receiver,
    txdata: &Vec<Transaction>,
    blkheight: u64,
    spk2secret: HashMap<[u8; 34], PublicKey>,
) -> Result<Vec<(OutPoint, OwnedOutput)>> {
    let mut res: Vec<(OutPoint, OwnedOutput)> = vec![];

    // loop over outputs
    for tx in txdata {
        let txid = tx.txid();

        // collect all taproot outputs from transaction
        let p2tr_outs: Vec<(usize, &TxOut)> = tx
            .output
            .iter()
            .enumerate()
            .filter(|(_, o)| o.script_pubkey.is_v1_p2tr())
            .collect();

        if p2tr_outs.is_empty() {
            continue;
        }; // no taproot output

        let mut secret: Option<PublicKey> = None;
        // Does this transaction contains one of the outputs we already found?
        for spk in p2tr_outs.iter().map(|(_, o)| &o.script_pubkey) {
            if let Some(s) = spk2secret.get(spk.as_bytes()) {
                // we might have at least one output in this transaction
                secret = Some(*s);
                break;
            }
        }

        if secret.is_none() {
            continue;
        }; // we don't have a secret that matches any of the keys

        // Now we can just run sp_receiver on all the p2tr outputs
        let xonlykeys: Result<Vec<XOnlyPublicKey>> = p2tr_outs
            .iter()
            .map(|(_, o)| {
                XOnlyPublicKey::from_slice(&o.script_pubkey.as_bytes()[2..]).map_err(Error::new)
            })
            .collect();

        let ours = sp_receiver.scan_transaction(&secret.unwrap(), xonlykeys?)?;
        for (label, map) in ours {
            res.extend(p2tr_outs.iter().filter_map(|(i, o)| {
                match XOnlyPublicKey::from_slice(&o.script_pubkey.as_bytes()[2..]) {
                    Ok(key) => {
                        if let Some(scalar) = map.get(&key) {
                            match SecretKey::from_slice(&scalar.to_be_bytes()) {
                                Ok(tweak) => {
                                    let outpoint = OutPoint {
                                        txid,
                                        vout: *i as u32,
                                    };
                                    let label_str: Option<String>;
                                    if let Some(l) = &label {
                                        label_str =
                                            Some(l.as_inner().to_be_bytes().to_lower_hex_string());
                                    } else {
                                        label_str = None;
                                    }
                                    return Some((
                                        outpoint,
                                        OwnedOutput {
                                            txoutpoint: outpoint.to_string(),
                                            blockheight: blkheight as u32,
                                            tweak: hex::encode(tweak.secret_bytes()),
                                            amount: o.value,
                                            script: hex::encode(o.script_pubkey.as_bytes()),
                                            label: label_str,
                                            spend_status: OutputSpendStatus::Unspent,
                                        },
                                    ));
                                }
                                Err(_) => {
                                    return None;
                                }
                            }
                        }
                        None
                    }
                    Err(_) => None,
                }
            }));
        }
    }
    Ok(res)
}

fn scan_block_inputs(sp_client: &SpClient, txdata: Vec<Transaction>) -> Result<Vec<OutPoint>> {
    let mut found = vec![];

    for tx in txdata {
        for input in tx.input {
            let prevout = input.previous_output;

            if sp_client.check_outpoint_owned(nakamoto_outpoint_to_bitcoin(prevout)) {
                found.push(prevout);
            }
        }
    }
    Ok(found)
}

pub fn deserialize_transaction(tx: &str) -> Result<Transaction> {
    Ok(Transaction::deserialize(&Vec::from_hex(tx)?)?)
}

pub fn broadcast_transaction(mut handle: Handle<Waker>, tx: Transaction) -> Result<String> {
    handle.set_timeout(Duration::from_secs(10));

    if let Err(_) = handle.wait_for_peers(1, ServiceFlags::NETWORK) {
        return Err(Error::msg("Can't connect to peers"));
    }
    let txid = tx.txid().to_string();

    handle.submit_transaction(tx)?;

    sleep(Duration::from_secs(2)); // this should be enough

    Ok(txid)
}

// workaround for library version mismatch
fn nakamoto_outpoint_to_bitcoin(
    outpoint: nakamoto::common::bitcoin::OutPoint,
) -> bitcoin::OutPoint {
    let txid_bytes = outpoint.txid.to_vec();
    let vout = outpoint.vout;

    bitcoin::OutPoint {
        txid: bitcoin::Txid::from_slice(&txid_bytes).unwrap(),
        vout,
    }
}
