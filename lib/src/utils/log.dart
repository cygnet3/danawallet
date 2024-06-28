import 'dart:async';
import 'package:donationwallet/generated/rust/api/simple.dart';
import 'package:donationwallet/generated/rust/logger.dart';

class LogStreamService {
  // Singleton instance
  static final LogStreamService _instance = LogStreamService._internal();

  factory LogStreamService() {
    return _instance;
  }

  LogStreamService._internal() {
    _initializeLogStream();
  }

  // Stream controller for log entries
  final StreamController<LogEntry> _logStreamController = StreamController<LogEntry>.broadcast();

  // Stream getter
  Stream<LogEntry> get logStream => _logStreamController.stream;

  // Initialize the log stream
  void _initializeLogStream() {
    createLogStream(level: LogLevel.debug, logDependencies: true);
  }

  // Dispose the stream controller
  void dispose() {
    _logStreamController.close();
  }
}
