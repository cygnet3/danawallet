mod info;
mod scan;
pub mod setup;
mod transaction;
mod labels;

use crate::wallet::WalletFingerprint;
use anyhow::Result;
use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use sp_client::{
    bitcoin::{absolute::Height, secp256k1::SecretKey, Network},
    SpClient, SpendKey,
};

use super::{history::TxHistory, outputs::OwnedOutputs, structs::ApiSilentPaymentAddress};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb(opaque)]
pub struct SpWallet {
    client: SpClient,
    wallet_fingerprint: WalletFingerprint,
    birthday: Height,
    /// old variable, to be removed
    #[serde(skip_serializing)]
    tx_history: Option<TxHistory>,
    /// old variable, to be removed
    #[serde(skip_serializing)]
    last_scan: Option<Height>,
    /// old variable, to be removed
    #[serde(skip_serializing)]
    outputs: Option<OwnedOutputs>,
}

impl SpWallet {
    #[frb(sync)]
    pub fn new(
        scan_key: ApiScanKey,
        spend_key: ApiSpendKey,
        network: String,
        birthday: u32,
    ) -> Result<Self> {
        let network = Network::from_core_arg(&network)?;

        let client = SpClient::new(scan_key.into(), spend_key.into(), network)?;

        let wallet_fingerprint = client.get_client_fingerprint()?;
        let birthday = Height::from_consensus(birthday)?;

        Ok(Self {
            client,
            birthday,
            wallet_fingerprint,
            tx_history: None,
            last_scan: None,
            outputs: None,
        })
    }

    #[frb(sync)]
    pub fn decode(encoded_wallet: String) -> Result<Self> {
        Ok(serde_json::from_str(&encoded_wallet)?)
    }

    #[frb(sync)]
    pub fn encode(&self) -> Result<String> {
        Ok(serde_json::to_string(&self)?)
    }

    #[frb(sync)]
    pub fn get_scan_key(&self) -> ApiScanKey {
        ApiScanKey(self.client.get_scan_key())
    }

    #[frb(sync)]
    pub fn get_spend_key(&self) -> ApiSpendKey {
        ApiSpendKey(self.client.get_spend_key())
    }

    #[frb(sync)]
    /// We expect as label the sorted, concatenated labels
    pub fn get_silent_payment_address_for_label(&self, label: Option<String>) -> Result<ApiSilentPaymentAddress> {
        // get the label from the string
        if let Some(label) = label {
            // "change" is a special case for the change address
            if label.as_str() == "change" {
                Ok(self.client.sp_receiver.get_change_address().into())
            } else {
                // We handle all other cases here
                let label = self.generate_label_from_input(label)?;
                let labelled_address = self.client.sp_receiver.get_receiving_address_for_label(&label)?;
                Ok(labelled_address.into())
            }
        } else {
            // Just the unlabeled address
            Ok(self.client.get_receiving_address().into())
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct ApiScanKey(pub(crate) SecretKey);

impl ApiScanKey {
    #[frb(sync)]
    pub fn decode(encoded: String) -> Result<Self> {
        Ok(serde_json::from_str(&encoded)?)
    }

    #[frb(sync)]
    pub fn encode(&self) -> Result<String> {
        Ok(serde_json::to_string(&self)?)
    }
}

impl From<ApiScanKey> for SecretKey {
    fn from(scan_key: ApiScanKey) -> Self {
        scan_key.0
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct ApiSpendKey(pub(crate) SpendKey);

impl ApiSpendKey {
    #[frb(sync)]
    pub fn decode(encoded: String) -> Result<Self> {
        Ok(serde_json::from_str(&encoded)?)
    }

    #[frb(sync)]
    pub fn encode(&self) -> Result<String> {
        Ok(serde_json::to_string(&self)?)
    }
}

impl From<ApiSpendKey> for SpendKey {
    fn from(spend_key: ApiSpendKey) -> Self {
        spend_key.0
    }
}
