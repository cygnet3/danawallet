import 'package:danawallet/generated/rust/api/structs.dart';

extension ApiAmountExtension on ApiAmount {
  ApiAmount operator +(ApiAmount other) {
    return ApiAmount(field0: field0 + other.field0);
  }
}
