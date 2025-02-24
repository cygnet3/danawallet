import 'dart:async';
import 'package:danawallet/constants.dart';
import 'package:danawallet/data/models/recipient_form_filled.dart';
import 'package:danawallet/data/models/recommended_fee_model.dart';
import 'package:danawallet/generated/rust/api/state.dart';
import 'package:danawallet/generated/rust/api/stream.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/generated/rust/api/wallet.dart';
import 'package:danawallet/repositories/mempool_api_repository.dart';
import 'package:danawallet/repositories/wallet_repository.dart';
import 'package:flutter/material.dart';

class WalletState extends ChangeNotifier {
  final walletRepository = WalletRepository();

  // variables that never change (unless wallet is reset)
  late Network network;
  late String address;
  late String changeAddress;
  late int birthday;

  // variables that change
  late BigInt amount;
  late BigInt unconfirmedChange;
  late int lastScan;
  late Map<String, ApiOwnedOutput> ownedOutputs;
  late List<ApiRecordedTransaction> txHistory;

  // stream to receive updates while scanning
  late StreamSubscription scanResultSubscription;

  // private constructor
  WalletState._();

  static Future<WalletState> create() async {
    final instance = WalletState._();
    await instance._initStreams();
    return instance;
  }

  Future<void> _initStreams() async {
    scanResultSubscription = createScanResultStream().listen(((event) async {
      await walletRepository.saveHistory(event.updatedTxHistory);
      await walletRepository.saveLastScan(event.updatedLastScan);
      await walletRepository.saveOwnedOutputs(event.updatedOwnedOutputs);
      try {
        await _updateWalletState();
      } catch (e) {
        rethrow;
      }
      notifyListeners();
    }));
  }

  Future<bool> initialize() async {
    // we check if wallet str is present in database
    final walletStr = await walletRepository.readWalletBlob();

    // if not present, we have no wallet and return false
    if (walletStr == null) {
      return false;
    }

    network = await walletRepository.readNetwork();

    // We try to load the wallet data blob.
    // This may fail if we make a change to the wallet data struct.
    // This case should crash the app, rather than continue.
    // If we continue, we risk the user accidentally
    // deleting their seed phrase.
    try {
      final walletInfo = getWalletInfo(encodedWallet: walletStr);
      address = walletInfo.address;
      changeAddress = walletInfo.changeAddress;
      birthday = walletInfo.birthday;

      await _updateWalletState();

      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    scanResultSubscription.cancel();
    super.dispose();
  }

  Future<void> reset() async {
    await walletRepository.reset();
  }

  Future<void> createNewWallet(
      String encodedWallet, String? seedphrase, Network network) async {
    final walletInfo = getWalletInfo(encodedWallet: encodedWallet);

    // save variables in storage
    await walletRepository.saveWalletBlob(encodedWallet);
    await walletRepository.saveNetwork(network);
    await walletRepository.trySaveSeedPhrase(seedphrase);

    // set default values for new wallet
    await walletRepository.saveLastScan(walletInfo.birthday);
    await walletRepository.saveHistory('[]');
    await walletRepository.saveOwnedOutputs('{}');

    // fill current state variables
    address = walletInfo.address;
    changeAddress = walletInfo.changeAddress;
    birthday = walletInfo.birthday;
    this.network = network;
    await _updateWalletState();
  }

  Future<String> getWalletFromSecureStorage() async {
    final wallet = await walletRepository.readWalletBlob();
    if (wallet != null) {
      return wallet;
    } else {
      throw Exception("No wallet in storage");
    }
  }

  Future<String> getEncodedHistory() async {
    return await walletRepository.readHistoryEncoded();
  }

  Future<String> getEncodedOutputs() async {
    return await walletRepository.readOwnedOutputsEncoded();
  }

  Future<String?> getSeedPhrase() async {
    return await walletRepository.readSeedPhrase();
  }

  Future<void> resetToScanHeight(int height) async {
    lastScan = height;

    final encodedOutputs = await walletRepository.readOwnedOutputsEncoded();
    final encodedHistory = await walletRepository.readHistoryEncoded();

    // this uses the stream to update the wallet state
    resetToHeight(
        height: height,
        encodedOwnedOutputs: encodedOutputs,
        encodedTxHistory: encodedHistory);
  }

  Future<void> updateWalletStatus() async {
    try {
      _updateWalletState();
    } catch (e) {
      rethrow;
    }
    notifyListeners();
  }

  Future<void> _updateWalletState() async {
    txHistory = await walletRepository.readHistory();
    ownedOutputs = await walletRepository.readOwnedOutputs();
    lastScan = await walletRepository.readLastScan();

    amount = BigInt.from(0);
    unconfirmedChange = BigInt.from(0);
    for (ApiOwnedOutput output in ownedOutputs.values) {
      if (output.spendStatus is ApiOutputSpendStatus_Unspent) {
        amount += output.amount.field0;
      }
    }

    for (ApiRecordedTransaction tx in txHistory) {
      switch (tx) {
        case ApiRecordedTransaction_Outgoing(:final field0):
          if (field0.confirmedAt == null) {
            // while an outgoing transaction is not yet confirmed, we add the change outputs manually
            unconfirmedChange += field0.change.field0;
          }
        default:
      }
    }
  }

  Future<RecommendedFeeResponse> getCurrentFeeRates() async {
    final mempoolApiRepository = MempoolApiRepository(network: network);
    final response = await mempoolApiRepository.getCurrentFeeRate();
    return response;
  }

  Future<ApiSilentPaymentUnsignedTransaction> createUnsignedTxToThisRecipient(
      RecipientFormFilled recipient) async {
    final wallet = await getWalletFromSecureStorage();

    final unspentOutputs = Map.fromEntries(
      ownedOutputs.entries.where((entry) =>
          entry.value.spendStatus == const ApiOutputSpendStatus.unspent()),
    );
    final bitcoinNetwork = network.toBitcoinNetwork;

    if (recipient.amount.field0 < amount - BigInt.from(546)) {
      return createNewTransaction(
          encodedWallet: wallet,
          apiOutputs: unspentOutputs,
          apiRecipients: [
            ApiRecipient(
                address: recipient.recipientAddress, amount: recipient.amount)
          ],
          feerate: recipient.feerate.toDouble(),
          network: bitcoinNetwork);
    } else {
      return createDrainTransaction(
          encodedWallet: wallet,
          apiOutputs: unspentOutputs,
          wipeAddress: recipient.recipientAddress,
          feerate: recipient.feerate.toDouble(),
          network: bitcoinNetwork);
    }
  }

  Future<void> signAndBroadcastUnsignedTx(
      ApiSilentPaymentUnsignedTransaction unsignedTx) async {
    final selectedOutputs = unsignedTx.selectedUtxos;

    List<String> selectedOutpoints =
        selectedOutputs.map((tuple) => tuple.$1).toList();

    final changeValue =
        unsignedTx.getChangeAmount(changeAddress: changeAddress);

    final recipients = unsignedTx.getRecipients(changeAddress: changeAddress);

    final finalizedTx = finalizeTransaction(unsignedTransaction: unsignedTx);

    final wallet = await getWalletFromSecureStorage();

    final signedTx = signTransaction(
        encodedWallet: wallet, unsignedTransaction: finalizedTx);
    final txid =
        await broadcastTx(tx: signedTx, network: network.toBitcoinNetwork);

    // we still have to do this since we 'save' using the encoded format
    final encodedOutputs = await walletRepository.readOwnedOutputsEncoded();
    final encodedHistory = await walletRepository.readHistoryEncoded();

    final updatedOwnedOutputs = markOutpointsSpent(
        encodedOutputs: encodedOutputs,
        spentBy: txid,
        spent: selectedOutpoints);

    final updatedTxHistory = addOutgoingTxToHistory(
        encodedHistory: encodedHistory,
        txid: txid,
        spentOutpoints: selectedOutpoints,
        recipients: recipients,
        change: changeValue);

    // save the updated wallet
    await walletRepository.saveOwnedOutputs(updatedOwnedOutputs);
    walletRepository.saveHistory(updatedTxHistory);
    await updateWalletStatus();

    return;
  }
}
