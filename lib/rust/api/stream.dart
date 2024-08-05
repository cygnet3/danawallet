// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.37.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import '../logger.dart';
import '../stream.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

Stream<LogEntry> createLogStream(
        {required LogLevel level, required bool logDependencies}) =>
    RustLib.instance.api.crateApiStreamCreateLogStream(
        level: level, logDependencies: logDependencies);

Stream<ScanProgress> createScanProgressStream() =>
    RustLib.instance.api.crateApiStreamCreateScanProgressStream();

Stream<ScanResult> createScanResultStream() =>
    RustLib.instance.api.crateApiStreamCreateScanResultStream();

Stream<BigInt> createAmountStream() =>
    RustLib.instance.api.crateApiStreamCreateAmountStream();
