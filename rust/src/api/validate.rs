use flutter_rust_bridge::frb;
use spdk::RecipientAddress;

#[frb(sync)]
pub fn validate_address(address: String) -> bool {
    let address = RecipientAddress::try_from(address);

    match address {
        Ok(RecipientAddress::LegacyAddress(_)) => true,
        Ok(RecipientAddress::SpAddress(_)) => true,
        _ => false,
    }
}
