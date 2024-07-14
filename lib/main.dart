import 'dart:async';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:donationwallet/rust/api/simple.dart';
import 'package:donationwallet/rust/frb_generated.dart';
import 'package:donationwallet/rust/logger.dart';

import 'package:donationwallet/global_functions.dart';
import 'package:donationwallet/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

class SynchronizationService {
  Timer? _timer;
  final Duration _interval = const Duration(minutes: 10);

  void startSyncTimer() {
    _scheduleNextTask();
  }

  void _scheduleNextTask() async {
    _timer?.cancel();
    await performSynchronizationTask();
    _timer = Timer(_interval, () async {
      _scheduleNextTask();
    });
  }

  Future<void> performSynchronizationTask() async {
    try {
      await syncBlockchain();
    } catch (e) {
      displayNotification(e.toString());
    }
  }

  void stopSyncTimer() {
    _timer?.cancel();
  }
}

class WalletState extends ChangeNotifier {
  final String label = "default";
  BigInt amount = BigInt.from(0);
  int birthday = 0;
  int lastScan = 0;
  int tip = 0;
  double progress = 0.0;
  bool scanning = false;
  String network = 'signet';
  bool walletLoaded = false;
  String address = "";
  Map<String, OwnedOutput> ownedOutputs = {};
  Map<String, OwnedOutput> selectedOutputs = {};
  List<RecordedTransaction> txHistory = List.empty(growable: true);
  List<Recipient> recipients = List.empty(growable: true);
  final secureStorage = const FlutterSecureStorage();

  late StreamSubscription logStreamSubscription;
  late StreamSubscription scanProgressSubscription;
  late StreamSubscription amountStreamSubscription;
  late StreamSubscription syncStreamSubscription;

  final _synchronizationService = SynchronizationService();

  WalletState();

  Future<void> initialize() async {
    try {
      await _initStreams();
      _synchronizationService.startSyncTimer();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _initStreams() async {
    logStreamSubscription =
        createLogStream(level: LogLevel.debug, logDependencies: true)
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

    syncStreamSubscription = createSyncStream().listen((event) {
      tip = event.blockheight;

      print('tip: $tip');

      notifyListeners();
    });

    amountStreamSubscription = createAmountStream().listen((event) {
      amount = event;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    logStreamSubscription.cancel();
    scanProgressSubscription.cancel();
    amountStreamSubscription.cancel();
    syncStreamSubscription.cancel();
    _synchronizationService.stopSyncTimer();
    super.dispose();
  }

  Future<void> reset() async {
    amount = BigInt.zero;
    birthday = 0;
    lastScan = 0;
    progress = 0.0;
    scanning = false;
    walletLoaded = false;
    address = "";
    ownedOutputs = {};
    selectedOutputs = {};
    recipients = List.empty(growable: true);
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
    WalletStatus walletInfo;
    try {
      final wallet = await getWalletFromSecureStorage();
      walletInfo = getWalletInfo(encodedWallet: wallet);
    } catch (e) {
      rethrow;
    }
    address = walletInfo.address;
    amount = walletInfo.balance;
    birthday = walletInfo.birthday;
    lastScan = walletInfo.lastScan;
    ownedOutputs = walletInfo.outputs;
    txHistory = walletInfo.txHistory;
    notifyListeners();
  }

  Map<String, OwnedOutput> getSpendableOutputs() {
    var spendable = ownedOutputs.entries.where((element) =>
        element.value.spendStatus == const OutputSpendStatus.unspent());
    return Map.fromEntries(spendable);
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
      throw Exception("Can't have amount inferior to 546 sats");
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

  Future<void> scan() async {
    try {
      scanning = true;
      await syncBlockchain();
      final wallet = await getWalletFromSecureStorage();
      final updatedWallet = await scanToTip(encodedWallet: wallet);
      print(updatedWallet);
      await saveWalletToSecureStorage(updatedWallet);
      await updateWalletStatus();
    } catch (e) {
      scanning = false;
      notifyListeners();
      rethrow;
    }
    scanning = false;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final walletState = WalletState();
  await walletState.initialize();
  runApp(
    ChangeNotifierProvider.value(
      value: walletState,
      child: const SilentPaymentApp(),
    ),
  );
}

class SilentPaymentApp extends StatelessWidget {
  const SilentPaymentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Donation wallet',
      navigatorKey: globalNavigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Bitcoin.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
