import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/recipient_form.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_outlined.dart';
import 'package:flutter/material.dart';

class TransactionSentScreen extends StatelessWidget {
  const TransactionSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String estimatedTime = RecipientForm().fee!.toEstimatedTime;

    return SpendSkeleton(
      showBackButton: false,
      body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 20.0,
            ),
            CircleAvatar(
              backgroundColor: Bitcoin.green,
              radius: 30, // Adjust size as needed
              child: Image(
                image: const AssetImage("icons/2.0x/share.png",
                    package: "bitcoin_ui"),
                color: Bitcoin.white,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            Text(
              "Transaction sent",
              style: BitcoinTextStyle.title4(Bitcoin.black),
            ),
            const SizedBox(
              height: 10.0,
            ),
            Text(
              "Your transfer should be completed in $estimatedTime.",
              textAlign: TextAlign.center,
              style: BitcoinTextStyle.body3(Bitcoin.neutral7),
            ),
          ]),
      footer: Column(
        children: [
          FooterButton(
              title: 'Done',
              onPressed: () {
                Navigator.pop(context);
              })
        ],
      ),
    );
  }
}
