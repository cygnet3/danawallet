use backend_blindbit_native::{BlindbitBackend, BlindbitClient, ChainBackend};
use sp_client::{bitcoin::Network};

pub async fn get_chain_height(blindbit_url: String) -> anyhow::Result<u32> {
    let backend = BlindbitBackend::new(blindbit_url)?;

    Ok(backend.block_height().await?.to_consensus_u32())
}

pub async fn check_network(blindbit_url: String, network: String) -> anyhow::Result<bool> {
    let network = Network::from_core_arg(&network)?;
    let client = BlindbitClient::new(blindbit_url)?;

    let blindbit_network = client.info().await?.network;

    Ok(network == blindbit_network)
}
