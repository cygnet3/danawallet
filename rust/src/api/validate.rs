use anyhow::Result;
use flutter_rust_bridge::frb;
use spdk::silentpayments::Network as SpNetwork;
use spdk::{bitcoin::Network, RecipientAddress};

#[frb(sync)]
pub fn validate_address_with_network(address: String, network: String) -> Result<()> {
    log::debug!(
        "address_with_network: address: {}, network: {}",
        address,
        network
    );
    let target_network = Network::from_core_arg(&network)?;
    let address = RecipientAddress::try_from(address);

    match address {
        Ok(RecipientAddress::LegacyAddress(legacy_address)) => {
            legacy_address.require_network(target_network)?;
            Ok(())
        }
        Ok(RecipientAddress::SpAddress(sp_address)) => {
            match (sp_address.get_network(), target_network) {
                (SpNetwork::Mainnet, Network::Bitcoin)
                | (SpNetwork::Testnet, Network::Testnet)
                | (SpNetwork::Testnet, Network::Signet)
                | (SpNetwork::Regtest, Network::Regtest) => Ok(()),
                (sp_network, _) => Err(anyhow::anyhow!(
                    "Wrong network, expected: {}, got: {:?}",
                    target_network,
                    sp_network,
                )),
            }
        }
        Ok(RecipientAddress::Data(_)) => {
            Err(anyhow::Error::msg("Sending to OP_RETURN not allowed"))
        }
        Err(e) => Err(e),
    }
}
