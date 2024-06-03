// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'package:donationwallet/rust/api/simple.dart';
import 'package:donationwallet/rust/constants.dart';
import 'package:donationwallet/rust/frb_generated.dart';
import 'package:donationwallet/rust/logger.dart';

import 'package:donationwallet/global_functions.dart';
import 'package:donationwallet/home.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
  Directory dir = Directory("/");
  BigInt amount = BigInt.from(0);
  int birthday = 0;
  int lastScan = 0;
  int tip = 0;
  double progress = 0.0;
  bool scanning = false;
  String network = 'signet';
  bool walletLoaded = false;
  String address = "";
  List<OwnedOutput> ownedOutputs = List.empty();
  List<OwnedOutput> selectedOutputs = List.empty(growable: true);
  List<Recipient> recipients = List.empty(growable: true);

  late StreamSubscription logStreamSubscription;
  late StreamSubscription scanProgressSubscription;
  late StreamSubscription amountStreamSubscription;
  late StreamSubscription syncStreamSubscription;

  final _synchronizationService = SynchronizationService();

  WalletState();

  Future<void> initialize() async {
    try {
      await _initStreams();
      await _initDir();
      _synchronizationService.startSyncTimer();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _initDir() async {
    try {
      dir = await getApplicationSupportDirectory();
    } catch (e) {
      rethrow;
    }
    notifyListeners();
  }

  Future<void> _initStreams() async {
    logStreamSubscription =
        createLogStream(level: LogLevel.info, logDependencies: true)
            .listen((event) {
      print('${event.level} (${event.tag}): ${event.msg}');
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
    // tip isn't specific to wallet, needs not be reset
    progress = 0.0;
    scanning = false;
    network = 'signet';
    walletLoaded = false;
    address = "";
    ownedOutputs = List.empty();
    selectedOutputs = List.empty(growable: true);
    recipients = List.empty(growable: true);
    // dir stays as it is

    notifyListeners();
  }

  Future<void> getAddress() async {
    try {
      address = await getReceivingAddress(path: dir.path, label: label);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateWalletStatus() async {
    try {
      final wallet = await getWalletInfo(path: dir.path, label: label);
      amount = wallet.amount;
      birthday = wallet.birthday;
      lastScan = wallet.scanHeight;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOwnedOutputs() async {
    try {
      ownedOutputs = await getOutputs(path: dir.path, label: label);
    } catch (e) {
      rethrow;
    }
    notifyListeners();
  }

  List<OwnedOutput> getSpendableOutputs() {
    return ownedOutputs
        .where(
            (output) => output.spendStatus == const OutputSpendStatus.unspent())
        .toList();
  }

  void toggleOutputSelection(OwnedOutput output) {
    if (selectedOutputs.contains(output)) {
      selectedOutputs.remove(output);
    } else {
      selectedOutputs.add(output);
    }
    notifyListeners();
  }

  BigInt outputSelectionTotalAmt() {
    final total = selectedOutputs.fold(
        BigInt.zero, (sum, element) => sum + element.amount);
    return total;
  }

  BigInt recipientTotalAmt() {
    final total =
        recipients.fold(BigInt.zero, (sum, element) => sum + element.amount);
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
    recipients
        .add(Recipient(address: address, amount: amount, nbOutputs: nbOutputs));

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
      notifyListeners();
      await scanToTip(path: dir.path, label: label);
      await syncBlockchain();
    } catch (e) {
      scanning = false;
      notifyListeners();
      rethrow;
    }
    scanning = false;
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
      title: 'Silent payments',
      navigatorKey: globalNavigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
