import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:flutter/material.dart';

class FooterButtonOutlined extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;

  const FooterButtonOutlined(
      {super.key, required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return BitcoinButtonOutlined(
      title: title,
      textStyle: BitcoinTextStyle.body2(Bitcoin.black),
      onPressed: onPressed,
      cornerRadius: 5.0,
      tintColor: Bitcoin.neutral5,
    );
  }
}
