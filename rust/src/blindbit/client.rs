#![allow(dead_code)]
use std::time::Duration;

use reqwest::{Client, Url};
use sp_client::bitcoin::{absolute::Height, secp256k1::PublicKey, Amount};

use anyhow::Result;

use super::{BlockHeightResponse, FilterResponse, SpentIndexResponse, UtxoResponse};

#[derive(Clone)]
pub struct BlindbitClient {
    client: Client,
    host_url: Url,
}

impl BlindbitClient {
    pub fn new(mut host_url: Url) -> Self {
        let client = reqwest::Client::new();

        // we need a trailing slash, if not present we append it
        if !host_url.path().ends_with('/') {
            host_url.set_path(&format!("{}/", host_url.path()));
        }

        BlindbitClient { client, host_url }
    }
    pub async fn block_height(&self) -> Result<Height> {
        let url = self.host_url.join("block-height")?;

        let res = self
            .client
            .get(url)
            .timeout(Duration::from_secs(5))
            .send()
            .await?;
        let blkheight: BlockHeightResponse = serde_json::from_str(&res.text().await?)?;
        Ok(blkheight.block_height)
    }

    pub async fn tweaks(&self, block_height: Height) -> Result<Vec<PublicKey>> {
        let url = self.host_url.join(&format!("tweaks/{}", block_height))?;

        let res = self.client.get(url).send().await?;
        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn tweak_index(
        &self,
        block_height: Height,
        dust_limit: Amount,
    ) -> Result<Vec<PublicKey>> {
        let url = self
            .host_url
            .join(&format!("tweak-index/{}", block_height))?;

        let res = self
            .client
            .get(url)
            .query(&[("dustLimit", format!("{}", dust_limit.to_sat()))])
            .send()
            .await?;
        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn utxos(&self, block_height: Height) -> Result<Vec<UtxoResponse>> {
        let url = self.host_url.join(&format!("utxos/{}", block_height))?;
        let res = self.client.get(url).send().await?;

        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn spent_index(&self, block_height: Height) -> Result<SpentIndexResponse> {
        let url = self
            .host_url
            .join(&format!("spent-index/{}", block_height))?;
        let res = self.client.get(url).send().await?;

        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn filter_new_utxos(&self, block_height: Height) -> Result<FilterResponse> {
        let url = self
            .host_url
            .join(&format!("filter/new-utxos/{}", block_height))?;

        let res = self.client.get(url).send().await?;

        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn filter_spent(&self, block_height: Height) -> Result<FilterResponse> {
        let url = self
            .host_url
            .join(&format!("filter/spent/{}", block_height))?;

        let res = self.client.get(url).send().await?;

        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn forward_tx(&self) {
        // not needed
    }
}
