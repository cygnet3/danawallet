use std::sync::Mutex;

use crate::frb_generated::StreamSink;
use lazy_static::lazy_static;

lazy_static! {
    static ref AMOUNT_STREAM_SINK: Mutex<Option<StreamSink<u64>>> = Mutex::new(None);
    static ref SCAN_STREAM_SINK: Mutex<Option<StreamSink<ScanProgress>>> = Mutex::new(None);
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

pub fn create_scan_progress_stream(s: StreamSink<ScanProgress>) {
    let mut stream_sink = SCAN_STREAM_SINK.lock().unwrap();
    *stream_sink = Some(s);
}

pub(crate) fn send_amount_update(amount: u64) {
    let stream_sink = AMOUNT_STREAM_SINK.lock().unwrap();
    if let Some(stream_sink) = stream_sink.as_ref() {
        stream_sink.add(amount).unwrap();
    }
}

pub(crate) fn send_scan_progress(scan_progress: ScanProgress) {
    let stream_sink = SCAN_STREAM_SINK.lock().unwrap();
    if let Some(stream_sink) = stream_sink.as_ref() {
        stream_sink.add(scan_progress).unwrap();
    }
}
