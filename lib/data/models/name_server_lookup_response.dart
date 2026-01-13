class NameServerLookupResponse {
  final String id;
  final String message;
  final List<String> danaAddresses;
  final String spAddress;

  const NameServerLookupResponse({
    required this.id,
    required this.message,
    required this.danaAddresses,
    required this.spAddress,
  });

  factory NameServerLookupResponse.fromJson(Map<String, dynamic> json) {
    return NameServerLookupResponse(
      id: json['id'] as String,
      message: json['message'] as String,
      danaAddresses: List<String>.from(json['dana_addresses']),
      spAddress: json['sp_address'] as String,
    );
  }
}
