import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/home/wallet/main/wallet_skeleton.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/transaction_history.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WalletScreenFull extends StatelessWidget {
  const WalletScreenFull({super.key});

  @override
  Widget build(BuildContext context) {
        final walletState = Provider.of<WalletState>(context);

    final transactions = walletState.txHistory.toApiTransactions();
    final txHistory = Column(children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Recent transactions',
              style: BitcoinTextStyle.body2(Bitcoin.neutral8)
                  .apply(fontWeightDelta: 2),
            )),
        LimitedBox(maxHeight: 240, child: TransactionHistoryWidget(transactions: transactions)),
      ]);


    return WalletSkeleton(
      showBottomButtons: true,
      showAddFundsWidget: false,
      txHistory: txHistory,
    );
  }
}
