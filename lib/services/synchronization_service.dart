import 'dart:async';
import 'dart:io';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class SynchronizationService {
  final BuildContext context;
  Timer? _timer;
  final Duration _interval = const Duration(seconds: 10);

  SynchronizationService(this.context);

  Future<void> startSyncTimer() async {
    // for the first task, we just received the chain tip so skip it
    await _tryPerformTask(false);
    await _scheduleNextTask();
  }

  Future<void> _tryPerformTask(bool updateChainTip) async {
    if (Platform.isAndroid) {
      final appState = SchedulerBinding.instance.lifecycleState;

      if (appState == AppLifecycleState.resumed) {
        // only sync on android if app is in foreground
        await _performTask(updateChainTip);
      } else {
        // todo: claim the wifi lock, so that we have internet access
        // to sync, even when the screen is off
        Logger().i("We are in background, skip sync");
      }
    } else {
      // for other platforms, we assume we always want to sync
      // todo: probably requires similar flow for iOS
      await _performTask(updateChainTip);
    }
  }

  Future<void> _performTask(bool updateChainTip) async {
    try {
      if (updateChainTip) {
        await performChainUpdateTask();
      }
      await performSynchronizationTask();
    } catch (e) {
      displayNotification(exceptionToString(e));
    }
  }

  Future<void> _scheduleNextTask() async {
    _timer = Timer(_interval, () async {
      await _tryPerformTask(true);
      _scheduleNextTask();
    });
  }

  Future<void> performChainUpdateTask() async {
    final chainState = Provider.of<ChainState>(context, listen: false);
    await chainState.updateChainTip();
  }

  Future<void> performSynchronizationTask() async {
    final chainState = Provider.of<ChainState>(context, listen: false);
    final walletState = Provider.of<WalletState>(context, listen: false);
    final scanProgress =
        Provider.of<ScanProgressNotifier>(context, listen: false);

    if (walletState.lastScan < chainState.tip) {
      if (!scanProgress.scanning) {
        Logger().i("Starting sync");
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
