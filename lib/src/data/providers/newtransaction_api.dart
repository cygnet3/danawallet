import 'package:donationwallet/generated/rust/api/simple.dart';

class NewTransactionApi {
  NewTransactionApi();

  String createNewPsbtApi(String encodedWallet, Map<String, OwnedOutput> inputs,
      List<Recipient> recipients) {
    try {
      return createNewPsbt(
          encodedWallet: encodedWallet, inputs: inputs, recipients: recipients);
    } catch (e) {
      rethrow;
    }
  }

  String updateFeesApi(String psbt, int feeRate, String payer) {
    try {
      return addFeeForFeeRate(psbt: psbt, feeRate: feeRate, payer: payer);
    } catch (e) {
      rethrow;
    }
  }

  String fillOutputsApi(String encodedWallet, String psbt) {
    try {
      return fillSpOutputs(encodedWallet: encodedWallet, psbt: psbt);
    } catch (e) {
      rethrow;
    }
  }

  String signPsbtApi(String encodedWallet, String psbt, bool finalize) {
    try {
      return signPsbt(encodedWallet: encodedWallet, psbt: psbt, finalize: finalize);
    } catch (e) {
      rethrow;
    }
  }
}
