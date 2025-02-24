use std::collections::{HashMap, HashSet};

use sp_client::{
    bitcoin::{absolute::Height, Amount, BlockHash, OutPoint, Txid},
    OwnedOutput, Updater,
};

use crate::{
    state::OwnedOutputs,
    state::TxHistory,
    stream::{send_scan_progress, send_scan_result, ScanProgress, ScanResult},
};

use anyhow::Result;

/// Currently, state updater keeps track of *all* outputs and txes, not just the new ones.
///
/// Todo: replace with new_outputs and new_txes, and flush them
/// after calling save_to_persistent_storage.
pub struct StateUpdater {
    tx_history: TxHistory,
    outputs: OwnedOutputs,
    last_scan: Height,
}

impl StateUpdater {
    pub fn new(tx_history: TxHistory, outputs: OwnedOutputs, last_scan: Height) -> Self {
        Self {
            tx_history,
            outputs,
            last_scan,
        }
    }
}

impl Updater for StateUpdater {
    fn record_scan_progress(&mut self, start: Height, current: Height, end: Height) -> Result<()> {
        self.last_scan = current;

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
        self.outputs.extend(found_outputs);

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
            self.outputs.mark_mined(outpoint, blkhash)?;
        }

        Ok(())
    }

    fn save_to_persistent_storage(&mut self) -> Result<()> {
        let tx_history_str = serde_json::to_string(&self.tx_history)?;
        let owned_outputs_str = serde_json::to_string(&self.outputs)?;
        send_scan_result(ScanResult {
            updated_last_scan: self.last_scan.to_consensus_u32(),
            updated_tx_history: tx_history_str,
            updated_owned_outputs: owned_outputs_str,
        });

        Ok(())
    }
}
