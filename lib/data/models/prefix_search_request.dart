class PrefixSearchRequest {
  final String prefix;
  final String id;

  const PrefixSearchRequest({
    required this.prefix,
    required this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'prefix': prefix,
      'id': id,
    };
  }

  factory PrefixSearchRequest.fromJson(Map<String, dynamic> json) {
    return PrefixSearchRequest(
      prefix: json['prefix'] as String,
      id: json['id'] as String,
    );
  }
}

