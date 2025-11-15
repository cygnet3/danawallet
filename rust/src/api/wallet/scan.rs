use crate::{api::outputs::OwnedOutPoints, http_client::ReqwestClient, state::scanner::NativeSpScanner, state::StateUpdater, wallet::KEEP_SCANNING};
use anyhow::Result;
use spdk_core::bitcoin::{Amount, absolute::Height};
use backend_blindbit_native::AsyncBlindbitBackend;
use spdk_core::scanner::AsyncSpScanner;

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
        owned_outpoints: OwnedOutPoints,
    ) -> Result<()> {
        let sp_client = self.client.clone();
        
        let http_client = ReqwestClient::new()?;
        let backend = AsyncBlindbitBackend::new(blindbit_url, http_client)?;

        let dust_limit = Amount::from_sat(dust_limit);

        let start = Height::from_consensus(last_scan + 1)?;
        let end = backend.block_height().await?;

        let updater = StateUpdater::new();

        KEEP_SCANNING.store(true, std::sync::atomic::Ordering::Relaxed);

        let mut scanner = NativeSpScanner::new(
            sp_client,
            updater,
            backend,
            owned_outpoints.to_inner(),
            &KEEP_SCANNING,
        );

        scanner.scan_blocks(start, end, dust_limit, ENABLE_CUTTHROUGH).await?;

        Ok(())
    }
}
