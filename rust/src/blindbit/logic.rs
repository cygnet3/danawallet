use std::{collections::HashMap, time::Instant};

use anyhow::{Error, Result};
use bitcoin::{
    bip158::BlockFilter,
    hashes::{sha256, Hash},
    secp256k1::{PublicKey, Scalar},
    Amount, BlockHash, OutPoint, Txid, XOnlyPublicKey,
};
use futures::{stream, StreamExt};
use log::info;
use sp_client::spclient::{OutputSpendStatus, OwnedOutput, SpClient};
use sp_client::{
    silentpayments::receiving::Label,
    spclient::{OutputList, SpWallet},
};

use crate::stream::{send_amount_update, send_scan_progress, ScanProgress};
use crate::blindbit::client::{BlindbitClient, UtxoResponse};

use super::client::FilterResponse;

const HOST: &str = "https://silentpayments.dev/blindbit/signet";
const CONCURRENT_FILTER_REQUESTS: usize = 200;

pub async fn sync_blockchain() -> Result<u32> {
    let blindbit_client = BlindbitClient::new(HOST.to_string());

    let height = blindbit_client.block_height().await?;

    Ok(height)
}

pub async fn scan_blocks(mut n_blocks_to_scan: u32, sp_wallet: &mut SpWallet) -> Result<()> {
    let blindbit_client = BlindbitClient::new(HOST.to_string());

    let last_scan = sp_wallet.get_outputs().get_last_scan();
    let tip_height = blindbit_client.block_height().await?;

    // 0 means scan to tip
    if n_blocks_to_scan == 0 {
        n_blocks_to_scan = tip_height - last_scan;
    }

    let start = last_scan + 1;
    let end = if last_scan + n_blocks_to_scan <= tip_height {
        last_scan + n_blocks_to_scan
    } else {
        tip_height
    };

    if start > end {
        info!("scan_blocks called with start > end: {} > {}", start, end);
        return Ok(());
    }

    info!("start: {} end: {}", start, end);
    let start_time: Instant = Instant::now();

    let range = start..=end;

    let mut data = stream::iter(range)
        .map(|n| {
            let bb_client = &blindbit_client;
            async move {
                let tweaks = bb_client.tweak_index(n).await.unwrap();
                let new_utxo_filter = bb_client.filter_new_utxos(n).await.unwrap();
                let spent_filter = bb_client.filter_spent(n).await.unwrap();
                let blkhash = new_utxo_filter.block_hash;
                (n, blkhash, tweaks, new_utxo_filter, spent_filter)
            }
        })
        .buffered(CONCURRENT_FILTER_REQUESTS);

    while let Some((blkheight, blkhash, tweaks, new_utxo_filter, spent_filter)) = data.next().await
    {
        let (found_outputs, found_inputs) = process_block(
            blkheight,
            tweaks,
            new_utxo_filter,
            spent_filter,
            sp_wallet,
            &blindbit_client,
        )
        .await?;

        send_scan_progress(ScanProgress {
            start,
            current: blkheight,
            end,
        });

        if !found_outputs.is_empty() {
            sp_wallet.get_mut_outputs().extend_from(found_outputs);

            send_amount_update(sp_wallet.get_outputs().get_balance().to_sat());
        }

        if !found_inputs.is_empty() {
            for outpoint in found_inputs {
                sp_wallet.get_mut_outputs().mark_mined(outpoint, blkhash)?;
            }
        }
    }

    // time elapsed for the scan
    info!(
        "Blindbit scan complete in {} seconds",
        start_time.elapsed().as_secs()
    );

    // update last_scan height
    sp_wallet.get_mut_outputs().update_last_scan(tip_height);
    Ok(())
}

pub async fn process_block(
    blkheight: u32,
    tweaks: Vec<PublicKey>,
    new_utxo_filter: FilterResponse,
    spent_filter: FilterResponse,
    sp_wallet: &SpWallet,
    blindbit_client: &BlindbitClient,
) -> Result<(HashMap<OutPoint, OwnedOutput>, Vec<OutPoint>)> {
    let outs = process_block_outputs(
        blkheight,
        tweaks,
        new_utxo_filter,
        sp_wallet.get_client(),
        blindbit_client,
    )
    .await?;

    let ins = process_block_inputs(
        blkheight,
        spent_filter,
        sp_wallet.get_outputs(),
        blindbit_client,
    )
    .await?;

    Ok((outs, ins))
}

pub async fn process_block_outputs(
    blkheight: u32,
    tweaks: Vec<PublicKey>,
    new_utxo_filter: FilterResponse,
    sp_client: &SpClient,
    blindbit_client: &BlindbitClient,
) -> Result<HashMap<OutPoint, OwnedOutput>> {
    let mut res = HashMap::new();

    if !tweaks.is_empty() {
        let secrets_map = sp_client.get_script_to_secret_map(tweaks).unwrap();

        //last_scan = last_scan.max(n as u32);
        let candidate_spks: Vec<&[u8; 34]> = secrets_map.keys().collect();

        //get block gcs & check match
        let blkfilter = BlockFilter::new(&hex::decode(new_utxo_filter.data)?);
        let blkhash = new_utxo_filter.block_hash;

        let matched_outputs = check_block_outputs(blkfilter, blkhash, candidate_spks)?;

        //if match: fetch and scan utxos
        if matched_outputs {
            info!("matched outputs on: {}", blkheight);
            let utxos = blindbit_client.utxos(blkheight).await?;
            let found = scan_utxos(utxos, secrets_map, &sp_client).await?;

            if !found.is_empty() {
                for (label, utxo, tweak) in found {
                    let outpoint = OutPoint {
                        txid: utxo.txid,
                        vout: utxo.vout,
                    };

                    let out = OwnedOutput {
                        blockheight: blkheight,
                        tweak: hex::encode(tweak.to_be_bytes()),
                        amount: Amount::from_sat(utxo.value),
                        script: utxo.scriptpubkey.to_hex_string(),
                        label: label.map(|l| l.as_string()),
                        spend_status: OutputSpendStatus::Unspent,
                    };

                    res.insert(outpoint, out);
                }
            }
        }
    }
    Ok(res)
}

pub async fn process_block_inputs(
    blkheight: u32,
    spent_filter: FilterResponse,
    outputs: &OutputList,
    blindbit_client: &BlindbitClient,
) -> Result<Vec<OutPoint>> {
    let mut res = vec![];

    let blkhash = spent_filter.block_hash;

    // first get the 8-byte hashes used to construct the input filter
    let input_hashes_map = get_input_hashes(blkhash, outputs)?;

    // check against filter
    let blkfilter = BlockFilter::new(&hex::decode(spent_filter.data)?);
    let matched_inputs = check_block_inputs(
        blkfilter,
        blkhash,
        input_hashes_map.keys().cloned().collect(),
    )?;

    // if match: download spent data, collect the outpoints that are spent
    if matched_inputs {
        info!("matched inputs on: {}", blkheight);
        let spent = blindbit_client.spent_index(blkheight).await?.data;

        for spent in spent {
            let hex: &[u8] = spent.hex.as_ref();

            if let Some(outpoint) = input_hashes_map.get(hex) {
                res.push(*outpoint)
            }
        }
    }
    Ok(res)
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
    outputs: &OutputList,
) -> Result<HashMap<[u8; 8], OutPoint>> {
    let owned = outputs.to_outpoints_list();

    let mut map: HashMap<[u8; 8], OutPoint> = HashMap::new();

    for (outpoint, _) in owned {
        let mut arr = [0u8; 68];
        arr[..32].copy_from_slice(&outpoint.txid.to_raw_hash().to_byte_array());
        arr[32..36].copy_from_slice(&outpoint.vout.to_le_bytes());
        arr[36..].copy_from_slice(&blkhash.to_byte_array());
        let hash = sha256::Hash::hash(&arr);

        let mut res = [0u8; 8];
        res.copy_from_slice(&hash[..8]);

        map.insert(res, outpoint);
    }

    Ok(map)
}

// Check if this block contains relevant transactions
pub fn check_block_inputs(
    spent_filter: BlockFilter,
    blkhash: BlockHash,
    input_hashes: Vec<[u8; 8]>,
) -> Result<bool> {
    // note: match will always return true for an empty query!
    if !input_hashes.is_empty() {
        Ok(spent_filter.match_any(&blkhash, &mut input_hashes.into_iter())?)
    } else {
        Ok(false)
    }
}
