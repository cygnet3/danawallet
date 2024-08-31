use reqwest::Url;

use crate::blindbit;

pub async fn get_chain_height(blindbit_url: String) -> anyhow::Result<u32> {
    let url = Url::parse(&blindbit_url)?;

    blindbit::logic::get_chain_height(url).await
}
