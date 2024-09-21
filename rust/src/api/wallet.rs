use std::str::FromStr;

use crate::{
    blindbit,
    scanner::SpScanner,
    wallet::{utils::derive_keys_from_seed, SpWallet, WalletUpdater},
};
use anyhow::{Error, Result};
use reqwest::Url;
use sp_client::{
    bitcoin::{
        absolute::Height,
        secp256k1::{PublicKey, SecretKey},
        Network, OutPoint, Txid,
    },
    spclient::{SpClient, SpendKey},
};

use super::structs::{Amount, Recipient, WalletStatus};

const PASSPHRASE: &str = ""; // no passphrase for now

pub async fn setup(
    label: String,
    mnemonic: Option<String>,
    scan_key: Option<String>,
    spend_key: Option<String>,
    birthday: u32,
    network: String,
) -> Result<String> {
    let sp_client: SpClient;

    let network = Network::from_core_arg(&network)?;

    match (mnemonic, scan_key, spend_key) {
        (None, None, None) => {
            // We create a new wallet and return the new mnemonic
            let m = bip39::Mnemonic::generate(12).unwrap();
            let seed = m.to_seed(PASSPHRASE);
            let (scan_sk, spend_sk) = derive_keys_from_seed(&seed, network)?;
            sp_client = SpClient::new(
                label,
                scan_sk,
                SpendKey::Secret(spend_sk),
                Some(m.to_string()),
                network,
            )?;
        }
        (mnemonic, None, None) => {
            // We restore from seed
            let m = bip39::Mnemonic::from_str(mnemonic.as_ref().unwrap()).unwrap();
            let seed = m.to_seed(PASSPHRASE);
            let (scan_sk, spend_sk) = derive_keys_from_seed(&seed, network)?;
            sp_client = SpClient::new(
                label,
                scan_sk,
                SpendKey::Secret(spend_sk),
                mnemonic,
                network,
            )?;
        }
        (None, scan_sk_hex, spend_key_hex) => {
            // We directly restore with the keys
            let scan_sk = SecretKey::from_str(scan_sk_hex.as_ref().unwrap())?;
            if let Ok(spend_key) = SecretKey::from_str(spend_key_hex.as_ref().unwrap()) {
                sp_client =
                    SpClient::new(label, scan_sk, SpendKey::Secret(spend_key), None, network)?;
            } else if let Ok(spend_key) = PublicKey::from_str(spend_key_hex.as_ref().unwrap()) {
                sp_client =
                    SpClient::new(label, scan_sk, SpendKey::Public(spend_key), None, network)?;
            } else {
                return Err(Error::msg("Can't parse spend key".to_owned()));
            }
        }
        _ => {
            return Err(Error::msg(
                "Invalid combination of mnemonic and keys".to_owned(),
            ))
        }
    }
    let sp_wallet = SpWallet::new(sp_client, birthday).unwrap();

    Ok(serde_json::to_string(&sp_wallet).unwrap())
}

/// Change wallet birthday
/// Reset the output list and last_scan
#[flutter_rust_bridge::frb(sync)]
pub fn change_birthday(encoded_wallet: String, birthday: u32) -> Result<String> {
    let mut wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    wallet.birthday = Height::from_consensus(birthday)?;
    wallet.reset_to_birthday();
    Ok(serde_json::to_string(&wallet).unwrap())
}

/// Reset the last_scan of the wallet to its birthday, removing all outpoints
#[flutter_rust_bridge::frb(sync)]
pub fn reset_wallet(encoded_wallet: String) -> Result<String> {
    let mut wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    wallet.reset_to_birthday();
    Ok(serde_json::to_string(&wallet).unwrap())
}

pub async fn scan_to_tip(
    blindbit_url: String,
    dust_limit: u64,
    encoded_wallet: String,
) -> Result<()> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;

    let blindbit_url = Url::parse(&blindbit_url)?;
    let blindbit_client = blindbit::BlindbitClient::new(blindbit_url);

    let dust_limit = sp_client::bitcoin::Amount::from_sat(dust_limit);

    let start = Height::from_consensus(wallet.last_scan.to_consensus_u32() + 1)?;
    let end = blindbit_client.block_height().await?;

    let owned_outpoints = wallet.outputs.keys().cloned().collect();

    let sp_client = wallet.client.clone();
    let updater = WalletUpdater::new(wallet, start, end);

    let mut scanner = SpScanner::new(
        sp_client,
        Box::new(updater),
        blindbit_client,
        owned_outpoints,
    );

    scanner.scan_blocks(start, end, dust_limit).await?;

    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_wallet_info(encoded_wallet: String) -> Result<WalletStatus> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    Ok(WalletStatus {
        address: wallet.client.get_receiving_address(),
        network: wallet.client.get_network().to_core_arg().to_owned(),
        balance: wallet.get_balance().to_sat(),
        birthday: wallet.birthday.to_consensus_u32(),
        last_scan: wallet.last_scan.to_consensus_u32(),
        tx_history: wallet.tx_history.into_iter().map(Into::into).collect(),
        outputs: wallet
            .outputs
            .into_iter()
            .map(|(outpoint, output)| (outpoint.to_string(), output.into()))
            .collect(),
    })
}

#[flutter_rust_bridge::frb(sync)]
pub fn mark_outpoints_spent(
    encoded_wallet: String,
    spent_by: String,
    spent: Vec<String>,
) -> Result<String> {
    let mut wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;

    for outpoint in spent {
        wallet.mark_spent(
            OutPoint::from_str(&outpoint)?,
            Txid::from_str(&spent_by)?,
            true,
        )?;
    }

    Ok(serde_json::to_string(&wallet)?)
}

#[flutter_rust_bridge::frb(sync)]
pub fn add_outgoing_tx_to_history(
    encoded_wallet: String,
    txid: String,
    spent_outpoints: Vec<String>,
    recipients: Vec<Recipient>,
    change: Amount,
) -> Result<String> {
    let txid = Txid::from_str(&txid)?;
    let spent_outpoints = spent_outpoints
        .into_iter()
        .map(|x| OutPoint::from_str(&x).unwrap())
        .collect();

    let mut wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;

    let recipients = recipients.into_iter().map(Into::into).collect();

    wallet.record_outgoing_transaction(txid, spent_outpoints, recipients, change.into());

    Ok(serde_json::to_string(&wallet)?)
}

#[flutter_rust_bridge::frb(sync)]
pub fn show_mnemonic(encoded_wallet: String) -> Result<Option<String>> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    let mnemonic = wallet.client.get_mnemonic();

    Ok(mnemonic)
}
