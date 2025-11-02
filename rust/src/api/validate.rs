use anyhow::Result;
use flutter_rust_bridge::frb;
use sp_client::{bitcoin::Network, silentpayments::Network as SpNetwork, RecipientAddress};

#[frb(sync)]
pub fn validate_address_with_network(address: String, network: String) -> Result<()> {
    let target_network = sp_client::bitcoin::Network::from_core_arg(&network)?;
    let address = RecipientAddress::try_from(address);

    match address {
        Ok(RecipientAddress::LegacyAddress(legacy_address)) => {
            legacy_address.require_network(target_network)?;
            Ok(())
        }
        Ok(RecipientAddress::SpAddress(sp_address)) => {
            let sp_network = match sp_address.get_network() {
                SpNetwork::Mainnet => {
                    if target_network == Network::Bitcoin {
                        return Ok(());
                    }
                    "Mainnet"
                }
                SpNetwork::Testnet => match target_network {
                    Network::Testnet | Network::Signet => {
                        return Ok(());
                    }
                    _ => "Testnet",
                },
                SpNetwork::Regtest => {
                    if target_network == Network::Regtest {
                        return Ok(());
                    }
                    "Regtest"
                }
            };
            return Err(anyhow::Error::msg(format!(
                "Wrong network, expected: {}, got: {}",
                target_network, sp_network
            )));
        }
        Ok(RecipientAddress::Data(_)) => {
            return Err(anyhow::Error::msg("Sending to OP_RETURN not allowed"));
        }
        Err(e) => return Err(e),
    }
}
