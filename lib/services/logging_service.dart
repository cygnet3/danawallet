import 'dart:async';

import 'package:danawallet/generated/rust/api/stream.dart';
import 'package:danawallet/generated/rust/logger.dart';

class LoggingService {
  late StreamSubscription logStreamSubscription;

  LoggingService();

  Future<void> initialize() async {
    logStreamSubscription =
        createLogStream(level: LogLevel.info, logDependencies: true)
            .listen((event) {
      // ignore: avoid_print
      print('${event.level} (${event.tag}): ${event.msg}');
    });
  }
}
