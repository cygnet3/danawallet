import 'package:danawallet/screens/home/wallet/main/wallet_skeleton.dart';
import 'package:flutter/material.dart';

class WalletScreenFull extends StatelessWidget {
  const WalletScreenFull({super.key});

  @override
  Widget build(BuildContext context) {
    return const WalletSkeleton(
      showBottomButtons: true,
      showAddFundsWidget: false,
      showTxHistory: true,
    );
  }
}
