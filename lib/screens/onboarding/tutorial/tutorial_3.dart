import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/onboarding/get_started.dart';
import 'package:danawallet/screens/onboarding/tutorial/tutorial_skeleton.dart';
import 'package:flutter/material.dart';

class TutorialScreen3 extends StatelessWidget {
  const TutorialScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return TutorialSkeleton(
      step: 2,
      nextScreen: const GetStartedScreen(),
      iconPath: "assets/icons/tag.svg",
      title: 'Auto-apply labels',
      text:
          'When you add labels to your address before sharing, those labels get auto-applied to every payment you receive at that labelled address!',
      main: Container(
        width: 372,
        height: 261,
        decoration: ShapeDecoration(
          color: Bitcoin.neutral2,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('history')),
          ],
        ),
      ),
    );
  }
}
