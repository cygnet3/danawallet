#![allow(dead_code)]
use bitcoin::{secp256k1::PublicKey, BlockHash, ScriptBuf, Txid};
use reqwest::Client;
use serde::Deserialize;

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
    host: String,
}

impl BlindbitClient {
    pub fn new(host: String) -> Self {
        let client = reqwest::Client::new();
        BlindbitClient { client, host }
    }
    pub async fn block_height(&self) -> Result<u32> {
        let res = self
            .client
            .get(format!("{}/block-height", self.host))
            .send()
            .await?;
        let blkheight: BlockHeightResponse = serde_json::from_str(&res.text().await?)?;

        Ok(blkheight.block_height)
    }

    pub async fn tweaks(&self, block_height: u32) -> Result<Vec<PublicKey>> {
        let res = self
            .client
            .get(format!("{}/tweaks/{}", self.host, block_height))
            .send()
            .await?;
        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn tweak_index(&self, block_height: u32) -> Result<Vec<PublicKey>> {
        let res = self
            .client
            .get(format!("{}/tweak-index/{}", self.host, block_height))
            .send()
            .await?;
        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn utxos(&self, block_height: u32) -> Result<Vec<UtxoResponse>> {
        let res = self
            .client
            .get(format!("{}/utxos/{}", self.host, block_height))
            .send()
            .await?;

        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn spent_index(&self, block_height: u32) -> Result<SpentIndexResponse> {
        let res = self
            .client
            .get(format!("{}/spent-index/{}", self.host, block_height))
            .send()
            .await?;

        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn filter_new_utxos(&self, block_height: u32) -> Result<FilterResponse> {
        let res = self
            .client
            .get(format!("{}/filter/new-utxos/{}", self.host, block_height))
            .send()
            .await?;

        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn filter_spent(&self, block_height: u32) -> Result<FilterResponse> {
        let res = self
            .client
            .get(format!("{}/filter/spent/{}", self.host, block_height))
            .send()
            .await?;

        Ok(serde_json::from_str(&res.text().await?)?)
    }

    pub async fn forward_tx(&self) {
        // todo
    }
}
