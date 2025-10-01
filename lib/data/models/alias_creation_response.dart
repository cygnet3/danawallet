class AliasCreationResponse {
  final String alias;
  final String spAddress;
  final bool success;
  final String? error;

  const AliasCreationResponse({
    required this.alias,
    required this.spAddress,
    required this.success,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'alias': alias,
      'spAddress': spAddress,
      'success': success,
      if (error != null) 'error': error,
    };
  }

  factory AliasCreationResponse.fromJson(Map<String, dynamic> json) {
    return AliasCreationResponse(
      alias: json['alias'] as String,
      spAddress: json['spAddress'] as String,
      success: json['success'] as bool,
      error: json['error'] as String?,
    );
  }

  @override
  String toString() {
    return 'AliasCreationResponse{alias: $alias, spAddress: $spAddress, success: $success, error: $error}';
  }
}

