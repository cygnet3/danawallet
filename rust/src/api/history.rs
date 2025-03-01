use std::{collections::HashMap, str::FromStr};

use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use sp_client::{
    bitcoin::{absolute::Height, Amount, OutPoint, Txid},
    Recipient,
};

use crate::{
    state::constants::{
        RecordedTransaction, RecordedTransactionIncoming, RecordedTransactionOutgoing,
    },
    stream::StateUpdate,
};

use super::structs::{ApiAmount, ApiRecipient, ApiRecordedTransaction};
use anyhow::{Error, Result};

#[derive(Debug, Clone, Deserialize, Serialize)]
#[frb(opaque)]
pub struct TxHistory(Vec<RecordedTransaction>);

impl TxHistory {
    #[flutter_rust_bridge::frb(sync)]
    pub fn empty() -> Self {
        Self(vec![])
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn decode(encoded_history: String) -> Self {
        serde_json::from_str(&encoded_history).unwrap()
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn encode(&self) -> String {
        serde_json::to_string(&self).unwrap()
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn to_api_transactions(&self) -> Vec<ApiRecordedTransaction> {
        self.0.iter().map(|x| x.clone().into()).collect()
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn process_state_update(&mut self, update: &StateUpdate) -> Result<()> {
        match update {
            StateUpdate::Update {
                blkheight,
                blkhash: _,
                found_outputs,
                found_inputs,
            } => {
                for outpoint in found_inputs {
                    // this may confirm the same tx multiple times, but this shouldn't be a problem
                    self.confirm_recorded_outgoing_transaction(*outpoint, *blkheight)?;
                }

                // add new incoming transactions
                let mut txs: HashMap<Txid, Amount> = HashMap::new();
                for (outpoint, output) in found_outputs {
                    let entry = txs.entry(outpoint.txid).or_default();
                    *entry += output.amount;
                }
                for (txid, amount) in txs {
                    self.record_incoming_transaction(txid, amount, *blkheight);
                }
            }
            StateUpdate::NoUpdate { .. } => (),
        }

        Ok(())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn add_outgoing_tx_to_history(
        &mut self,
        txid: String,
        spent_outpoints: Vec<String>,
        recipients: Vec<ApiRecipient>,
        change: ApiAmount,
    ) -> Result<()> {
        let txid = Txid::from_str(&txid)?;
        let spent_outpoints = spent_outpoints
            .into_iter()
            .map(|x| OutPoint::from_str(&x).unwrap())
            .collect();

        let recipients = recipients
            .into_iter()
            .map(|r| r.try_into().unwrap())
            .collect();

        self.record_outgoing_transaction(txid, spent_outpoints, recipients, change.into());

        Ok(())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn reset_to_height(&mut self, height: u32) -> Result<()> {
        let blkheight = Height::from_consensus(height)?;
        self.0.retain(|tx| match tx {
            RecordedTransaction::Incoming(incoming) => {
                incoming.confirmed_at.is_some_and(|x| x <= blkheight)
            }
            RecordedTransaction::Outgoing(outgoing) => {
                outgoing.confirmed_at.is_some_and(|x| x <= blkheight)
            }
        });

        Ok(())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn get_unconfirmed_change(&self) -> u64 {
        self.0
            .iter()
            .filter_map(|x| match x {
                RecordedTransaction::Outgoing(outgoing) if outgoing.confirmed_at == None => {
                    Some(outgoing.change.to_sat())
                }
                _ => None,
            })
            .sum()
    }

    fn record_outgoing_transaction(
        &mut self,
        txid: Txid,
        spent_outpoints: Vec<OutPoint>,
        recipients: Vec<Recipient>,
        change: Amount,
    ) {
        self.0
            .push(RecordedTransaction::Outgoing(RecordedTransactionOutgoing {
                txid,
                spent_outpoints,
                recipients,
                confirmed_at: None,
                change,
            }))
    }

    fn confirm_recorded_outgoing_transaction(
        &mut self,
        outpoint: OutPoint,
        blkheight: Height,
    ) -> Result<()> {
        for recorded_tx in self.0.iter_mut() {
            match recorded_tx {
                RecordedTransaction::Outgoing(outgoing)
                    if (outgoing.spent_outpoints.contains(&outpoint)) =>
                {
                    outgoing.confirmed_at = Some(blkheight);
                    return Ok(());
                }
                _ => (),
            }
        }

        Err(Error::msg(format!(
            "No outgoing tx found for input: {}",
            outpoint
        )))
    }

    fn record_incoming_transaction(&mut self, txid: Txid, amount: Amount, confirmed_at: Height) {
        self.0
            .push(RecordedTransaction::Incoming(RecordedTransactionIncoming {
                txid,
                amount,
                confirmed_at: Some(confirmed_at),
            }))
    }
}
