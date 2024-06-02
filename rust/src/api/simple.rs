use std::str::FromStr;

use bitcoin::{
    consensus::{encode::serialize_hex, Decodable},
    secp256k1::{PublicKey, SecretKey},
    Transaction,
};

use crate::{frb_generated::StreamSink, stream::send_amount_update};
use log::info;

use crate::{
    blindbit,
    constants::{OutputSpendStatus, OwnedOutput, Recipient, WalletType},
    logger::{self, LogEntry, LogLevel},
    stream::{self, ScanProgress, SyncStatus},
};

use anyhow::{anyhow, Result};

use sp_client::spclient::{derive_keys_from_mnemonic, Psbt, SpClient, SpendKey};

const PASSPHRASE: &str = ""; // no passphrase for now

pub struct WalletStatus {
    pub amount: u64,
    pub birthday: u32,
    pub scan_height: u32,
}

pub fn create_log_stream(s: StreamSink<LogEntry>, level: LogLevel, log_dependencies: bool) {
    logger::init_logger(level.into(), log_dependencies);
    logger::FlutterLogger::set_stream_sink(s);
}
pub fn create_sync_stream(s: StreamSink<SyncStatus>) {
    stream::create_sync_stream(s);
}
pub fn create_scan_progress_stream(s: StreamSink<ScanProgress>) {
    stream::create_scan_progress_stream(s);
}
pub fn create_amount_stream(s: StreamSink<u64>) {
    stream::create_amount_stream(s);
}
pub fn wallet_exists(label: String, files_dir: String) -> bool {
    SpClient::try_init_from_disk(label, files_dir).is_ok()
}

pub async fn setup(
    label: String,
    files_dir: String,
    wallet_type: WalletType,
    birthday: u32,
    is_testnet: bool,
) -> Result<String> {
    if wallet_exists(label.clone(), files_dir.clone()) {
        return Err(anyhow!(label));
    }; // If the wallet already exists we just send the label as an error message

    // TODO lot of repetition here
    match wallet_type {
        WalletType::New => {
            // We create a new wallet and return the new mnemonic
            let (mnemonic, scan_sk, spend_sk) =
                derive_keys_from_mnemonic("", PASSPHRASE, is_testnet)?;
            let sp_client = SpClient::new(
                label,
                scan_sk,
                SpendKey::Secret(spend_sk),
                Some(mnemonic.to_string()),
                birthday,
                is_testnet,
                files_dir,
            )?;
            sp_client.save_to_disk()?;
            Ok(mnemonic.to_string())
        }
        WalletType::Mnemonic(mnemonic) => {
            // We restore from seed
            let (_, scan_sk, spend_sk) =
                derive_keys_from_mnemonic(&mnemonic, PASSPHRASE, is_testnet)?;
            let sp_client = SpClient::new(
                label,
                scan_sk,
                SpendKey::Secret(spend_sk),
                Some(mnemonic),
                birthday,
                is_testnet,
                files_dir,
            )?;
            sp_client.save_to_disk()?;
            Ok("".to_owned())
        }
        WalletType::PrivateKeys(scan_sk_hex, spend_sk_hex) => {
            // We directly restore with the keys
            let scan_sk = SecretKey::from_str(&scan_sk_hex)?;
            let spend_sk = SecretKey::from_str(&spend_sk_hex)?;
            let sp_client = SpClient::new(
                label,
                scan_sk,
                SpendKey::Secret(spend_sk),
                None,
                birthday,
                is_testnet,
                files_dir,
            )?;
            sp_client.save_to_disk()?;
            Ok("".to_owned())
        }
        WalletType::ReadOnly(scan_sk_hex, spend_pk_hex) => {
            // We're only able to find payments but not to spend it
            let scan_sk = SecretKey::from_str(&scan_sk_hex)?;
            let spend_pk = PublicKey::from_str(&spend_pk_hex)?;
            let sp_client = SpClient::new(
                label,
                scan_sk,
                SpendKey::Public(spend_pk),
                None,
                birthday,
                is_testnet,
                files_dir,
            )?;
            sp_client.save_to_disk()?;
            Ok("".to_string())
        }
    }
}

/// Change wallet birthday
/// Since this method doesn't touch the known outputs
/// the caller is responsible for resetting the wallet to its new birthday  
pub fn change_birthday(path: String, label: String, birthday: u32) -> Result<()> {
    match SpClient::try_init_from_disk(label, path) {
        Ok(mut sp_client) => {
            sp_client.birthday = birthday;
            sp_client.save_to_disk()
        }
        Err(_) => Err(anyhow!("Wallet doesn't exist")),
    }
}

/// Reset the last_scan of the wallet to its birthday, removing all outpoints
pub fn reset_wallet(path: String, label: String) -> Result<()> {
    match SpClient::try_init_from_disk(label, path) {
        Ok(sp_client) => {
            let birthday = sp_client.birthday;
            let new = sp_client.reset_from_blockheight(birthday);
            new.save_to_disk()
        }
        Err(_) => Err(anyhow!("Wallet doesn't exist")),
    }
}

pub fn remove_wallet(path: String, label: String) -> Result<()> {
    match SpClient::try_init_from_disk(label, path) {
        Ok(sp_client) => sp_client.delete_from_disk(),
        Err(_) => Err(anyhow!("Wallet doesn't exist")),
    }
}

pub async fn sync_blockchain() -> Result<()> {
    blindbit::logic::sync_blockchain().await
}

pub async fn scan_to_tip(path: String, label: String) -> Result<()> {
    let res = match SpClient::try_init_from_disk(label, path) {
        Err(_) => Err(anyhow!("Wallet not found")),
        Ok(sp_client) => blindbit::logic::scan_blocks(0, sp_client).await,
    };
    res
}

pub fn get_wallet_info(path: String, label: String) -> Result<WalletStatus> {
    let sp_client = match SpClient::try_init_from_disk(label, path) {
        Ok(s) => s,
        Err(_) => return Err(anyhow!("Wallet not found")),
    };

    let scan_height = sp_client.last_scan;
    let birthday = sp_client.birthday;
    let amount = sp_client.get_spendable_amt();

    Ok(WalletStatus {
        amount,
        birthday,
        scan_height,
    })
}

pub fn get_receiving_address(path: String, label: String) -> Result<String> {
    let sp_client: SpClient = match SpClient::try_init_from_disk(label, path) {
        Ok(s) => s,
        Err(_) => return Err(anyhow!("Wallet not found")),
    };

    Ok(sp_client.get_receiving_address())
}

pub fn get_spendable_outputs(path: String, label: String) -> Result<Vec<OwnedOutput>> {
    let outputs = get_outputs(path, label)?;

    Ok(outputs
        .into_iter()
        .filter(|o| o.spend_status == OutputSpendStatus::Unspent)
        .collect())
}

pub fn get_outputs(path: String, label: String) -> Result<Vec<OwnedOutput>> {
    let sp_client: SpClient = match SpClient::try_init_from_disk(label, path) {
        Ok(s) => s,
        Err(_) => return Err(anyhow!("Wallet not found")),
    };

    Ok(sp_client
        .list_outpoints()
        .into_iter()
        .map(Into::into)
        .collect())
}

pub fn create_new_psbt(
    label: String,
    path: String,
    inputs: Vec<OwnedOutput>,
    recipients: Vec<Recipient>,
) -> Result<String> {
    let sp_client: SpClient = match SpClient::try_init_from_disk(label, path) {
        Ok(s) => s,
        Err(_) => return Err(anyhow!("Wallet not found")),
    };

    // convert to spclient inputs
    let inputs = inputs.into_iter().map(Into::into).collect();
    let recipients = recipients.into_iter().map(Into::into).collect();

    let psbt = sp_client.create_new_psbt(inputs, recipients)?;

    Ok(psbt.to_string())
}

// payer is an address, either Silent Payment or not
pub fn add_fee_for_fee_rate(psbt: String, fee_rate: u32, payer: String) -> Result<String> {
    let mut psbt = Psbt::from_str(&psbt)?;

    SpClient::set_fees(&mut psbt, fee_rate, payer)?;

    Ok(psbt.to_string())
}

pub fn fill_sp_outputs(path: String, label: String, psbt: String) -> Result<String> {
    let sp_client: SpClient = match SpClient::try_init_from_disk(label, path) {
        Ok(s) => s,
        Err(_) => return Err(anyhow!("Wallet not found")),
    };

    let mut psbt = Psbt::from_str(&psbt)?;

    sp_client.fill_sp_outputs(&mut psbt)?;

    Ok(psbt.to_string())
}

pub fn sign_psbt(path: String, label: String, psbt: String, finalize: bool) -> Result<String> {
    let sp_client: SpClient = match SpClient::try_init_from_disk(label, path) {
        Ok(s) => s,
        Err(_) => return Err(anyhow!("Wallet not found")),
    };

    let psbt = Psbt::from_str(&psbt)?;

    let mut signed = sp_client.sign_psbt(psbt)?;

    if finalize {
        SpClient::finalize_psbt(&mut signed)?;
    }

    Ok(signed.to_string())
}

pub fn extract_tx_from_psbt(psbt: String) -> Result<String> {
    let psbt = Psbt::from_str(&psbt)?;

    let final_tx = psbt.extract_tx()?;
    Ok(serialize_hex(&final_tx))
}

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

pub fn mark_transaction_inputs_as_spent(path: String, label: String, tx: String) -> Result<()> {
    let mut sp_client: SpClient = match SpClient::try_init_from_disk(label, path) {
        Ok(s) => s,
        Err(_) => return Err(anyhow!("Wallet not found")),
    };

    let tx_bytes = hex::decode(tx)?;

    let tx = Transaction::consensus_decode(&mut tx_bytes.as_slice())?;

    sp_client.mark_transaction_inputs_as_spent(tx)?;

    send_amount_update(sp_client.get_spendable_amt());

    Ok(())
}

pub fn show_mnemonic(path: String, label: String) -> Result<Option<String>> {
    let sp_client: SpClient = match SpClient::try_init_from_disk(label, path) {
        Ok(s) => s,
        Err(_) => return Err(anyhow::Error::msg("Wallet not found")),
    };

    let mnemonic = sp_client.mnemonic;

    Ok(mnemonic)
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
