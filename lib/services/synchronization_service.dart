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
    // for the first task, we just received the chain tip so skip it
    _scheduleNextTask(false);
  }

  void _scheduleNextTask(bool updateChainTip) async {
    try {
      if (updateChainTip) {
        await performChainUpdateTask();
      }
      await performSynchronizationTask();
    } catch (e) {
      displayNotification(exceptionToString(e));
    }

    // for next tasks, also update the chain tip
    _timer = Timer(_interval, () async {
      _scheduleNextTask(true);
    });
  }

  Future<void> performChainUpdateTask() async {
    final chainState = Provider.of<ChainState>(context, listen: false);
    await chainState.updateChainTip();
  }

  Future<void> performSynchronizationTask() async {
    Logger().i("Performing sync task");
    final chainState = Provider.of<ChainState>(context, listen: false);
    final walletState = Provider.of<WalletState>(context, listen: false);
    final scanProgress =
        Provider.of<ScanProgressNotifier>(context, listen: false);

    if (walletState.lastScan < chainState.tip) {
      if (!scanProgress.scanning) {
        await scanProgress.scan(walletState);
      }
    }

    if (chainState.tip < walletState.lastScan) {
      // not sure what we should do here, that's really bad
      Logger().e('Current height is less than wallet last scan');
    }
  }

  void stopSyncTimer() {
    _timer?.cancel();
  }
}
