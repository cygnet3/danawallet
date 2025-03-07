import 'dart:async';
import 'package:danawallet/constants.dart';
import 'package:danawallet/data/models/recipient_form_filled.dart';
import 'package:danawallet/data/models/recommended_fee_model.dart';
import 'package:danawallet/generated/rust/api/history.dart';
import 'package:danawallet/generated/rust/api/outputs.dart';
import 'package:danawallet/generated/rust/api/stream.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/generated/rust/api/wallet.dart';
import 'package:danawallet/generated/rust/api/wallet/setup.dart';
import 'package:danawallet/repositories/mempool_api_repository.dart';
import 'package:danawallet/repositories/wallet_repository.dart';
import 'package:flutter/material.dart';

class WalletState extends ChangeNotifier {
  final walletRepository = WalletRepository.instance;

  // variables that never change (unless wallet is reset)
  late Network network;
  late String address;
  late String changeAddress;
  late int birthday;

  // variables that change
  late BigInt amount;
  late BigInt unconfirmedChange;
  late int lastScan;
  late TxHistory txHistory;
  late OwnedOutputs ownedOutputs;

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
      // process update
      lastScan = event.getHeight();
      txHistory.processStateUpdate(update: event);
      ownedOutputs.processStateUpdate(update: event);

      // save updates to storage
      await walletRepository.saveHistory(txHistory);
      await walletRepository.saveOwnedOutputs(ownedOutputs);
      await walletRepository.saveLastScan(lastScan);

      // update UI
      await _updateWalletState();
      notifyListeners();
    }));
  }

  Future<bool> initialize() async {
    // we check if wallet str is present in database
    final wallet = await walletRepository.readWallet();

    // if not present, we have no wallet and return false
    if (wallet == null) {
      return false;
    }

    network = await walletRepository.readNetwork();

    // We try to load the wallet data blob.
    // This may fail if we make a change to the wallet data struct.
    // This case should crash the app, rather than continue.
    // If we continue, we risk the user accidentally
    // deleting their seed phrase.
    try {
      address = wallet.getReceivingAddress();
      changeAddress = wallet.getChangeAddress();
      birthday = wallet.getBirthday();

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
      WalletSetupResult setupResult, Network network, int birthday) async {
    final wallet =
        await walletRepository.setupWallet(setupResult, network, birthday);

    // fill current state variables
    address = wallet.getReceivingAddress();
    changeAddress = wallet.getChangeAddress();
    this.birthday = wallet.getBirthday();
    this.network = network;
    await _updateWalletState();
  }

  Future<SpWallet> getWalletFromSecureStorage() async {
    final wallet = await walletRepository.readWallet();
    if (wallet != null) {
      return wallet;
    } else {
      throw Exception("No wallet in storage");
    }
  }

  Future<String?> getSeedPhraseFromSecureStorage() async {
    return await walletRepository.readSeedPhrase();
  }

  Future<void> resetToScanHeight(int height) async {
    lastScan = height;

    ownedOutputs.resetToHeight(height: height);
    txHistory.resetToHeight(height: height);

    await walletRepository.saveLastScan(height);
    await walletRepository.saveHistory(txHistory);
    await walletRepository.saveOwnedOutputs(ownedOutputs);

    await _updateWalletState();
    notifyListeners();
  }

  Future<void> _updateWalletState() async {
    txHistory = await walletRepository.readHistory();
    ownedOutputs = await walletRepository.readOwnedOutputs();
    lastScan = await walletRepository.readLastScan();

    amount = ownedOutputs.getUnspentAmount();
    unconfirmedChange = txHistory.getUnconfirmedChange();
  }

  Future<RecommendedFeeResponse> getCurrentFeeRates() async {
    final mempoolApiRepository = MempoolApiRepository(network: network);
    final response = await mempoolApiRepository.getCurrentFeeRate();
    return response;
  }

  Future<ApiSilentPaymentUnsignedTransaction> createUnsignedTxToThisRecipient(
      RecipientFormFilled recipient) async {
    final wallet = await getWalletFromSecureStorage();

    final unspentOutputs = ownedOutputs.getUnspentOutputs();
    final bitcoinNetwork = network.toBitcoinNetwork;

    if (recipient.amount.field0 < amount - BigInt.from(546)) {
      return wallet.createNewTransaction(
          apiOutputs: unspentOutputs,
          apiRecipients: [
            ApiRecipient(
                address: recipient.recipientAddress, amount: recipient.amount)
          ],
          feerate: recipient.feerate.toDouble(),
          network: bitcoinNetwork);
    } else {
      return wallet.createDrainTransaction(
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

    final finalizedTx =
        SpWallet.finalizeTransaction(unsignedTransaction: unsignedTx);

    final wallet = await getWalletFromSecureStorage();

    final signedTx = wallet.signTransaction(unsignedTransaction: finalizedTx);
    final txid = await SpWallet.broadcastTx(
        tx: signedTx, network: network.toBitcoinNetwork);

    ownedOutputs.markOutpointsSpent(spentBy: txid, spent: selectedOutpoints);

    txHistory.addOutgoingTxToHistory(
        txid: txid,
        spentOutpoints: selectedOutpoints,
        recipients: recipients,
        change: changeValue);

    // save the updated wallet
    await walletRepository.saveOwnedOutputs(ownedOutputs);
    await walletRepository.saveHistory(txHistory);

    // refresh variables and notify listeners
    await _updateWalletState();
    notifyListeners();

    return;
  }
}
