import 'dart:async';

import 'package:danawallet/generated/rust/api/stream.dart';
import 'package:danawallet/generated/rust/logger.dart';

class LoggingService {
  late StreamSubscription logStreamSubscription;

  // private constructor
  LoggingService._();

  Future<void> _initialize() async {
    logStreamSubscription =
        createLogStream(level: LogLevel.info, logDependencies: true)
            .listen((event) {
      // ignore: avoid_print
      print('${event.level} (${event.tag}): ${event.msg}');
    });
  }

  static Future<LoggingService> create() async {
    final service = LoggingService._();
    await service._initialize();
    return service;
  }
}
