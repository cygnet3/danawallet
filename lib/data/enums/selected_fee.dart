import 'package:danawallet/data/models/recommended_fee_model.dart';

enum SelectedFee {
  fast,
  normal,
  slow,
  custom;

  String get toName {
    switch (this) {
      case SelectedFee.fast:
        return "Fast";
      case SelectedFee.normal:
        return "Normal";
      case SelectedFee.slow:
        return "Slow";
      case SelectedFee.custom:
        return "Custom";
    }
  }

  String get toEstimatedTime {
    switch (this) {
      case SelectedFee.fast:
        return "10-30 minutes";
      case SelectedFee.normal:
        return "30-60 minutes";
      case SelectedFee.slow:
        return "1+ hour";
      case SelectedFee.custom:
        return "Custom";
    }
  }

  int getFeeRate(RecommendedFeeResponse response) {
    switch (this) {
      case SelectedFee.fast:
        return response.nextBlockFee;
      case SelectedFee.normal:
        return response.halfHourFee;
      case SelectedFee.slow:
        return response.hourFee;
      case SelectedFee.custom:
        throw Exception('Can\'t get fee rate for custom fee');
    }
  }
}
