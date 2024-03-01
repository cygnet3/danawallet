import 'package:flutter/material.dart';

final globalNavigatorKey = GlobalKey<NavigatorState>();

void displayNotification(String text) {
  print(text);
  final snackBar = SnackBar(
    content: Text(text),
  );
  ScaffoldMessenger.of(globalNavigatorKey.currentContext!)
      .showSnackBar(snackBar);
}

void showAlertDialog(String title, String text) {
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
