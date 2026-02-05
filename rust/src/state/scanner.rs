use std::sync::atomic::AtomicBool;
use std::collections::{HashMap, HashSet};
use std::time::Instant;
use std::pin::Pin;

use anyhow::{Result, bail};
use backend_blindbit_native::futures::stream::Stream;
use backend_blindbit_native::async_trait::async_trait;

use backend_blindbit_native::{AsyncBlindbitBackend, HttpClient};
use spdk_core::scanner::AsyncSpScanner;
use spdk_core::backend::AsyncChainBackend;
use log::info;
use spdk_core::bitcoin::bip158::BlockFilter;
use spdk_core::bitcoin::hashes::{Hash, sha256};
use spdk_core::{FilterData, OutputSpendStatus, OwnedOutput};
use spdk_core::bitcoin::{Amount, BlockHash};
use spdk_core::bitcoin::secp256k1::PublicKey;
use spdk_core::{BlockData, SpClient, bitcoin::{OutPoint, absolute::Height}};

use crate::state::StateUpdater;

pub struct NativeSpScanner<'a, H: HttpClient> {
    updater: StateUpdater,
    backend: AsyncBlindbitBackend<H>,
    client: SpClient,
    keep_scanning: &'a AtomicBool,      // used to interrupt scanning
    owned_outpoints: HashSet<OutPoint>, // used to scan block inputs
}

impl<'a, H: HttpClient> NativeSpScanner<'a, H> {
    pub fn new(
        client: SpClient,
        updater: StateUpdater,
        backend: AsyncBlindbitBackend<H>,
        owned_outpoints: HashSet<OutPoint>,
        keep_scanning: &'a AtomicBool,
    ) -> Self {
        Self {
            client,
            updater,
            backend,
            owned_outpoints,
            keep_scanning,
        }
    }

}

#[async_trait]
impl<'a, H: HttpClient + Clone + Send + Sync + 'static> AsyncSpScanner for NativeSpScanner<'a, H> {
    async fn scan_blocks(
        &mut self,
        start: Height,
        end: Height,
        dust_limit: Amount,
        with_cutthrough: bool,
    ) -> Result<()> {
        if start > end {
            bail!("bigger start than end: {} > {}", start, end);
        }

        info!("start: {} end: {}", start, end);
        let start_time: Instant = Instant::now();

        // get block data stream
        let range = start.to_consensus_u32()..=end.to_consensus_u32();
        let block_data_stream = self.get_block_data_stream(range, dust_limit, with_cutthrough);

        // process blocks using block data stream (default implementation from trait)
        self.process_blocks(start, end, block_data_stream).await?;

        // time elapsed for the scan
        info!(
            "Blindbit scan complete in {} seconds",
            start_time.elapsed().as_secs()
        );

        Ok(())
    }

    async fn process_block(
        &mut self,
        blockdata: BlockData,
    ) -> Result<(HashMap<OutPoint, OwnedOutput>, HashSet<OutPoint>)> {
        let BlockData {
            blkheight,
            tweaks,
            new_utxo_filter,
            spent_filter,
            ..
        } = blockdata;

        let outs = self
            .process_block_outputs(blkheight, tweaks, new_utxo_filter).await?;

        // after processing outputs, we add the found outputs to our list
        self.owned_outpoints.extend(outs.keys());

        let ins = self.process_block_inputs(blkheight, spent_filter).await?;

        // after processing inputs, we remove the found inputs
        self.owned_outpoints.retain(|item| !ins.contains(item));

        Ok((outs, ins))
    }

    async fn process_block_outputs(
        &self,
        blkheight: Height,
        tweaks: Vec<PublicKey>,
        new_utxo_filter: FilterData,
    ) -> Result<HashMap<OutPoint, OwnedOutput>> {
        let mut res = HashMap::new();

        if !tweaks.is_empty() {
            let secrets_map = self.client.get_script_to_secret_map(tweaks)?;

            //last_scan = last_scan.max(n as u32);
            let candidate_spks: Vec<&[u8; 34]> = secrets_map.keys().collect();

            //get block gcs & check match
            let blkfilter = BlockFilter::new(&new_utxo_filter.data);
            let blkhash = new_utxo_filter.block_hash;

            let matched_outputs = Self::check_block_outputs(blkfilter, blkhash, candidate_spks)?;

            //if match: fetch and scan utxos
            if matched_outputs {
                info!("matched outputs on: {}", blkheight);
                let found = self.scan_utxos(blkheight, secrets_map).await?;

                if !found.is_empty() {
                    for (label, utxo, tweak) in found {
                        let outpoint = OutPoint {
                            txid: utxo.txid,
                            vout: utxo.vout,
                        };

                        let out = OwnedOutput {
                            blockheight: blkheight,
                            tweak: tweak.to_be_bytes(),
                            amount: utxo.value,
                            script: utxo.scriptpubkey,
                            label,
                            spend_status: OutputSpendStatus::Unspent,
                        };

                        res.insert(outpoint, out);
                    }
                }
            }
        }
        Ok(res)
    }

    async fn process_block_inputs(
        &self,
        blkheight: Height,
        spent_filter: FilterData,
    ) -> Result<HashSet<OutPoint>> {
        let mut res = HashSet::new();

        let blkhash = spent_filter.block_hash;

        // first get the 8-byte hashes used to construct the input filter
        let input_hashes_map = self.get_input_hashes(blkhash).await?;

        // check against filter
        let blkfilter = BlockFilter::new(&spent_filter.data);
        let matched_inputs = self.check_block_inputs(
            blkfilter,
            blkhash,
            input_hashes_map.keys().cloned().collect(),
        )?;

        // if match: download spent data, collect the outpoints that are spent
        if matched_inputs {
            info!("matched inputs on: {}", blkheight);
            let spent = self.backend.spent_index(blkheight).await?.data;

            for spent in spent {
                let hex: &[u8] = spent.as_ref();

                if let Some(outpoint) = input_hashes_map.get(hex) {
                    res.insert(*outpoint);
                }
            }
        }
        Ok(res)
    }

    fn get_block_data_stream(
        &self,
        range: std::ops::RangeInclusive<u32>,
        dust_limit: Amount,
        with_cutthrough: bool,
    ) -> Pin<Box<dyn Stream<Item = Result<BlockData>> + Send + 'static>> {
        self.backend
            .get_block_data_stream(range, dust_limit, with_cutthrough)
    }

    fn should_interrupt(&self) -> bool {
        !self
            .keep_scanning
            .load(std::sync::atomic::Ordering::Relaxed)
    }

    async fn save_state(&mut self) -> Result<()> {
        <StateUpdater as spdk_core::AsyncUpdater>::save_to_persistent_storage(&mut self.updater).await
    }

    async fn record_outputs(
        &mut self,
        height: Height,
        block_hash: BlockHash,
        outputs: HashMap<OutPoint, OwnedOutput>,
    ) -> Result<()> {
        <StateUpdater as spdk_core::AsyncUpdater>::record_block_outputs(&mut self.updater, height, block_hash, outputs).await
    }

    async fn record_inputs(
        &mut self,
        height: Height,
        block_hash: BlockHash,
        inputs: HashSet<OutPoint>,
    ) -> Result<()> {
        <StateUpdater as spdk_core::AsyncUpdater>::record_block_inputs(&mut self.updater, height, block_hash, inputs).await
    }

    async fn record_progress(&mut self, start: Height, current: Height, end: Height) -> Result<()> {
        <StateUpdater as spdk_core::AsyncUpdater>::record_scan_progress(&mut self.updater, start, current, end).await
    }

    fn client(&self) -> &SpClient {
        &self.client
    }

    fn backend(&self) -> &dyn AsyncChainBackend {
        &self.backend
    }

    fn updater(&mut self) -> &mut dyn spdk_core::AsyncUpdater {
        &mut self.updater
    }

    // Override the default get_input_hashes implementation to use owned_outpoints
    async fn get_input_hashes(&self, blkhash: BlockHash) -> Result<HashMap<[u8; 8], OutPoint>> {
        let mut map: HashMap<[u8; 8], OutPoint> = HashMap::new();

        for outpoint in &self.owned_outpoints {
            let mut arr = [0u8; 68];
            arr[..32].copy_from_slice(&outpoint.txid.to_raw_hash().to_byte_array());
            arr[32..36].copy_from_slice(&outpoint.vout.to_le_bytes());
            arr[36..].copy_from_slice(&blkhash.to_byte_array());
            let hash = sha256::Hash::hash(&arr);

            let mut res = [0u8; 8];
            res.copy_from_slice(&hash[..8]);

            map.insert(res, outpoint.clone());
        }

        Ok(map)
    }
}
