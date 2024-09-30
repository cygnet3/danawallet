use sp_client::{BlindbitBackend, ChainBackend};

pub async fn get_chain_height(blindbit_url: String) -> anyhow::Result<u32> {
    let backend = BlindbitBackend::new(blindbit_url)?;

    Ok(backend.block_height().await?.to_consensus_u32())
}
