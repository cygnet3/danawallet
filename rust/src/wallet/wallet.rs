use std::collections::HashMap;
use std::sync::atomic::AtomicBool;

use serde::{Deserialize, Serialize};
use sp_client::bitcoin::absolute::Height;
use sp_client::bitcoin::OutPoint;
use sp_client::bitcoin::{Amount, Txid};

use anyhow::{Error, Result};

use sp_client::{OutputSpendStatus, OwnedOutput, SpClient};

type WalletFingerprint = [u8; 8];

use lazy_static::lazy_static;

lazy_static! {
    pub static ref KEEP_SCANNING: AtomicBool = AtomicBool::new(true);
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SpWallet {
    pub client: SpClient,
    pub wallet_fingerprint: WalletFingerprint,
    pub birthday: Height,
    pub last_scan: Height,
    pub outputs: HashMap<OutPoint, OwnedOutput>,
}

impl SpWallet {
    pub fn new(client: SpClient, birthday: u32) -> Result<Self> {
        let wallet_fingerprint = client.get_client_fingerprint()?;
        let birthday = Height::from_consensus(birthday)?;
        let last_scan = birthday;
        let outputs = HashMap::new();

        Ok(Self {
            client,
            birthday,
            wallet_fingerprint,
            last_scan,
            outputs,
        })
    }

    pub fn get_balance(&self) -> Amount {
        self.outputs
            .iter()
            .filter(|(_, o)| o.spend_status == OutputSpendStatus::Unspent)
            .fold(Amount::from_sat(0), |acc, x| acc + x.1.amount)
    }

    fn reset_to_height(&mut self, blkheight: Height) {
        // reset known outputs to height
        self.outputs.retain(|_, o| o.blockheight < blkheight);
    }

    pub fn reset_to_birthday(&mut self) {
        self.reset_to_height(self.birthday);
        self.last_scan = self.birthday;
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
}
