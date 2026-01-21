import 'package:danawallet/data/models/bip353_address.dart';

class NameServerLookupResponse {
  final String id;
  final String message;
  final List<Bip353Address> danaAddresses;
  final String spAddress;

  const NameServerLookupResponse({
    required this.id,
    required this.message,
    required this.danaAddresses,
    required this.spAddress,
  });

  factory NameServerLookupResponse.fromJson(Map<String, dynamic> json) {
    List<Bip353Address> danaAddresses = [];
    for (String danaAddress in json['dana_addresses']) {
      danaAddresses.add(Bip353Address.fromString(danaAddress));
    }

    return NameServerLookupResponse(
      id: json['id'] as String,
      message: json['message'] as String,
      danaAddresses: danaAddresses,
      spAddress: json['sp_address'] as String,
    );
  }
}
