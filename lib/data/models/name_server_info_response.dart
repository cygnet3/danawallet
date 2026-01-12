class NameServerInfoResponse {
  final String domain;
  final String network;

  const NameServerInfoResponse({
    required this.domain,
    required this.network,
  });

  factory NameServerInfoResponse.fromJson(Map<String, dynamic> json) {
    return NameServerInfoResponse(
      domain: json['domain'] as String,
      network: json['network'] as String,
    );
  }
}
