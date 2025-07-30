import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:flutter/material.dart';

class WarningMessage extends StatelessWidget {
  final String message;

  const WarningMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding:
          const EdgeInsetsGeometry.symmetric(vertical: 30, horizontal: 20),
      backgroundColor: Colors.white,
      icon: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.orange[100],
        child: Icon(
          size: 60,
          Icons.warning_amber_rounded,
          color: Colors.orange[700],
        ),
      ),
      content: Text(
        message,
        style: BitcoinTextStyle.body4(Bitcoin.neutral7),
        textAlign: TextAlign.center,
      ),
      actions: [
        FooterButton(
          color: Colors.orange,
          title: "I understand",
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
