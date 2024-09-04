import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:flutter/material.dart';

class SpendState extends ChangeNotifier {
  Map<String, OwnedOutput> selectedOutputs = {};
  List<Recipient> recipients = List.empty(growable: true);

  SpendState();

  void reset() {
    selectedOutputs = {};
    recipients = List.empty(growable: true);

    notifyListeners();
  }

  void toggleOutputSelection(String outpoint, OwnedOutput output) {
    if (selectedOutputs.containsKey(outpoint)) {
      selectedOutputs.remove(outpoint);
    } else {
      selectedOutputs[outpoint] = output;
    }
    notifyListeners();
  }

  BigInt outputSelectionTotalAmt() {
    final total = selectedOutputs.values
        .fold(BigInt.zero, (sum, element) => sum + element.amount.field0);
    return total;
  }

  BigInt recipientTotalAmt() {
    final total = recipients.fold(
        BigInt.zero, (sum, element) => sum + element.amount.field0);
    return total;
  }

  Future<void> addRecipients(
      String address, BigInt amount, int nbOutputs) async {
    final alreadyInList = recipients.where((r) => r.address == address);
    if (alreadyInList.isNotEmpty) {
      throw Exception("Address already in list");
    }

    if (nbOutputs < 1) {
      nbOutputs = 1;
    }

    if (amount <= BigInt.from(546)) {
      throw Exception("Can't have amount less than 546 sats");
    }
    recipients.add(Recipient(
        address: address,
        amount: Amount(field0: amount),
        nbOutputs: nbOutputs));

    notifyListeners();
  }

  Future<void> rmRecipient(String address) async {
    final alreadyInList = recipients.where((r) => r.address == address);
    if (alreadyInList.isEmpty) {
      throw Exception("Unknown recipient");
    } else {
      recipients.removeWhere((r) => r.address == address);
    }
    notifyListeners();
  }
}
