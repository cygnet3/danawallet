use std::str::FromStr;

use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use sp_client::{
    bitcoin::{
        self,
        absolute::Height,
        consensus::{deserialize, serialize},
        hex::{DisplayHex, FromHex},
        secp256k1::SecretKey,
        Network, OutPoint, ScriptBuf, Txid,
    },
    OutputSpendStatus, OwnedOutput, Recipient, SilentPaymentUnsignedTransaction,
};

use crate::state::constants::{
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

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Default)]
pub struct ApiAmount(pub u64);

impl From<bitcoin::Amount> for ApiAmount {
    fn from(value: bitcoin::Amount) -> Self {
        ApiAmount(value.to_sat())
    }
}

impl From<ApiAmount> for bitcoin::Amount {
    fn from(value: ApiAmount) -> bitcoin::Amount {
        bitcoin::Amount::from_sat(value.0)
    }
}

impl ApiAmount {
    #[frb(sync)]
    pub fn to_int(&self) -> u64 {
        self.0
    }

    #[frb(sync)]
    pub fn display_btc(&self) -> String {
        let amount_btc = self.0 as f32 / 100_000_000 as f32;
        let decimals = format!("{:.8}", amount_btc);
        let len = decimals.len();
        format!(
            "₿ {} {} {}",
            &decimals[..len - 6],
            &decimals[len - 6..len - 3],
            &decimals[len - 3..]
        )
    }

    #[frb(sync)]
    pub fn display_sats(&self) -> String {
        format!("{} sats", self.0)
    }

    #[frb(sync)]
    pub fn displaybip177(&self) -> String {
        let mut s = String::new();
        for (i, c) in self.0.to_string().chars().rev().enumerate() {
            if (i + 1) % 3 == 0 {
                s.insert(0, ' ');
            }
            s.insert(0, c);
        }

        format!("{} ₿", s)
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct ApiOwnedOutput {
    pub blockheight: u32,
    pub tweak: [u8; 32],
    pub amount: ApiAmount,
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
    pub amount: ApiAmount,
}

impl From<Recipient> for ApiRecipient {
    fn from(value: Recipient) -> Self {
        ApiRecipient {
            address: value.address.into(),
            amount: value.amount.into(),
        }
    }
}

impl TryFrom<ApiRecipient> for Recipient {
    type Error = anyhow::Error;
    fn try_from(value: ApiRecipient) -> Result<Self, Self::Error> {
        let address = value.address.try_into()?;
        let res = Recipient {
            address,
            amount: value.amount.into(),
        };

        Ok(res)
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
    pub amount: ApiAmount,
    pub confirmed_at: Option<u32>,
}

impl ApiRecordedTransactionIncoming {
    #[frb(sync)]
    pub fn to_string(&self) -> String {
        serde_json::to_string_pretty(&self).unwrap()
    }
}

impl ApiRecordedTransactionOutgoing {
    #[frb(sync)]
    pub fn to_string(&self) -> String {
        serde_json::to_string_pretty(&self).unwrap()
    }

    #[frb(sync)]
    pub fn total_outgoing(&self) -> ApiAmount {
        let sum: u64 = self.recipients.iter().map(|r| r.amount.0).sum();
        // include fee to the total as well
        let fee = self.fee.0;

        ApiAmount(sum + fee)
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct ApiRecordedTransactionOutgoing {
    pub txid: String,
    pub spent_outpoints: Vec<String>,
    pub recipients: Vec<ApiRecipient>,
    pub confirmed_at: Option<u32>,
    pub change: ApiAmount,
    pub fee: ApiAmount,
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
            fee: value.fee.into(),
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
            recipients: value
                .recipients
                .into_iter()
                .map(|r| r.try_into().unwrap())
                .collect(),
            confirmed_at,
            change: value.change.into(),
            fee: value.fee.into(),
        }
    }
}

pub struct ApiSilentPaymentUnsignedTransaction {
    pub selected_utxos: Vec<(String, ApiOwnedOutput)>,
    pub recipients: Vec<ApiRecipient>,
    pub partial_secret: [u8; 32],
    pub unsigned_tx: Option<String>,
    pub network: String,
}

impl From<SilentPaymentUnsignedTransaction> for ApiSilentPaymentUnsignedTransaction {
    fn from(value: SilentPaymentUnsignedTransaction) -> Self {
        Self {
            selected_utxos: value
                .selected_utxos
                .into_iter()
                .map(|(outpoint, output)| (outpoint.to_string(), output.into()))
                .collect(),
            recipients: value.recipients.into_iter().map(|r| r.into()).collect(),
            partial_secret: value.partial_secret.secret_bytes(),
            unsigned_tx: value
                .unsigned_tx
                .map(|tx| serialize(&tx).to_lower_hex_string()),
            network: value.network.to_core_arg().to_string(),
        }
    }
}

impl From<ApiSilentPaymentUnsignedTransaction> for SilentPaymentUnsignedTransaction {
    fn from(value: ApiSilentPaymentUnsignedTransaction) -> Self {
        Self {
            selected_utxos: value
                .selected_utxos
                .into_iter()
                .map(|(outpoint, output)| (OutPoint::from_str(&outpoint).unwrap(), output.into()))
                .collect(),
            recipients: value
                .recipients
                .into_iter()
                .map(|r| r.try_into().unwrap())
                .collect(),
            partial_secret: SecretKey::from_slice(&value.partial_secret).unwrap(),
            unsigned_tx: value
                .unsigned_tx
                .map(|tx| deserialize(&Vec::from_hex(&tx).unwrap()).unwrap()),
            network: Network::from_core_arg(&value.network).unwrap(),
        }
    }
}

impl ApiSilentPaymentUnsignedTransaction {
    #[frb(sync)]
    pub fn get_send_amount(&self, change_address: String) -> ApiAmount {
        let amount = self
            .recipients
            .iter()
            .filter_map(|r| {
                if r.address != change_address {
                    Some(r.amount.0)
                } else {
                    None
                }
            })
            .sum();

        ApiAmount(amount)
    }

    #[frb(sync)]
    pub fn get_change_amount(&self, change_address: String) -> ApiAmount {
        let amount = self
            .recipients
            .iter()
            .filter_map(|r| {
                if r.address == change_address {
                    Some(r.amount.0)
                } else {
                    None
                }
            })
            .sum();
        ApiAmount(amount)
    }

    #[frb(sync)]
    pub fn get_fee_amount(&self) -> ApiAmount {
        let input_sum: u64 = self
            .selected_utxos
            .iter()
            .map(|(_, o)| o.amount.to_int())
            .sum();

        let output_sum: u64 = self.recipients.iter().map(|r| r.amount.to_int()).sum();

        ApiAmount(input_sum - output_sum)
    }

    #[frb(sync)]
    pub fn get_recipients(&self, change_address: String) -> Vec<ApiRecipient> {
        self.recipients
            .iter()
            .filter(|r| r.address != change_address)
            .cloned()
            .collect()
    }
}
