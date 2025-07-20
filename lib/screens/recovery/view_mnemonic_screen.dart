import 'package:auto_size_text/auto_size_text.dart';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/widgets/back_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/pills/mnemonic_pill_box.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ViewMnemonicScreen extends StatelessWidget {
  final String mnemonic;
  const ViewMnemonicScreen({
    super.key,
    required this.mnemonic,
  });

  @override
  Widget build(BuildContext context) {
    final title = AutoSizeText(
      "This is your recovery phrase",
      style: BitcoinTextStyle.title2(Colors.black)
          .copyWith(height: 1.8, fontFamily: 'Inter'),
      maxLines: 1,
    );

    final text = AutoSizeText(
      "Make sure to write it down as shown here, including both numbers and words.",
      style: BitcoinTextStyle.body3(Bitcoin.neutral7).copyWith(
        fontFamily: 'Inter',
      ),
      textAlign: TextAlign.center,
      maxLines: 3,
    );

    final pills = MnemonicPillBox(mnemonic: mnemonic);
    final footer =
        FooterButton(title: "Verify", onPressed: () => goBack(context));

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const BackButtonWidget(),
        ),
        body: SafeArea(
          child: Padding(
              padding: EdgeInsets.fromLTRB(
                Adaptive.w(5), // Responsive left padding
                0,
                Adaptive.w(5), // Responsive right padding
                Adaptive.h(5), // Responsive bottom padding
              ),
              child: Column(
                children: [
                  Column(
                    children: [
                      title,
                      Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: Adaptive.h(3),
                              horizontal: Adaptive.w(2)),
                          child: text),
                    ],
                  ),
                  Expanded(child: pills),
                  footer,
                ],
              )),
        ));
  }
}
