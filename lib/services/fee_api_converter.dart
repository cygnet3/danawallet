import '../data/models/recommended_fee_model.dart';

abstract class FeeConverter {
  RecommendedFeeResponse convert(Map<String, dynamic> json);
}
