use crate::{
    frb_generated::StreamSink,
    logger::{self, LogEntry, LogLevel},
    stream::{self, ScanProgress, SyncStatus},
};

#[flutter_rust_bridge::frb(sync)]
pub fn create_log_stream(s: StreamSink<LogEntry>, level: LogLevel, log_dependencies: bool) {
    logger::init_logger(level.into(), log_dependencies);
    logger::FlutterLogger::set_stream_sink(s);
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_sync_stream(s: StreamSink<SyncStatus>) {
    stream::create_sync_stream(s);
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_scan_progress_stream(s: StreamSink<ScanProgress>) {
    stream::create_scan_progress_stream(s);
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_amount_stream(s: StreamSink<u64>) {
    stream::create_amount_stream(s);
}
