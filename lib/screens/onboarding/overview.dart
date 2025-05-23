import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/onboarding/get_started.dart';
import 'package:danawallet/screens/onboarding/onboarding_skeleton.dart';
import 'package:danawallet/screens/onboarding/tutorial/tutorial_1.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_plain.dart';
import 'package:danawallet/widgets/info_widget.dart';
import 'package:flutter/material.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        Image(
          width: 120.0,
          image: const AssetImage(
            "assets/icons/dana_outline.png",
          ),
          color: Bitcoin.black,
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          "The Dana Promise",
          style: BitcoinTextStyle.title2(Colors.black)
              .copyWith(height: 1.8, fontFamily: 'Inter'),
        ),
        const SizedBox(
          height: 25,
        ),
        const InfoWidget(
            iconPath: "assets/icons/rocket.svg",
            title: "Hassle-free payments",
            text:
                "Get or share an address just once. Reuse it again and again!"),
        const SizedBox(
          height: 30,
        ),
        const InfoWidget(
            iconPath: "assets/icons/hidden.svg",
            title: "Better privacy",
            text: "Bitcoin privacy tools used to be hard-to-use. Not anymore."),
        const SizedBox(
          height: 30,
        ),
        const InfoWidget(
            iconPath: "assets/icons/address-book.svg",
            title: "Address book",
            text: "Keep an overview of your payments and addresses."),
      ],
    );

    final footer = Column(
      children: [
        FooterButtonPlain(
            title: 'Skip intro',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const GetStartedScreen()))),
        const SizedBox(
          height: 15,
        ),
        FooterButton(
            title: 'Learn more',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TutorialScreen1()))),
      ],
    );

    return OnboardingSkeleton(body: body, footer: footer);
  }
}
