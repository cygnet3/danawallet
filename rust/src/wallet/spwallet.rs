use std::collections::HashMap;
use std::str::FromStr;

use serde::{Deserialize, Serialize};
use sp_client::bitcoin::absolute::Height;
use sp_client::bitcoin::bip32::{DerivationPath, Xpriv};
use sp_client::bitcoin::hex::DisplayHex;
use sp_client::bitcoin::secp256k1::SecretKey;
use sp_client::bitcoin::{self, Amount, BlockHash, Network, Txid, XOnlyPublicKey};
use sp_client::bitcoin::{key::Secp256k1, secp256k1::PublicKey, OutPoint, Transaction};

use anyhow::{Error, Result};

use sp_client::silentpayments::utils as sp_utils;
use sp_client::spclient::{OutputSpendStatus, OwnedOutput, Recipient, SpClient};

use super::recorded::{
    RecordedTransaction, RecordedTransactionIncoming, RecordedTransactionOutgoing,
};

type WalletFingerprint = [u8; 8];

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct SpWallet {
    client: SpClient,
    wallet_fingerprint: WalletFingerprint,
    tx_history: Vec<RecordedTransaction>,
    birthday: u32,
    last_scan: u32,
    outputs: HashMap<OutPoint, OwnedOutput>,
}

impl SpWallet {
    pub fn new(client: SpClient, birthday: u32) -> Result<Self> {
        let wallet_fingerprint = client.get_client_fingerprint()?;
        let last_scan = birthday;
        let tx_history = vec![];
        let outputs = HashMap::new();

        Ok(Self {
            client,
            birthday,
            wallet_fingerprint,
            last_scan,
            tx_history,
            outputs,
        })
    }

    pub fn get_client(&self) -> &SpClient {
        &self.client
    }

    pub fn get_tx_history(&self) -> Vec<RecordedTransaction> {
        self.tx_history.clone()
    }

    #[allow(dead_code)]
    pub fn get_mut_client(&mut self) -> &mut SpClient {
        &mut self.client
    }

    pub fn get_birthday(&self) -> u32 {
        self.birthday
    }

    pub fn set_birthday(&mut self, new_birthday: u32) {
        self.birthday = new_birthday;
    }

    pub fn get_last_scan(&self) -> u32 {
        self.last_scan
    }

    pub fn set_last_scan(&mut self, new_scan: u32) {
        self.last_scan = new_scan;
    }

    pub fn get_outputs(self) -> HashMap<OutPoint, OwnedOutput> {
        self.outputs.clone()
    }

    pub fn get_owned_outpoints(&self) -> Vec<OutPoint> {
        self.outputs.keys().cloned().collect()
    }

    pub fn get_balance(&self) -> Amount {
        self.outputs
            .iter()
            .filter(|(_, o)| o.spend_status == OutputSpendStatus::Unspent)
            .fold(Amount::from_sat(0), |acc, x| acc + x.1.amount)
    }

    #[allow(dead_code)]
    pub fn update_wallet_with_transaction(
        &mut self,
        tx: &Transaction,
        blockheight: u32,
        partial_tweak: PublicKey,
    ) -> Result<HashMap<OutPoint, OwnedOutput>> {
        // First check that we haven't already scanned this transaction
        let txid = tx.txid();

        for i in 0..tx.output.len() {
            if self.outputs.contains_key(&OutPoint {
                txid,
                vout: i as u32,
            }) {
                return Err(Error::msg("Transaction already scanned"));
            }
        }

        for input in tx.input.iter() {
            if let Some(output) = self.outputs.get_mut(&input.previous_output) {
                match output.spend_status.clone() {
                    OutputSpendStatus::Spent(tx) => {
                        if tx == txid.to_string() {
                            return Err(Error::msg("Transaction already scanned"));
                        }
                    }
                    OutputSpendStatus::Mined(_) => {
                        return Err(Error::msg("Transaction already scanned"))
                    }
                    _ => continue,
                }
            }
        }

        let shared_secret = sp_utils::receiving::calculate_ecdh_shared_secret(
            &partial_tweak,
            &self.client.get_scan_key(),
        );
        let mut pubkeys_to_check: HashMap<XOnlyPublicKey, u32> = HashMap::new();
        for (vout, output) in (0u32..).zip(tx.output.iter()) {
            if output.script_pubkey.is_p2tr() {
                let xonly = XOnlyPublicKey::from_slice(&output.script_pubkey.as_bytes()[2..])?;
                pubkeys_to_check.insert(xonly, vout);
            }
        }
        let ours = self
            .client
            .sp_receiver
            .scan_transaction(&shared_secret, pubkeys_to_check.keys().cloned().collect())?;
        let mut new_outputs: HashMap<OutPoint, OwnedOutput> = HashMap::new();
        for (label, map) in ours {
            for (key, scalar) in map {
                let vout = pubkeys_to_check.get(&key).unwrap().to_owned();
                let txout = tx.output.get(vout as usize).unwrap();

                let label_str: Option<String>;
                if let Some(ref l) = label {
                    label_str = Some(l.as_string());
                } else {
                    label_str = None;
                }

                let outpoint = OutPoint::new(tx.txid(), vout);
                let owned = OwnedOutput {
                    blockheight,
                    tweak: scalar.to_be_bytes().to_lower_hex_string(),
                    amount: txout.value,
                    script: txout.script_pubkey.as_bytes().to_lower_hex_string(),
                    label: label_str,
                    spend_status: OutputSpendStatus::Unspent,
                };
                new_outputs.insert(outpoint, owned);
            }
        }
        let mut res = new_outputs.clone();
        self.outputs.extend(new_outputs);

        let txid = tx.txid().to_string();
        // update outputs that we own and that are spent
        for input in tx.input.iter() {
            if let Some(prevout) = self.outputs.get_mut(&input.previous_output) {
                // This is spent by this tx
                prevout.spend_status = OutputSpendStatus::Spent(txid.clone());
                res.insert(input.previous_output, prevout.clone());
            }
        }

        Ok(res)
    }

    pub fn record_outgoing_transaction(
        &mut self,
        txid: Txid,
        spent_outpoints: Vec<OutPoint>,
        recipients: Vec<Recipient>,
        change: Amount,
    ) {
        self.tx_history
            .push(RecordedTransaction::Outgoing(RecordedTransactionOutgoing {
                txid,
                spent_outpoints,
                recipients,
                confirmed_at: None,
                change,
            }))
    }

    pub fn confirm_recorded_outgoing_transaction(
        &mut self,
        outpoint: OutPoint,
        blkheight: Height,
    ) -> Result<()> {
        for recorded_tx in self.tx_history.iter_mut() {
            match recorded_tx {
                RecordedTransaction::Outgoing(outgoing)
                    if (outgoing.spent_outpoints.contains(&outpoint)) =>
                {
                    outgoing.confirmed_at = Some(blkheight);
                    return Ok(());
                }
                _ => (),
            }
        }

        Err(Error::msg(format!(
            "No outgoing tx found for input: {}",
            outpoint
        )))
    }

    pub fn record_incoming_transaction(
        &mut self,
        txid: Txid,
        amount: Amount,
        confirmed_at: Height,
    ) {
        self.tx_history
            .push(RecordedTransaction::Incoming(RecordedTransactionIncoming {
                txid,
                amount,
                confirmed_at: Some(confirmed_at),
            }))
    }

    fn reset_to_height(&mut self, blkheight: u32) {
        // reset known outputs to height
        self.outputs.retain(|_, o| o.blockheight < blkheight);

        // reset tx history to height
        self.tx_history.retain(|tx| match tx {
            RecordedTransaction::Incoming(incoming) => incoming
                .confirmed_at
                .is_some_and(|x| x.to_consensus_u32() < blkheight),
            RecordedTransaction::Outgoing(outgoing) => outgoing
                .confirmed_at
                .is_some_and(|x| x.to_consensus_u32() < blkheight),
        });
    }

    pub fn reset_to_birthday(&mut self) {
        self.reset_to_height(self.birthday);
        self.last_scan = self.birthday;
    }

    pub fn record_block_outputs(
        &mut self,
        height: Height,
        found_outputs: HashMap<OutPoint, OwnedOutput>,
    ) {
        // add outputs to history
        let mut txs: HashMap<Txid, Amount> = HashMap::new();
        for (outpoint, output) in found_outputs.iter() {
            let entry = txs.entry(outpoint.txid).or_default();
            *entry += output.amount;
        }
        for (txid, amount) in txs {
            self.tx_history
                .push(RecordedTransaction::Incoming(RecordedTransactionIncoming {
                    txid,
                    amount,
                    confirmed_at: Some(height),
                }))
        }

        // add outputs to known outputs
        self.outputs.extend(found_outputs);
    }

    pub fn record_block_inputs(
        &mut self,
        blkheight: Height,
        blkhash: BlockHash,
        found_inputs: Vec<OutPoint>,
    ) -> Result<()> {
        for outpoint in found_inputs {
            // this may confirm the same tx multiple times, but this shouldn't be a problem
            self.confirm_recorded_outgoing_transaction(outpoint, blkheight)?;
            self.mark_mined(outpoint, blkhash)?;
        }

        Ok(())
    }

    pub fn mark_spent(
        &mut self,
        outpoint: OutPoint,
        spending_tx: Txid,
        force_update: bool,
    ) -> Result<()> {
        let output = self
            .outputs
            .get_mut(&outpoint)
            .ok_or(Error::msg("Outpoint not in list"))?;

        match &output.spend_status {
            OutputSpendStatus::Unspent => {
                let tx_hex = spending_tx.to_string();
                output.spend_status = OutputSpendStatus::Spent(tx_hex);
                //self.outputs.insert(outpoint, output);
                Ok(())
            }
            OutputSpendStatus::Spent(tx_hex) => {
                // We may want to fail if that's the case, or force update if we know what we're doing
                if force_update {
                    let tx_hex = spending_tx.to_string();
                    output.spend_status = OutputSpendStatus::Spent(tx_hex);
                    //self.outputs.insert(outpoint, output);
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
        let output = self
            .outputs
            .get_mut(&outpoint)
            .ok_or(Error::msg("Outpoint not in list"))?;

        let block_hex = mined_in_block.to_string();
        output.spend_status = OutputSpendStatus::Mined(block_hex);
        //self.outputs.insert(outpoint, output);
        Ok(())
    }

    /// Revert the outpoint status to Unspent, regardless of the current status
    /// This could be useful on some rare occurrences, like a transaction falling out of mempool after a while
    /// Watch out we also reverse the mined state, use with caution
    #[allow(dead_code)]
    pub fn revert_spent_status(&mut self, outpoint: OutPoint) -> Result<()> {
        let output = self
            .outputs
            .get_mut(&outpoint)
            .ok_or(Error::msg("Outpoint not in list"))?;

        output.spend_status = OutputSpendStatus::Unspent;
        Ok(())
    }
}

pub fn derive_keys_from_seed(seed: &[u8; 64], network: Network) -> Result<(SecretKey, SecretKey)> {
    let xprv = Xpriv::new_master(network, seed)?;

    let (scan_privkey, spend_privkey) = derive_keys_from_xprv(xprv)?;

    Ok((scan_privkey, spend_privkey))
}

fn derive_keys_from_xprv(xprv: Xpriv) -> Result<(SecretKey, SecretKey)> {
    let (scan_path, spend_path) = match xprv.network {
        bitcoin::Network::Bitcoin => ("m/352h/0h/0h/1h/0", "m/352h/0h/0h/0h/0"),
        _ => ("m/352h/1h/0h/1h/0", "m/352h/1h/0h/0h/0"),
    };

    let secp = Secp256k1::signing_only();
    let scan_path = DerivationPath::from_str(scan_path)?;
    let spend_path = DerivationPath::from_str(spend_path)?;
    let scan_privkey = xprv.derive_priv(&secp, &scan_path)?.private_key;
    let spend_privkey = xprv.derive_priv(&secp, &spend_path)?.private_key;

    Ok((scan_privkey, spend_privkey))
}
