import 'dart:convert';

import 'package:danawallet/data/models/payment_address.dart';

class Contact {
  int? id;
  final String nym;
  final Map<PaymentAddress, String> addresses;
  final String? imagePath;

  Contact({
    this.id,
    required this.nym,
    required this.addresses,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    final flatMap =
        addresses.map((key, value) => MapEntry(key.toJsonString(), value));
    return {
      'id': id,
      'nym': nym,
      'addresses': jsonEncode(flatMap),
      'imagePath': imagePath,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    final raw = map['addresses'] as String;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final Map<PaymentAddress, String> addresses =
        decoded.map((k, v) => MapEntry(
              PaymentAddress.fromJson(jsonDecode(k)),
              v.toString(),
            ));
    return Contact(
      id: map['id'],
      nym: map['nym'],
      addresses: addresses,
      imagePath: map['imagePath'],
    );
  }
}
