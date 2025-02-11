import 'package:danawallet/generated/rust/api/structs.dart';

class RecipientFormFilled {
  String recipientAddress;
  ApiAmount amount;
  int feerate;

  RecipientFormFilled(
      {required this.recipientAddress,
      required this.amount,
      required this.feerate});
}
