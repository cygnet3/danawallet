use std::{ops::RangeInclusive, pin::Pin};

use anyhow::Result;
use async_trait::async_trait;
use futures::Stream;
use sp_client::bitcoin::{absolute::Height, Amount};

use crate::blindbit::{BlockData, SpentIndexResponse, UtxoResponse};

#[async_trait]
pub trait ChainBackend {
    fn get_block_data_for_range(
        &self,
        range: RangeInclusive<u32>,
        dust_limit: Amount,
    ) -> Pin<Box<dyn Stream<Item = Result<BlockData>> + Send>>;

    async fn spent_index(&self, block_height: Height) -> Result<SpentIndexResponse>;

    async fn utxos(&self, block_height: Height) -> Result<Vec<UtxoResponse>>;

    async fn block_height(&self) -> Result<Height>;
}
