use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};

use super::{
    history::TxHistory,
    outputs::OwnedOutputs,
    wallet::{ApiScanKey, ApiSpendKey, SpWallet},
};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DanaBackup {
    version: u32,
    pub wallet: WalletBackup,
    pub settings: SettingsBackup,
}

impl DanaBackup {
    #[frb(sync)]
    pub fn new(wallet: WalletBackup, settings: SettingsBackup) -> Self {
        Self {
            // version number to mark backwards incompatible versions
            version: 1,
            wallet,
            settings,
        }
    }

    #[frb(sync)]
    pub fn encode(&self) -> String {
        serde_json::to_string(&self).unwrap()
    }

    #[frb(sync)]
    pub fn decode(encoded_backup: String) -> Self {
        serde_json::from_str(&encoded_backup).unwrap()
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct WalletBackup {
    pub scan_key: ApiScanKey,
    pub spend_key: ApiSpendKey,
    pub birthday: u32,
    pub network: String,
    pub tx_history: TxHistory,
    pub owned_outputs: OwnedOutputs,
    pub seed_phrase: Option<String>,
    pub last_scan: u32,
}

impl WalletBackup {
    #[frb(sync)]
    pub fn new(
        wallet: SpWallet,
        network: String,
        tx_history: TxHistory,
        owned_outputs: OwnedOutputs,
        seed_phrase: Option<String>,
        last_scan: u32,
    ) -> Self {
        Self {
            scan_key: wallet.get_scan_key(),
            spend_key: wallet.get_spend_key(),
            birthday: wallet.get_birthday(),
            network,
            tx_history,
            owned_outputs,
            seed_phrase,
            last_scan,
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct SettingsBackup {
    pub blindbit_url: String,
    pub dust_limit: u32,
}

impl SettingsBackup {
    #[frb(sync)]
    pub fn new(blindbit_url: String, dust_limit: u32) -> Self {
        Self {
            blindbit_url,
            dust_limit,
        }
    }
}
