use std::{collections::HashSet, str::FromStr};

use crate::{state::StateUpdater, wallet::KEEP_SCANNING};
use anyhow::Result;
use backend_blindbit_v1::BlindbitBackend;
use spdk_core::{bitcoin::{absolute::Height, OutPoint}, ChainBackend, SpScanner};

use super::SpWallet;

/// we enable cutthrough by default, no need to let the user decide
const ENABLE_CUTTHROUGH: bool = true;

impl SpWallet {
    #[flutter_rust_bridge::frb(sync)]
    pub fn interrupt_scanning() {
        KEEP_SCANNING.store(false, std::sync::atomic::Ordering::Relaxed);
    }

    pub async fn scan_to_tip(
        &self,
        blindbit_url: String,
        last_scan: u32,
        dust_limit: u64,
        owned_outpoints: Vec<String>,
    ) -> Result<()> {
        let backend = BlindbitBackend::new(blindbit_url)?;

        let dust_limit = spdk_core::bitcoin::Amount::from_sat(dust_limit);

        let owned_outpoints: HashSet<OutPoint> = owned_outpoints
            .into_iter()
            .map(|s| OutPoint::from_str(&s))
            .collect::<Result<_, _>>()?;

        let start = Height::from_consensus(last_scan + 1)?;
        let end = backend.block_height().await?;

        let sp_client = self.client.clone();
        let updater = StateUpdater::new();

        KEEP_SCANNING.store(true, std::sync::atomic::Ordering::Relaxed);

        let mut scanner = SpScanner::new(
            sp_client,
            Box::new(updater),
            Box::new(backend),
            owned_outpoints,
            &KEEP_SCANNING,
        );

        scanner
            .scan_blocks(start, end, dust_limit, ENABLE_CUTTHROUGH)
            .await?;

        Ok(())
    }
}
