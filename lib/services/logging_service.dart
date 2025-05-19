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
