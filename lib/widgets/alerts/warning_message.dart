import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/enums/warning_type.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:flutter/material.dart';

class WarningMessage extends StatelessWidget {
  final String message;
  final WarningType type;

  const WarningMessage({super.key, required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding:
          const EdgeInsetsGeometry.symmetric(vertical: 30, horizontal: 20),
      backgroundColor: Colors.white,
      icon: CircleAvatar(
        radius: 50,
        backgroundColor: type.backgroundColor,
        child: Icon(size: 60, type.icon, color: type.toColor),
      ),
      content: Text(
        message,
        style: BitcoinTextStyle.body4(Bitcoin.neutral7),
        textAlign: TextAlign.center,
      ),
      actions: [
        FooterButton(
          color: type.toColor,
          title: "I understand",
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
