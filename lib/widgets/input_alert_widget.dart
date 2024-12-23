import 'package:flutter/material.dart';

class InputAlertWidget<T> extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType inputType;
  final String titleText;
  final String labelText;

  const InputAlertWidget(
      {super.key,
      required this.controller,
      required this.inputType,
      required this.titleText,
      required this.labelText});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titleText),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: inputType,
        decoration: InputDecoration(labelText: labelText),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true); // bool indicates we pressed reset
          },
          child: const Text('Reset to default'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null); // Close the dialog without saving
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isEmpty) {
              // return null if no input
              Navigator.of(context).pop(null);
            }
            // base return type on keyboard type
            else if (inputType == TextInputType.number) {
              Navigator.of(context).pop(int.tryParse(controller.text));
            } else {
              Navigator.of(context).pop(controller.text);
            }
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
