import 'package:danawallet/widgets/pills/mnemonic_pill.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MnemonicPillBox extends StatelessWidget {
  final String mnemonic;

  const MnemonicPillBox({super.key, required this.mnemonic});
  @override
  Widget build(BuildContext context) {
    final words = mnemonic.split(" ");

    const crossAxisCount = 2; // Assume we don't want more for larger screens

    final wordsPerColumn = (words.length / crossAxisCount).ceil();

    return Row(
      children: List.generate(crossAxisCount, (columnIndex) {
        return Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevent infinite height
            children: List.generate(wordsPerColumn, (rowIndex) {
              final wordIndex = columnIndex * wordsPerColumn + rowIndex;
              if (wordIndex >= words.length) {
                return const SizedBox
                    .shrink(); // Empty space for incomplete columns
              }
              return Padding(
                padding: EdgeInsets.only(bottom: Adaptive.h(1.5)),
                child:
                    MnemonicPill(number: wordIndex + 1, word: words[wordIndex]),
              );
            }),
          ),
        );
      }),
    );
  }
}
