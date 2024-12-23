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
    TextInputType inputType, String titleText, String labelText) {
  if (globalNavigatorKey.currentContext != null) {
    return showDialog<dynamic>(
        context: globalNavigatorKey.currentContext!,
        builder: (BuildContext dialogContext) {
          return InputAlertWidget(
            controller: controller,
            inputType: inputType,
            titleText: titleText,
            labelText: labelText,
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
