import 'dart:convert';
import 'package:danawallet/generated/rust/api/structs.dart';

class PaymentAddress {
  final ApiSilentPaymentAddress inner;

  PaymentAddress(this.inner);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PaymentAddress &&
            other.inner.stringRepresentation == inner.stringRepresentation;
  }

  @override
  int get hashCode => inner.stringRepresentation.hashCode;

  ApiSilentPaymentAddress get raw => inner;

  Map<String, dynamic> toJson() => {
        'version': inner.version,
        'scan_pubkey': inner.scanPubkey,
        'm_pubkey': inner.mPubkey,
        'network': inner.network.toString(),
        'string_representation': inner.stringRepresentation,
      };

  String toJsonString() => jsonEncode(toJson());

  factory PaymentAddress.fromJson(Map<String, dynamic> json) {
    final api = ApiSilentPaymentAddress.fromJsonString(
      json: jsonEncode(json),
    );
    return PaymentAddress(api);
  }
}
