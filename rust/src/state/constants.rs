use serde::{Deserialize, Serialize};
use sp_client::{
    bitcoin::{absolute::Height, Amount, OutPoint, Txid},
    Recipient,
};

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum RecordedTransaction {
    Incoming(RecordedTransactionIncoming),
    Outgoing(RecordedTransactionOutgoing),
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct RecordedTransactionIncoming {
    pub txid: Txid,
    pub amount: Amount,
    pub confirmed_at: Option<Height>,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct RecordedTransactionOutgoing {
    pub txid: Txid,
    pub spent_outpoints: Vec<OutPoint>,
    pub recipients: Vec<Recipient>,
    pub confirmed_at: Option<Height>,
    pub change: Amount,
    #[serde(default)]
    pub fee: Amount,
}
