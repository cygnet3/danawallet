use std::{
    collections::{HashMap, HashSet},
    mem,
};

use spdk_core::{
    bitcoin::{absolute::Height, BlockHash, OutPoint},
    OwnedOutput, Updater,
};

use crate::stream::{send_scan_progress, send_state_update, ScanProgress, StateUpdate};

use anyhow::Result;

pub struct StateUpdater {
    update: bool,
    blkhash: Option<BlockHash>,
    blkheight: Option<Height>,
    found_outputs: HashMap<OutPoint, OwnedOutput>,
    found_inputs: HashSet<OutPoint>,
}

impl StateUpdater {
    pub fn new() -> Self {
        Self {
            update: false,
            blkheight: None,
            blkhash: None,
            found_outputs: HashMap::new(),
            found_inputs: HashSet::new(),
        }
    }

    pub fn to_update(&mut self) -> Result<StateUpdate> {
        let blkheight = self
            .blkheight
            .ok_or(anyhow::Error::msg("blkheight not filled"))?;

        if self.update {
            self.update = false;

            let blkhash = self.blkhash.take();

            self.blkheight = None;

            // take results, and insert new empty values
            let found_inputs = mem::take(&mut self.found_inputs);
            let found_outputs = mem::take(&mut self.found_outputs);

            Ok(StateUpdate::from_internal(
                blkheight,
                blkhash,
                found_outputs,
                found_inputs,
            ))
        } else {
            Ok(StateUpdate::from_internal(
                blkheight,
                None,
                HashMap::new(),
                HashSet::new(),
            ))
        }
    }
}

impl Updater for StateUpdater {
    fn record_scan_progress(&mut self, start: Height, current: Height, end: Height) -> Result<()> {
        self.blkheight = Some(current);

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
        blkhash: BlockHash,
        found_outputs: HashMap<OutPoint, OwnedOutput>,
    ) -> Result<()> {
        // may have already been written by record_block_inputs
        self.update = true;
        self.found_outputs = found_outputs;
        self.blkhash = Some(blkhash);
        self.blkheight = Some(height);

        Ok(())
    }

    fn record_block_inputs(
        &mut self,
        blkheight: Height,
        blkhash: BlockHash,
        found_inputs: HashSet<OutPoint>,
    ) -> Result<()> {
        self.update = true;
        self.blkheight = Some(blkheight);
        self.blkhash = Some(blkhash);
        self.found_inputs = found_inputs;

        Ok(())
    }

    fn save_to_persistent_storage(&mut self) -> Result<()> {
        send_state_update(self.to_update()?);
        Ok(())
    }
}
