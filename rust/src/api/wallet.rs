use std::{collections::HashMap, str::FromStr};

use crate::wallet::{utils::derive_keys_from_seed, SpWallet, WalletUpdater, KEEP_SCANNING};
use anyhow::Result;
use bdk_coin_select::{Candidate, ChangePolicy, CoinSelector, DrainWeights, FeeRate, Target, TargetFee, TargetOutputs, TR_DUST_RELAY_MIN_VALUE, TR_KEYSPEND_TXIN_WEIGHT};
use sp_client::{
    bitcoin::{
        absolute::Height, secp256k1::{PublicKey, SecretKey}, Address, Network, OutPoint, TxOut, Txid,  
    }, silentpayments::utils::SilentPaymentAddress, BlindbitBackend, ChainBackend, SpClient, SpScanner, SpendKey
};

use super::structs::{
    Amount, ApiOutputSpendStatus, ApiOwnedOutput, ApiRecipient, ApiSelectOutputsResult, ApiSetupResult, ApiSetupWalletArgs, ApiSetupWalletType, ApiWalletStatus
};

/// we enable cutthrough by default, no need to let the user decide
const ENABLE_CUTTHROUGH: bool = true;
/// we don't add a passphrase to the bip39 mnemonic
const PASSPHRASE: &str = "";
const DUMMYADDRESS: &str = "bc1p2wsldez5mud2yam29q22wgfh9439spgduvct83k3pm50fcxa5dps59h4z5"; // we use that as a dummy tr address when selecting outputs

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

    let backend = BlindbitBackend::new(blindbit_url)?;

    let dust_limit = sp_client::bitcoin::Amount::from_sat(dust_limit);

    let start = Height::from_consensus(wallet.last_scan.to_consensus_u32() + 1)?;
    let end = backend.block_height().await?;

    let owned_outpoints = wallet.outputs.keys().cloned().collect();

    let sp_client = wallet.client.clone();
    let updater = WalletUpdater::new(wallet);

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
        address: wallet.client.get_receiving_address(),
        network: Some(wallet.client.get_network().to_core_arg().to_owned()),
        change_address: wallet.client.sp_receiver.get_change_address(),
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
    recipients: Vec<ApiRecipient>,
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
pub fn select_outputs(
    owned_outputs: HashMap<String, ApiOwnedOutput>,
    recipients: Vec<ApiRecipient>,
    feerate: u32,
) -> Result<ApiSelectOutputsResult> {
    let change_policy = ChangePolicy::min_value(DrainWeights::default(), TR_DUST_RELAY_MIN_VALUE);

    let outputs_vec: Vec<(String, ApiOwnedOutput)> = owned_outputs.into_iter()
        .filter(|(_, o)| o.spend_status == ApiOutputSpendStatus::Unspent)
        .collect(); 

    let candidates: Vec<Candidate> = outputs_vec.iter()
        .map(|(_, o)| Candidate::new(o.amount.0, TR_KEYSPEND_TXIN_WEIGHT, true))
        .collect();

    let mut coin_selector = CoinSelector::new(&candidates);

    let outputs: Result<Vec<TxOut>> = recipients.into_iter()
        .map(|r| {
            let address = Address::from_str(&r.address).or_else(|_| {
                // We just check that this is a valid sp address
                // We will check networks at a later stage
                let _ = SilentPaymentAddress::try_from(r.address).or_else(|_| {
                    Err(anyhow::Error::msg("Invalid sp address"))
                });
                // We just use some placeholder for fee calculation 
                Address::from_str(DUMMYADDRESS)
            })?;
            Ok(TxOut {
                value: r.amount.into(),
                script_pubkey: address.assume_checked().script_pubkey()
            })
        })
        .collect();

    let outputs = outputs?;

    let fee_rate = FeeRate::from_sat_per_vb(feerate as f32);

    let target = Target {
        fee: TargetFee::from_feerate(fee_rate),
        outputs: TargetOutputs::fund_outputs(outputs.iter().map(|o| (o.weight().to_wu(), o.value.to_sat())))
    };

    coin_selector.select_until_target_met(target)?;

    let selected_indices = coin_selector.selected_indices();
    let mut selection: HashMap<String, ApiOwnedOutput> = HashMap::with_capacity(selected_indices.len()); 
    for i in selected_indices {
        let (outpoint, output) = outputs_vec.get(*i).unwrap();
        selection.insert(outpoint.to_string(), output.clone().into());
    }
    let change = coin_selector.drain(target, change_policy);

    let change_value = if change.is_some() { change.value } else { 0 };

    Ok(ApiSelectOutputsResult { 
        selected_outputs: selection, 
        change_value 
    })
}
