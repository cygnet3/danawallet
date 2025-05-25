import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/onboarding/get_started.dart';
import 'package:danawallet/screens/onboarding/tutorial/tutorial_skeleton.dart';
import 'package:flutter/material.dart';

class TutorialScreen3 extends StatelessWidget {
  const TutorialScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return const TutorialSkeleton(
      step: 2,
      nextScreen: GetStartedScreen(),
      iconPath: "assets/icons/boxes.svg",
      title: 'Stay organized',
      text: 'Keep things organized with dedicated addresses.',
      main: SizedBox(),
      // main: Container(
      //   width: 372,
      //   height: 261,
      //   decoration: ShapeDecoration(
      //     color: Bitcoin.neutral2,
      //     shape: const RoundedRectangleBorder(
      //         borderRadius: BorderRadius.all(Radius.circular(10))),
      //   ),
      //   child: const Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: [
      //       Padding(
      //           padding: EdgeInsets.symmetric(horizontal: 20), child: Text('')),
      //     ],
      //   ),
      // ),
    );
  }
}
