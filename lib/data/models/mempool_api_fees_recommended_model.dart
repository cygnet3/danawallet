class RecommendedFeeResponse {
  final int fastestFee;
  final int halfHourFee;
  final int hourFee;
  final int economyFee;
  final int minimumFee;

  RecommendedFeeResponse({
    required this.fastestFee,
    required this.halfHourFee,
    required this.hourFee,
    required this.economyFee,
    required this.minimumFee,
  });

  RecommendedFeeResponse.empty()
      : fastestFee = 0,
        halfHourFee = 0,
        hourFee = 0,
        economyFee = 0,
        minimumFee = 0;

  factory RecommendedFeeResponse.fromJson(Map<String, dynamic> json) {
    return RecommendedFeeResponse(
      fastestFee: json['fastestFee'] ?? 0,
      halfHourFee: json['halfHourFee'] ?? 0,
      hourFee: json['hourFee'] ?? 0,
      economyFee: json['economyFee'] ?? 0,
      minimumFee: json['minimumFee'] ?? 0,
    );
  }
}