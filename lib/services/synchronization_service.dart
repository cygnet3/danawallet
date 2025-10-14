import 'dart:async';
import 'dart:io';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/fiat_exchange_rate_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/scheduler.dart';
import 'package:logger/logger.dart';

class SynchronizationService {
  WalletState walletState;
  ChainState chainState;
  FiatExchangeRateState fiatExchangeRateState;
  ScanProgressNotifier scanProgress;

  Timer? _timer;
  final Duration _interval = const Duration(seconds: 10);
  
  // Different intervals for different data types
  static const Duration _exchangeRateInterval = Duration(minutes: 10);
  static const Duration _networkFeesInterval = Duration(minutes: 2);
  
  // Track last update times
  DateTime? _lastExchangeRateUpdate;
  DateTime? _lastNetworkFeesUpdate;

  SynchronizationService(
      {required this.chainState,
      required this.walletState,
      required this.fiatExchangeRateState,
      required this.scanProgress});

  Future<void> startSyncTimer(bool immediate) async {
    Logger().i("Starting sync service");

    if (immediate) {
      _tryPerformTask();
    }
    await _scheduleNextTask();
  }

  Future<void> _tryPerformTask() async {
    if (Platform.isAndroid) {
      final appState = SchedulerBinding.instance.lifecycleState;

      if (appState == AppLifecycleState.resumed) {
        // only sync on android if app is in foreground
        await _performTask();
      } else {
        // todo: claim the wifi lock, so that we have internet access
        // to sync, even when the screen is off
        Logger().i("We are in background, skip sync");
      }
    } else {
      // for other platforms, we assume we always want to sync
      // todo: probably requires similar flow for iOS
      await _performTask();
    }
  }

  Future<void> _performTask() async {
    try {
      if (!chainState.available) {
        //attempt to reconnect to the chain state
        if (!await chainState.reconnect()) {
          return;
        }
      }

      // fetch new tip before syncing
      await chainState.updateChainTip();
      await _performSynchronizationTask();
    } on Exception catch (e) {
      // todo: we should have a connection status with the server
      // e.g. a green or red circle based on whether we have connection issues
      Logger().e("Error performing sync task: $e");
      displayNotification(exceptionToString(e));
    }
    
    // Perform periodic updates for other data types
    await _updateExchangeRateIfNeeded();
    await _updateNetworkFeesIfNeeded();

    // if one or more services are not available, force update on all services to keep consistency
    if (!chainState.available || fiatExchangeRateState.exchangeRate == null || walletState.currentFeesEstimation == null) {
      await fiatExchangeRateState.updateExchangeRate();
      await walletState.updateNetworkFees();
      await chainState.updateChainTip();
    }
  }

  Future<void> _scheduleNextTask() async {
    _timer = Timer(_interval, () async {
      await _tryPerformTask();
      if (chainState.initiated) {
        _scheduleNextTask();
      }
    });
  }

  Future<void> _performSynchronizationTask() async {
    if (walletState.lastScan < chainState.tip) {
      if (!scanProgress.scanning) {
        Logger().i("Starting sync");
        await scanProgress.scan(walletState);
      }
    } else if (chainState.tip < walletState.lastScan) {
      // not sure what we should do here, that's really bad
      Logger().e('Current height is less than wallet last scan');
    }
  }

  /// Updates exchange rate if enough time has passed since last update
  Future<void> _updateExchangeRateIfNeeded() async {
    final now = DateTime.now();
    if (_lastExchangeRateUpdate == null || 
        now.difference(_lastExchangeRateUpdate!) > _exchangeRateInterval) {
      try {
        await fiatExchangeRateState.updateExchangeRate();
        _lastExchangeRateUpdate = now;
        Logger().d("Updated exchange rate via sync service");
      } catch (e) {
        Logger().w('Failed to update exchange rate in sync service: $e');
      }
    }
  }

  /// Updates network fees estimation if enough time has passed since last update
  Future<void> _updateNetworkFeesIfNeeded() async {
    final now = DateTime.now();
    if (_lastNetworkFeesUpdate == null || 
        now.difference(_lastNetworkFeesUpdate!) > _networkFeesInterval) {
      try {
        await walletState.updateNetworkFees();
        _lastNetworkFeesUpdate = now;
        Logger().d("Updated network fees via sync service");
      } catch (e) {
        Logger().w('Failed to update network fees in sync service: $e');
      }
    }
  }

  void stopSyncTimer() {
    Logger().i("Stopping sync service");
    _timer?.cancel();
  }
}
