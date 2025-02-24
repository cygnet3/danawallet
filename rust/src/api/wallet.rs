use std::{collections::HashMap, str::FromStr};

use crate::{
    state::{OwnedOutputs, StateUpdater, TxHistory},
    wallet::{utils::derive_keys_from_seed, SpWallet, KEEP_SCANNING},
};
use anyhow::Result;
use bip39::rand::{thread_rng, RngCore};
use sp_client::{
    bitcoin::{
        absolute::Height,
        consensus::serialize,
        hex::DisplayHex,
        secp256k1::{PublicKey, SecretKey},
        Network, OutPoint,
    },
    BlindbitBackend, ChainBackend, OwnedOutput, Recipient, RecipientAddress, SpClient, SpScanner,
    SpendKey,
};

use super::structs::{
    ApiOwnedOutput, ApiRecipient, ApiRecordedTransaction, ApiSetupResult, ApiSetupWalletArgs,
    ApiSetupWalletType, ApiSilentPaymentUnsignedTransaction, ApiWalletStatus,
};

/// we enable cutthrough by default, no need to let the user decide
const ENABLE_CUTTHROUGH: bool = true;
/// we don't add a passphrase to the bip39 mnemonic
const PASSPHRASE: &str = "";

#[flutter_rust_bridge::frb(sync)]
pub fn setup_wallet(setup_args: ApiSetupWalletArgs) -> Result<ApiSetupResult> {
    let ApiSetupWalletArgs {
        setup_type,
        birthday,
        network,
    } = setup_args;

    let network = Network::from_core_arg(&network)?;

    match setup_type {
        ApiSetupWalletType::NewWallet => {
            // We create a new wallet and return the new mnemonic
            let m = bip39::Mnemonic::generate(12)?;
            let seed = m.to_seed(PASSPHRASE);
            let (scan_sk, spend_sk) = derive_keys_from_seed(&seed, network)?;
            let sp_client = SpClient::new(scan_sk, SpendKey::Secret(spend_sk), network)?;

            let sp_wallet = SpWallet::new(sp_client, birthday)?;

            let wallet_blob = serde_json::to_string(&sp_wallet)?;
            Ok(ApiSetupResult {
                mnemonic: Some(m.to_string()),
                wallet_blob,
            })
        }
        ApiSetupWalletType::Mnemonic(mnemonic) => {
            // We restore from seed
            let m = bip39::Mnemonic::from_str(&mnemonic)?;
            let seed = m.to_seed(PASSPHRASE);
            let (scan_sk, spend_sk) = derive_keys_from_seed(&seed, network)?;
            let sp_client = SpClient::new(scan_sk, SpendKey::Secret(spend_sk), network)?;

            let sp_wallet = SpWallet::new(sp_client, birthday)?;
            let wallet_blob = serde_json::to_string(&sp_wallet)?;

            Ok(ApiSetupResult {
                mnemonic: Some(mnemonic),
                wallet_blob,
            })
        }
        ApiSetupWalletType::Full(scan_sk_hex, spend_sk_hex) => {
            let scan_sk = SecretKey::from_str(&scan_sk_hex)?;
            let spend_sk = SecretKey::from_str(&spend_sk_hex)?;

            let sp_client = SpClient::new(scan_sk, SpendKey::Secret(spend_sk), network)?;

            let sp_wallet = SpWallet::new(sp_client, birthday).unwrap();
            let wallet_blob = serde_json::to_string(&sp_wallet)?;

            Ok(ApiSetupResult {
                mnemonic: None,
                wallet_blob,
            })
        }
        ApiSetupWalletType::WatchOnly(scan_sk_hex, spend_pk_hex) => {
            let scan_sk = SecretKey::from_str(&scan_sk_hex)?;
            let spend_pk = PublicKey::from_str(&spend_pk_hex)?;

            let sp_client = SpClient::new(scan_sk, SpendKey::Public(spend_pk), network)?;

            let sp_wallet = SpWallet::new(sp_client, birthday).unwrap();
            let wallet_blob = serde_json::to_string(&sp_wallet)?;

            Ok(ApiSetupResult {
                mnemonic: None,
                wallet_blob,
            })
        }
    }
}

pub async fn scan_to_tip(
    blindbit_url: String,
    last_scan: u32,
    dust_limit: u64,
    encoded_wallet: String,
    encoded_history: String,
    encoded_owned_outputs: String,
) -> Result<()> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    let tx_history: TxHistory = serde_json::from_str(&encoded_history)?;
    let owned_outputs: OwnedOutputs = serde_json::from_str(&encoded_owned_outputs)?;

    let backend = BlindbitBackend::new(blindbit_url)?;

    let dust_limit = sp_client::bitcoin::Amount::from_sat(dust_limit);

    let start = Height::from_consensus(last_scan + 1)?;
    let end = backend.block_height().await?;

    let owned_outpoints = owned_outputs.get_owned_outpoints();

    let sp_client = wallet.client.clone();
    let updater = StateUpdater::new(
        tx_history,
        owned_outputs,
        Height::from_consensus(last_scan)?,
    );

    KEEP_SCANNING.store(true, std::sync::atomic::Ordering::Relaxed);

    let mut scanner = SpScanner::new(
        sp_client,
        Box::new(updater),
        Box::new(backend),
        owned_outpoints,
        &KEEP_SCANNING,
    );

    scanner
        .scan_blocks(start, end, dust_limit, ENABLE_CUTTHROUGH)
        .await?;

    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn interrupt_scanning() {
    KEEP_SCANNING.store(false, std::sync::atomic::Ordering::Relaxed);
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_wallet_info(encoded_wallet: String) -> Result<ApiWalletStatus> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    Ok(ApiWalletStatus {
        address: wallet.client.get_receiving_address().to_string(),
        network: Some(wallet.client.get_network().to_core_arg().to_owned()),
        change_address: wallet.client.sp_receiver.get_change_address().to_string(),
        birthday: wallet.birthday.to_consensus_u32(),
    })
}

#[flutter_rust_bridge::frb(sync)]
/// Only call this when we expect this value to be present
pub fn get_wallet_last_scan(encoded_wallet: String) -> Result<u32> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;

    Ok(wallet.last_scan.unwrap().to_consensus_u32())
}

#[flutter_rust_bridge::frb(sync)]
/// Only call this when we expect this value to be present
pub fn get_wallet_tx_history(encoded_wallet: String) -> Result<String> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;

    let history: Vec<ApiRecordedTransaction> = wallet
        .tx_history
        .unwrap()
        .into_iter()
        .map(Into::into)
        .collect();

    Ok(serde_json::to_string(&history)?)
}

#[flutter_rust_bridge::frb(sync)]
/// Only call this when we expect this value to be present
pub fn get_wallet_owned_outputs(encoded_wallet: String) -> Result<String> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;

    let owned_outputs: HashMap<String, ApiOwnedOutput> = wallet
        .outputs
        .unwrap()
        .into_iter()
        .map(|(outpoint, output)| (outpoint.to_string(), output.into()))
        .collect();

    Ok(serde_json::to_string(&owned_outputs)?)
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_new_transaction(
    encoded_wallet: String,
    api_outputs: HashMap<String, ApiOwnedOutput>,
    api_recipients: Vec<ApiRecipient>,
    feerate: f32,
    network: String,
) -> Result<ApiSilentPaymentUnsignedTransaction> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    let client = wallet.client;
    let available_utxos: Result<Vec<(OutPoint, OwnedOutput)>> = api_outputs
        .into_iter()
        .map(|(string, output)| {
            let outpoint = OutPoint::from_str(&string)?;
            Ok((outpoint, output.into()))
        })
        .collect();
    let recipients: Vec<Recipient> = api_recipients
        .into_iter()
        .map(|r| r.try_into().unwrap())
        .collect();
    let core_network = Network::from_core_arg(&network)?;
    let res = client.create_new_transaction(available_utxos?, recipients, feerate, core_network)?;

    Ok(res.into())
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_drain_transaction(
    encoded_wallet: String,
    api_outputs: HashMap<String, ApiOwnedOutput>,
    wipe_address: String,
    feerate: f32,
    network: String,
) -> Result<ApiSilentPaymentUnsignedTransaction> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    let client = wallet.client;
    let available_utxos: Result<Vec<(OutPoint, OwnedOutput)>> = api_outputs
        .into_iter()
        .map(|(string, output)| {
            let outpoint = OutPoint::from_str(&string)?;
            Ok((outpoint, output.into()))
        })
        .collect();

    let recipient_address: RecipientAddress = RecipientAddress::try_from(wipe_address)?;
    let core_network = Network::from_core_arg(&network)?;
    let res = client.create_drain_transaction(
        available_utxos?,
        recipient_address,
        feerate,
        core_network,
    )?;

    Ok(res.into())
}

#[flutter_rust_bridge::frb(sync)]
pub fn finalize_transaction(
    unsigned_transaction: ApiSilentPaymentUnsignedTransaction,
) -> Result<ApiSilentPaymentUnsignedTransaction> {
    let res = SpClient::finalize_transaction(unsigned_transaction.into())?;
    Ok(res.into())
}

#[flutter_rust_bridge::frb(sync)]
pub fn sign_transaction(
    encoded_wallet: String,
    unsigned_transaction: ApiSilentPaymentUnsignedTransaction,
) -> Result<String> {
    let wallet: SpWallet = serde_json::from_str(&encoded_wallet)?;
    let client = wallet.client;
    let mut aux_rand = [0u8; 32];

    let mut rng = thread_rng();
    rng.fill_bytes(&mut aux_rand);

    let tx = client.sign_transaction(unsigned_transaction.into(), &aux_rand)?;
    Ok(serialize(&tx).to_lower_hex_string())
}

pub async fn broadcast_tx(tx: String, network: String) -> Result<String> {
    let tx: pushtx::Transaction = tx.parse().unwrap();

    let txid = tx.txid();

    let network = Network::from_core_arg(&network)?;

    let network = match network {
        Network::Bitcoin => pushtx::Network::Mainnet,
        Network::Testnet => pushtx::Network::Testnet,
        Network::Signet => pushtx::Network::Signet,
        Network::Regtest => pushtx::Network::Regtest,
        _ => unreachable!(),
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
                        log::info!("broadcasted {} transactions", report.success.len());
                        break;
                    } else {
                         return Err(anyhow::Error::msg("Failed to broadcast transaction, probably unable to connect to Tor peers"));
                    }
                }
                pushtx::Info::Done(Err(err)) => return Err(anyhow::Error::msg(err.to_string())),
                _ => {}
            }
        }
        Ok(())
    })
    .await??;

    Ok(txid.to_string())
}
