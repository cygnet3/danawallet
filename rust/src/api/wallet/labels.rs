use anyhow::{Error, Result};
use crypto::{digest::Digest, sha2::Sha256};
use flutter_rust_bridge::frb;
use sp_client::silentpayments::receiving::Label;

use crate::api::structs::ApiSilentPaymentAddress;

use super::SpWallet;

impl SpWallet {
    pub(crate) fn generate_label_from_input(&self, input: String) -> Result<Label> {
        // We hash the new_label and take the first 32 bits
        let mut hasher = Sha256::new();
        hasher.input_str(&input);
        let mut out = [0u8; 32];
        hasher.result(out.as_mut_slice());
        let mut buf = [0u8; 4];
        buf.copy_from_slice(&out[..4]);
        let new_label = Label::new(self.client.get_scan_key(), u32::from_be_bytes(buf));

        Ok(new_label)
    }
}
