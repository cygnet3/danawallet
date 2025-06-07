import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:flutter/material.dart';

class FooterButtonPlain extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;

  const FooterButtonPlain({
    super.key,
    required this.title,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BitcoinButtonPlain(
      title: title,
      textStyle:
          BitcoinTextStyle.body2(Bitcoin.black).copyWith(fontFamily: 'Inter'),
      onPressed: onPressed,
      cornerRadius: 5.0,
      isLoading: isLoading,
      disabled: !enabled,
      disabledTintColor: Colors.grey,
    );
  }
}
