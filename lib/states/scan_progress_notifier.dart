import 'dart:async';

import 'package:danawallet/generated/rust/api/stream.dart';
import 'package:danawallet/generated/rust/api/wallet.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';

class ScanProgressNotifier extends ChangeNotifier {
  Completer? _completer;
  double progress = 0.0;
  int current = 0;

  late StreamSubscription scanProgressSubscription;

  bool get scanning => _completer != null && !_completer!.isCompleted;

  ScanProgressNotifier();

  Future<void> initialize() async {
    scanProgressSubscription = createScanProgressStream().listen(((event) {
      int start = event.start;
      current = event.current;
      int end = event.end;
      double scanned = (current - start).toDouble();
      double total = (end - start).toDouble();
      double progress = scanned / total;
      if (current == end) {
        deactivate();
      } else {
        this.progress = progress;

        notifyListeners();
      }
    }));
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
      final wallet = await walletState.getWalletFromSecureStorage();
      final settings = SettingsRepository();
      final blindbitUrl = await settings.getBlindbitUrl();
      final dustLimit = await settings.getDustLimit();

      activate(walletState.lastScan);
      await scanToTip(
          blindbitUrl: blindbitUrl!,
          dustLimit: BigInt.from(dustLimit!),
          encodedWallet: wallet);
    } catch (e) {
      deactivate();
      rethrow;
    }
    deactivate();
  }

  Future<void> interruptScan() async {
    if (scanning) {
      interruptScanning();

      // this makes sure the scan function has been terminated
      await _completer?.future;
    }
  }
}
