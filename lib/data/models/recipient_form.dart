import 'package:danawallet/data/models/recipient_form_filled.dart';
import 'package:danawallet/data/models/recommended_fee_model.dart';
import 'package:danawallet/data/models/selected_fee.dart';
import 'package:danawallet/generated/rust/api/structs.dart';

// this singleton class contains all filled data during the send flow
// to save data in a global state, we use a singleton class.
// this is very similar to using Provider, but without NotifyListeners
class RecipientForm {
  String? recipientAddress;
  String? recipientBip353;
  ApiAmount? amount;
  SelectedFee? fee;
  RecommendedFeeResponse? currentFeeRates;
  ApiSilentPaymentUnsignedTransaction? unsignedTx;

  static final RecipientForm _instance = RecipientForm._internal();

  factory RecipientForm() {
    return _instance;
  }

  RecipientForm._internal();

  void reset() {
    _instance.recipientAddress = null;
    _instance.recipientBip353 = null;
    _instance.amount = null;
    _instance.fee = null;
    _instance.unsignedTx = null;
    _instance.currentFeeRates = null;
  }

  RecipientFormFilled toFilled() {
    if (recipientAddress == null ||
        amount == null ||
        fee == null ||
        currentFeeRates == null) {
      throw Exception('Not all required parameters filled');
    }

    final feerate = fee!.getFeeRate(currentFeeRates!);

    return RecipientFormFilled(
        recipientAddress: recipientAddress!, amount: amount!, feerate: feerate);
  }
}
