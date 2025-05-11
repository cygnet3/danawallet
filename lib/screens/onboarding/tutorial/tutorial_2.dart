import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/onboarding/tutorial/tutorial_3.dart';
import 'package:danawallet/screens/onboarding/tutorial/tutorial_skeleton.dart';
import 'package:danawallet/widgets/icons/circular_icon.dart';
import 'package:flutter/material.dart';

class TutorialScreen2 extends StatelessWidget {
  const TutorialScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return TutorialSkeleton(
        step: 1,
        nextScreen: const TutorialScreen3(),
        iconPath: "assets/icons/contact.svg",
        title: 'Contacts',
        text:
            'Easily store & send to bitcoin addresses of people you want to send to.',
        main: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Container(
                  width: 372,
                  height: 184,
                  decoration: ShapeDecoration(
                    color: Bitcoin.neutral2,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: addressAsRichText(
                              'sp1q q0cy gnet gn3r z2kl a5cp 05nj 5uet lsrz ez0l 4p8g 7weh f7ld r93l cqad w65u pymw zvp5 ed38 l8ur 2rzn d693 4xh9 5mse vwrd wtrp k372 hyz4 vr6g')),
                    ],
                  ),
                )),
            const CircularIcon(
                iconPath: "assets/icons/contact.svg",
                iconHeight: 30,
                radius: 30),
          ],
        ));
  }
}
