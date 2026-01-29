use serde::{Deserialize, Serialize};
use spdk_core::{
    Recipient, bitcoin::{Amount, BlockHash, OutPoint, Txid, absolute::Height}
};

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum RecordedTransaction {
    Incoming(RecordedTransactionIncoming),
    Outgoing(RecordedTransactionOutgoing),
    UnknownOutgoing(RecordedTransactionUnknownOutgoing),
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct RecordedTransactionIncoming {
    pub txid: Txid,
    pub amount: Amount,
    pub confirmation_height: Option<Height>,
    pub confirmation_blockhash: Option<BlockHash>,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct RecordedTransactionOutgoing {
    pub txid: Txid,
    pub spent_outpoints: Vec<OutPoint>,
    pub recipients: Vec<Recipient>,
    pub confirmation_height: Option<Height>,
    pub confirmation_blockhash: Option<BlockHash>,
    pub change: Amount,
    #[serde(default)]
    pub fee: Amount,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct RecordedTransactionUnknownOutgoing {
    pub spent_outpoints: Vec<OutPoint>,
    pub amount: Amount,
    pub confirmation_height: Height,
    pub confirmation_blockhash: BlockHash,
}
