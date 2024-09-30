use std::{collections::HashMap, str::FromStr};

use bip39::rand::RngCore;
use log::info;
use pushtx::Network;
use sp_client::bitcoin;
use sp_client::bitcoin::{consensus::encode::serialize_hex, OutPoint, Psbt};
use sp_client::SpClient;

use crate::wallet::SpWallet;

use super::structs::{Amount, OwnedOutput, Recipient};
use anyhow::{anyhow, Error, Result};

#[flutter_rust_bridge::frb(sync)]
pub fn create_new_psbt(
    encoded_wallet: String,
    inputs: HashMap<String, OwnedOutput>,
    recipients: Vec<Recipient>,
) -> Result<(String, Option<usize>)> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;

    // convert to spclient inputs
    let inputs = inputs
        .into_iter()
        .map(|(outpoint, output)| (OutPoint::from_str(&outpoint).unwrap(), output.into()))
        .collect();

    let recipients = recipients.into_iter().map(Into::into).collect();

    let (psbt, change_idx) = wallet.client.create_new_psbt(inputs, recipients, None)?;

    Ok((psbt.to_string(), change_idx))
}

// payer is an address, either Silent Payment or not
#[flutter_rust_bridge::frb(sync)]
pub fn add_fee_for_fee_rate(psbt: String, fee_rate: u32, payer: String) -> Result<String> {
    let mut psbt = Psbt::from_str(&psbt)?;

    SpClient::set_fees(&mut psbt, Amount(fee_rate.into()).into(), payer)?;

    Ok(psbt.to_string())
}

#[flutter_rust_bridge::frb(sync)]
pub fn fill_sp_outputs(encoded_wallet: String, psbt: String) -> Result<String> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    let mut psbt = Psbt::from_str(&psbt)?;

    let partial_secret = wallet.client.get_partial_secret_from_psbt(&psbt)?;

    wallet.client.fill_sp_outputs(&mut psbt, partial_secret)?;

    Ok(psbt.to_string())
}

#[flutter_rust_bridge::frb(sync)]
pub fn sign_psbt(encoded_wallet: String, psbt: String, finalize: bool) -> Result<String> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    let psbt = Psbt::from_str(&psbt)?;

    let mut rng = sp_client::silentpayments::secp256k1::rand::thread_rng();
    let mut aux_rand = [0u8; 32];
    rng.fill_bytes(&mut aux_rand);

    let mut signed = wallet.client.sign_psbt(psbt, &aux_rand)?;

    if finalize {
        SpClient::finalize_psbt(&mut signed)?;
    }

    Ok(signed.to_string())
}

#[flutter_rust_bridge::frb(sync)]
pub fn extract_tx_from_psbt(psbt: String) -> Result<String> {
    let psbt = Psbt::from_str(&psbt)?;

    let final_tx = psbt.extract_tx()?;
    Ok(serialize_hex(&final_tx))
}

pub async fn broadcast_tx(tx: String, network: String) -> Result<String> {
    let tx: pushtx::Transaction = tx.parse().unwrap();

    let txid = tx.txid();

    let network = bitcoin::Network::from_core_arg(&network)?;

    let network = match network {
        bitcoin::Network::Bitcoin => Network::Mainnet,
        bitcoin::Network::Testnet => Network::Testnet,
        bitcoin::Network::Signet => Network::Signet,
        bitcoin::Network::Regtest => Network::Regtest,
        _ => return Err(Error::msg("unknown network for broadcasting")),
    };

    let opts = pushtx::Opts {
        network,
        ..Default::default()
    };

    tokio::task::spawn_blocking(move || {
        let receiver = pushtx::broadcast(vec![tx], opts);

        loop {
            match receiver.recv().unwrap() {
                pushtx::Info::Done(Ok(report)) => {
                    if report.success.len() > 0 {
                        info!("broadcasted {} transactions", report.success.len());
                        break;
                    } else {
                         return Err(Error::msg("Failed to broadcast transaction, probably unable to connect to Tor peers"));
                    }
                }
                pushtx::Info::Done(Err(err)) => return Err(anyhow!(err.to_string())),
                _ => {}
            }
        }
        Ok(())
    })
    .await??;

    Ok(txid.to_string())
}

#[flutter_rust_bridge::frb(sync)]
pub fn read_amt_from_psbt_output(psbt: String, idx: usize) -> Result<u64> {
    let psbt = Psbt::from_str(&psbt)?;
    let tx = psbt.extract_tx()?;

    if tx.output.len() > idx {
        let amt = tx.output.get(idx).unwrap().value;
        Ok(amt.to_sat())
    } else {
        Err(Error::msg("idx not in range of output length"))
    }
}
