import 'dart:async';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class SynchronizationService {
  final BuildContext context;
  Timer? _timer;
  final Duration _interval = const Duration(seconds: 10);

  SynchronizationService(this.context);

  void startSyncTimer() {
    _scheduleNextTask();
  }

  void _scheduleNextTask() async {
    _timer = Timer(_interval, () async {
      await performSynchronizationTask();
      _scheduleNextTask();
    });
  }

  Future<void> performSynchronizationTask() async {
    Logger().i("Performing sync task");
    try {
      final chainState = Provider.of<ChainState>(context, listen: false);
      final walletState = Provider.of<WalletState>(context, listen: false);
      final scanProgress =
          Provider.of<ScanProgressNotifier>(context, listen: false);
      
      await chainState.updateChainTip();

      if (walletState.lastScan < chainState.tip) {
        if (!scanProgress.scanning) {
          await scanProgress.scan(walletState);
        }
      }

      if (chainState.tip < walletState.lastScan) {
        // not sure what we should do here, that's really bad
        Logger().e('Current height is less than wallet last scan');
      }
    } catch (e) {
      displayNotification(exceptionToString(e));
    }
  }

  void stopSyncTimer() {
    _timer?.cancel();
  }
}
