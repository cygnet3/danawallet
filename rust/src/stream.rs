use std::{
    collections::{HashMap, HashSet},
    sync::Mutex,
};

use crate::{frb_generated::StreamSink, api::structs::ApiOwnedOutput};
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
use spdk_core::{
    bitcoin::{absolute::Height, BlockHash, OutPoint},
    OwnedOutput,
};

lazy_static! {
    static ref SCAN_PROGRESS_STREAM_SINK: Mutex<Option<StreamSink<ScanProgress>>> =
        Mutex::new(None);
    static ref STATE_UPDATE_STREAM_SINK: Mutex<Option<StreamSink<StateUpdate>>> = Mutex::new(None);
}

// StateUpdate - FFI-compatible, exposed to Dart
#[derive(Debug, Clone)]
#[frb]
pub enum StateUpdate {
    NoUpdate {
        blkheight: u32    },
    Update {
        blkheight: u32,
        blkhash: String,
        found_outputs: Vec<FoundOutput>,
        found_inputs: Vec<String>, // outpoint strings "txid:vout"
    },
}

#[derive(Debug, Clone)]
#[frb]
pub struct FoundOutput {
    pub outpoint: String, // "txid:vout"
    pub output: ApiOwnedOutput,
}

// Internal conversion from spdk types
impl StateUpdate {
    pub(crate) fn from_internal(
        blkheight: Height,
        blkhash: Option<BlockHash>,
        found_outputs: HashMap<OutPoint, OwnedOutput>,
        found_inputs: HashSet<OutPoint>,
    ) -> Self {
        if blkhash.is_none() {
            return StateUpdate::NoUpdate {
                blkheight: blkheight.to_consensus_u32(),
            };
        }

        StateUpdate::Update {
            blkheight: blkheight.to_consensus_u32(),
            blkhash: blkhash.unwrap().to_string(),
            found_outputs: found_outputs
                .into_iter()
                .map(|(outpoint, output)| FoundOutput {
                    outpoint: outpoint.to_string(),
                    output: output.into(),
                })
                .collect(),
            found_inputs: found_inputs
                .into_iter()
                .map(|outpoint| outpoint.to_string())
                .collect(),
        }
    }
}

#[derive(Debug, Clone)]
#[frb]
pub struct ScanProgress {
    pub start: u32,
    pub current: u32,
    pub end: u32,
}

pub fn create_scan_progress_stream(s: StreamSink<ScanProgress>) {
    let mut stream_sink = SCAN_PROGRESS_STREAM_SINK.lock().unwrap();
    *stream_sink = Some(s);
}

pub fn create_scan_update_stream(s: StreamSink<StateUpdate>) {
    let mut stream_sink = STATE_UPDATE_STREAM_SINK.lock().unwrap();
    *stream_sink = Some(s);
}

pub(crate) fn send_scan_progress(scan_progress: ScanProgress) {
    let stream_sink = SCAN_PROGRESS_STREAM_SINK.lock().unwrap();
    if let Some(stream_sink) = stream_sink.as_ref() {
        stream_sink.add(scan_progress).unwrap();
    }
}

pub(crate) fn send_state_update(update: StateUpdate) {
    let stream_sink = STATE_UPDATE_STREAM_SINK.lock().unwrap();
    if let Some(stream_sink) = stream_sink.as_ref() {
        stream_sink.add(update).unwrap();
    }
}
