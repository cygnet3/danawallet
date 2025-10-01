class AliasCreationRequest {
  final String userName;
  final String domain;
  final String spAddress;

  const AliasCreationRequest({
    required this.userName,
    required this.domain,
    required this.spAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_name': userName,
      'domain': domain,
      'sp_address': spAddress,
    };
  }

  factory AliasCreationRequest.fromJson(Map<String, dynamic> json) {
    return AliasCreationRequest(
      userName: json['user_name'] as String,
      domain: json['domain'] as String,
      spAddress: json['sp_address'] as String,
    );
  }
}

