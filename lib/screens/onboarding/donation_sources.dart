import 'package:auto_size_text/auto_size_text.dart';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/onboarding/giving.dart';
import 'package:danawallet/screens/onboarding/onboarding_skeleton.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/icons/circular_icon.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DonationSourcesScreen extends StatefulWidget {
  const DonationSourcesScreen({super.key});

  @override
  State<DonationSourcesScreen> createState() => _DonationSourcesScreenState();
}

class _DonationSourcesScreenState extends State<DonationSourcesScreen> {
  bool socialMediaChecked = false;
  bool contentCreationChecked = false;
  bool gamingChecked = false;
  bool customChecked = false;
  final TextEditingController customController = TextEditingController();

  Widget _buildCheckboxOption(String text, bool value) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (bool? newValue) {
            setState(() {
              if (text == 'X (Twitter)') {
                socialMediaChecked = newValue ?? false;
              } else if (text == 'Twitch') {
                contentCreationChecked = newValue ?? false;
              } else if (text == 'Nostr') {
                gamingChecked = newValue ?? false;
              }
            });
          },
          activeColor: Bitcoin.blue,
        ),
        Expanded(
          child: Text(
            text,
            style: BitcoinTextStyle.body3(Bitcoin.black)
                .copyWith(fontFamily: 'Inter'),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomCheckboxOption() {
    return Row(
      children: [
        Checkbox(
          value: customChecked,
          onChanged: (bool? newValue) {
            setState(() {
              customChecked = newValue ?? false;
            });
          },
          activeColor: Bitcoin.blue,
        ),
        Expanded(
          child: TextField(
            controller: customController,
            decoration: InputDecoration(
              hintText: 'Other (specify)',
              hintStyle: BitcoinTextStyle.body3(Bitcoin.neutral6)
                  .copyWith(fontFamily: 'Inter'),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: BitcoinTextStyle.body3(Bitcoin.black)
                .copyWith(fontFamily: 'Inter'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularIcon(
          iconPath: "assets/icons/rocket.svg",
          iconHeight: 44,
          radius: 50,
        ),
        SizedBox(
          height: Adaptive.h(3),
        ),
        AutoSizeText(
          'Where would like to receive donations from?',
          style: BitcoinTextStyle.title4(Colors.black)
              .copyWith(height: 2.0, fontFamily: 'Inter'),
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: Adaptive.h(2),
        ),
        AutoSizeText(
          'Select one or more.\nThose are just examples, you can add more or different sources later.',
          style: BitcoinTextStyle.body3(Bitcoin.neutral7)
              .copyWith(fontFamily: 'Inter'),
          maxLines: 3,
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: Adaptive.h(4),
        ),
        Column(
          children: [
            _buildCheckboxOption('X (Twitter)', socialMediaChecked),
            SizedBox(height: Adaptive.h(1)),
            _buildCheckboxOption('Twitch', contentCreationChecked),
            SizedBox(height: Adaptive.h(1)),
            _buildCheckboxOption('Nostr', gamingChecked),
            SizedBox(height: Adaptive.h(1)),
            _buildCustomCheckboxOption(),
          ],
        ),
      ],
    );

    final footer = FooterButton(
        title: 'Continue',
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const GivingScreen())));

    return OnboardingSkeleton(
      body: body,
      footer: footer,
    );
  }
} 