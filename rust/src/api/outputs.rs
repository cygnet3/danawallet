use std::{
    collections::{HashMap, HashSet},
    str::FromStr,
};

use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use sp_client::{
    bitcoin::{absolute::Height, BlockHash, OutPoint, Txid},
    OutputSpendStatus, OwnedOutput,
};

use anyhow::{Error, Result};

use crate::stream::StateUpdate;

use super::structs::ApiOwnedOutput;

#[frb(opaque)]
pub struct OwnedOutPoints(HashSet<OutPoint>);

impl OwnedOutPoints {
    pub(crate) fn to_inner(self) -> HashSet<OutPoint> {
        self.0
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb(opaque)]
pub struct OwnedOutputs(HashMap<OutPoint, OwnedOutput>);

impl OwnedOutputs {
    #[flutter_rust_bridge::frb(sync)]
    pub fn empty() -> Self {
        Self(HashMap::new())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn decode(encoded_outputs: String) -> Self {
        serde_json::from_str(&encoded_outputs).unwrap()
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn encode(&self) -> String {
        serde_json::to_string(&self).unwrap()
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn process_state_update(&mut self, update: &StateUpdate) -> Result<()> {
        match update {
            StateUpdate::Update {
                blkheight: _,
                blkhash,
                found_outputs,
                found_inputs,
            } => {
                // mark inputs as mined
                for outpoint in found_inputs {
                    // this may confirm the same tx multiple times, but this shouldn't be a problem
                    self.mark_mined(*outpoint, *blkhash)?;
                }

                // record the outputs
                self.0.extend(found_outputs.clone());
            }
            StateUpdate::NoUpdate { .. } => (),
        }

        Ok(())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn mark_outpoints_spent(&mut self, spent_by: String, spent: Vec<String>) -> Result<()> {
        for outpoint in spent {
            self.mark_spent(
                OutPoint::from_str(&outpoint)?,
                Txid::from_str(&spent_by)?,
                true,
            )?;
        }

        Ok(())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn reset_to_height(&mut self, height: u32) -> Result<()> {
        let blkheight = Height::from_consensus(height)?;
        // reset known outputs to height
        self.0.retain(|_, o| o.blockheight <= blkheight);

        Ok(())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn get_unspent_amount(&self) -> u64 {
        self.0
            .values()
            .filter(|x| x.spend_status == OutputSpendStatus::Unspent)
            .fold(0, |acc, x| acc + x.amount.to_sat())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn get_unspent_outputs(&self) -> HashMap<String, ApiOwnedOutput> {
        let mut res = HashMap::new();
        for (outpoint, output) in self.0.iter() {
            if output.spend_status == OutputSpendStatus::Unspent {
                res.insert(outpoint.to_string(), output.clone().into());
            }
        }

        res
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn get_unconfirmed_spent_outpoints(&self) -> OwnedOutPoints {
        let mut res = HashSet::new();
        for (outpoint, output) in self.0.iter() {
            if matches!(output.spend_status, OutputSpendStatus::Spent(_)) {
                res.insert(*outpoint);
            }
        }

        OwnedOutPoints(res)
    }

    /// Mark the output as being spent in block `mined_in_block`
    /// We don't really need to check the previous status, if it's in a block there's nothing we can do
    fn mark_mined(&mut self, outpoint: OutPoint, mined_in_block: BlockHash) -> Result<()> {
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

    fn mark_spent(
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
}
