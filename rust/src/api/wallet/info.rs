use flutter_rust_bridge::frb;

use crate::api::{history::TxHistory, outputs::OwnedOutputs};

use super::SpWallet;

impl SpWallet {
    #[frb(sync)]
    pub fn get_birthday(&self) -> u32 {
        self.birthday.to_consensus_u32()
    }

    #[frb(sync)]
    pub fn get_receiving_address(&self) -> String {
        self.client.get_receiving_address().to_string()
    }

    #[frb(sync)]
    pub fn get_change_address(&self) -> String {
        self.client.sp_receiver.get_change_address().to_string()
    }

    #[frb(sync)]
    pub fn get_network(&self) -> String {
        self.client.get_network().to_core_arg().to_string()
    }

    #[frb(sync)]
    /// Only call this when we expect this value to be present
    pub fn get_wallet_last_scan(&self) -> Option<u32> {
        self.last_scan.map(|x| x.to_consensus_u32())
    }

    #[frb(sync)]
    /// Only call this when we expect this value to be present
    pub fn get_wallet_tx_history(&self) -> Option<TxHistory> {
        self.tx_history.clone()
    }

    #[frb(sync)]
    /// Only call this when we expect this value to be present
    pub fn get_wallet_owned_outputs(&self) -> Option<OwnedOutputs> {
        self.outputs.clone()
    }
}
