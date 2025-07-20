import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MnemonicInputPill extends StatelessWidget {
  final int number;
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String)? onSubmitted;

  const MnemonicInputPill(
      {super.key,
      required this.number,
      required this.controller,
      this.onSubmitted,
      required this.focusNode});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Adaptive.h(6), // Define a fixed height
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
              child: Container(
            decoration: BoxDecoration(
                color: Bitcoin.neutral3,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                )),
            child: Center(
                child:
                    Text("$number", style: BitcoinTextStyle.title3(Bitcoin.black)
                        // .copyWith(fontFamily: "Inter"),
                        )),
          )),
          const SizedBox(width: 5.0),
          Flexible(
              flex: 3,
              child: Container(
                  decoration: BoxDecoration(
                      // border: Border.all(color: Bitcoin.black),
                      color: Bitcoin.neutral2,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      )),
                  child: Center(
                    child: TextField(
                      controller: controller,
                      onSubmitted: onSubmitted,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 15.0),
                        hintText: 'word',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  ))),
        ],
      ),
    );
  }
}
