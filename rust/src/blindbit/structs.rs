use serde::Deserialize;
use sp_client::{
    bitcoin::{absolute::Height, Amount, BlockHash, ScriptBuf, Txid},
    FilterData, SpentIndexData, UtxoData,
};

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

impl From<UtxoResponse> for UtxoData {
    fn from(value: UtxoResponse) -> Self {
        Self {
            txid: value.txid,
            vout: value.vout,
            value: value.value,
            scriptpubkey: value.scriptpubkey,
            spent: value.spent,
        }
    }
}

#[derive(Debug, Deserialize)]
pub struct SpentIndexResponse {
    pub block_hash: BlockHash,
    pub data: Vec<MyHex>,
}

impl From<SpentIndexResponse> for SpentIndexData {
    fn from(value: SpentIndexResponse) -> Self {
        Self {
            data: value.data.into_iter().map(|x| x.hex).collect(),
        }
    }
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
    pub data: MyHex,
    pub filter_type: i32,
}

impl From<FilterResponse> for FilterData {
    fn from(value: FilterResponse) -> Self {
        Self {
            block_hash: value.block_hash,
            data: value.data.hex,
        }
    }
}
