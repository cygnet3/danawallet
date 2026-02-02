import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:flutter/material.dart';

class InfoTextContainer extends StatelessWidget {
  final String infoText;

  const InfoTextContainer({super.key, required this.infoText});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: ShapeDecoration(
          color: Bitcoin.neutral2,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Text(infoText),
        ));
  }
}
