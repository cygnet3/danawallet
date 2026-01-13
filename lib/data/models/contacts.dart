import 'package:danawallet/data/models/contact_field.dart';

class Contact {
  int? id;
  final String? nym; // user defined user name
  final String
      danaAddress; // Eventually register more than one, for now keep it simple
  final String spAddress; // silent payment address of the contact
  final List<ContactField>? customFields; // Optional custom fields

  Contact({
    this.id,
    this.nym,
    required this.danaAddress,
    required this.spAddress,
    this.customFields,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nym': nym,
      'danaAddress': danaAddress,
      'spAddress': spAddress,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'],
      nym: map['nym'],
      danaAddress: map['danaAddress'],
      spAddress: map['spAddress'],
      customFields: null, // Custom fields loaded separately
    );
  }
}
