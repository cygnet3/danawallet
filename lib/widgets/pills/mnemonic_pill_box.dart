import 'package:danawallet/widgets/pills/mnemonic_pill.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MnemonicPillBox extends StatelessWidget {
  final String mnemonic;

  const MnemonicPillBox({super.key, required this.mnemonic});
  @override
  Widget build(BuildContext context) {
    final words = mnemonic.split(" ");
    return SizedBox(
        height: Adaptive.h(50),
        child: GridView.count(
          crossAxisCount: 6,
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(10),
          mainAxisSpacing: Adaptive.w(2),
          crossAxisSpacing: Adaptive.h(1.5),
          childAspectRatio: 0.3,
          children: List.generate(words.length, (index) {
            return MnemonicPill(number: index + 1, word: words[index]);
          }),
        ));
  }
}
