use std::{collections::HashMap, str::FromStr};

use serde::{Deserialize, Serialize};
use sp_client::bitcoin::{self, absolute::Height, OutPoint, ScriptBuf, Txid};

use crate::wallet;

type SpendingTxId = String;
type MinedInBlock = String;

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum OutputSpendStatus {
    Unspent,
    Spent(SpendingTxId),
    Mined(MinedInBlock),
}

impl From<sp_client::OutputSpendStatus> for OutputSpendStatus {
    fn from(value: sp_client::OutputSpendStatus) -> Self {
        match value {
            sp_client::OutputSpendStatus::Unspent => OutputSpendStatus::Unspent,
            sp_client::OutputSpendStatus::Spent(txid) => OutputSpendStatus::Spent(txid),
            sp_client::OutputSpendStatus::Mined(block) => OutputSpendStatus::Mined(block),
        }
    }
}

impl From<OutputSpendStatus> for sp_client::OutputSpendStatus {
    fn from(value: OutputSpendStatus) -> Self {
        match value {
            OutputSpendStatus::Unspent => sp_client::OutputSpendStatus::Unspent,
            OutputSpendStatus::Spent(txid) => sp_client::OutputSpendStatus::Spent(txid),
            OutputSpendStatus::Mined(block) => sp_client::OutputSpendStatus::Mined(block),
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
    pub tweak: [u8; 32],
    pub amount: Amount,
    pub script: String,
    pub label: Option<String>,
    pub spend_status: OutputSpendStatus,
}

impl From<sp_client::OwnedOutput> for OwnedOutput {
    fn from(value: sp_client::OwnedOutput) -> Self {
        OwnedOutput {
            blockheight: value.blockheight.to_consensus_u32(),
            tweak: value.tweak,
            amount: value.amount.into(),
            script: value.script.to_hex_string(),
            label: value.label,
            spend_status: value.spend_status.into(),
        }
    }
}

impl From<OwnedOutput> for sp_client::OwnedOutput {
    fn from(value: OwnedOutput) -> Self {
        sp_client::OwnedOutput {
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
pub struct Recipient {
    pub address: String, // either old school or silent payment
    pub amount: Amount,
    pub nb_outputs: u32, // if address is not SP, only 1 is valid
}

impl From<sp_client::Recipient> for Recipient {
    fn from(value: sp_client::Recipient) -> Self {
        Recipient {
            address: value.address,
            amount: value.amount.into(),
            nb_outputs: value.nb_outputs,
        }
    }
}

impl From<Recipient> for sp_client::Recipient {
    fn from(value: Recipient) -> Self {
        sp_client::Recipient {
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
    pub change: Amount,
}

impl From<wallet::recorded::RecordedTransaction> for RecordedTransaction {
    fn from(value: wallet::recorded::RecordedTransaction) -> Self {
        match value {
            wallet::recorded::RecordedTransaction::Incoming(incoming) => {
                Self::Incoming(incoming.into())
            }

            wallet::recorded::RecordedTransaction::Outgoing(outgoing) => {
                Self::Outgoing(outgoing.into())
            }
        }
    }
}

impl From<RecordedTransaction> for wallet::recorded::RecordedTransaction {
    fn from(value: RecordedTransaction) -> Self {
        match value {
            RecordedTransaction::Incoming(incoming) => Self::Incoming(incoming.into()),
            RecordedTransaction::Outgoing(outgoing) => Self::Outgoing(outgoing.into()),
        }
    }
}

impl From<wallet::recorded::RecordedTransactionIncoming> for RecordedTransactionIncoming {
    fn from(value: wallet::recorded::RecordedTransactionIncoming) -> Self {
        let confirmed_at = value.confirmed_at.map(|height| height.to_consensus_u32());

        Self {
            txid: value.txid.to_string(),
            amount: value.amount.into(),
            confirmed_at,
        }
    }
}

impl From<RecordedTransactionIncoming> for wallet::recorded::RecordedTransactionIncoming {
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

impl From<wallet::recorded::RecordedTransactionOutgoing> for RecordedTransactionOutgoing {
    fn from(value: wallet::recorded::RecordedTransactionOutgoing) -> Self {
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

impl From<RecordedTransactionOutgoing> for wallet::recorded::RecordedTransactionOutgoing {
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
            change: value.change.into(),
        }
    }
}

pub struct WalletStatus {
    pub address: String,
    pub network: String,
    pub balance: u64,
    pub birthday: u32,
    pub last_scan: u32,
    pub outputs: HashMap<String, OwnedOutput>,
    pub tx_history: Vec<RecordedTransaction>,
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
