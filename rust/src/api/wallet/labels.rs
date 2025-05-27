use anyhow::{Error, Result};
use crypto::{digest::Digest, sha2::Sha256};
use flutter_rust_bridge::frb;
use sp_client::silentpayments::receiving::Label;

use crate::api::structs::ApiSilentPaymentAddress;

use super::SpWallet;

impl SpWallet {
    pub(crate) fn generate_label(&self, index: u32) -> Result<Label> {
        let new_label = Label::new(self.client.get_scan_key(), index);

        Ok(new_label)
    }
}
