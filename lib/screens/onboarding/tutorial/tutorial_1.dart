import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/onboarding/tutorial/tutorial_2.dart';
import 'package:danawallet/screens/onboarding/tutorial/tutorial_skeleton.dart';
import 'package:flutter/material.dart';

class TutorialScreen1 extends StatelessWidget {
  const TutorialScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return TutorialSkeleton(
      step: 0,
      nextScreen: const TutorialScreen2(),
      iconPath: "assets/icons/sparkle.svg",
      title: 'Re-usable bitcoin address',
      text: 'Dana uses a new type of address that can be reused indefinitely!',
      main: Container(
        width: 372,
        height: 212,
        decoration: ShapeDecoration(
          color: Bitcoin.neutral2,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Here\'s what a reusable address looks like:',
              style: BitcoinTextStyle.body5(Bitcoin.neutral6)
                  .copyWith(fontFamily: 'Inter'),
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: addressAsRichText(exampleAddress, null)),
          ],
        ),
      ),
    );
  }
}
