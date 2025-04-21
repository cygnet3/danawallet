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
                              'sp1q qffj 92fj dv6y jspq hlm0 6e9p 3r59 zd3s ghuw rqg2 w8vu 3v34 9pg5 sqnk 6dmf 9l9d exzq 8j0y f8jl 03xc jlmt pxly 5xns rhck 3n35 wfm zqnt y4xc')),
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
