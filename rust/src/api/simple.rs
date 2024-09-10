#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // This function can be used to set up the frb provided logger and stacktrace.
    // Since we use our own logger, we disable the default one.

    // flutter_rust_bridge::setup_default_user_utils();
}
