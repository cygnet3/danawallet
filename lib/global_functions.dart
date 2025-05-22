import 'dart:math';

import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/widgets/confirmation_widget.dart';
import 'package:danawallet/widgets/input_alert_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

final globalNavigatorKey = GlobalKey<NavigatorState>();

void displayNotification(String text) {
  // ignore: avoid_print
  print(text);
  if (globalNavigatorKey.currentContext != null) {
    final snackBar = SnackBar(
      content: Text(text),
    );
    ScaffoldMessenger.of(globalNavigatorKey.currentContext!)
        .showSnackBar(snackBar);
  }
}

void showAlertDialog(String title, String text) {
  if (globalNavigatorKey.currentContext != null) {
    showDialog(
      context: globalNavigatorKey.currentContext!,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: SelectableText(text),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

Future<dynamic> showInputAlertDialog(TextEditingController controller,
    TextInputType inputType, String titleText, String labelText,
    {bool showReset = true}) {
  if (globalNavigatorKey.currentContext != null) {
    return showDialog<dynamic>(
        context: globalNavigatorKey.currentContext!,
        builder: (BuildContext dialogContext) {
          return InputAlertWidget(
            controller: controller,
            inputType: inputType,
            titleText: titleText,
            labelText: labelText,
            showReset: showReset,
          );
        });
  } else {
    return Future.value(null);
  }
}

Future<bool> showConfirmationAlertDialog(
    String titleText, String labelText) async {
  if (globalNavigatorKey.currentContext != null) {
    final res = await showDialog<bool>(
        context: globalNavigatorKey.currentContext!,
        builder: (BuildContext dialogContext) {
          return ConfirmationWidget(
            titleText: titleText,
            labelText: labelText,
          );
        });

    return res ?? false;
  } else {
    return Future.value(false);
  }
}

String exceptionToString(Object e) {
  String message;
  if (e is AnyhowException) {
    // remove stack trace from anyhow exception
    message = e.message.split('\n').first;
  } else {
    message = e.toString();
  }
  return message;
}

RichText addressAsRichText(String address, double? fontSize) {
  // split the address into chunks of size 4
  List<String> chunks = [];

  // if there is overflow, we add it to the first chunk
  int overflow = address.length % 4;
  chunks.add(address.substring(0, 4 + overflow));

  for (int i = 4 + overflow; i < address.length; i += 4) {
    int endIndex = min(i + 4, address.length);
    chunks.add(address.substring(i, endIndex));
  }

  String first = chunks.removeAt(0);

  List<TextSpan> spans = List.empty(growable: true);
  for (final (i, chunk) in chunks.indexed) {
    spans.add(TextSpan(
        text: '$chunk ',
        style: BitcoinTextStyle.body5(
                i % 2 == 0 ? Bitcoin.neutral8 : Bitcoin.neutral6)
            .copyWith(
                fontSize: fontSize,
                fontFamily: 'Inter',
                letterSpacing: 2,
                height: 2)));
  }

  return RichText(
    text: TextSpan(
        text: '$first ',
        style: BitcoinTextStyle.body5(Bitcoin.blue).copyWith(
            fontSize: fontSize,
            fontFamily: 'Inter',
            letterSpacing: 2,
            height: 2),
        children: spans),
    textAlign: TextAlign.justify,
  );
}

String displayAddress(BuildContext context, String address, TextStyle style,
    double widthFraction) {
  // split the address into chunks of size 4
  List<String> addrChunks = [];

  // if there is overflow, we add it to the first chunk
  int overflow = address.length % 4;
  addrChunks.add(address.substring(0, 4 + overflow));

  for (int i = 4 + overflow; i < address.length; i += 4) {
    int endIndex = min(i + 4, address.length);
    addrChunks.add(address.substring(i, endIndex));
  }

  // we take a fraction of the total screen width
  // this is the maximum size the address widget is allowed to be
  final maxWidth = MediaQuery.of(context).size.width * widthFraction;

  final chunkCount = _getChunkFittingWidth(addrChunks, style, maxWidth);

  // if all chunks fit, print everything
  if (addrChunks.length <= chunkCount) {
    return addrChunks.join(' ');
  }

  int firstHalfLength = ((chunkCount - 3).toDouble() / 2.0).ceil();
  int secondHalfLength = chunkCount - 3 - (firstHalfLength * 2);

  String firstHalfStr = addrChunks.sublist(0, firstHalfLength).join(' ');
  String secondHalfStr = addrChunks
      .sublist(addrChunks.length - firstHalfLength - secondHalfLength)
      .join(' ');

  return '$firstHalfStr  ...  $secondHalfStr';
}

int _getChunkFittingWidth(List<String> chunks, TextStyle style, double width) {
  final TextPainter textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
  );

  int low = 1;
  int high = chunks.length;
  int best = 0;

  // we do a binary search to find the max number of chunks that fit within 'width'
  while (low <= high) {
    int mid = (low + high) ~/ 2;
    String subset = chunks.getRange(0, mid).join(' ');

    textPainter.text = TextSpan(text: subset, style: style);
    textPainter.layout();

    if (textPainter.width <= width) {
      best = mid;
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }

  return best;
}

bool isDevEnv() {
  return const String.fromEnvironment('FLUTTER_APP_FLAVOR') == 'dev';
}
