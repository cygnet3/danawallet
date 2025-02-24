use std::collections::HashMap;
use std::str::FromStr;

use anyhow::Result;
use sp_client::bitcoin::{absolute::Height, OutPoint, Txid};
use sp_client::Updater;

use crate::state::OwnedOutputs;

use crate::state::StateUpdater;
use crate::state::TxHistory;

use super::structs::ApiOwnedOutput;
use super::structs::{ApiAmount, ApiRecipient, ApiRecordedTransaction};

#[flutter_rust_bridge::frb(sync)]
pub fn parse_encoded_tx_history(encoded_history: String) -> Result<Vec<ApiRecordedTransaction>> {
    let tx_history: TxHistory = serde_json::from_str(&encoded_history)?;

    Ok(tx_history.to_api_recorded_transaction())
}

#[flutter_rust_bridge::frb(sync)]
pub fn parse_encoded_owned_outputs(
    encoded_outputs: String,
) -> Result<HashMap<String, ApiOwnedOutput>> {
    let outputs: OwnedOutputs = serde_json::from_str(&encoded_outputs)?;

    Ok(outputs.to_api_owned_outputs())
}

#[flutter_rust_bridge::frb(sync)]
pub fn add_outgoing_tx_to_history(
    encoded_history: String,
    txid: String,
    spent_outpoints: Vec<String>,
    recipients: Vec<ApiRecipient>,
    change: ApiAmount,
) -> Result<String> {
    let txid = Txid::from_str(&txid)?;
    let spent_outpoints = spent_outpoints
        .into_iter()
        .map(|x| OutPoint::from_str(&x).unwrap())
        .collect();

    let mut tx_history: TxHistory = serde_json::from_str(&encoded_history)?;

    let recipients = recipients
        .into_iter()
        .map(|r| r.try_into().unwrap())
        .collect();

    tx_history.record_outgoing_transaction(txid, spent_outpoints, recipients, change.into());

    Ok(serde_json::to_string(&tx_history)?)
}

#[flutter_rust_bridge::frb(sync)]
pub fn mark_outpoints_spent(
    encoded_outputs: String,
    spent_by: String,
    spent: Vec<String>,
) -> Result<String> {
    let mut outputs: OwnedOutputs = serde_json::from_str(&encoded_outputs)?;

    for outpoint in spent {
        outputs.mark_spent(
            OutPoint::from_str(&outpoint)?,
            Txid::from_str(&spent_by)?,
            true,
        )?;
    }

    Ok(serde_json::to_string(&outputs)?)
}

/// Reset owned outputs and tx history to `height`, removing any data after this height.
#[flutter_rust_bridge::frb(sync)]
pub fn reset_to_height(
    height: u32,
    encoded_owned_outputs: String,
    encoded_tx_history: String,
) -> Result<()> {
    let height = Height::from_consensus(height)?;
    let mut tx_history: TxHistory = serde_json::from_str(&encoded_tx_history)?;
    let mut outputs: OwnedOutputs = serde_json::from_str(&encoded_owned_outputs)?;
    tx_history.reset_to_height(height);
    outputs.reset_to_height(height);

    let mut updater = StateUpdater::new(tx_history, outputs, height);
    updater.save_to_persistent_storage()?;

    Ok(())
}
