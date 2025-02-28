use std::{collections::HashMap, str::FromStr};

use crate::api::structs::ApiOwnedOutput;
use crate::api::structs::ApiRecipient;
use crate::api::structs::ApiSilentPaymentUnsignedTransaction;
use anyhow::Result;
use bip39::rand::{thread_rng, RngCore};
use sp_client::{
    bitcoin::{consensus::serialize, hex::DisplayHex, Network, OutPoint},
    OwnedOutput, Recipient, RecipientAddress, SpClient,
};

use super::SpWallet;

impl SpWallet {
    #[flutter_rust_bridge::frb(sync)]
    pub fn create_new_transaction(
        &self,
        api_outputs: HashMap<String, ApiOwnedOutput>,
        api_recipients: Vec<ApiRecipient>,
        feerate: f32,
        network: String,
    ) -> Result<ApiSilentPaymentUnsignedTransaction> {
        let client = &self.client;
        let available_utxos: Result<Vec<(OutPoint, OwnedOutput)>> = api_outputs
            .into_iter()
            .map(|(string, output)| {
                let outpoint = OutPoint::from_str(&string)?;
                Ok((outpoint, output.into()))
            })
            .collect();
        let recipients: Vec<Recipient> = api_recipients
            .into_iter()
            .map(|r| r.try_into().unwrap())
            .collect();
        let core_network = Network::from_core_arg(&network)?;
        let res =
            client.create_new_transaction(available_utxos?, recipients, feerate, core_network)?;

        Ok(res.into())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn create_drain_transaction(
        &self,
        api_outputs: HashMap<String, ApiOwnedOutput>,
        wipe_address: String,
        feerate: f32,
        network: String,
    ) -> Result<ApiSilentPaymentUnsignedTransaction> {
        let client = &self.client;
        let available_utxos: Result<Vec<(OutPoint, OwnedOutput)>> = api_outputs
            .into_iter()
            .map(|(string, output)| {
                let outpoint = OutPoint::from_str(&string)?;
                Ok((outpoint, output.into()))
            })
            .collect();

        let recipient_address: RecipientAddress = RecipientAddress::try_from(wipe_address)?;
        let core_network = Network::from_core_arg(&network)?;
        let res = client.create_drain_transaction(
            available_utxos?,
            recipient_address,
            feerate,
            core_network,
        )?;

        Ok(res.into())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn sign_transaction(
        &self,
        unsigned_transaction: ApiSilentPaymentUnsignedTransaction,
    ) -> Result<String> {
        let mut aux_rand = [0u8; 32];

        let mut rng = thread_rng();
        rng.fill_bytes(&mut aux_rand);

        let client = &self.client;
        let tx = client.sign_transaction(unsigned_transaction.into(), &aux_rand)?;
        Ok(serialize(&tx).to_lower_hex_string())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn finalize_transaction(
        unsigned_transaction: ApiSilentPaymentUnsignedTransaction,
    ) -> Result<ApiSilentPaymentUnsignedTransaction> {
        let res = SpClient::finalize_transaction(unsigned_transaction.into())?;
        Ok(res.into())
    }

    pub async fn broadcast_tx(tx: String, network: String) -> Result<String> {
        let tx: pushtx::Transaction = tx.parse().unwrap();

        let txid = tx.txid();

        let network = Network::from_core_arg(&network)?;

        let network = match network {
            Network::Bitcoin => pushtx::Network::Mainnet,
            Network::Testnet => pushtx::Network::Testnet,
            Network::Signet => pushtx::Network::Signet,
            Network::Regtest => pushtx::Network::Regtest,
            _ => unreachable!(),
        };

        let opts = pushtx::Opts {
            network,
            ..Default::default()
        };

        tokio::task::spawn_blocking(move || {
        let receiver = pushtx::broadcast(vec![tx], opts);

        loop {
            match receiver.recv().unwrap() {
                pushtx::Info::Done(Ok(report)) => {
                    if report.success.len() > 0 {
                        log::info!("broadcasted {} transactions", report.success.len());
                        break;
                    } else {
                         return Err(anyhow::Error::msg("Failed to broadcast transaction, probably unable to connect to Tor peers"));
                    }
                }
                pushtx::Info::Done(Err(err)) => return Err(anyhow::Error::msg(err.to_string())),
                _ => {}
            }
        }
        Ok(())
    })
    .await??;

        Ok(txid.to_string())
    }
}
