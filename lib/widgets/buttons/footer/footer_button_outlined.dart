import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:flutter/material.dart';

class FooterButtonOutlined extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;

  const FooterButtonOutlined({
    super.key,
    required this.title,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BitcoinButtonOutlined(
      title: title,
      textStyle: BitcoinTextStyle.body2(Bitcoin.black),
      onPressed: onPressed,
      cornerRadius: 5.0,
      tintColor: Bitcoin.neutral5,
      isLoading: isLoading,
      disabled: !enabled,
      // note: disabled color doesn't seem to work
      disabledTintColor: Colors.grey,
    );
  }
}
