use spdk_core::{bitcoin::Network};
use backend_blindbit_native::{AsyncBlindbitBackend, BlindbitClient};
use crate::http_client::ReqwestClient;

pub async fn get_chain_height(blindbit_url: String) -> anyhow::Result<u32> {
    let http_client = ReqwestClient::new()?;
    let backend = AsyncBlindbitBackend::new(blindbit_url, http_client)?;

    Ok(backend.block_height().await?.to_consensus_u32())
}

pub async fn check_network(blindbit_url: String, network: String) -> anyhow::Result<bool> {
    let network = Network::from_core_arg(&network)?;
    let http_client = ReqwestClient::new()?;
    let client = BlindbitClient::new(blindbit_url, http_client)?;

    let blindbit_network = client.info().await?.network;

    Ok(network == blindbit_network)
}
