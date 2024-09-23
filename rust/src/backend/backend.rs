use std::{ops::RangeInclusive, pin::Pin, sync::Arc};

use async_trait::async_trait;
use futures::{stream, Stream, StreamExt};
use reqwest::Url;
use sp_client::{
    bitcoin::{absolute::Height, Amount},
    BlockData, ChainBackend, SpentIndexData, UtxoData,
};

use anyhow::Result;

use crate::blindbit::BlindbitClient;

const CONCURRENT_FILTER_REQUESTS: usize = 200;

pub struct BlindbitBackend {
    client: BlindbitClient,
}

impl BlindbitBackend {
    pub fn new(host_url: Url) -> Self {
        Self {
            client: BlindbitClient::new(host_url),
        }
    }
}

#[async_trait]
impl ChainBackend for BlindbitBackend {
    /// High-level function to get block data for a range of blocks.
    /// Block data includes all the information needed to determine if a block is relevant for scanning,
    /// but does not include utxos, or spent index.
    /// These need to be fetched separately afterwards, if it is determined this block is relevant.
    fn get_block_data_for_range(
        &self,
        range: RangeInclusive<u32>,
        dust_limit: Amount,
    ) -> Pin<Box<dyn Stream<Item = Result<BlockData>> + Send>> {
        let client = Arc::new(self.client.clone());

        let res = stream::iter(range)
            .map(move |n| {
                let client = client.clone();

                async move {
                    let blkheight = Height::from_consensus(n)?;
                    let tweaks = client.tweak_index(blkheight, dust_limit).await?;
                    let new_utxo_filter = client.filter_new_utxos(blkheight).await?;
                    let spent_filter = client.filter_spent(blkheight).await?;
                    let blkhash = new_utxo_filter.block_hash;
                    Ok(BlockData {
                        blkheight,
                        blkhash,
                        tweaks,
                        new_utxo_filter: new_utxo_filter.into(),
                        spent_filter: spent_filter.into(),
                    })
                }
            })
            .buffered(CONCURRENT_FILTER_REQUESTS);

        Box::pin(res)
    }

    async fn spent_index(&self, block_height: Height) -> Result<SpentIndexData> {
        self.client.spent_index(block_height).await.map(Into::into)
    }

    async fn utxos(&self, block_height: Height) -> Result<Vec<UtxoData>> {
        Ok(self
            .client
            .utxos(block_height)
            .await?
            .into_iter()
            .map(Into::into)
            .collect())
    }

    async fn block_height(&self) -> Result<Height> {
        self.client.block_height().await
    }
}
