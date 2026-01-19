import 'package:danawallet/data/models/bip353_address.dart';

class NameServerRegisterResponse {
  final String id;
  final String message;
  final Bip353Address? danaAddress;
  final String? spAddress;
  final String? dnsRecordId;

  const NameServerRegisterResponse({
    required this.id,
    required this.message,
    this.danaAddress,
    this.spAddress,
    this.dnsRecordId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      if (danaAddress != null) 'dana_address': danaAddress,
      if (spAddress != null) 'sp_address': spAddress,
      if (dnsRecordId != null) 'dns_record_id': dnsRecordId,
    };
  }

  factory NameServerRegisterResponse.fromJson(Map<String, dynamic> json) {
    final String? danaAddress = json['dana_address'];
    return NameServerRegisterResponse(
      id: json['id'] as String,
      message: json['message'] as String,
      danaAddress:
          danaAddress != null ? Bip353Address.fromString(danaAddress) : null,
      spAddress: json['sp_address'] as String?,
      dnsRecordId: json['dns_record_id'] as String?,
    );
  }

  @override
  String toString() {
    return 'DanaAddressCreationResponse{id: $id, message: $message, danaAddress: $danaAddress, spAddress: $spAddress, dnsRecordId: $dnsRecordId}';
  }
}
