import 'package:auto_size_text/auto_size_text.dart';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MnemonicPill extends StatelessWidget {
  final int number;
  final String word;

  const MnemonicPill({super.key, required this.number, required this.word});

  @override
  Widget build(BuildContext context) {
    final pillHeight = Adaptive.h(6);
    return Row(
      children: [
        Flexible(
            child: Container(
          height: pillHeight,
          decoration: BoxDecoration(
            // border: Border.all(color: Bitcoin.black),
            color: Bitcoin.neutral3,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              bottomLeft: Radius.circular(30),
            ),
          ),
          child: Center(
              child: Text(number.toString(),
                  style: BitcoinTextStyle.title5(Bitcoin.black))),
        )),
        SizedBox(width: Adaptive.w(1)),
        Flexible(
            flex: 3,
            child: Container(
                height: pillHeight,
                decoration: BoxDecoration(
                  // border: Border.all(color: Bitcoin.black),
                  color: Bitcoin.neutral3,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Center(
                  child: AutoSizeText(word,
                      style: BitcoinTextStyle.body3(Bitcoin.black)),
                ))),
      ],
    );
  }
}
