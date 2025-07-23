import 'package:danawallet/data/models/recommended_fee_model.dart';
import 'package:danawallet/generated/rust/api/structs.dart';

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

  ApiAmount getEstimatedFee(RecommendedFeeResponse currentFeeRates) {
    // 1 in, 1 out has size 111 vbytes
    // 1 in, 2 out has size 154 vbytes
    // 2 in, 1 out has size 168.6 vbytes
    // 2 in, 2 out has size 211.5 vbytes
    // 3 in, 1 out has size 226 vbytes
    int estimatedSize = 200;
    int feeRate = getFeeRate(currentFeeRates);

    int estimatedFee = estimatedSize * feeRate;

    return ApiAmount(field0: BigInt.from(estimatedFee));
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
        // todo change
        return response.dayFee;
    }
  }
}
