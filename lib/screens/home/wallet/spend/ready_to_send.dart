import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:danawallet/screens/home/wallet/spend/transaction_sent.dart';
import 'package:flutter/material.dart';

class ReadyToSendScreen extends StatefulWidget {
  const ReadyToSendScreen({super.key});

  @override
  ReadyToSendScreenState createState() => ReadyToSendScreenState();
}

class ReadyToSendScreenState extends State<ReadyToSendScreen> {
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return SpendSkeleton(
        showBackButton: true,
        title: 'Ready to send?',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 50.0,
            ),
            Row(
              children: [
                Text(
                  'To',
                  style: BitcoinTextStyle.title5(Bitcoin.neutral7),
                ),
                const Spacer(),
                Text(
                  'sp1q kjh5 j340 234n rr92 b35c',
                  style: BitcoinTextStyle.title5(Bitcoin.neutral8),
                )
              ],
            ),
            const Divider(),
            Row(
              children: [
                Text(
                  'Amount',
                  style: BitcoinTextStyle.title5(Bitcoin.neutral7),
                ),
                const Spacer(),
                Text(
                  '₿0.35651816',
                  style: BitcoinTextStyle.title5(Bitcoin.neutral8),
                )
              ],
            ),
            const Divider(),
            Row(
              children: [
                Text(
                  'Arrival time',
                  style: BitcoinTextStyle.title5(Bitcoin.neutral7),
                ),
                const Spacer(),
                Text(
                  '30-60 minutes',
                  style: BitcoinTextStyle.title5(Bitcoin.neutral8),
                )
              ],
            ),
            const Divider(),
            Row(
              children: [
                Text(
                  'Fee',
                  style: BitcoinTextStyle.title5(Bitcoin.neutral7),
                ),
                const Spacer(),
                Text(
                  '₿0.00007987',
                  style: BitcoinTextStyle.title5(Bitcoin.neutral8),
                )
              ],
            ),
          ],
        ),
        footer: Column(
          children: [
            BitcoinButtonOutlined(
              textStyle: BitcoinTextStyle.title4(Bitcoin.black),
              title: 'See details',
              onPressed: () => (),
              cornerRadius: 5.0,
            ),
            const SizedBox(
              height: 10.0,
            ),
            BitcoinButtonFilled(
              textStyle: BitcoinTextStyle.body2(Bitcoin.neutral1),
              title: 'Send',
              isLoading: _isSending,
              onPressed: () async {
                setState(() {
                  _isSending = true;
                });
                await Future.delayed(const Duration(seconds: 2));
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TransactionSentScreen()),
                      (Route<dynamic> route) => false);
                }
              },
              cornerRadius: 5.0,
            )
          ],
        ));
  }
}
