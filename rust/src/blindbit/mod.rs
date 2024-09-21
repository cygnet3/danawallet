mod client;

use std::ops::RangeInclusive;

pub use client::*;
use futures::{stream, Stream, StreamExt};
use sp_client::bitcoin::{absolute::Height, secp256k1::PublicKey, Amount, BlockHash};

const CONCURRENT_FILTER_REQUESTS: usize = 200;

pub struct BlockData {
    pub blkheight: Height,
    pub blkhash: BlockHash,
    pub tweaks: Vec<PublicKey>,
    pub new_utxo_filter: FilterResponse,
    pub spent_filter: FilterResponse,
}

/// High-level function to get block data for a range of blocks.
/// Block data includes all the information needed to determine if a block is relevant for scanning,
/// but does not include utxos, or spent index.
/// These need to be fetched separately afterwards, if it is determined this block is relevant.
pub fn get_block_data_for_range<'a>(
    client: &'a BlindbitClient,
    range: RangeInclusive<u32>,
    dust_limit: Amount,
) -> impl Stream<Item = anyhow::Result<BlockData>> + 'a {
    stream::iter(range)
        .map(move |n| async move {
            let blkheight = Height::from_consensus(n)?;
            let tweaks = client.tweak_index(blkheight, dust_limit).await?;
            let new_utxo_filter = client.filter_new_utxos(blkheight).await?;
            let spent_filter = client.filter_spent(blkheight).await?;
            let blkhash = new_utxo_filter.block_hash;
            Ok(BlockData {
                blkheight,
                blkhash,
                tweaks,
                new_utxo_filter,
                spent_filter,
            })
        })
        .buffered(CONCURRENT_FILTER_REQUESTS)
}
