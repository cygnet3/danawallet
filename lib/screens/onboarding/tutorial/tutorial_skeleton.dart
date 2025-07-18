import 'package:auto_size_text/auto_size_text.dart';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/widgets/icons/circular_icon.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TutorialSkeleton extends StatelessWidget {
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
    return Column(
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
            AutoSizeText(
              title,
              style: BitcoinTextStyle.title2(Colors.black)
                  .copyWith(height: 1.8, fontFamily: 'Inter'),
              maxLines: 1,
            ),
            const SizedBox(
              height: 10,
            ),
            AutoSizeText(
              text,
              style: BitcoinTextStyle.body3(Bitcoin.neutral7).copyWith(
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
        main,
      ],
    );
  }
}
