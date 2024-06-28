use std::{collections::HashMap, str::FromStr};

use serde::{Deserialize, Serialize};

use bip39::rand::RngCore;
use bitcoin::{
    consensus::encode::serialize_hex,
    secp256k1::{PublicKey, SecretKey},
    Network, OutPoint, Txid,
};

use crate::frb_generated::StreamSink;
use log::info;

use crate::{
    blindbit,
    logger::{self, LogEntry, LogLevel},
    stream::{self, ScanProgress},
};

use anyhow::{anyhow, Error, Result};

use sp_client::spclient::{derive_keys_from_seed, Psbt, SpClient, SpWallet, SpendKey};

const PASSPHRASE: &str = ""; // no passphrase for now

type SpendingTxId = String;
type MinedInBlock = String;

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum OutputSpendStatus {
    Unspent,
    Spent(SpendingTxId),
    Mined(MinedInBlock),
}

impl From<sp_client::spclient::OutputSpendStatus> for OutputSpendStatus {
    fn from(value: sp_client::spclient::OutputSpendStatus) -> Self {
        match value {
            sp_client::spclient::OutputSpendStatus::Unspent => OutputSpendStatus::Unspent,
            sp_client::spclient::OutputSpendStatus::Spent(txid) => OutputSpendStatus::Spent(txid),
            sp_client::spclient::OutputSpendStatus::Mined(block) => OutputSpendStatus::Mined(block),
        }
    }
}

impl From<OutputSpendStatus> for sp_client::spclient::OutputSpendStatus {
    fn from(value: OutputSpendStatus) -> Self {
        match value {
            OutputSpendStatus::Unspent => sp_client::spclient::OutputSpendStatus::Unspent,
            OutputSpendStatus::Spent(txid) => sp_client::spclient::OutputSpendStatus::Spent(txid),
            OutputSpendStatus::Mined(block) => sp_client::spclient::OutputSpendStatus::Mined(block),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct Amount(pub u64);

impl From<bitcoin::Amount> for Amount {
    fn from(value: bitcoin::Amount) -> Self {
        Amount(value.to_sat())
    }
}

impl From<Amount> for bitcoin::Amount {
    fn from(value: Amount) -> bitcoin::Amount {
        bitcoin::Amount::from_sat(value.0)
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct OwnedOutput {
    pub blockheight: u32,
    pub tweak: String,
    pub amount: Amount,
    pub script: String,
    pub label: Option<String>,
    pub spend_status: OutputSpendStatus,
}

impl From<sp_client::spclient::OwnedOutput> for OwnedOutput {
    fn from(value: sp_client::spclient::OwnedOutput) -> Self {
        OwnedOutput {
            blockheight: value.blockheight,
            tweak: value.tweak,
            amount: value.amount.into(),
            script: value.script,
            label: value.label,
            spend_status: value.spend_status.into(),
        }
    }
}

impl From<OwnedOutput> for sp_client::spclient::OwnedOutput {
    fn from(value: OwnedOutput) -> Self {
        sp_client::spclient::OwnedOutput {
            blockheight: value.blockheight,
            tweak: value.tweak,
            amount: value.amount.into(),
            script: value.script,
            label: value.label,
            spend_status: value.spend_status.into(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct Recipient {
    pub address: String, // either old school or silent payment
    pub amount: Amount,
    pub nb_outputs: u32, // if address is not SP, only 1 is valid
}

impl From<sp_client::spclient::Recipient> for Recipient {
    fn from(value: sp_client::spclient::Recipient) -> Self {
        Recipient {
            address: value.address,
            amount: value.amount.into(),
            nb_outputs: value.nb_outputs,
        }
    }
}

impl From<Recipient> for sp_client::spclient::Recipient {
    fn from(value: Recipient) -> Self {
        sp_client::spclient::Recipient {
            address: value.address,
            amount: value.amount.into(),
            nb_outputs: value.nb_outputs,
        }
    }
}
pub struct WalletStatus {
    pub address: String,
    pub balance: u64,
    pub birthday: u32,
    pub last_scan: u32,
    pub outputs: HashMap<String, OwnedOutput>,
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_log_stream(s: StreamSink<LogEntry>, level: LogLevel, log_dependencies: bool) {
    logger::init_logger(level.into(), log_dependencies);
    logger::FlutterLogger::set_stream_sink(s);
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_scan_progress_stream(s: StreamSink<ScanProgress>) {
    stream::create_scan_progress_stream(s);
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_amount_stream(s: StreamSink<u64>) {
    stream::create_amount_stream(s);
}

pub async fn setup(
    label: String,
    mnemonic: Option<String>,
    scan_key: Option<String>,
    spend_key: Option<String>,
    birthday: u32,
    network: String,
) -> Result<String> {
    let sp_client: SpClient;

    let network = match network.as_str() {
        "main" => Network::Bitcoin,
        "testnet" => Network::Testnet,
        "signet" => Network::Signet,
        "regtest" => Network::Regtest,
        _ => return Err(Error::msg("unknown network")),
    };

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
    let mut sp_wallet = SpWallet::new(sp_client, None).unwrap();

    sp_wallet.get_mut_outputs().set_birthday(birthday);
    sp_wallet.get_mut_outputs().reset_to_birthday();

    Ok(serde_json::to_string(&sp_wallet).unwrap())
}

/// Change wallet birthday
/// Reset the output list and last_scan
#[flutter_rust_bridge::frb(sync)]
pub fn change_birthday(encoded_wallet: String, birthday: u32) -> Result<String> {
    let mut wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    let outputs = wallet.get_mut_outputs();
    outputs.set_birthday(birthday);
    outputs.reset_to_birthday();
    Ok(serde_json::to_string(&wallet).unwrap())
}

/// Reset the last_scan of the wallet to its birthday, removing all outpoints
#[flutter_rust_bridge::frb(sync)]
pub fn reset_wallet(encoded_wallet: String) -> Result<String> {
    let mut wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    let outputs = wallet.get_mut_outputs();
    outputs.reset_to_birthday();
    Ok(serde_json::to_string(&wallet).unwrap())
}

pub async fn sync_blockchain() -> Result<u32> {
    blindbit::logic::sync_blockchain().await
}

pub async fn scan_to_tip(encoded_wallet: String) -> Result<String> {
    let mut wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    blindbit::logic::scan_blocks(0, &mut wallet).await?;
    Ok(serde_json::to_string(&wallet).unwrap())
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_wallet_info(encoded_wallet: String) -> Result<WalletStatus> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    Ok(WalletStatus {
        address: wallet.get_client().get_receiving_address(),
        balance: wallet.get_outputs().get_balance().to_sat(),
        birthday: wallet.get_outputs().get_birthday(),
        last_scan: wallet.get_outputs().get_last_scan(),
        outputs: wallet
            .get_outputs()
            .to_outpoints_list()
            .into_iter()
            .map(|(outpoint, output)| (outpoint.to_string(), output.into()))
            .collect(),
    })
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_new_psbt(
    encoded_wallet: String,
    inputs: HashMap<String, OwnedOutput>,
    recipients: Vec<Recipient>,
) -> Result<String> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;

    // convert to spclient inputs
    let inputs = inputs
        .into_iter()
        .map(|(outpoint, output)| (OutPoint::from_str(&outpoint).unwrap(), output.into()))
        .collect();

    let recipients = recipients.into_iter().map(Into::into).collect();

    let psbt = wallet
        .get_client()
        .create_new_psbt(inputs, recipients, None)?;

    Ok(psbt.to_string())
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

    let partial_secret = wallet.get_client().get_partial_secret_from_psbt(&psbt)?;

    wallet
        .get_client()
        .fill_sp_outputs(&mut psbt, partial_secret)?;

    Ok(psbt.to_string())
}

#[flutter_rust_bridge::frb(sync)]
pub fn sign_psbt(encoded_wallet: String, psbt: String, finalize: bool) -> Result<String> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    let psbt = Psbt::from_str(&psbt)?;

    let mut rng = sp_client::silentpayments::secp256k1::rand::thread_rng();
    let mut aux_rand = [0u8; 32];
    rng.fill_bytes(&mut aux_rand);

    let mut signed = wallet.get_client().sign_psbt(psbt, &aux_rand)?;

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

#[flutter_rust_bridge::frb(sync)]
pub fn broadcast_tx(tx: String) -> Result<String> {
    let tx: pushtx::Transaction = tx.parse().unwrap();

    let txid = tx.txid();

    let opts = pushtx::Opts {
        network: pushtx::Network::Signet,
        ..Default::default()
    };

    let receiver = pushtx::broadcast(vec![tx], opts);

    loop {
        match receiver.recv().unwrap() {
            pushtx::Info::Done(Ok(report)) => {
                info!("broadcasted to {} peers", report.broadcasts);
                break;
            }
            pushtx::Info::Done(Err(err)) => return Err(anyhow!(err.to_string())),
            _ => {}
        }
    }

    Ok(txid.to_string())
}

#[flutter_rust_bridge::frb(sync)]
pub fn mark_outpoints_spent(
    encoded_wallet: String,
    spent_by: String,
    spent: Vec<String>,
) -> Result<String> {
    let mut wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;

    for outpoint in spent {
        wallet.get_mut_outputs().mark_spent(
            OutPoint::from_str(&outpoint)?,
            Txid::from_str(&spent_by)?,
            true,
        )?;
    }

    Ok(serde_json::to_string(&wallet)?)
}

#[flutter_rust_bridge::frb(sync)]
pub fn show_mnemonic(encoded_wallet: String) -> Result<Option<String>> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    let mnemonic = wallet.get_client().get_mnemonic();

    Ok(mnemonic)
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
