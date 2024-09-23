use std::collections::{HashMap, HashSet};

use sp_client::{
    bitcoin::{absolute::Height, Amount, BlockHash, OutPoint, Txid},
    OutputSpendStatus, OwnedOutput, Updater,
};

use crate::{
    stream::{send_scan_progress, send_scan_result, ScanProgress, ScanResult},
    wallet::{
        recorded::{RecordedTransaction, RecordedTransactionIncoming},
        SpWallet,
    },
};

use anyhow::{Error, Result};

pub struct WalletUpdater {
    wallet: SpWallet,
    scan_start: Height,
    scan_end: Height,
}

impl WalletUpdater {
    pub fn new(wallet: SpWallet, scan_start: Height, scan_end: Height) -> Self {
        Self {
            wallet,
            scan_start,
            scan_end,
        }
    }

    fn confirm_recorded_outgoing_transaction(
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

    fn record_incoming_transaction(&mut self, txid: Txid, amount: Amount, confirmed_at: Height) {
        self.wallet
            .tx_history
            .push(RecordedTransaction::Incoming(RecordedTransactionIncoming {
                txid,
                amount,
                confirmed_at: Some(confirmed_at),
            }))
    }
}

impl Updater for WalletUpdater {
    fn update_last_scan(&mut self, height: Height) {
        self.wallet.last_scan = height;

        let wallet_str = serde_json::to_string(&self.wallet).unwrap();
        send_scan_result(ScanResult {
            updated_wallet: wallet_str,
        });
    }

    fn send_scan_progress(&self, current: Height) {
        send_scan_progress(ScanProgress {
            start: self.scan_start.to_consensus_u32(),
            current: current.to_consensus_u32(),
            end: self.scan_end.to_consensus_u32(),
        });
    }

    fn record_block_outputs(
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

    fn record_block_inputs(
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
    fn mark_mined(&mut self, outpoint: OutPoint, mined_in_block: BlockHash) -> Result<()> {
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
    fn revert_spent_status(&mut self, outpoint: OutPoint) -> Result<()> {
        let output = self
            .wallet
            .outputs
            .get_mut(&outpoint)
            .ok_or(Error::msg("Outpoint not in list"))?;

        output.spend_status = OutputSpendStatus::Unspent;
        Ok(())
    }
}
