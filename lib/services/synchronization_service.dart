import 'dart:async';
import 'package:donationwallet/global_functions.dart';
import 'package:donationwallet/states/chain_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SynchronizationService {
  final BuildContext context;
  Timer? _timer;
  final Duration _interval = const Duration(minutes: 10);

  SynchronizationService(this.context);

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
      final chainState = Provider.of<ChainState>(context, listen: false);
      await chainState.updateChainTip();
    } catch (e) {
      displayNotification(e.toString());
    }
  }

  void stopSyncTimer() {
    _timer?.cancel();
  }
}
