class PrefixSearchResponse {
  final String id;
  final String message;
  final List<String> danaAddress;
  final int count;
  final int totalCount;

  const PrefixSearchResponse({
    required this.id,
    required this.message,
    required this.danaAddress,
    required this.count,
    required this.totalCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'dana_address': danaAddress,
      'count': count,
      'total_count': totalCount,
    };
  }

  factory PrefixSearchResponse.fromJson(Map<String, dynamic> json) {
    final danaAddressList = json['dana_address'] as List<dynamic>?;
    return PrefixSearchResponse(
      id: json['id'] as String,
      message: json['message'] as String,
      danaAddress: danaAddressList != null
          ? danaAddressList.map((e) => e as String).toList()
          : [],
      count: json['count'] as int? ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
    );
  }
}
