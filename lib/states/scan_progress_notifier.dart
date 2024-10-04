import 'dart:async';

import 'package:danawallet/generated/rust/api/stream.dart';
import 'package:flutter/material.dart';

class ScanProgressNotifier extends ChangeNotifier {
  bool scanning = false;
  double progress = 0.0;
  int current = 0;

  late StreamSubscription scanProgressSubscription;

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
        progress = 0.0;
        scanning = false;
      }
      this.progress = progress;

      notifyListeners();
    }));
  }

  @override
  void dispose() {
    scanProgressSubscription.cancel();
    super.dispose();
  }

  void activate(int start) {
    scanning = true;
    progress = 0.0;
    current = start;
    notifyListeners();
  }

  void deactivate() {
    scanning = false;
    notifyListeners();
  }
}
