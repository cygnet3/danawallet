import 'dart:convert';

import 'package:danawallet/generated/rust/api/structs.dart';

extension ApiSilentPaymentAddressJson on ApiSilentPaymentAddress {
  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
        'version': version,
        'scan_pubkey': scanPubkey,
        'm_pubkey': mPubkey,
        'network': network.toString(),
        'string_representation': stringRepresentation,
      };

  /// Convenience: JSON‑encode.
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize via the Rust bridge.
  /// Calls into Rust to build the real object.
  static ApiSilentPaymentAddress fromJson(Map<String, dynamic> json) {
    final jsonString = jsonEncode(json);
    return ApiSilentPaymentAddress.fromJsonString(json: jsonString);
  }
}
