import 'package:danawallet/data/models/bip353_address.dart';
import 'package:danawallet/data/models/contact_field.dart';

class Contact {
  int? id;
  final String? nym; // user defined user name
  final Bip353Address?
      danaAddress; // Eventually register more than one, for now keep it simple
  final String spAddress; // silent payment address of the contact
  final List<ContactField>? customFields; // Optional custom fields

  Contact({
    this.id,
    this.nym,
    this.danaAddress,
    required this.spAddress,
    this.customFields,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nym': nym,
      'danaAddress': danaAddress?.toString(),
      'spAddress': spAddress,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    final String? danaAddress = map['danaAddress'];
    return Contact(
      id: map['id'],
      nym: map['nym'],
      danaAddress:
          danaAddress != null ? Bip353Address.fromString(danaAddress) : null,
      spAddress: map['spAddress'],
      customFields: null, // Custom fields loaded separately
    );
  }
}
