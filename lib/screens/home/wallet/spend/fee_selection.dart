import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/home/wallet/spend/ready_to_send.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:danawallet/widgets/fee_selector.dart';
import 'package:flutter/material.dart';

class FeeSelectionScreen extends StatelessWidget {
  const FeeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SpendSkeleton(
      showBackButton: true,
      title: 'Confirmation time',
      body: const FeeSelector(),
      footer: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const SizedBox(
            height: 10.0,
          ),
          BitcoinButtonFilled(
            textStyle: BitcoinTextStyle.body2(Bitcoin.neutral1),
            title: 'Continue',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ReadyToSendScreen())),
            cornerRadius: 5.0,
          )
        ],
      ),
    );
  }
}
