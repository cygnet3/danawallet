import 'package:danawallet/screens/home/wallet/main/wallet_skeleton.dart';
import 'package:flutter/material.dart';

class WalletScreenAddressCreated extends StatelessWidget {
  const WalletScreenAddressCreated({super.key});

  @override
  Widget build(BuildContext context) {
    return const WalletSkeleton(
        showBottomButtons: true,
        showAddFundsWidget: false,
        showTxHistory: false);
  }
}
