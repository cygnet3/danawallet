import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/onboarding/onboarding_skeleton.dart';
import 'package:danawallet/screens/onboarding/overview.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_plain.dart';
import 'package:flutter/material.dart';

class IntroductionScreen extends StatelessWidget {
  const IntroductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image(
          width: 200.0,
          image: const AssetImage(
            "assets/icons/dana_outline.png",
          ),
          color: Bitcoin.black,
        ),
        Text(
          'Dana wallet',
          style: BitcoinTextStyle.title2(Colors.black)
              .copyWith(height: 1.8, fontFamily: 'Inter'),
        ),
        Text('Convenient, private payments',
            style: BitcoinTextStyle.body1(Bitcoin.neutral8)
                .copyWith(height: 1.8, fontFamily: 'Inter')),
      ],
    );

    final footer = FooterButtonPlain(
        title: 'Begin',
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const OverviewScreen())));

    return OnboardingSkeleton(
      body: body,
      footer: footer,
    );
  }
}
