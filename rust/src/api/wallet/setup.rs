use std::str::FromStr;

use sp_client::{
    bitcoin::{
        secp256k1::{PublicKey, SecretKey},
        Network,
    },
    SpClient, SpendKey,
};

use crate::{
    api::structs::{ApiSetupResult, ApiSetupWalletArgs, ApiSetupWalletType},
    frb_generated::RustAutoOpaque,
    wallet::derive_keys_from_seed,
};

use super::SpWallet;
use anyhow::Result;

/// we don't add a passphrase to the bip39 mnemonic
const PASSPHRASE: &str = "";

impl SpWallet {
    #[flutter_rust_bridge::frb(sync)]
    pub fn setup_wallet(setup_args: ApiSetupWalletArgs) -> Result<ApiSetupResult> {
        let ApiSetupWalletArgs {
            setup_type,
            birthday,
            network,
        } = setup_args;

        let network = Network::from_core_arg(&network)?;

        match setup_type {
            ApiSetupWalletType::NewWallet => {
                // We create a new wallet and return the new mnemonic
                let m = bip39::Mnemonic::generate(12)?;
                let seed = m.to_seed(PASSPHRASE);
                let (scan_sk, spend_sk) = derive_keys_from_seed(&seed, network)?;
                let sp_client = SpClient::new(scan_sk, SpendKey::Secret(spend_sk), network)?;

                let wallet = SpWallet::new(sp_client, birthday)?;
                Ok(ApiSetupResult {
                    mnemonic: Some(m.to_string()),
                    wallet: RustAutoOpaque::new(wallet),
                })
            }
            ApiSetupWalletType::Mnemonic(mnemonic) => {
                // We restore from seed
                let m = bip39::Mnemonic::from_str(&mnemonic)?;
                let seed = m.to_seed(PASSPHRASE);
                let (scan_sk, spend_sk) = derive_keys_from_seed(&seed, network)?;
                let sp_client = SpClient::new(scan_sk, SpendKey::Secret(spend_sk), network)?;

                let wallet = SpWallet::new(sp_client, birthday)?;

                Ok(ApiSetupResult {
                    mnemonic: Some(mnemonic),
                    wallet: RustAutoOpaque::new(wallet),
                })
            }
            ApiSetupWalletType::Full(scan_sk_hex, spend_sk_hex) => {
                let scan_sk = SecretKey::from_str(&scan_sk_hex)?;
                let spend_sk = SecretKey::from_str(&spend_sk_hex)?;

                let sp_client = SpClient::new(scan_sk, SpendKey::Secret(spend_sk), network)?;

                let wallet = SpWallet::new(sp_client, birthday).unwrap();

                Ok(ApiSetupResult {
                    mnemonic: None,
                    wallet: RustAutoOpaque::new(wallet),
                })
            }
            ApiSetupWalletType::WatchOnly(scan_sk_hex, spend_pk_hex) => {
                let scan_sk = SecretKey::from_str(&scan_sk_hex)?;
                let spend_pk = PublicKey::from_str(&spend_pk_hex)?;

                let sp_client = SpClient::new(scan_sk, SpendKey::Public(spend_pk), network)?;

                let wallet = SpWallet::new(sp_client, birthday).unwrap();

                Ok(ApiSetupResult {
                    mnemonic: None,
                    wallet: RustAutoOpaque::new(wallet),
                })
            }
        }
    }
}
