import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
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
        iconPath: "assets/icons/address-book.svg",
        iconHeight: 55,
        title: 'Address book',
        text: 'Save bitcoin addresses as contacts.',
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
                          child: addressAsRichText(exampleAddress, null)),
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
