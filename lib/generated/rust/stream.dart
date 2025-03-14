// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.9.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import 'frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

// Rust type: RustOpaqueMoi<flutter_rust_bridge::for_generated::RustAutoOpaqueInner<StateUpdate>>
abstract class StateUpdate implements RustOpaqueInterface {
  int getHeight();
}

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
