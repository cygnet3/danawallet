import 'package:flutter/material.dart';

class InputAlertWidget<T> extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType inputType;
  final String titleText;
  final String hintText;

  const InputAlertWidget(
      {super.key,
      required this.controller,
      required this.inputType,
      required this.titleText,
      required this.hintText});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titleText),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: inputType,
        decoration: InputDecoration(hintText: hintText),
        // onSubmitted: (value) {
        //   Navigator.of(context).pop(int.tryParse(value));
        // },
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog without saving
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(controller.text);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
