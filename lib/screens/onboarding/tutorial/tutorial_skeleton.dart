import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/onboarding/onboarding_skeleton.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/icons/circular_icon.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TutorialSkeleton extends StatelessWidget {
  final Widget nextScreen;
  final String iconPath;
  final String title;
  final String text;
  final Widget main;
  final double step;

  const TutorialSkeleton({
    super.key,
    required this.nextScreen,
    required this.iconPath,
    required this.title,
    required this.text,
    required this.main,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            SizedBox(
              height: Adaptive.h(5),
            ),
            CircularIcon(iconPath: iconPath, iconHeight: 44, radius: 50),
            const SizedBox(
              height: 20,
            ),
            Text(
              title,
              style: BitcoinTextStyle.title2(Colors.black)
                  .copyWith(height: 1.8, fontFamily: 'Inter'),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              text,
              style: BitcoinTextStyle.body3(Bitcoin.neutral7).copyWith(
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        main,
      ],
    );

    final footer = Column(
      children: [
        const SizedBox(
          height: 40,
        ),
        DotsIndicator(
          dotsCount: 3,
          position: step,
        ),
        const SizedBox(
          height: 15,
        ),
        FooterButton(
            title: 'Next',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => nextScreen))),
      ],
    );

    return OnboardingSkeleton(body: body, footer: footer);
  }
}
