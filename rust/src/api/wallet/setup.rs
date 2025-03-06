use std::str::FromStr;

use sp_client::{
    bitcoin::{
        secp256k1::{PublicKey, SecretKey},
        Network,
    },
    SpendKey,
};

use crate::{
    api::structs::{ApiSetupResult, ApiSetupWalletArgs, ApiSetupWalletType},
    wallet::derive_keys_from_seed,
};

use super::{ApiScanKey, ApiSpendKey, SpWallet};
use anyhow::Result;

/// we don't add a passphrase to the bip39 mnemonic
const PASSPHRASE: &str = "";

impl SpWallet {
    #[flutter_rust_bridge::frb(sync)]
    pub fn setup_wallet(setup_args: ApiSetupWalletArgs) -> Result<ApiSetupResult> {
        let ApiSetupWalletArgs {
            setup_type,
            network,
        } = setup_args;

        let network = Network::from_core_arg(&network)?;

        match setup_type {
            ApiSetupWalletType::NewWallet => {
                // We create a new wallet and return the new mnemonic
                let m = bip39::Mnemonic::generate(12)?;
                let seed = m.to_seed(PASSPHRASE);
                let (scan_sk, spend_sk) = derive_keys_from_seed(&seed, network)?;

                let scan_key = ApiScanKey(scan_sk);
                let spend_key = ApiSpendKey(SpendKey::Secret(spend_sk));

                Ok(ApiSetupResult {
                    mnemonic: Some(m.to_string()),
                    scan_key,
                    spend_key,
                })
            }
            ApiSetupWalletType::Mnemonic(mnemonic) => {
                // We restore from seed
                let m = bip39::Mnemonic::from_str(&mnemonic)?;
                let seed = m.to_seed(PASSPHRASE);
                let (scan_sk, spend_sk) = derive_keys_from_seed(&seed, network)?;

                let scan_key = ApiScanKey(scan_sk);
                let spend_key = ApiSpendKey(SpendKey::Secret(spend_sk));

                Ok(ApiSetupResult {
                    mnemonic: Some(mnemonic),
                    scan_key,
                    spend_key,
                })
            }
            ApiSetupWalletType::Full(scan_sk_hex, spend_sk_hex) => {
                let scan_sk = SecretKey::from_str(&scan_sk_hex)?;
                let spend_sk = SecretKey::from_str(&spend_sk_hex)?;

                let scan_key = ApiScanKey(scan_sk);
                let spend_key = ApiSpendKey(SpendKey::Secret(spend_sk));

                Ok(ApiSetupResult {
                    mnemonic: None,
                    scan_key,
                    spend_key,
                })
            }
            ApiSetupWalletType::WatchOnly(scan_sk_hex, spend_pk_hex) => {
                let scan_sk = SecretKey::from_str(&scan_sk_hex)?;
                let spend_pk = PublicKey::from_str(&spend_pk_hex)?;

                let scan_key = ApiScanKey(scan_sk);
                let spend_key = ApiSpendKey(SpendKey::Public(spend_pk));

                Ok(ApiSetupResult {
                    mnemonic: None,
                    scan_key,
                    spend_key,
                })
            }
        }
    }
}
