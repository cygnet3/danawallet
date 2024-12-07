import 'package:danawallet/constants.dart';
import 'package:danawallet/generated/rust/api/psbt.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/generated/rust/api/wallet.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';

class SpendState extends ChangeNotifier {
  List<ApiRecipient> recipients = List.empty(growable: true);

  SpendState();

  void reset() {
    recipients = List.empty(growable: true);
  }

  // BigInt outputSelectionTotalAmt() {
  //   final total = selectedOutputs.values
  //       .fold(BigInt.zero, (sum, element) => sum + element.amount.field0);
  //   return total;
  // }

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
    recipients.add(ApiRecipient(
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

    final selectOutputsRes = selectOutputs(ownedOutputs: walletState.ownedOutputs, recipients: recipients, feerate: fees);

    final selectedOutputs = selectOutputsRes.selectedOutputs;
    final changeValue = selectOutputsRes.changeValue;

    if (changeValue > BigInt.zero) {
      // We need to add a change output
      final changeAddress = getWalletInfo(encodedWallet: wallet).changeAddress;
      recipients.add(ApiRecipient(address: changeAddress, amount: Amount(field0: changeValue), nbOutputs: 1));
    }

    final unsignedPsbt =
        _newTransactionWithFees(wallet, selectedOutputs, recipients);

    final signedPsbt = _signPsbt(wallet, unsignedPsbt);
    final sentTxId =
        await _broadcastSignedPsbt(signedPsbt, walletState.network);
    final markedAsSpentWallet = _markAsSpent(wallet, sentTxId, selectedOutputs);
    final updatedWallet = _addTxToHistory(markedAsSpentWallet, sentTxId,
        selectedOutputs.keys.toList(), recipients, changeValue);

    // Clear selections
    recipients.clear();

    // save the updated wallet
    walletState.saveWalletToSecureStorage(updatedWallet);
    await walletState.updateWalletStatus();

    return sentTxId;
  }

  String _newTransactionWithFees(
      String wallet,
      Map<String, ApiOwnedOutput> selectedOutputs,
      List<ApiRecipient> recipients) {
    try {
      final (psbt, changeIdx) = createNewPsbt(
          encodedWallet: wallet,
          inputs: selectedOutputs,
          recipients: recipients);

      final psbtWithSpOutputsFilled =
          fillSpOutputs(encodedWallet: wallet, psbt: psbt);
      return psbtWithSpOutputsFilled;
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
    Map<String, ApiOwnedOutput> selectedOutputs,
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
      List<ApiRecipient> recipients,
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
