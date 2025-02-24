use std::collections::HashMap;
use std::sync::atomic::AtomicBool;

use serde::{Deserialize, Serialize};
use sp_client::bitcoin::absolute::Height;
use sp_client::bitcoin::OutPoint;

use anyhow::Result;

use sp_client::{OwnedOutput, SpClient};

type WalletFingerprint = [u8; 8];

use lazy_static::lazy_static;

use crate::state::constants::RecordedTransaction;

lazy_static! {
    pub static ref KEEP_SCANNING: AtomicBool = AtomicBool::new(true);
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SpWallet {
    pub client: SpClient,
    pub wallet_fingerprint: WalletFingerprint,
    pub birthday: Height,
    pub tx_history: Option<Vec<RecordedTransaction>>,
    pub last_scan: Option<Height>,
    pub outputs: Option<HashMap<OutPoint, OwnedOutput>>,
}

impl SpWallet {
    pub fn new(client: SpClient, birthday: u32) -> Result<Self> {
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
}
