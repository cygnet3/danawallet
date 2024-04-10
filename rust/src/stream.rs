use std::sync::Mutex;

use flutter_rust_bridge::StreamSink;
use lazy_static::lazy_static;

lazy_static! {
    static ref AMOUNT_STREAM_SINK: Mutex<Option<StreamSink<u64>>> = Mutex::new(None);
    static ref SCAN_STREAM_SINK: Mutex<Option<StreamSink<ScanProgress>>> = Mutex::new(None);
    static ref SYNC_STREAM_SINK: Mutex<Option<StreamSink<SyncStatus>>> = Mutex::new(None);
    static ref NAKAMOTO_RUN_STREAM_SINK: Mutex<Option<StreamSink<bool>>> = Mutex::new(None);
}

pub struct SyncStatus {
    pub peer_count: u32,
    pub blockheight: u64,
    pub bestblockhash: String,
}

pub struct ScanProgress {
    pub start: u32,
    pub current: u32,
    pub end: u32,
}

pub fn create_amount_stream(s: StreamSink<u64>) {
    let mut stream_sink = AMOUNT_STREAM_SINK.lock().unwrap();
    *stream_sink = Some(s);
}

pub fn create_sync_stream(s: StreamSink<SyncStatus>) {
    let mut stream_sink = SYNC_STREAM_SINK.lock().unwrap();
    *stream_sink = Some(s);
}

pub fn create_scan_progress_stream(s: StreamSink<ScanProgress>) {
    let mut stream_sink = SCAN_STREAM_SINK.lock().unwrap();
    *stream_sink = Some(s);
}

pub fn create_nakamoto_run_stream(s: StreamSink<bool>) {
    let mut stream_sink = NAKAMOTO_RUN_STREAM_SINK.lock().unwrap();
    *stream_sink = Some(s);
}

pub(crate) fn send_amount_update(amount: u64) {
    let stream_sink = AMOUNT_STREAM_SINK.lock().unwrap();
    if let Some(stream_sink) = stream_sink.as_ref() {
        stream_sink.add(amount);
    }
}

pub(crate) fn send_sync_progress(sync_status: SyncStatus) {
    let stream_sink = SYNC_STREAM_SINK.lock().unwrap();
    if let Some(stream_sink) = stream_sink.as_ref() {
        stream_sink.add(sync_status);
    }
}

pub(crate) fn send_scan_progress(scan_progress: ScanProgress) {
    let stream_sink = SCAN_STREAM_SINK.lock().unwrap();
    if let Some(stream_sink) = stream_sink.as_ref() {
        stream_sink.add(scan_progress);
    }
}

pub(crate) fn send_nakamoto_run(nakamoto_run: bool) {
    let stream_sink = NAKAMOTO_RUN_STREAM_SINK.lock().unwrap();
    if let Some(stream_sink) = stream_sink.as_ref() {
        stream_sink.add(nakamoto_run);
    }
}
