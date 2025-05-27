import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/home/wallet/main/wallet_skeleton.dart';
import 'package:danawallet/screens/home/wallet/receive/generate_address.dart';
import 'package:danawallet/widgets/add_funds_widget.dart';
import 'package:flutter/material.dart';

class WalletScreenNew extends StatelessWidget {
  const WalletScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    final txHistory = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('No transactions yet.',
            textAlign: TextAlign.center,
            style: BitcoinTextStyle.body3(Bitcoin.neutral6)
                .copyWith(fontFamily: 'Inter')),
      ],
    );

    final setupAccount = AddFundsWidget(
      text: "Set up your first account!",
      onTap: () => {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const GenerateAddressScreen()),
        )
      },
    );

    return WalletSkeleton(
        callToActionWidget: setupAccount, txHistory: txHistory);
  }
}
