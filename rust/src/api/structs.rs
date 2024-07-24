use std::{collections::HashMap, str::FromStr};

use bitcoin::{absolute::Height, OutPoint, Txid};
use serde::{Deserialize, Serialize};

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

impl Amount {
    #[flutter_rust_bridge::frb(sync)]
    pub fn to_int(&self) -> u64 {
        self.0
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

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum RecordedTransaction {
    Incoming(RecordedTransactionIncoming),
    Outgoing(RecordedTransactionOutgoing),
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct RecordedTransactionIncoming {
    pub txid: String,
    pub amount: Amount,
    pub confirmed_at: Option<u32>,
}

impl RecordedTransactionIncoming {
    #[flutter_rust_bridge::frb(sync)]
    pub fn to_string(&self) -> String {
        format!("{:#?}", self)
    }
}

impl RecordedTransactionOutgoing {
    #[flutter_rust_bridge::frb(sync)]
    pub fn to_string(&self) -> String {
        format!("{:#?}", self)
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct RecordedTransactionOutgoing {
    pub txid: String,
    pub spent_outpoints: Vec<String>,
    pub recipients: Vec<Recipient>,
    pub confirmed_at: Option<u32>,
}

impl From<sp_client::spclient::RecordedTransaction> for RecordedTransaction {
    fn from(value: sp_client::spclient::RecordedTransaction) -> Self {
        match value {
            sp_client::spclient::RecordedTransaction::Incoming(incoming) => {
                Self::Incoming(incoming.into())
            }

            sp_client::spclient::RecordedTransaction::Outgoing(outgoing) => {
                Self::Outgoing(outgoing.into())
            }
        }
    }
}

impl From<RecordedTransaction> for sp_client::spclient::RecordedTransaction {
    fn from(value: RecordedTransaction) -> Self {
        match value {
            RecordedTransaction::Incoming(incoming) => Self::Incoming(incoming.into()),
            RecordedTransaction::Outgoing(outgoing) => Self::Outgoing(outgoing.into()),
        }
    }
}

impl From<sp_client::spclient::RecordedTransactionIncoming> for RecordedTransactionIncoming {
    fn from(value: sp_client::spclient::RecordedTransactionIncoming) -> Self {
        let confirmed_at = value.confirmed_at.map(|height| height.to_consensus_u32());

        Self {
            txid: value.txid.to_string(),
            amount: value.amount.into(),
            confirmed_at,
        }
    }
}

impl From<RecordedTransactionIncoming> for sp_client::spclient::RecordedTransactionIncoming {
    fn from(value: RecordedTransactionIncoming) -> Self {
        let confirmed_at = value
            .confirmed_at
            .map(|height| Height::from_consensus(height).unwrap());

        Self {
            txid: Txid::from_str(&value.txid).unwrap(),
            amount: value.amount.into(),
            confirmed_at,
        }
    }
}

impl From<sp_client::spclient::RecordedTransactionOutgoing> for RecordedTransactionOutgoing {
    fn from(value: sp_client::spclient::RecordedTransactionOutgoing) -> Self {
        let confirmed_at = value.confirmed_at.map(|height| height.to_consensus_u32());

        Self {
            txid: value.txid.to_string(),
            spent_outpoints: value
                .spent_outpoints
                .into_iter()
                .map(|x| x.to_string())
                .collect(),
            recipients: value.recipients.into_iter().map(Into::into).collect(),
            confirmed_at,
        }
    }
}

impl From<RecordedTransactionOutgoing> for sp_client::spclient::RecordedTransactionOutgoing {
    fn from(value: RecordedTransactionOutgoing) -> Self {
        let confirmed_at = value
            .confirmed_at
            .map(|height| Height::from_consensus(height).unwrap());

        Self {
            txid: Txid::from_str(&value.txid).unwrap(),
            spent_outpoints: value
                .spent_outpoints
                .into_iter()
                .map(|x| OutPoint::from_str(&x).unwrap())
                .collect(),
            recipients: value.recipients.into_iter().map(Into::into).collect(),
            confirmed_at,
        }
    }
}

pub struct WalletStatus {
    pub address: String,
    pub balance: u64,
    pub birthday: u32,
    pub last_scan: u32,
    pub outputs: HashMap<String, OwnedOutput>,
    pub tx_history: Vec<RecordedTransaction>,
}
