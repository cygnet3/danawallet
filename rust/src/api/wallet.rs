mod info;
mod scan;
mod setup;
mod transaction;

use crate::wallet::WalletFingerprint;
use anyhow::Result;
use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use sp_client::{bitcoin::absolute::Height, SpClient};

use super::{history::TxHistory, outputs::OwnedOutputs};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb(opaque)]
pub struct SpWallet {
    client: SpClient,
    wallet_fingerprint: WalletFingerprint,
    birthday: Height,
    /// old variable, to be removed
    tx_history: Option<TxHistory>,
    /// old variable, to be removed
    last_scan: Option<Height>,
    /// old variable, to be removed
    outputs: Option<OwnedOutputs>,
}

impl SpWallet {
    fn new(client: SpClient, birthday: u32) -> Result<Self> {
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
}
