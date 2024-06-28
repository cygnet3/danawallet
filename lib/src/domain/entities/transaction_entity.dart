import 'package:donationwallet/generated/rust/api/simple.dart';

class TransactionEntity {
  final String spWallet;
  Map<String, OwnedOutput> selectedOutputs = {};
  List<Recipient> recipients = List.empty(growable: true);
  int feeRate = 0;
  String feePayer;
  String? psbt;
  String? finalTx;

  TransactionEntity({required this.spWallet, required this.feePayer});

  String get getSpWallet => spWallet;
  Map<String, OwnedOutput> get getSelectedOutputs => selectedOutputs;
  List<Recipient> get getRecipients => recipients;
  int get getFeeRate => feeRate;
  String? get getPsbt => psbt;
  String? get getFinalTx => finalTx;
  String get getFeePayer => feePayer;

  set setSelectedOutputs(Map<String, OwnedOutput> outputs) {
    selectedOutputs = outputs;
  }

  set setRecipients(List<Recipient> recipientList) {
    recipients = recipientList;
  }

  set setFeeRate(int feeRate) {
    feeRate = feeRate;
  }

  set setPsbt(String newPsbt) {
    psbt = newPsbt;
  }

  set setFinalTx(String finalTx) {
    finalTx = finalTx;
  }

  set setFeePayer(String newPayer) {
    feePayer = newPayer;
  }

  void appendOutput(String outpoint, OwnedOutput output) {
    selectedOutputs[outpoint] = output;
  }
}
