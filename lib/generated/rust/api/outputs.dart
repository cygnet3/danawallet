// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.9.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import '../lib.dart';
import '../stream.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'structs.dart';

// These functions are ignored because they are not marked as `pub`: `mark_mined`, `mark_spent`, `revert_spent_status`, `to_inner`
// These function are ignored because they are on traits that is not defined in current crate (put an empty `#[frb]` on it to unignore): `clone`, `fmt`

// Rust type: RustOpaqueMoi<flutter_rust_bridge::for_generated::RustAutoOpaqueInner<OwnedOutPoints>>
abstract class OwnedOutPoints implements RustOpaqueInterface {}

// Rust type: RustOpaqueMoi<flutter_rust_bridge::for_generated::RustAutoOpaqueInner<OwnedOutputs>>
abstract class OwnedOutputs implements RustOpaqueInterface {
  static OwnedOutputs decode({required String encodedOutputs}) =>
      RustLib.instance.api
          .crateApiOutputsOwnedOutputsDecode(encodedOutputs: encodedOutputs);

  static OwnedOutputs empty() =>
      RustLib.instance.api.crateApiOutputsOwnedOutputsEmpty();

  String encode();

  OwnedOutPoints getUnconfirmedSpentOutpoints();

  BigInt getUnspentAmount();

  Map<String, ApiOwnedOutput> getUnspentOutputs();

  void markOutpointsSpent(
      {required String spentBy, required List<String> spent});

  void processStateUpdate({required StateUpdate update});

  void resetToHeight({required int height});
}
