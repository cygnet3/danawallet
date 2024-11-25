use std::{collections::HashMap, str::FromStr};

use serde::{Deserialize, Serialize};
use sp_client::{
    bitcoin::{self, absolute::Height, OutPoint, ScriptBuf, Txid},
    OutputSpendStatus, OwnedOutput, Recipient,
};

use crate::wallet::recorded::{
    RecordedTransaction, RecordedTransactionIncoming, RecordedTransactionOutgoing,
};

type SpendingTxId = String;
type MinedInBlock = String;

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum ApiOutputSpendStatus {
    Unspent,
    Spent(SpendingTxId),
    Mined(MinedInBlock),
}

impl From<OutputSpendStatus> for ApiOutputSpendStatus {
    fn from(value: OutputSpendStatus) -> Self {
        match value {
            OutputSpendStatus::Unspent => ApiOutputSpendStatus::Unspent,
            OutputSpendStatus::Spent(txid) => ApiOutputSpendStatus::Spent(txid),
            OutputSpendStatus::Mined(block) => ApiOutputSpendStatus::Mined(block),
        }
    }
}

impl From<ApiOutputSpendStatus> for OutputSpendStatus {
    fn from(value: ApiOutputSpendStatus) -> Self {
        match value {
            ApiOutputSpendStatus::Unspent => OutputSpendStatus::Unspent,
            ApiOutputSpendStatus::Spent(txid) => OutputSpendStatus::Spent(txid),
            ApiOutputSpendStatus::Mined(block) => OutputSpendStatus::Mined(block),
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
pub struct ApiOwnedOutput {
    pub blockheight: u32,
    pub tweak: [u8; 32],
    pub amount: Amount,
    pub script: String,
    pub label: Option<String>,
    pub spend_status: ApiOutputSpendStatus,
}

impl From<OwnedOutput> for ApiOwnedOutput {
    fn from(value: OwnedOutput) -> Self {
        ApiOwnedOutput {
            blockheight: value.blockheight.to_consensus_u32(),
            tweak: value.tweak,
            amount: value.amount.into(),
            script: value.script.to_hex_string(),
            label: value.label,
            spend_status: value.spend_status.into(),
        }
    }
}

impl From<ApiOwnedOutput> for OwnedOutput {
    fn from(value: ApiOwnedOutput) -> Self {
        OwnedOutput {
            blockheight: Height::from_consensus(value.blockheight).unwrap(),
            tweak: value.tweak,
            amount: value.amount.into(),
            script: ScriptBuf::from_hex(&value.script).unwrap(),
            label: value.label,
            spend_status: value.spend_status.into(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct ApiRecipient {
    pub address: String, // either old school or silent payment
    pub amount: Amount,
    pub nb_outputs: u32, // if address is not SP, only 1 is valid
}

impl From<Recipient> for ApiRecipient {
    fn from(value: Recipient) -> Self {
        ApiRecipient {
            address: value.address,
            amount: value.amount.into(),
            nb_outputs: value.nb_outputs,
        }
    }
}

impl From<ApiRecipient> for Recipient {
    fn from(value: ApiRecipient) -> Self {
        Recipient {
            address: value.address,
            amount: value.amount.into(),
            nb_outputs: value.nb_outputs,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum ApiRecordedTransaction {
    Incoming(ApiRecordedTransactionIncoming),
    Outgoing(ApiRecordedTransactionOutgoing),
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct ApiRecordedTransactionIncoming {
    pub txid: String,
    pub amount: Amount,
    pub confirmed_at: Option<u32>,
}

impl ApiRecordedTransactionIncoming {
    #[flutter_rust_bridge::frb(sync)]
    pub fn to_string(&self) -> String {
        format!("{:#?}", self)
    }
}

impl ApiRecordedTransactionOutgoing {
    #[flutter_rust_bridge::frb(sync)]
    pub fn to_string(&self) -> String {
        format!("{:#?}", self)
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct ApiRecordedTransactionOutgoing {
    pub txid: String,
    pub spent_outpoints: Vec<String>,
    pub recipients: Vec<ApiRecipient>,
    pub confirmed_at: Option<u32>,
    pub change: Amount,
}

impl From<RecordedTransaction> for ApiRecordedTransaction {
    fn from(value: RecordedTransaction) -> Self {
        match value {
            RecordedTransaction::Incoming(incoming) => Self::Incoming(incoming.into()),

            RecordedTransaction::Outgoing(outgoing) => Self::Outgoing(outgoing.into()),
        }
    }
}

impl From<ApiRecordedTransaction> for RecordedTransaction {
    fn from(value: ApiRecordedTransaction) -> Self {
        match value {
            ApiRecordedTransaction::Incoming(incoming) => Self::Incoming(incoming.into()),
            ApiRecordedTransaction::Outgoing(outgoing) => Self::Outgoing(outgoing.into()),
        }
    }
}

impl From<RecordedTransactionIncoming> for ApiRecordedTransactionIncoming {
    fn from(value: RecordedTransactionIncoming) -> Self {
        let confirmed_at = value.confirmed_at.map(|height| height.to_consensus_u32());

        Self {
            txid: value.txid.to_string(),
            amount: value.amount.into(),
            confirmed_at,
        }
    }
}

impl From<ApiRecordedTransactionIncoming> for RecordedTransactionIncoming {
    fn from(value: ApiRecordedTransactionIncoming) -> Self {
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

impl From<RecordedTransactionOutgoing> for ApiRecordedTransactionOutgoing {
    fn from(value: RecordedTransactionOutgoing) -> Self {
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
            change: value.change.into(),
        }
    }
}

impl From<ApiRecordedTransactionOutgoing> for RecordedTransactionOutgoing {
    fn from(value: ApiRecordedTransactionOutgoing) -> Self {
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
            change: value.change.into(),
        }
    }
}

pub struct ApiWalletStatus {
    pub address: String,
    pub network: Option<String>,
    pub change_address: String,
    pub balance: u64,
    pub birthday: u32,
    pub last_scan: u32,
    pub outputs: HashMap<String, ApiOwnedOutput>,
    pub tx_history: Vec<ApiRecordedTransaction>,
}

pub struct ApiSetupWalletArgs {
    pub setup_type: ApiSetupWalletType,
    pub birthday: u32,
    pub network: String,
}

pub enum ApiSetupWalletType {
    NewWallet,
    Mnemonic(String),
    Full(String, String),
    WatchOnly(String, String),
}

pub struct ApiSetupResult {
    pub wallet_blob: String,
    pub mnemonic: Option<String>,
}

pub struct ApiSelectOutputsResult {
    pub selected_outputs: HashMap<String, ApiOwnedOutput>,
    pub change_value: u64,
}
