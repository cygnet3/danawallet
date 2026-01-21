import 'package:danawallet/data/models/contact.dart';
import 'package:danawallet/generated/rust/api/structs.dart';

class RecipientFormFilled {
  Contact recipient;
  ApiAmount amount;
  int feerate;

  RecipientFormFilled(
      {required this.recipient, required this.amount, required this.feerate});
}
