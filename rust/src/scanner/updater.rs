use std::collections::{HashMap, HashSet};

use sp_client::{
    bitcoin::{
        absolute::Height, secp256k1::PublicKey, Amount, BlockHash, OutPoint, Transaction, Txid,
        XOnlyPublicKey,
    },
    spclient::{OutputSpendStatus, OwnedOutput},
};

use crate::{
    stream::{send_scan_progress, send_scan_result, ScanProgress, ScanResult},
    wallet::{
        recorded::{RecordedTransaction, RecordedTransactionIncoming},
        SpWallet,
    },
};

use sp_client::silentpayments::utils as sp_utils;

pub struct Updater {
    wallet: SpWallet,
    scan_start: Height,
    scan_end: Height,
}

use anyhow::{Error, Result};

impl Updater {
    pub fn new(wallet: SpWallet, scan_start: Height, scan_end: Height) -> Self {
        Self {
            wallet,
            scan_start,
            scan_end,
        }
    }

    pub fn update_last_scan(&mut self, height: Height) {
        self.wallet.last_scan = height;

        let wallet_str = serde_json::to_string(&self.wallet).unwrap();
        send_scan_result(ScanResult {
            updated_wallet: wallet_str,
        });
    }

    pub fn send_scan_progress(&self, current: Height) {
        send_scan_progress(ScanProgress {
            start: self.scan_start.to_consensus_u32(),
            current: current.to_consensus_u32(),
            end: self.scan_end.to_consensus_u32(),
        });
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
            self.record_incoming_transaction(txid, amount, height);
        }

        // add outputs to known outputs
        self.wallet.outputs.extend(found_outputs);
    }

    pub fn record_block_inputs(
        &mut self,
        blkheight: Height,
        blkhash: BlockHash,
        found_inputs: HashSet<OutPoint>,
    ) -> Result<()> {
        for outpoint in found_inputs {
            // this may confirm the same tx multiple times, but this shouldn't be a problem
            self.confirm_recorded_outgoing_transaction(outpoint, blkheight)?;
            self.mark_mined(outpoint, blkhash)?;
        }

        Ok(())
    }

    /// Mark the output as being spent in block `mined_in_block`
    /// We don't really need to check the previous status, if it's in a block there's nothing we can do
    pub fn mark_mined(&mut self, outpoint: OutPoint, mined_in_block: BlockHash) -> Result<()> {
        let output = self
            .wallet
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
            .wallet
            .outputs
            .get_mut(&outpoint)
            .ok_or(Error::msg("Outpoint not in list"))?;

        output.spend_status = OutputSpendStatus::Unspent;
        Ok(())
    }

    #[allow(dead_code)]
    pub fn update_wallet_with_transaction(
        &mut self,
        tx: &Transaction,
        blockheight: Height,
        partial_tweak: PublicKey,
    ) -> Result<HashMap<OutPoint, OwnedOutput>> {
        // First check that we haven't already scanned this transaction
        let txid = tx.txid();

        for i in 0..tx.output.len() {
            if self.wallet.outputs.contains_key(&OutPoint {
                txid,
                vout: i as u32,
            }) {
                return Err(Error::msg("Transaction already scanned"));
            }
        }

        for input in tx.input.iter() {
            if let Some(output) = self.wallet.outputs.get_mut(&input.previous_output) {
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
            &self.wallet.client.get_scan_key(),
        );
        let mut pubkeys_to_check: HashMap<XOnlyPublicKey, u32> = HashMap::new();
        for (vout, output) in (0u32..).zip(tx.output.iter()) {
            if output.script_pubkey.is_p2tr() {
                let xonly = XOnlyPublicKey::from_slice(&output.script_pubkey.as_bytes()[2..])?;
                pubkeys_to_check.insert(xonly, vout);
            }
        }
        let ours = self
            .wallet
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
                    tweak: scalar.to_be_bytes(),
                    amount: txout.value,
                    script: txout.script_pubkey.clone(),
                    label: label_str,
                    spend_status: OutputSpendStatus::Unspent,
                };
                new_outputs.insert(outpoint, owned);
            }
        }
        let mut res = new_outputs.clone();
        self.wallet.outputs.extend(new_outputs);

        let txid = tx.txid().to_string();
        // update outputs that we own and that are spent
        for input in tx.input.iter() {
            if let Some(prevout) = self.wallet.outputs.get_mut(&input.previous_output) {
                // This is spent by this tx
                prevout.spend_status = OutputSpendStatus::Spent(txid.clone());
                res.insert(input.previous_output, prevout.clone());
            }
        }

        Ok(res)
    }

    pub fn confirm_recorded_outgoing_transaction(
        &mut self,
        outpoint: OutPoint,
        blkheight: Height,
    ) -> Result<()> {
        for recorded_tx in self.wallet.tx_history.iter_mut() {
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
        self.wallet
            .tx_history
            .push(RecordedTransaction::Incoming(RecordedTransactionIncoming {
                txid,
                amount,
                confirmed_at: Some(confirmed_at),
            }))
    }
}
