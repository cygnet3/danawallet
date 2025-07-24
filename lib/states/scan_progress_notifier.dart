import 'dart:async';

import 'package:danawallet/constants.dart';
import 'package:danawallet/generated/rust/api/stream.dart';
import 'package:danawallet/generated/rust/api/wallet.dart';
import 'package:danawallet/repositories/contact_dao.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ScanProgressNotifier extends ChangeNotifier {
  Completer? _completer;
  double progress = 0.0;
  int current = 0;

  late StreamSubscription scanProgressSubscription;

  bool get scanning => _completer != null && !_completer!.isCompleted;

  // private constructor
  ScanProgressNotifier._();

  Future<void> _initialize() async {
    scanProgressSubscription = createScanProgressStream().listen(((event) {
      int start = event.start;
      current = event.current;
      int end = event.end;
      double scanned = (current - start).toDouble();
      double total = (end - start).toDouble();
      double progress = scanned / total;
      if (current != end) {
        this.progress = progress;

        notifyListeners();
      }
    }));
  }

  static Future<ScanProgressNotifier> create() async {
    final instance = ScanProgressNotifier._();
    await instance._initialize();
    return instance;
  }

  @override
  void dispose() {
    scanProgressSubscription.cancel();
    super.dispose();
  }

  void activate(int start) {
    _completer = Completer();
    progress = 0.0;
    current = start;
    notifyListeners();
  }

  void deactivate() {
    _completer?.complete();
    progress = 0.0;
    notifyListeners();
  }

  Future<void> scan(WalletState walletState) async {
    try {
      final wallet = walletState.wallet;
      final settings = SettingsRepository.instance;
      final blindbitUrl = await settings.getBlindbitUrl();
      final dustLimit = await settings.getDustLimit();

      final lastScan = walletState.lastScan;

      final ownedOutPoints =
          walletState.ownedOutputs.getUnconfirmedSpentOutpoints();

      // Load all the accounts that exists in the db
      final contactDao = ContactDAO();
      final userContact = contactDao.getUserContact();

      final nbAccounts = userContact.addresses.length;

      for (int i = 1; i < nbAccounts; i++) {
        final _ = wallet.getSilentPaymentAddressForIndex(index: i);
        Logger().d('Registered account at index $i');
      }

      activate(walletState.lastScan);
      await wallet.scanToTip(
          blindbitUrl: blindbitUrl!,
          dustLimit: BigInt.from(dustLimit!),
          ownedOutpoints: ownedOutPoints,
          lastScan: lastScan);
    } catch (e) {
      deactivate();
      rethrow;
    }
    deactivate();
  }

  Future<void> interruptScan() async {
    if (scanning) {
      SpWallet.interruptScanning();

      // this makes sure the scan function has been terminated
      await _completer?.future;
    }
  }
}
