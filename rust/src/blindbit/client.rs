#![allow(dead_code)]
use std::time::Duration;

use reqwest::{Client, Url};
use serde::Deserialize;
use sp_client::bitcoin::{secp256k1::PublicKey, BlockHash, ScriptBuf, Txid};

use anyhow::Result;

#[derive(Debug, Deserialize)]
pub struct BlockHeightResponse {
    block_height: u32,
}

#[derive(Debug, Deserialize)]
pub struct UtxoResponse {
    pub txid: Txid,
    pub vout: u32,
    pub value: u64,
    pub scriptpubkey: ScriptBuf,
    pub block_height: i32,
    pub block_hash: BlockHash,
    pub timestamp: i32,
    pub spent: bool,
}

#[derive(Debug, Deserialize)]
pub struct SpentIndexResponse {
    pub block_hash: BlockHash,
    pub data: Vec<MyHex>,
}

#[derive(Deserialize, Debug)]
#[serde(transparent)]
pub struct MyHex {
    #[serde(with = "hex::serde")]
    pub hex: Vec<u8>,
}

#[derive(Debug, Deserialize)]
pub struct FilterResponse {
    pub block_hash: BlockHash,
    pub block_height: i32,
    pub data: String,
    pub filter_type: i32,
}

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
    pub async fn block_height(&self) -> Result<u32> {
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

    pub async fn tweaks(&self, block_height: u32) -> Result<Vec<PublicKey>> {
        let url = self.host_url.join(&format!("tweaks/{}", block_height))?;

        let res = self.client.get(url).send().await?;
        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn tweak_index(&self, block_height: u32, dust_limit: u32) -> Result<Vec<PublicKey>> {
        let url = self
            .host_url
            .join(&format!("tweak-index/{}", block_height))?;

        let res = self
            .client
            .get(url)
            .query(&[("dustLimit", format!("{}", dust_limit))])
            .send()
            .await?;
        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn utxos(&self, block_height: u32) -> Result<Vec<UtxoResponse>> {
        let url = self.host_url.join(&format!("utxos/{}", block_height))?;
        let res = self.client.get(url).send().await?;

        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn spent_index(&self, block_height: u32) -> Result<SpentIndexResponse> {
        let url = self
            .host_url
            .join(&format!("spent-index/{}", block_height))?;
        let res = self.client.get(url).send().await?;

        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn filter_new_utxos(&self, block_height: u32) -> Result<FilterResponse> {
        let url = self
            .host_url
            .join(&format!("filter/new-utxos/{}", block_height))?;

        let res = self.client.get(url).send().await?;

        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn filter_spent(&self, block_height: u32) -> Result<FilterResponse> {
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
