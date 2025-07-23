import 'package:danawallet/widgets/pills/mnemonic_input_pill.dart';
import 'package:flutter/widgets.dart';
import 'package:sizer/sizer.dart';

class MnemonicInputPillBox extends StatelessWidget {
  final List<String> validWords;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  const MnemonicInputPillBox(
      {super.key,
      required this.controllers,
      required this.focusNodes,
      required this.validWords});

  String get mnemonic => controllers.map((element) => element.text).join(" ");

  @override
  Widget build(BuildContext context) {
    const crossAxisCount = 2; // 2 columns for better mobile layout
    final wordsPerColumn = (controllers.length / crossAxisCount).ceil();

    return SingleChildScrollView(
        child: Row(
      children: List.generate(crossAxisCount, (columnIndex) {
        return Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevent infinite height
            children: List.generate(wordsPerColumn, (rowIndex) {
              final wordIndex = columnIndex * wordsPerColumn + rowIndex;
              if (wordIndex >= controllers.length) {
                return const SizedBox
                    .shrink(); // Empty space for incomplete columns
              }

              onSubmitted() => (wordIndex < 11)
                  ? focusNodes[wordIndex + 1].requestFocus()
                  // last input field simply unfocuses
                  : focusNodes[11].unfocus();

              return Padding(
                padding: EdgeInsets.only(bottom: Adaptive.h(1.5)),
                child: MnemonicInputPill(
                    validWords: validWords,
                    number: wordIndex + 1,
                    controller: controllers[wordIndex],
                    focusNode: focusNodes[wordIndex],
                    onSubmitted: onSubmitted),
              );
            }),
          ),
        );
      }),
    ));
  }
}
