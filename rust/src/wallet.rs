use std::str::FromStr;
use std::sync::{atomic::AtomicBool, Arc};

use anyhow::Result;
use lazy_static::lazy_static;
use sp_client::bitcoin::bip32::{DerivationPath, Xpriv};
use sp_client::bitcoin::key::Secp256k1;
use sp_client::bitcoin::secp256k1::SecretKey;
use sp_client::bitcoin::{self, Network};

lazy_static! {
    pub static ref KEEP_SCANNING: Arc<AtomicBool> = Arc::new(AtomicBool::new(true));
}

pub type WalletFingerprint = [u8; 8];

pub fn derive_keys_from_seed(seed: &[u8; 64], network: Network) -> Result<(SecretKey, SecretKey)> {
    let xprv = Xpriv::new_master(network, seed)?;

    let (scan_privkey, spend_privkey) = derive_keys_from_xprv(xprv)?;

    Ok((scan_privkey, spend_privkey))
}

fn derive_keys_from_xprv(xprv: Xpriv) -> Result<(SecretKey, SecretKey)> {
    let (scan_path, spend_path) = match xprv.network {
        bitcoin::Network::Bitcoin => ("m/352h/0h/0h/1h/0", "m/352h/0h/0h/0h/0"),
        _ => ("m/352h/1h/0h/1h/0", "m/352h/1h/0h/0h/0"),
    };

    let secp = Secp256k1::signing_only();
    let scan_path = DerivationPath::from_str(scan_path)?;
    let spend_path = DerivationPath::from_str(spend_path)?;
    let scan_privkey = xprv.derive_priv(&secp, &scan_path)?.private_key;
    let spend_privkey = xprv.derive_priv(&secp, &spend_path)?.private_key;

    Ok((scan_privkey, spend_privkey))
}
