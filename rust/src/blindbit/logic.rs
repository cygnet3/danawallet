use std::{collections::HashMap, str::FromStr, time::Instant};

use anyhow::{Error, Result};
use bitcoin::{
    bip158::BlockFilter,
    hashes::{sha256, Hash},
    key::Secp256k1,
    secp256k1::{PublicKey, Scalar},
    BlockHash, OutPoint, Txid, XOnlyPublicKey,
};
use log::info;
use sp_client::silentpayments::receiving::Label;
use sp_client::spclient::{OutputSpendStatus, OwnedOutput, SpClient};

use crate::blindbit::client::{BlindbitClient, UtxoResponse};
use crate::stream::{send_amount_update, send_scan_progress, ScanProgress};

const HOST: &str = "https://silentpayments.dev/blindbit";

pub async fn scan_blocks(mut n_blocks_to_scan: u32, mut sp_client: SpClient) -> Result<()> {
    let blindbit_client = BlindbitClient::new(HOST.to_string());

    let mut last_scan = sp_client.last_scan;
    let tip_height = blindbit_client.block_height().await;

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
    let start_time: Instant = Instant::now();

    for n in start..=end {
        if n % 10 == 0 || n == end {
            send_scan_progress(ScanProgress {
                start,
                current: n,
                end,
            });
        }

        let secrets_map = get_block_secrets(&blindbit_client, &sp_client, n).await?;

        if secrets_map.is_empty() {
            // no relevant transactions for us
            continue;
        }

        last_scan = last_scan.max(n as u32);
        let candidate_spks: Vec<&[u8; 34]> = secrets_map.keys().collect();

        //get block gcs & check match
        let new_utxo_filter = blindbit_client.filter_new_utxos(n).await?;
        let blkfilter = BlockFilter::new(&hex::decode(new_utxo_filter.data)?);
        let blkhash = new_utxo_filter.block_hash;

        let matched_outputs = check_block_outputs(blkfilter, blkhash, candidate_spks)?;

        //if match: fetch and scan utxos
        if matched_outputs {
            info!("matched outputs on: {}", n);
            let utxos = blindbit_client.utxos(n).await?;
            let found = scan_utxos(utxos, secrets_map, &sp_client).await?;

            if !found.is_empty() {
                let mut new = vec![];

                for (label, utxo, tweak) in found {
                    let outpoint = OutPoint {
                        txid: utxo.txid,
                        vout: utxo.vout,
                    };

                    let out = OwnedOutput {
                        txoutpoint: outpoint.to_string(),
                        blockheight: n,
                        tweak: hex::encode(tweak.to_be_bytes()),
                        amount: utxo.value,
                        script: utxo.scriptpubkey.to_hex_string(),
                        label: label.map(|l| l.as_string()),
                        spend_status: OutputSpendStatus::Unspent,
                    };

                    new.push((outpoint, out));
                }
                sp_client.extend_owned(new);

                send_amount_update(sp_client.get_spendable_amt());

                send_scan_progress(ScanProgress {
                    start,
                    current: n,
                    end,
                });
            }
        }

        // input checking

        // first get the 8-byte hashes used to construct the input filter
        let input_hashes_map = get_input_hashes(blkhash, &sp_client)?;

        // check against filter
        let spent_filter = blindbit_client.filter_spent(n).await?;
        let blkfilter = BlockFilter::new(&hex::decode(spent_filter.data)?);
        let matched_inputs = check_block_inputs(
            blkfilter,
            blkhash,
            input_hashes_map.keys().cloned().collect(),
        )?;

        // if match: download spent data, and mark present outputs as spent
        if matched_inputs {
            info!("matched inputs on: {}", n);
            let spent = blindbit_client.spent_index(n).await?.data;

            for spent in spent {
                if let Some(outpoint) = input_hashes_map.get(&spent.hex) {
                    sp_client.mark_outpoint_mined(*outpoint, blkhash)?;
                }
            }
        }
    }

    // time elapsed for the scan
    info!(
        "Blindbit scan complete in {} seconds",
        start_time.elapsed().as_secs()
    );

    // update last_scan height
    sp_client.update_last_scan(last_scan);
    sp_client.save_to_disk()
}

pub async fn get_block_secrets(
    client: &BlindbitClient,
    sp_client: &SpClient,
    n: u32,
) -> Result<HashMap<[u8; 34], PublicKey>> {
    // get block tweaks
    let tweaks = client.tweak_index(n).await?;

    let secp = Secp256k1::new();

    //calculate spks
    sp_client.get_script_to_secret_map(tweaks, &secp)
}

pub async fn scan_utxos(
    utxos: Vec<UtxoResponse>,
    secrets_map: HashMap<[u8; 34], PublicKey>,
    sp_client: &SpClient,
) -> Result<Vec<(Option<Label>, UtxoResponse, Scalar)>> {
    let mut res: Vec<(Option<Label>, UtxoResponse, Scalar)> = vec![];

    // group utxos by the txid
    let mut txmap: HashMap<Txid, Vec<UtxoResponse>> = HashMap::new();
    for utxo in utxos {
        txmap.entry(utxo.txid).or_default().push(utxo);
    }

    for utxos in txmap.into_values() {
        // check if we know the secret to any of the spks
        let mut secret = None;
        for utxo in utxos.iter() {
            let spk = utxo.scriptpubkey.as_bytes();
            if let Some(s) = secrets_map.get(spk) {
                secret = Some(s);
                break;
            }
        }

        // skip this tx if no secret is found
        let secret = match secret {
            Some(secret) => secret,
            None => continue,
        };

        let output_keys: Result<Vec<XOnlyPublicKey>> = utxos
            .iter()
            .filter_map(|x| {
                if x.scriptpubkey.is_p2tr() {
                    Some(
                        XOnlyPublicKey::from_slice(&x.scriptpubkey.as_bytes()[2..])
                            .map_err(Error::new),
                    )
                } else {
                    None
                }
            })
            .collect();

        let ours = sp_client
            .sp_receiver
            .scan_transaction(secret, output_keys?)?;

        for utxo in utxos {
            if !utxo.scriptpubkey.is_p2tr() || utxo.spent {
                continue;
            }

            match XOnlyPublicKey::from_slice(&utxo.scriptpubkey.as_bytes()[2..]) {
                Ok(xonly) => {
                    for (label, map) in ours.iter() {
                        if let Some(scalar) = map.get(&xonly) {
                            res.push((label.clone(), utxo, scalar.clone()));
                            break;
                        }
                    }
                }
                Err(_) => todo!(),
            }
        }
    }

    Ok(res)
}

// Check if this block contains relevant transactions
pub fn check_block_outputs(
    created_utxo_filter: BlockFilter,
    blkhash: BlockHash,
    candidate_spks: Vec<&[u8; 34]>,
) -> Result<bool> {
    // check output scripts
    let output_keys: Vec<_> = candidate_spks
        .into_iter()
        .map(|spk| spk[2..].as_ref())
        .collect();

    // note: match will always return true for an empty query!
    if !output_keys.is_empty() {
        Ok(created_utxo_filter.match_any(&blkhash, &mut output_keys.into_iter())?)
    } else {
        Ok(false)
    }
}

pub fn get_input_hashes(
    blkhash: BlockHash,
    client: &SpClient,
) -> Result<HashMap<Vec<u8>, OutPoint>> {
    let owned = client.list_outpoints();

    let mut map: HashMap<Vec<u8>, OutPoint> = HashMap::new();

    for output in owned {
        let outpoint = OutPoint::from_str(&output.txoutpoint)?;
        let mut arr = [0u8; 68];
        arr[..32].copy_from_slice(&outpoint.txid.to_raw_hash().to_byte_array());
        arr[32..36].copy_from_slice(&outpoint.vout.to_le_bytes());
        arr[36..].copy_from_slice(&blkhash.to_byte_array());
        let hash = sha256::Hash::hash(&arr);

        let mut res = [0u8; 8];
        res.copy_from_slice(&hash[..8]);

        map.insert(res.to_vec(), outpoint);
    }

    Ok(map)
}

// Check if this block contains relevant transactions
pub fn check_block_inputs(
    spent_filter: BlockFilter,
    blkhash: BlockHash,
    input_hashes: Vec<Vec<u8>>,
) -> Result<bool> {
    // note: match will always return true for an empty query!
    if !input_hashes.is_empty() {
        Ok(spent_filter.match_any(&blkhash, &mut input_hashes.into_iter())?)
    } else {
        Ok(false)
    }
}
