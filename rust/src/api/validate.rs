use flutter_rust_bridge::frb;
use sp_client::RecipientAddress;

#[frb(sync)]
pub fn validate_address(address: String) -> bool {
    RecipientAddress::try_from(address).is_ok()
}
