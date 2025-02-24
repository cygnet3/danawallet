use std::str::FromStr;

use crate::history::TxHistory;

use super::structs::{ApiAmount, ApiRecipient, ApiRecordedTransaction};
use anyhow::Result;

use sp_client::bitcoin::{OutPoint, Txid};

#[flutter_rust_bridge::frb(sync)]
pub fn read_tx_history(encoded_history: String) -> Result<Vec<ApiRecordedTransaction>> {
    let tx_history: TxHistory = serde_json::from_str(&encoded_history)?;

    Ok(tx_history.tx_history.into_iter().map(Into::into).collect())
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
