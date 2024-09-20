use reqwest::Url;

use crate::blindbit;

pub async fn get_chain_height(blindbit_url: String) -> anyhow::Result<u32> {
    let url = Url::parse(&blindbit_url)?;
    let blindbit_client = blindbit::BlindbitClient::new(url);

    blindbit_client
        .block_height()
        .await
        .map(|height| height.to_consensus_u32())
}
