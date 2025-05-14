import 'package:danawallet/screens/home/wallet/main/wallet_skeleton.dart';
import 'package:flutter/material.dart';

class WalletScreenNew extends StatelessWidget {
  const WalletScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    return const WalletSkeleton(
        showBottomButtons: false,
        showAddFundsWidget: true,
        showTxHistory: false);
  }
}
