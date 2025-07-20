import 'package:auto_size_text/auto_size_text.dart';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/onboarding/fund_wallet.dart';
import 'package:danawallet/screens/onboarding/onboarding_skeleton.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/icons/circular_icon.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class GivingScreen extends StatefulWidget {
  const GivingScreen({super.key});

  @override
  State<GivingScreen> createState() => _GivingScreenState();
}

class _GivingScreenState extends State<GivingScreen> {
  String? selectedOption;
  final TextEditingController customController = TextEditingController();

  Widget _buildRadioOption(String text, String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: selectedOption,
          onChanged: (String? newValue) {
            setState(() {
              selectedOption = newValue;
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

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularIcon(
          iconPath: "assets/icons/hands-holding-gift.svg",
          iconHeight: 44,
          radius: 50,
        ),
        SizedBox(
          height: Adaptive.h(3),
        ),
        AutoSizeText(
          'Giving is godly',
          style: BitcoinTextStyle.title4(Colors.black)
              .copyWith(height: 2.0, fontFamily: 'Inter'),
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: Adaptive.h(2),
        ),
        AutoSizeText(
          'Do you always take without ever giving back?',
          style: BitcoinTextStyle.body3(Bitcoin.neutral7)
              .copyWith(fontFamily: 'Inter'),
          maxLines: 3,
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: Adaptive.h(4),
        ),
        AutoSizeText(
          'Set a monthly donation target:',
          style: BitcoinTextStyle.body2(Bitcoin.black)
              .copyWith(fontFamily: 'Inter', fontWeight: FontWeight.w500),
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: Adaptive.h(2),
        ),
        Column(
          children: [
            _buildRadioOption('\$100 or less', '100'),
            SizedBox(height: Adaptive.h(1)),
            _buildRadioOption('\$1000 or less', '1000'),
            SizedBox(height: Adaptive.h(1)),
            _buildRadioOption('\$10,000 or less', '10000'),
            SizedBox(height: Adaptive.h(1)),
            _buildRadioOption('I don\'t know yet', '0'),
            SizedBox(height: Adaptive.h(1)),
          ],
        ),
      ],
    );

    final footer =         FooterButton(
            title: 'Proceed',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FundWalletScreen())));

    return OnboardingSkeleton(
      body: body,
      footer: footer,
    );
  }
} 