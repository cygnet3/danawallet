import 'dart:async';
import 'package:donationwallet/global_functions.dart';
import 'package:donationwallet/rust/api/wallet.dart';

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
