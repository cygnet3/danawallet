import 'dart:async';

import 'package:danawallet/generated/rust/api/stream.dart';
import 'package:danawallet/generated/rust/logger.dart';
import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(
    methodCount: 1,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.none,
  ),
);

class LoggingService {
  late StreamSubscription logStreamSubscription;

  // private constructor
  LoggingService._();

  Future<void> _initialize() async {
    logStreamSubscription =
        createLogStream(level: LogLevel.info, logDependencies: true)
            .listen((event) {
      String msg = '(${event.tag}): ${event.msg}';
      switch (event.level) {
        case LogLevel.debug:
          logger.d(msg);
          break;
        case LogLevel.error:
          logger.e(msg);
          break;
        case LogLevel.info:
          logger.i(msg);
          break;
        case LogLevel.off:
          break;
        case LogLevel.trace:
          logger.t(msg);
          break;
        case LogLevel.warn:
          logger.w(msg);
          break;
      }
    });
  }

  static Future<LoggingService> create() async {
    final service = LoggingService._();
    await service._initialize();
    return service;
  }
}
