use serde::{Deserialize, Serialize};

type SecretKeyString = String;
type PublicKeyString = String;

#[derive(Deserialize, Serialize)]
pub enum WalletType {
    New,
    Mnemonic(String),
    // scan_sk_hex, spend_sk_hex
    PrivateKeys(SecretKeyString, SecretKeyString),
    // scan_sk_hex, spend_pk_hex
    ReadOnly(SecretKeyString, PublicKeyString),
}

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
pub struct OwnedOutput {
    pub txoutpoint: String,
    pub blockheight: u32,
    pub tweak: String,
    pub amount: u64,
    pub script: String,
    pub label: Option<String>,
    pub spend_status: OutputSpendStatus,
}

impl From<sp_client::spclient::OwnedOutput> for OwnedOutput {
    fn from(value: sp_client::spclient::OwnedOutput) -> Self {
        OwnedOutput {
            txoutpoint: value.txoutpoint,
            blockheight: value.blockheight,
            tweak: value.tweak,
            amount: value.amount,
            script: value.script,
            label: value.label,
            spend_status: value.spend_status.into(),
        }
    }
}

impl From<OwnedOutput> for sp_client::spclient::OwnedOutput {
    fn from(value: OwnedOutput) -> Self {
        sp_client::spclient::OwnedOutput {
            txoutpoint: value.txoutpoint,
            blockheight: value.blockheight,
            tweak: value.tweak,
            amount: value.amount,
            script: value.script,
            label: value.label,
            spend_status: value.spend_status.into(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct Recipient {
    pub address: String, // either old school or silent payment
    pub amount: u64,
    pub nb_outputs: u32, // if address is not SP, only 1 is valid
}

impl From<sp_client::spclient::Recipient> for Recipient {
    fn from(value: sp_client::spclient::Recipient) -> Self {
        Recipient {
            address: value.address,
            amount: value.amount,
            nb_outputs: value.nb_outputs,
        }
    }
}

impl From<Recipient> for sp_client::spclient::Recipient {
    fn from(value: Recipient) -> Self {
        sp_client::spclient::Recipient {
            address: value.address,
            amount: value.amount,
            nb_outputs: value.nb_outputs,
        }
    }
}
