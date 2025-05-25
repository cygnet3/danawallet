import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/generated/rust/api/history.dart';
import 'package:danawallet/screens/onboarding/get_started.dart';
import 'package:danawallet/screens/onboarding/tutorial/tutorial_skeleton.dart';
import 'package:danawallet/widgets/transaction_history.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TutorialScreen3 extends StatelessWidget {
  const TutorialScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    final example = TxHistory.exampleHistory();

    final height = Adaptive.h(27);
    final history = LimitedBox(
        maxHeight: height,
        child: TransactionHistoryWidget(
            transactions: example.toApiTransactions()));

    return TutorialSkeleton(
      step: 2,
      nextScreen: const GetStartedScreen(),
      iconPath: "assets/icons/boxes.svg",
      title: 'Stay organized',
      text: 'Keep things organized with dedicated addresses.',
      // main: history,
      main: Container(
        // width: 372,
        // height: 261,
        decoration: ShapeDecoration(
          color: Bitcoin.neutral2,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: history),
          ],
        ),
      ),
    );
  }
}
