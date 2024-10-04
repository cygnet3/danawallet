import 'dart:async';
import 'package:danawallet/constants.dart';
import 'package:danawallet/generated/rust/api/stream.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/generated/rust/api/wallet.dart';
import 'package:danawallet/generated/rust/logger.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/repositories/wallet_repository.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:flutter/material.dart';

class WalletState extends ChangeNotifier {
  final walletRepository = WalletRepository();
  BigInt amount = BigInt.from(0);
  int birthday = 0;
  int lastScan = 0;
  Network _network = Network.signet;
  String address = "";
  Map<String, OwnedOutput> ownedOutputs = {};
  List<RecordedTransaction> txHistory = List.empty(growable: true);

  late StreamSubscription logStreamSubscription;
  late StreamSubscription scanResultSubscription;

  WalletState();

  Network get network => _network;
  set network(Network value) {
    _network = value;
    notifyListeners();
  }

  Future<bool> initialize() async {
    // todo: move logging stream to more sensible place
    await _initStreams();

    // we check if wallet str is present in database
    final walletStr = await walletRepository.readWalletBlob();

    // if not present, we have no wallet and return false
    if (walletStr == null) {
      return false;
    }

    // We try to load the wallet data blob.
    // This may fail if we make a change to the wallet data struct.
    // This case should crash the app, rather than continue.
    // If we continue, we risk the user accidentally
    // deleting their seed phrase.
    try {
      await _updateWalletStatus(walletStr);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _initStreams() async {
    logStreamSubscription =
        createLogStream(level: LogLevel.info, logDependencies: true)
            .listen((event) {
      print('${event.level} (${event.tag}): ${event.msg}');
      notifyListeners();
    });
    scanResultSubscription = createScanResultStream().listen(((event) async {
      await saveWalletToSecureStorage(event.updatedWallet);
      try {
        await _updateWalletStatus(event.updatedWallet);
      } catch (e) {
        rethrow;
      }
      notifyListeners();
    }));
  }

  @override
  void dispose() {
    logStreamSubscription.cancel();
    scanResultSubscription.cancel();
    super.dispose();
  }

  Future<void> reset() async {
    await walletRepository.reset();

    amount = BigInt.zero;
    network = Network.signet;
    birthday = 0;
    lastScan = 0;
    address = "";
    ownedOutputs = {};
    txHistory = List.empty(growable: true);

    notifyListeners();
  }

  Future<void> saveWalletToSecureStorage(String wallet) async {
    await walletRepository.saveWalletBlob(wallet);
  }

  Future<void> saveSeedPhraseToSecureStorage(String seedphrase) async {
    await walletRepository.saveSeedPhrase(seedphrase);
  }

  Future<String> getWalletFromSecureStorage() async {
    final wallet = await walletRepository.readWalletBlob();
    if (wallet != null) {
      return wallet;
    } else {
      throw Exception("No wallet in storage");
    }
  }

  Future<String?> getSeedPhrase() async {
    return await walletRepository.readSeedPhrase();
  }

  Future<void> updateWalletStatus() async {
    try {
      final wallet = await getWalletFromSecureStorage();
      _updateWalletStatus(wallet);
    } catch (e) {
      rethrow;
    }
    notifyListeners();
  }

  Future<void> _updateWalletStatus(String wallet) async {
    WalletStatus walletInfo;
    try {
      walletInfo = getWalletInfo(encodedWallet: wallet);
    } catch (e) {
      rethrow;
    }

    BigInt totalAmount = walletInfo.balance;

    for (RecordedTransaction tx in walletInfo.txHistory) {
      switch (tx) {
        case RecordedTransaction_Outgoing(:final field0):
          if (field0.confirmedAt == null) {
            // while an outgoing transaction is not yet confirmed, we add the change outputs manually
            totalAmount += field0.change.field0;
          }
        default:
      }
    }

    address = walletInfo.address;
    amount = totalAmount;
    birthday = walletInfo.birthday;
    lastScan = walletInfo.lastScan;
    ownedOutputs = walletInfo.outputs;
    txHistory = walletInfo.txHistory;
    network = Network.fromBitcoinNetwork(walletInfo.network);
  }

  Map<String, OwnedOutput> getSpendableOutputs() {
    var spendable = ownedOutputs.entries.where((element) =>
        element.value.spendStatus == const OutputSpendStatus.unspent());
    return Map.fromEntries(spendable);
  }

  Future<void> scan(ScanProgressNotifier scanProgress) async {
    try {
      final wallet = await getWalletFromSecureStorage();

      final settings = SettingsRepository();
      final blindbitUrl = await settings.getBlindbitUrl();
      final dustLimit = await settings.getDustLimit();

      scanProgress.activate(lastScan);
      await scanToTip(
          blindbitUrl: blindbitUrl!,
          dustLimit: BigInt.from(dustLimit!),
          encodedWallet: wallet);
    } catch (e) {
      scanProgress.deactivate();
      rethrow;
    }
    scanProgress.deactivate();
  }

  Future<void> interruptScan(ScanProgressNotifier scanProgress) async {
    interruptScanning();
    scanProgress.deactivate();
  }
}
