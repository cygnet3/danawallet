import 'package:danawallet/widgets/input_alert_widget.dart';
import 'package:flutter/material.dart';

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

Future<String?> showInputAlertDialog(TextEditingController controller,
    TextInputType inputType, String titleText, String labelText) {
  if (globalNavigatorKey.currentContext != null) {
    return showDialog<String>(
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
