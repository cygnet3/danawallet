use std::time::Duration;

use log::warn;
use tokio::time::sleep;
use spdk_core::{bitcoin::Network};
use backend_blindbit_native::{AsyncBlindbitBackend, BlindbitClient};
use crate::http_client::ReqwestClient;

pub async fn get_chain_height(blindbit_url: String) -> anyhow::Result<u32> {
    let http_client = ReqwestClient::new()?;
    let backend = AsyncBlindbitBackend::new(blindbit_url, http_client)?;

    match backend.block_height().await {
        Ok(res) => Ok(res.to_consensus_u32()),
        Err(e) => {
            if e.root_cause()
                .to_string()
                .starts_with("operation timed out")
            {
                warn!("Got timeout fetching block height, retrying");

                // sleep for 1 second
                sleep(Duration::from_millis(1000)).await;

                Ok(backend.block_height().await?.to_consensus_u32())
            } else {
                Err(e)
            }
        }
    }
}

pub async fn check_network(blindbit_url: String, network: String) -> anyhow::Result<bool> {
    let network = Network::from_core_arg(&network)?;
    let http_client = ReqwestClient::new()?;
    let client = BlindbitClient::new(blindbit_url, http_client)?;

    let blindbit_network = client.info().await?.network;

    Ok(network == blindbit_network)
}
