import 'dart:async';
import 'dart:io';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/scheduler.dart';
import 'package:logger/logger.dart';

class SynchronizationService {
  WalletState walletState;
  ChainState chainState;
  ScanProgressNotifier scanProgress;

  Timer? _timer;
  final Duration _interval = const Duration(seconds: 10);

  SynchronizationService(
      {required this.chainState,
      required this.walletState,
      required this.scanProgress});

  Future<void> startSyncTimer() async {
    // for the first task, we just received the chain tip so skip it
    Logger().i("Starting sync service");
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
    Exception? err;
    if (updateChainTip) {
      try {
        await _performChainUpdateTask();
      } on Exception catch (e) {
        // todo: we should have a connection status with the server
        // e.g. a green or red circle based on whether we have connection issues
        Logger().w("Error trying to update the chain tip");
        err = e;
      }
    }
    if (err == null) {
      try {
        await _performSynchronizationTask();
      } catch (e) {
        displayNotification(exceptionToString(e));
      }
    }
  }

  Future<void> _scheduleNextTask() async {
    _timer = Timer(_interval, () async {
      await _tryPerformTask(true);
      _scheduleNextTask();
    });
  }

  Future<void> _performChainUpdateTask() async {
    await chainState.updateChainTip();
  }

  Future<void> _performSynchronizationTask() async {
    if (!chainState.initiated) {
      Logger().w('Cannot perform sync: chain state not initialized');
      return;
    }

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
    Logger().i("Stopping sync service");
    _timer?.cancel();
  }
}
