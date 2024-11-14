import 'package:flutter/material.dart';

class ConfirmationWidget extends StatelessWidget {
  final String titleText;
  final String labelText;

  const ConfirmationWidget(
      {super.key, required this.titleText, required this.labelText});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titleText),
      content: Text(labelText),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
