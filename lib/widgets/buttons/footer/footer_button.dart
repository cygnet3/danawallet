import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:flutter/material.dart';

class FooterButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool enabled;

  const FooterButton(
      {super.key,
      required this.title,
      required this.onPressed,
      this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return BitcoinButtonFilled(
      body: Text(
        title,
        style: BitcoinTextStyle.body2(Bitcoin.neutral1),
      ),
      onPressed: onPressed,
      cornerRadius: 5.0,
      tintColor: const Color.fromARGB(255, 10, 109, 214),
      disabledTintColor: Colors.grey,
      disabled: !enabled,
      
    );
  }
}
