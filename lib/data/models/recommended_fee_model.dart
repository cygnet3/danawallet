class RecommendedFeeResponse {
  final int nextBlockFee;
  final int halfHourFee; // 3 blocks
  final int hourFee; // 6 blocks
  final int dayFee; // 144 blocks

  RecommendedFeeResponse({
    required this.nextBlockFee,
    required this.halfHourFee,
    required this.hourFee,
    required this.dayFee,
  });

  RecommendedFeeResponse.empty()
      : nextBlockFee = 0,
        halfHourFee = 0,
        hourFee = 0,
        dayFee = 0;
}
