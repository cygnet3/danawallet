use crate::{
    frb_generated::StreamSink,
    logger::{self, LogEntry, LogLevel},
    stream::{self, ScanProgress, StateUpdate},
};

#[flutter_rust_bridge::frb(sync)]
pub fn create_log_stream(s: StreamSink<LogEntry>, level: LogLevel, log_dependencies: bool) {
    logger::init_logger(level.into(), log_dependencies);
    logger::FlutterLogger::set_stream_sink(s);
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_scan_progress_stream(s: StreamSink<ScanProgress>) {
    stream::create_scan_progress_stream(s);
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_scan_result_stream(s: StreamSink<StateUpdate>) {
    stream::create_scan_update_stream(s);
}

impl StateUpdate {
    #[flutter_rust_bridge::frb(sync)]
    pub fn get_height(&self) -> u32 {
        match self {
            StateUpdate::Update { blkheight, .. } => blkheight.to_consensus_u32(),
            StateUpdate::NoUpdate { blkheight } => blkheight.to_consensus_u32(),
        }
    }
}
