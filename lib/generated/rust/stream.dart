// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.37.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import 'frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class ScanProgress {
  final int start;
  final int current;
  final int end;

  const ScanProgress({
    required this.start,
    required this.current,
    required this.end,
  });

  @override
  int get hashCode => start.hashCode ^ current.hashCode ^ end.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanProgress &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          current == other.current &&
          end == other.end;
}

class ScanResult {
  final String updatedWallet;

  const ScanResult({
    required this.updatedWallet,
  });

  @override
  int get hashCode => updatedWallet.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResult &&
          runtimeType == other.runtimeType &&
          updatedWallet == other.updatedWallet;
}