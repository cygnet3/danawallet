import 'dart:convert';
import 'package:danawallet/generated/rust/api/structs.dart';

/// A small Dart wrapper around the Rust `ApiSilentPaymentAddress`
/// which gives you:
///   1) Dart-friendly `==` and `hashCode` (so you can use it as a Map key or in Sets),
///   2) JSON (de)serialization,
///   3) easy access to the raw bridge object when you need it.
class PaymentAddress {
  final ApiSilentPaymentAddress inner;

  PaymentAddress(this.inner);

  /// Two addresses are equal if their stringRepresentation matches.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
      other is PaymentAddress &&
      other.inner.stringRepresentation == inner.stringRepresentation;
  }

  @override
  int get hashCode => inner.stringRepresentation.hashCode;

  /// Expose the bridge object if the DAO or other code needs it.
  ApiSilentPaymentAddress get raw => inner;

  /// Convert to a simple JSON map.
  Map<String, dynamic> toJson() => {
    'version': inner.version,
    'scan_pubkey': inner.scanPubkey,
    'm_pubkey': inner.mPubkey,
    'network': inner.network.toString(),
    'string_representation': inner.stringRepresentation,
  };

  /// JSON-encode as a string.
  String toJsonString() => jsonEncode(toJson());

  /// Build one of these from a JSON map by going back through the bridge.
  factory PaymentAddress.fromJson(Map<String, dynamic> json) {
    final api = ApiSilentPaymentAddress.fromJsonString(
      json: jsonEncode(json),
    );
    return PaymentAddress(api);
  }
}
