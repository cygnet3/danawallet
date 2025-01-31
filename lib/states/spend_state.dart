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

  Future<void> addRecipients(
      String address, BigInt amount) async {
    final alreadyInList = recipients.where((r) => r.address == address);
    if (alreadyInList.isNotEmpty) {
      throw Exception("Address already in list");
    }

    if (amount <= BigInt.from(546)) {
      throw Exception("Can't have amount less than 546 sats");
    }
    recipients.add(ApiRecipient(
        address: address,
        amount: Amount(field0: amount),
    ));

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
    if (recipients.isEmpty) {
      throw Exception('Empty recipients list');
    }

    final wallet = await walletState.getWalletFromSecureStorage();

    final ownedOutputs = Map.fromEntries(
      walletState.ownedOutputs.entries.where((entry) => entry.value.spendStatus == const ApiOutputSpendStatus.unspent()),
    );
    final network = walletState.network.toBitcoinNetwork;
    final walletInfo = getWalletInfo(encodedWallet: wallet);

    final totalAmt = recipients.fold(BigInt.zero, (previousValue, element) => previousValue + element.amount.field0);

    String txid = "";
    List<(String, ApiOwnedOutput)> selectedOutputs;
    BigInt changeValue = BigInt.zero;

    try {
      ApiSilentPaymentUnsignedTransaction unsignedTx;
      if (totalAmt < walletState.amount) {
        unsignedTx = createNewTransaction(
            encodedWallet: wallet,
            apiOutputs: ownedOutputs,
            apiRecipients: recipients,
            feerate: fees.toDouble(),
            network: network);
      } else {
        final wipeAddress = recipients[0].address;
        unsignedTx = createDrainTransaction(
          encodedWallet: wallet, 
          apiOutputs: ownedOutputs, 
          wipeAddress: wipeAddress, 
          feerate: fees.toDouble(), 
          network: network
        );
      }

      selectedOutputs = unsignedTx.selectedUtxos;

      for (final recipient in unsignedTx.recipients) {
        if (recipient.address == walletInfo.changeAddress) {
          changeValue += recipient.amount.field0;
          break;
        }
      }

      final finalizedTx = finalizeTransaction(unsignedTransaction: unsignedTx);

      final signedTx = signTransaction(
          encodedWallet: wallet, unsignedTransaction: finalizedTx);
      txid = await broadcastTx(tx: signedTx, network: network);
    } catch (e) {
      rethrow;
    }

    final markedAsSpentWallet = _markAsSpent(wallet, txid, selectedOutputs);
    final updatedWallet = _addTxToHistory(
        markedAsSpentWallet,
        txid,
        selectedOutputs.map((tuple) => tuple.$1).toList(),
        recipients,
        changeValue);

    // Clear selections
    recipients.clear();

    // save the updated wallet
    walletState.saveWalletToSecureStorage(updatedWallet);
    await walletState.updateWalletStatus();

    return txid;
  }

  String _markAsSpent(
    String wallet,
    String txid,
    List<(String, ApiOwnedOutput)> selectedOutputs,
  ) {
    List<String> selectedOutpoints =
        selectedOutputs.map((tuple) => tuple.$1).toList();
    try {
      final updatedWallet = markOutpointsSpent(
          encodedWallet: wallet, spentBy: txid, spent: selectedOutpoints);
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
