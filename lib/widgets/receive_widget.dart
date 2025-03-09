import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:flutter/material.dart';

class ReceiveWidget extends StatelessWidget {
  final void Function()? onPressed;

  const ReceiveWidget({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor:
              WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          fixedSize: const WidgetStatePropertyAll(Size(46, 46)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          enableFeedback: true,
        ),
        onPressed: onPressed,
        child: Image(
            color: Bitcoin.white,
            image:
                const AssetImage("icons/receive.png", package: "bitcoin_ui")));
  }
}
