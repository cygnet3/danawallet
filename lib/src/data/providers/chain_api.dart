import 'package:donationwallet/generated/rust/api/simple.dart';

class ChainApiProvider {
  ChainApiProvider();

  Future<int> getChainTipFromApi() async {
    try {
      final tip = await syncBlockchain();
      return tip;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> scanChainFromApi(String wallet) async {
    try {
      final updatedWallet = await scanToTip(encodedWallet: wallet);
      return updatedWallet;
    } catch (e) {
      rethrow;
    }
  }
}
// class SynchronizationService {
//   Timer? _timer;
//   final Duration _interval = const Duration(minutes: 10);

//   void startSyncTimer() {
//     _scheduleNextTask();
//   }

//   void _scheduleNextTask() async {
//     _timer?.cancel();
//     await performSynchronizationTask();
//     _timer = Timer(_interval, () async {
//       _scheduleNextTask();
//     });
//   }

//   Future<void> performSynchronizationTask() async {
//     try {
//       await syncBlockchain();
//     } catch (e) {
//       displayNotification(e.toString());
//     }
//   }

//   void stopSyncTimer() {
//     _timer?.cancel();
//   }
// }
