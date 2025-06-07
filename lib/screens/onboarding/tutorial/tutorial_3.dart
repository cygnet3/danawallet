import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/onboarding/tutorial/tutorial_skeleton.dart';
import 'package:flutter/material.dart';

class TutorialScreen3 extends StatelessWidget {
  const TutorialScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    // final example = TxHistory.exampleHistory();

    // final height = Adaptive.h(27);
    // final history = LimitedBox(
    //     maxHeight: height,
    //     child: TransactionHistoryWidget(
    //         transactions: example.toApiTransactions()));

    return TutorialSkeleton(
      step: 2,
      iconPath: "assets/icons/boxes.svg",
      title: 'Stay organized',
      text: 'Keep things organized with dedicated addresses.',
      // main: history,
      main: Container(
        decoration: ShapeDecoration(
          color: Bitcoin.neutral2,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 10),
            //     child: history),
          ],
        ),
      ),
    );
  }
}
