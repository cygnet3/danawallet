import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/recipient_form.dart';
import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
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
          BitcoinButtonOutlined(
            textStyle: BitcoinTextStyle.title4(Bitcoin.black),
            title: 'View transaction',
            onPressed: () => (),
            cornerRadius: 5.0,
          ),
          const SizedBox(
            height: 10.0,
          ),
          BitcoinButtonFilled(
            textStyle: BitcoinTextStyle.body2(Bitcoin.neutral1),
            title: 'Done',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (Route<dynamic> route) => false);
            },
            cornerRadius: 5.0,
          )
        ],
      ),
    );
  }
}
