use crate::api::structs::ApiRecordedTransaction;

use super::constants::{
    RecordedTransaction, RecordedTransactionIncoming, RecordedTransactionOutgoing,
};
use serde::{Deserialize, Serialize};
use sp_client::bitcoin::absolute::Height;
use sp_client::bitcoin::OutPoint;
use sp_client::bitcoin::{Amount, Txid};

use anyhow::{Error, Result};

use sp_client::Recipient;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TxHistory(Vec<RecordedTransaction>);

impl TxHistory {
    pub fn reset_to_height(&mut self, blkheight: Height) {
        self.0.retain(|tx| match tx {
            RecordedTransaction::Incoming(incoming) => {
                incoming.confirmed_at.is_some_and(|x| x <= blkheight)
            }
            RecordedTransaction::Outgoing(outgoing) => {
                outgoing.confirmed_at.is_some_and(|x| x <= blkheight)
            }
        });
    }

    pub fn record_outgoing_transaction(
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

    pub fn confirm_recorded_outgoing_transaction(
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

    pub fn record_incoming_transaction(
        &mut self,
        txid: Txid,
        amount: Amount,
        confirmed_at: Height,
    ) {
        self.0
            .push(RecordedTransaction::Incoming(RecordedTransactionIncoming {
                txid,
                amount,
                confirmed_at: Some(confirmed_at),
            }))
    }

    pub fn to_api_recorded_transaction(self) -> Vec<ApiRecordedTransaction> {
        self.0.into_iter().map(Into::into).collect()
    }
}
