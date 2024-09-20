import 'dart:async';
import 'package:danawallet/constants.dart';
import 'package:danawallet/generated/rust/api/stream.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/generated/rust/api/wallet.dart';
import 'package:danawallet/generated/rust/logger.dart';
import 'package:danawallet/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WalletState extends ChangeNotifier {
  final String label = "default";
  BigInt amount = BigInt.from(0);
  int birthday = 0;
  int lastScan = 0;
  double progress = 0.0;
  bool scanning = false;
  Network _network = Network.signet;
  String address = "";
  Map<String, OwnedOutput> ownedOutputs = {};
  List<RecordedTransaction> txHistory = List.empty(growable: true);
  final secureStorage = const FlutterSecureStorage();

  late StreamSubscription logStreamSubscription;
  late StreamSubscription scanProgressSubscription;
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
    final walletStr = await secureStorage.read(key: label);

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

    scanProgressSubscription = createScanProgressStream().listen(((event) {
      int start = event.start;
      int current = event.current;
      int end = event.end;
      double scanned = (current - start).toDouble();
      double total = (end - start).toDouble();
      double progress = scanned / total;
      if (current == end) {
        progress = 0.0;
        scanning = false;
      }
      this.progress = progress;
      lastScan = current;

      notifyListeners();
    }));

    scanResultSubscription = createScanResultStream().listen(((event) async {
      String updatedWallet = event.updatedWallet;
      await saveWalletToSecureStorage(updatedWallet);
      await updateWalletStatus();
    }));
  }

  @override
  void dispose() {
    logStreamSubscription.cancel();
    scanProgressSubscription.cancel();
    scanResultSubscription.cancel();
    super.dispose();
  }

  Future<void> reset() async {
    amount = BigInt.zero;
    network = Network.signet;
    birthday = 0;
    lastScan = 0;
    progress = 0.0;
    scanning = false;
    address = "";
    ownedOutputs = {};
    txHistory = List.empty(growable: true);

    notifyListeners();
  }

  Future<void> saveWalletToSecureStorage(String wallet) async {
    await secureStorage.write(key: label, value: wallet);
  }

  Future<void> rmWalletFromSecureStorage() async {
    await secureStorage.write(key: label, value: null);
  }

  Future<String> getWalletFromSecureStorage() async {
    final wallet = await secureStorage.read(key: label);
    if (wallet != null) {
      return wallet;
    } else {
      throw Exception("No wallet in storage");
    }
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

  Future<void> scan() async {
    try {
      scanning = true;
      final wallet = await getWalletFromSecureStorage();

      final settings = SettingsService();
      final blindbitUrl = await settings.getBlindbitUrl();
      final dustLimit = await settings.getDustLimit();

      await scanToTip(
          blindbitUrl: blindbitUrl!,
          dustLimit: BigInt.from(dustLimit!),
          encodedWallet: wallet);
    } catch (e) {
      scanning = false;
      notifyListeners();
      rethrow;
    }
    scanning = false;
    notifyListeners();
  }
}
