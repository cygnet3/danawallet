use electrum_client::{Client, ConfigBuilder, ElectrumApi};
use log::info;

const ELECTRS_URI: &str = "ssl://silentpayments.dev:51002";
const VALIDATE_DOMAIN: bool = false; // self-signed cert, so we don't validate

pub fn create_electrum_client() -> anyhow::Result<Client> {
    let config = ConfigBuilder::new()
        .validate_domain(VALIDATE_DOMAIN)
        .build();
    let electrum_client = Client::from_config(ELECTRS_URI, config)?;
    info!("ssl client {}", ELECTRS_URI);

    Ok(electrum_client)
}

pub fn backup_broadcast_transaction_using_electrum(tx: &str) -> anyhow::Result<String> {
    let client = create_electrum_client()?;

    let raw_tx = hex::decode(tx)?;

    let txid = client.transaction_broadcast_raw(&raw_tx)?;
    info!("broadcasted using electrs: {}", txid);

    Ok(txid.to_string())
}
