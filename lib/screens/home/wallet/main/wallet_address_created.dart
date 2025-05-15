import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/home/wallet/main/wallet_skeleton.dart';
import 'package:flutter/material.dart';

class WalletScreenAddressCreated extends StatelessWidget {
  const WalletScreenAddressCreated({super.key});

  @override
  Widget build(BuildContext context) {
    final txHistory = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('No transactions yet.\n',
            textAlign: TextAlign.center,
            style: BitcoinTextStyle.body3(Bitcoin.neutral6)
                .copyWith(fontFamily: 'Inter')),
        Text('Fund your wallet to get started!',
            textAlign: TextAlign.center,
            style: BitcoinTextStyle.body3(Bitcoin.neutral6)
                .copyWith(fontFamily: 'Inter')),
      ],
    );

    return WalletSkeleton(
        showBottomButtons: true,
        showAddFundsWidget: false,
        txHistory: txHistory);
  }
}
