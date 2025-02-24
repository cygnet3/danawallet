use std::collections::{HashMap, HashSet};

use serde::{Deserialize, Serialize};
use sp_client::{
    bitcoin::{absolute::Height, Amount, BlockHash, OutPoint, Txid},
    OutputSpendStatus, OwnedOutput,
};

use anyhow::{Error, Result};

use crate::api::structs::ApiOwnedOutput;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OwnedOutputs(HashMap<OutPoint, OwnedOutput>);

impl OwnedOutputs {
    /// Mark the output as being spent in block `mined_in_block`
    /// We don't really need to check the previous status, if it's in a block there's nothing we can do
    pub fn mark_mined(&mut self, outpoint: OutPoint, mined_in_block: BlockHash) -> Result<()> {
        let output = self
            .0
            .get_mut(&outpoint)
            .ok_or(Error::msg("Outpoint not in list"))?;

        let block_hex = mined_in_block.to_string();
        output.spend_status = OutputSpendStatus::Mined(block_hex);
        Ok(())
    }

    /// Revert the outpoint status to Unspent, regardless of the current status
    /// This could be useful on some rare occurrences, like a transaction falling out of mempool after a while
    /// Watch out we also reverse the mined state, use with caution
    #[allow(unused)]
    fn revert_spent_status(&mut self, outpoint: OutPoint) -> Result<()> {
        let output = self
            .0
            .get_mut(&outpoint)
            .ok_or(Error::msg("Outpoint not in list"))?;

        output.spend_status = OutputSpendStatus::Unspent;
        Ok(())
    }

    pub fn extend(&mut self, found_outputs: HashMap<OutPoint, OwnedOutput>) {
        self.0.extend(found_outputs);
    }

    pub fn get_owned_outpoints(&self) -> HashSet<OutPoint> {
        self.0.keys().cloned().collect()
    }

    pub fn reset_to_height(&mut self, blkheight: Height) {
        // reset known outputs to height
        self.0.retain(|_, o| o.blockheight <= blkheight);
    }

    pub fn mark_spent(
        &mut self,
        outpoint: OutPoint,
        spending_tx: Txid,
        force_update: bool,
    ) -> Result<()> {
        let output = self
            .0
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

    pub fn to_api_owned_outputs(self) -> HashMap<String, ApiOwnedOutput> {
        self.0
            .into_iter()
            .map(|(outpoint, output)| (outpoint.to_string(), output.into()))
            .collect()
    }
}
