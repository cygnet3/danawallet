use std::{
    collections::HashMap,
    str::FromStr,
};

use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use spdk_core::{
    bitcoin::OutPoint,
    OwnedOutput,
};

use anyhow::Result;

use super::structs::ApiOwnedOutput;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb(opaque)]
pub struct OwnedOutputs(HashMap<OutPoint, OwnedOutput>);

impl OwnedOutputs {
    #[flutter_rust_bridge::frb(sync)]
    pub fn empty() -> Self {
        Self(HashMap::new())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn decode(encoded_outputs: String) -> Result<Self> {
        let decoded: HashMap<String, ApiOwnedOutput> = serde_json::from_str(&encoded_outputs)?;

        let mut res: HashMap<OutPoint, OwnedOutput> = HashMap::new();

        for (outpoint, output) in decoded.into_iter() {
            res.insert(OutPoint::from_str(&outpoint)?, output.into());
        }

        Ok(Self(res))
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn encode(&self) -> Result<String> {
        let mut encoded: HashMap<String, ApiOwnedOutput> = HashMap::new();

        for (outpoint, output) in self.0.iter() {
            encoded.insert(outpoint.to_string(), output.clone().into());
        }

        Ok(serde_json::to_string(&encoded)?)
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn get_unspent_outputs(&self) -> HashMap<String, ApiOwnedOutput> {
        let mut res = HashMap::new();
        for (outpoint, output) in self.0.iter() {
            if !output.is_mined() {
                res.insert(outpoint.to_string(), output.clone().into());
            }
        }

        res
    }
}
