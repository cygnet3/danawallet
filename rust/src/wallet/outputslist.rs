use std::{collections::HashMap, io::Write};

use anyhow::{Error, Result};
use serde::{Deserialize, Serialize};
use sp_client::{
    bitcoin::{hashes::Hash, secp256k1::PublicKey, Amount, BlockHash, OutPoint, Txid},
    silentpayments::{self, utils::SilentPaymentAddress},
    spclient::{OutputSpendStatus, OwnedOutput, SpClient},
};

type WalletFingerprint = [u8; 8];

#[derive(Debug, Default, Serialize, Deserialize, Clone, PartialEq)]
pub struct OutputList {
    pub wallet_fingerprint: WalletFingerprint,
    birthday: u32,
    last_scan: u32,
    outputs: HashMap<OutPoint, OwnedOutput>,
}

impl OutputList {
    pub fn new(scan_pk: PublicKey, spend_pk: PublicKey, birthday: u32) -> Self {
        // take a fingerprint of the wallet by hashing its keys
        let mut engine = silentpayments::bitcoin_hashes::sha256::HashEngine::default();
        engine
            .write_all(&scan_pk.serialize())
            .expect("Failed to write scan_pk to engine");
        engine
            .write_all(&spend_pk.serialize())
            .expect("Failed to write spend_pk to engine");
        let hash = silentpayments::bitcoin_hashes::sha256::Hash::from_engine(engine);
        let mut wallet_fingerprint = [0u8; 8];
        wallet_fingerprint.copy_from_slice(&hash.to_byte_array()[..8]);
        let outputs = HashMap::new();
        Self {
            wallet_fingerprint,
            outputs,
            birthday,
            last_scan: birthday,
        }
    }

    pub fn check_fingerprint(&self, client: &SpClient) -> bool {
        let sp_address: SilentPaymentAddress = client.get_receiving_address().try_into().unwrap();
        let new = Self::new(sp_address.get_scan_key(), sp_address.get_spend_key(), 0);
        new.wallet_fingerprint == self.wallet_fingerprint
    }

    pub fn get_birthday(&self) -> u32 {
        self.birthday
    }

    pub fn get_last_scan(&self) -> u32 {
        self.last_scan
    }

    pub fn set_birthday(&mut self, new_birthday: u32) {
        self.birthday = new_birthday;
    }

    pub fn update_last_scan(&mut self, scan_height: u32) {
        self.last_scan = scan_height;
    }

    pub(crate) fn reset_to_height(&mut self, height: u32) {
        let new_outputs = self
            .to_outpoints_list()
            .into_iter()
            .filter(|(_, o)| o.blockheight < height)
            .collect::<HashMap<OutPoint, OwnedOutput>>();
        self.outputs = new_outputs;
    }

    pub fn to_outpoints_list(&self) -> HashMap<OutPoint, OwnedOutput> {
        self.outputs.clone()
    }

    pub fn extend_from(&mut self, new: HashMap<OutPoint, OwnedOutput>) {
        self.outputs.extend(new);
    }

    pub fn get_balance(&self) -> Amount {
        self.outputs
            .iter()
            .filter(|(_, o)| o.spend_status == OutputSpendStatus::Unspent)
            .fold(Amount::from_sat(0), |acc, x| acc + x.1.amount)
    }

    #[allow(dead_code)]
    pub fn to_spendable_list(&self) -> HashMap<OutPoint, OwnedOutput> {
        self.to_outpoints_list()
            .into_iter()
            .filter(|(_, o)| o.spend_status == OutputSpendStatus::Unspent)
            .collect()
    }

    pub fn get_outpoint(&self, outpoint: OutPoint) -> Result<(OutPoint, OwnedOutput)> {
        let output = self
            .to_outpoints_list()
            .get_key_value(&outpoint)
            .ok_or_else(|| Error::msg("Outpoint not in list"))?
            .1
            .to_owned();

        Ok((outpoint, output))
    }

    pub fn mark_spent(
        &mut self,
        outpoint: OutPoint,
        spending_tx: Txid,
        force_update: bool,
    ) -> Result<()> {
        let (outpoint, mut output) = self.get_outpoint(outpoint)?;

        match output.spend_status {
            OutputSpendStatus::Unspent => {
                let tx_hex = spending_tx.to_string();
                output.spend_status = OutputSpendStatus::Spent(tx_hex);
                self.outputs.insert(outpoint, output);
                Ok(())
            }
            OutputSpendStatus::Spent(tx_hex) => {
                // We may want to fail if that's the case, or force update if we know what we're doing
                if force_update {
                    let tx_hex = spending_tx.to_string();
                    output.spend_status = OutputSpendStatus::Spent(tx_hex);
                    self.outputs.insert(outpoint, output);
                    Ok(())
                } else {
                    Err(Error::msg(format!(
                        "Output already spent by transaction {}",
                        tx_hex
                    )))
                }
            }
            OutputSpendStatus::Mined(block) => Err(Error::msg(format!(
                "Output already mined in block {}",
                block
            ))),
        }
    }

    /// Mark the output as being spent in block `mined_in_block`
    /// We don't really need to check the previous status, if it's in a block there's nothing we can do
    pub fn mark_mined(&mut self, outpoint: OutPoint, mined_in_block: BlockHash) -> Result<()> {
        let (outpoint, mut output) = self.get_outpoint(outpoint)?;

        let block_hex = mined_in_block.to_string();
        output.spend_status = OutputSpendStatus::Mined(block_hex);
        self.outputs.insert(outpoint, output);
        Ok(())
    }

    /// Revert the outpoint status to Unspent, regardless of the current status
    /// This could be useful on some rare occurrences, like a transaction falling out of mempool after a while
    /// Watch out we also reverse the mined state, use with caution
    #[allow(dead_code)]
    pub fn revert_spent_status(&mut self, outpoint: OutPoint) -> Result<()> {
        let (outpoint, mut output) = self.get_outpoint(outpoint)?;

        if output.spend_status != OutputSpendStatus::Unspent {
            output.spend_status = OutputSpendStatus::Unspent;
            self.outputs.insert(outpoint, output);
        }
        Ok(())
    }

    pub fn get_mut(&mut self, outpoint: &OutPoint) -> Option<&mut OwnedOutput> {
        self.outputs.get_mut(outpoint)
    }
}
