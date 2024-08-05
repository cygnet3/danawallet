use bitcoin::Network;

use crate::blindbit;

pub async fn get_chain_height(network: String) -> anyhow::Result<u32> {
    let network = Network::from_core_arg(&network)?;

    blindbit::logic::get_chain_height(network).await
}
