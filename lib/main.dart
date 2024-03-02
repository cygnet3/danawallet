// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';

import 'package:donationwallet/ffi.dart';
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
      await api.syncBlockchain();
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
  bool nakamotoIsRunning = false;
  int amount = 0;
  int birthday = 0;
  int lastScan = 0;
  int tip = 0;
  String bestBlockHash = "";
  double progress = 0.0;
  bool scanning = false;
  int peercount = 0;
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
  late StreamSubscription nakamotoRunSubscription;

  final _synchronizationService = SynchronizationService();

  WalletState();

  Future<void> initialize() async {
    try {
      await _initStreams();
      await _initDir();
      await _setupNakamoto();
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

  Future<void> _setupNakamoto() async {
    while (dir == Directory("/")) {
      sleep(const Duration(milliseconds: 100));
    }
    try {
      await api.setupNakamoto(network: network, path: dir.path);
    } catch (e) {
      rethrow;
    }
    notifyListeners();
  }

  Future<void> _initStreams() async {
    logStreamSubscription = api
        .createLogStream(level: LogLevel.Info, logDependencies: true)
        .listen((event) {
      // ignore p2p messages as these are really spammy
      if (event.tag != 'p2p') {
        print('${event.level} (${event.tag}): ${event.msg}');
      }
    });

    scanProgressSubscription = api.createScanProgressStream().listen(((event) {
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

    syncStreamSubscription = api.createSyncStream().listen((event) {
      peercount = event.peerCount;
      tip = event.blockheight;
      bestBlockHash = event.bestblockhash;

      print('tip: $tip');

      notifyListeners();
    });

    amountStreamSubscription = api.createAmountStream().listen((event) {
      amount = event;
      notifyListeners();
    });

    nakamotoRunSubscription = api.createNakamotoRunStream().listen((event) {
      nakamotoIsRunning = event;
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
    _stopNakamoto();
    super.dispose();
  }

  void _stopNakamoto() {
    // api.forceInterruptNakamoto();
    // todo: check that nakamoto is properly stopped
    nakamotoRunSubscription.cancel();
  }

  Future<void> reset() async {
    amount = 0;
    birthday = 0;
    lastScan = 0;
    // tip isn't specific to wallet, needs not be reset
    progress = 0.0;
    scanning = false;
    peercount = 0;
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
      address = await api.getReceivingAddress(path: dir.path, label: label);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateWalletStatus() async {
    try {
      final wallet = await api.getWalletInfo(path: dir.path, label: label);
      amount = wallet.amount;
      birthday = wallet.birthday;
      lastScan = wallet.scanHeight;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOwnedOutputs() async {
    try {
      ownedOutputs = await api.getOutputs(path: dir.path, label: label);
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

  int outputSelectionTotalAmt() {
    final total =
        selectedOutputs.fold(0, (sum, element) => sum + element.amount);
    return total;
  }

  int recipientTotalAmt() {
    final total = recipients.fold(0, (sum, element) => sum + element.amount);
    return total;
  }

  Future<void> addRecipients(String address, int amount, int nbOutputs) async {
    final alreadyInList = recipients.where((r) => r.address == address);
    if (alreadyInList.isNotEmpty) {
      throw Exception("Address already in list");
    }

    if (nbOutputs < 1) {
      nbOutputs = 1;
    }

    if (amount <= 564) {
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

  Future<void> scanToTip() async {
    try {
      scanning = true;
      await api.scanToTip(path: dir.path, label: label);
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
