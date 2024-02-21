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
