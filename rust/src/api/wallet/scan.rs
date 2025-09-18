use std::{collections::{HashMap, HashSet}, sync::{atomic::{AtomicBool}, Arc}, time::Instant};

use crate::{api::outputs::OwnedOutPoints, state::StateUpdater, wallet::KEEP_SCANNING};
use anyhow::{bail, Result};
use backend_blindbit_native::{BlindbitBackend, ChainBackend, SpScanner};
use flutter_rust_bridge::frb;
use futures::Stream;
use log::info;
use sp_client::{bitcoin::{absolute::Height, bip158::BlockFilter, hashes::{sha256, Hash}, secp256k1::PublicKey, Amount, BlockHash, OutPoint}, BlockData, FilterData, OutputSpendStatus, OwnedOutput, SpClient, Updater};

use super::SpWallet;

#[frb(opaque)]
pub struct NativeSpScanner {
    updater: Box<dyn Updater + Sync + Send>,
    backend: Box<dyn ChainBackend + Sync + Send>,
    client: SpClient,
    keep_scanning: Arc<AtomicBool>,     // used to interrupt scanning
    owned_outpoints: HashSet<OutPoint>, // used to scan block inputs
}

impl NativeSpScanner {
    pub fn new(
        client: SpClient,
        updater: Box<dyn Updater + Sync + Send>,
        backend: Box<dyn ChainBackend + Sync + Send>,
        owned_outpoints: HashSet<OutPoint>,
        keep_scanning: Arc<AtomicBool>,
    ) -> Self {
        Self {
            client,
            updater,
            backend,
            owned_outpoints,
            keep_scanning,
        }
    }

    pub async fn process_blocks(
        &mut self,
        start: Height,
        end: Height,
        block_data_stream: impl Stream<Item = Result<BlockData>> + Unpin + Send,
    ) -> Result<()> {
        use futures_util::StreamExt;
        use std::time::{Duration, Instant};

        let mut update_time = Instant::now();
        let mut stream = block_data_stream;

        while let Some(blockdata) = stream.next().await {
            let blockdata = blockdata?;
            let blkheight = blockdata.blkheight;
            let blkhash = blockdata.blkhash;

            // stop scanning and return if interrupted
            if self.should_interrupt() {
                self.save_state()?;
                return Ok(());
            }

            let mut save_to_storage = false;

            // always save on last block or after 30 seconds since last save
            if blkheight == end || update_time.elapsed() > Duration::from_secs(30) {
                save_to_storage = true;
            }

            let (found_outputs, found_inputs) = self.process_block(blockdata).await?;

            if !found_outputs.is_empty() {
                save_to_storage = true;
                self.record_outputs(blkheight, blkhash, found_outputs)?;
            }

            if !found_inputs.is_empty() {
                save_to_storage = true;
                self.record_inputs(blkheight, blkhash, found_inputs)?;
            }

            // tell the updater we scanned this block
            self.record_progress(start, blkheight, end)?;

            if save_to_storage {
                self.save_state()?;
                update_time = Instant::now();
            }
        }

        Ok(())
    }
}

#[async_trait::async_trait]
impl SpScanner for NativeSpScanner {
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

        // process blocks using block data stream
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
            .process_block_outputs(blkheight, tweaks, new_utxo_filter)
            .await?;

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
        let input_hashes_map = self.get_input_hashes(blkhash)?;

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
    ) -> std::pin::Pin<Box<dyn Stream<Item = Result<BlockData>> + Send>> {
        self.backend
            .get_block_data_for_range(range, dust_limit, with_cutthrough)
    }

    fn should_interrupt(&self) -> bool {
        !self
            .keep_scanning
            .load(std::sync::atomic::Ordering::Relaxed)
    }

    fn save_state(&mut self) -> Result<()> {
        self.updater.save_to_persistent_storage()
    }

    fn record_outputs(
        &mut self,
        height: Height,
        block_hash: BlockHash,
        outputs: HashMap<OutPoint, OwnedOutput>,
    ) -> Result<()> {
        self.updater
            .record_block_outputs(height, block_hash, outputs)
    }

    fn record_inputs(
        &mut self,
        height: Height,
        block_hash: BlockHash,
        inputs: HashSet<OutPoint>,
    ) -> Result<()> {
        self.updater.record_block_inputs(height, block_hash, inputs)
    }

    fn record_progress(&mut self, start: Height, current: Height, end: Height) -> Result<()> {
        self.updater.record_scan_progress(start, current, end)
    }

    fn client(&self) -> &SpClient {
        &self.client
    }

    fn backend(&self) -> &dyn ChainBackend {
        self.backend.as_ref()
    }

    fn updater(&mut self) -> &mut dyn Updater {
        self.updater.as_mut()
    }

    // Override the default get_input_hashes implementation to use owned_outpoints
    fn get_input_hashes(&self, blkhash: BlockHash) -> Result<HashMap<[u8; 8], OutPoint>> {
        let mut map: HashMap<[u8; 8], OutPoint> = HashMap::new();

        for outpoint in &self.owned_outpoints {
            let mut arr = [0u8; 68];
            arr[..32].copy_from_slice(outpoint.txid.to_raw_hash().as_byte_array());
            arr[32..36].copy_from_slice(&outpoint.vout.to_le_bytes());
            arr[36..].copy_from_slice(blkhash.as_byte_array());
            let hash = sha256::Hash::hash(&arr);

            let mut res = [0u8; 8];
            res.copy_from_slice(&hash[..8]);

            map.insert(res, outpoint.clone());
        }

        Ok(map)
    }
}

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
        let backend = BlindbitBackend::new(blindbit_url)?;

        let dust_limit = sp_client::bitcoin::Amount::from_sat(dust_limit);

        let start = Height::from_consensus(last_scan + 1)?;
        let end = backend.block_height().await?;

        let sp_client = self.client.clone();
        let updater = StateUpdater::new();

        KEEP_SCANNING.store(true, std::sync::atomic::Ordering::Relaxed);

        let mut scanner = NativeSpScanner::new(
            sp_client,
            Box::new(updater),
            Box::new(backend),
            owned_outpoints.to_inner(),
            KEEP_SCANNING.clone(),
        );

        scanner
            .scan_blocks(start, end, dust_limit, ENABLE_CUTTHROUGH)
            .await?;

        Ok(())
    }
}
