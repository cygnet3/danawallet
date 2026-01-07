class NameServerInfoResponse {
  final String domain;
  final bool mainnetOnly;

  const NameServerInfoResponse({
    required this.domain,
    required this.mainnetOnly,
  });

  factory NameServerInfoResponse.fromJson(Map<String, dynamic> json) {
    return NameServerInfoResponse(
      domain: json['domain'] as String,
      mainnetOnly: json['mainnet_only'] as bool,
    );
  }
}
