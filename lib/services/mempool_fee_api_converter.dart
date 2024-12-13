import '../data/models/recommended_fee_model.dart';
import 'fee_api_converter.dart';

class MempoolApiFeeConverter implements FeeConverter {
  @override
  RecommendedFeeResponse convert(Map<String, dynamic> json) {
    return RecommendedFeeResponse(
      nextBlockFee: json['fastestFee'] ?? 0,
      halfHourFee: json['halfHourFee'] ?? 0,
      hourFee: json['hourFee'] ?? 0,
      dayFee: json['economyFee'] ?? 0,
    );
  }
}
