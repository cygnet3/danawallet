import 'dart:async';
import 'package:donationwallet/generated/rust/api/simple.dart';
import 'package:donationwallet/generated/rust/stream.dart';

class ScanProgressService {
  // Singleton instance
  static final ScanProgressService _instance = ScanProgressService._internal();

  factory ScanProgressService() {
    return _instance;
  }

  ScanProgressService._internal() {
    _initializeScanProgressStream();
  }

  // Stream controller for scan progress updates
  final StreamController<ScanProgress> _scanProgressStreamController = StreamController<ScanProgress>.broadcast();

  // Stream getter
  Stream<ScanProgress> get scanProgressStream => _scanProgressStreamController.stream;

  // Initialize the scan progress stream
  void _initializeScanProgressStream() {
    createScanProgressStream();
  }

  // Dispose the stream controller
  void dispose() {
    _scanProgressStreamController.close();
  }
}
