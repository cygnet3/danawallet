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
  final double iconHeight;
  final String? leftIconPath;
  final String? rightIconPath;
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
    this.leftIconPath,
    this.rightIconPath,
    this.iconHeight = 44,
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
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CircularIcon(
                    iconPath: iconPath, iconHeight: iconHeight, radius: 50),
                if (leftIconPath != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 100),
                    child: CircularIcon(
                        iconPath: leftIconPath!, iconHeight: 22, radius: 25),
                  ),
                if (rightIconPath != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 100),
                    child: CircularIcon(
                        iconPath: rightIconPath!, iconHeight: 22, radius: 25),
                  ),
              ],
            ),
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
