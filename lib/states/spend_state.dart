import 'package:danawallet/constants.dart';
import 'package:danawallet/generated/rust/api/psbt.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/generated/rust/api/wallet.dart';
import 'package:danawallet/states/wallet_state.dart';
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

  Future<String> createSpendTx(WalletState walletState, int fees) async {
    final wallet = await walletState.getWalletFromSecureStorage();
    final (unsignedPsbt, changeAmt) =
        _newTransactionWithFees(wallet, selectedOutputs, recipients, fees);

    final signedPsbt = _signPsbt(wallet, unsignedPsbt);
    final sentTxId =
        await _broadcastSignedPsbt(signedPsbt, walletState.network);
    final markedAsSpentWallet = _markAsSpent(wallet, sentTxId, selectedOutputs);
    final updatedWallet = _addTxToHistory(markedAsSpentWallet, sentTxId,
        selectedOutputs.keys.toList(), recipients, changeAmt);

    // Clear selections
    selectedOutputs.clear();
    recipients.clear();

    // save the updated wallet
    walletState.saveWalletToSecureStorage(updatedWallet);
    await walletState.updateWalletStatus();

    return sentTxId;
  }

  (String, BigInt?) _newTransactionWithFees(
      String wallet,
      Map<String, OwnedOutput> selectedOutputs,
      List<Recipient> recipients,
      int feeRate) {
    try {
      final (psbt, changeIdx) = createNewPsbt(
          encodedWallet: wallet,
          inputs: selectedOutputs,
          recipients: recipients);

      // todo: use change address for fees instead of first address
      final psbtWithFee = addFeeForFeeRate(
          psbt: psbt, feeRate: feeRate, payer: recipients[0].address);

      // get change amount after reducing fees
      BigInt? changeAmt;
      if (changeIdx != null) {
        changeAmt = readAmtFromPsbtOutput(psbt: psbt, idx: changeIdx);
      }

      final psbtWithSpOutputsFilled =
          fillSpOutputs(encodedWallet: wallet, psbt: psbtWithFee);
      return (psbtWithSpOutputsFilled, changeAmt);
    } catch (e) {
      rethrow;
    }
  }

  String _signPsbt(
    String wallet,
    String unsignedPsbt,
  ) {
    return signPsbt(encodedWallet: wallet, psbt: unsignedPsbt, finalize: true);
  }

  Future<String> _broadcastSignedPsbt(
      String signedPsbt, Network network) async {
    try {
      final tx = extractTxFromPsbt(psbt: signedPsbt);
      final txid = await broadcastTx(tx: tx, network: network.toBitcoinNetwork);
      return txid;
    } catch (e) {
      rethrow;
    }
  }

  String _markAsSpent(
    String wallet,
    String txid,
    Map<String, OwnedOutput> selectedOutputs,
  ) {
    try {
      final updatedWallet = markOutpointsSpent(
          encodedWallet: wallet,
          spentBy: txid,
          spent: selectedOutputs.keys.toList());
      return updatedWallet;
    } catch (e) {
      rethrow;
    }
  }

  String _addTxToHistory(
      String wallet,
      String txid,
      List<String> selectedOutpoints,
      List<Recipient> recipients,
      BigInt? changeAmount) {
    final changeAmt = Amount(field0: changeAmount ?? BigInt.from(0));
    try {
      final updatedWallet = addOutgoingTxToHistory(
          encodedWallet: wallet,
          txid: txid,
          spentOutpoints: selectedOutpoints,
          recipients: recipients,
          change: changeAmt);
      return updatedWallet;
    } catch (e) {
      rethrow;
    }
  }
}
