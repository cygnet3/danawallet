import 'package:danawallet/widgets/pills/mnemonic_input_pill.dart';
import 'package:flutter/widgets.dart';
import 'package:sizer/sizer.dart';

class MnemonicInputPillBox extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String)? onFinalSubmit;

  const MnemonicInputPillBox(
      {super.key,
      required this.controllers,
      required this.focusNodes,
      this.onFinalSubmit});

  String get mnemonic => controllers.map((element) => element.text).join(" ");

  @override
  Widget build(BuildContext context) {
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
          children: List.generate(12, (index) {
            onSubmitted(value) => focusNodes[index + 1].requestFocus();

            return MnemonicInputPill(
              number: index + 1,
              controller: controllers[index],
              focusNode: focusNodes[index],
              onSubmitted: (index == 11) ? onFinalSubmit : onSubmitted,
            );
          }),
        ));
  }
}
