use serde::Deserialize;
use sp_client::bitcoin::{absolute::Height, secp256k1::PublicKey, Amount, BlockHash, ScriptBuf, Txid};

pub struct BlockData {
    pub blkheight: Height,
    pub blkhash: BlockHash,
    pub tweaks: Vec<PublicKey>,
    pub new_utxo_filter: FilterResponse,
    pub spent_filter: FilterResponse,
}

#[derive(Debug, Deserialize)]
pub struct BlockHeightResponse {
    pub block_height: Height,
}

#[derive(Debug, Deserialize)]
pub struct UtxoResponse {
    pub txid: Txid,
    pub vout: u32,
    pub value: Amount,
    pub scriptpubkey: ScriptBuf,
    pub block_height: Height,
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
    pub block_height: Height,
    pub data: String,
    pub filter_type: i32,
}

