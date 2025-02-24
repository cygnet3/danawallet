use std::collections::{HashMap, HashSet};

use sp_client::{
    bitcoin::{absolute::Height, Amount, BlockHash, OutPoint, Txid},
    OutputSpendStatus, OwnedOutput, Updater,
};

use crate::{
    history::TxHistory,
    stream::{send_scan_progress, send_scan_result, ScanProgress, ScanResult},
    wallet::SpWallet,
};

use anyhow::{Error, Result};

pub struct WalletUpdater {
    wallet: SpWallet,
    tx_history: TxHistory,
}

impl WalletUpdater {
    pub fn new(wallet: SpWallet, tx_history: TxHistory) -> Self {
        Self { wallet, tx_history }
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
    #[allow(unused)]
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

impl Updater for WalletUpdater {
    fn record_scan_progress(&mut self, start: Height, current: Height, end: Height) -> Result<()> {
        self.wallet.last_scan = current;

        send_scan_progress(ScanProgress {
            start: start.to_consensus_u32(),
            current: current.to_consensus_u32(),
            end: end.to_consensus_u32(),
        });

        Ok(())
    }

    fn record_block_outputs(
        &mut self,
        height: Height,
        _blkhash: BlockHash,
        found_outputs: HashMap<OutPoint, OwnedOutput>,
    ) -> Result<()> {
        // add outputs to history
        let mut txs: HashMap<Txid, Amount> = HashMap::new();
        for (outpoint, output) in found_outputs.iter() {
            let entry = txs.entry(outpoint.txid).or_default();
            *entry += output.amount;
        }
        for (txid, amount) in txs {
            self.tx_history
                .record_incoming_transaction(txid, amount, height);
        }

        // add outputs to known outputs
        self.wallet.outputs.extend(found_outputs);

        Ok(())
    }

    fn record_block_inputs(
        &mut self,
        blkheight: Height,
        blkhash: BlockHash,
        found_inputs: HashSet<OutPoint>,
    ) -> Result<()> {
        for outpoint in found_inputs {
            // this may confirm the same tx multiple times, but this shouldn't be a problem
            self.tx_history
                .confirm_recorded_outgoing_transaction(outpoint, blkheight)?;
            self.mark_mined(outpoint, blkhash)?;
        }

        Ok(())
    }

    fn save_to_persistent_storage(&mut self) -> Result<()> {
        let wallet_str = serde_json::to_string(&self.wallet)?;
        let tx_history_str = serde_json::to_string(&self.tx_history)?;
        send_scan_result(ScanResult {
            updated_wallet: wallet_str,
            updated_tx_history: tx_history_str,
        });

        Ok(())
    }
}
