import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/screens/home/wallet/generate/show_address.dart';
import 'package:danawallet/screens/home/wallet/main/wallet_skeleton.dart';
import 'package:danawallet/screens/home/wallet/spend/choose_recipient.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/receive_widget.dart';
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
      LimitedBox(
          maxHeight: 240,
          child: TransactionHistoryWidget(transactions: transactions)),
    ]);

    final buttons = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: BitcoinButtonFilled(
              tintColor: danaBlue,
              body: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  'Pay  ',
                  style: BitcoinTextStyle.body3(Bitcoin.white),
                ),
                Image(
                  image:
                      const AssetImage("icons/send.png", package: "bitcoin_ui"),
                  color: Bitcoin.white,
                )
              ]),
              cornerRadius: 6,
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChooseRecipientScreen())),
            ),
          ),
          const SizedBox(width: 10),
          ReceiveWidget(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ShowAddressScreen(address: walletState.address))),
          )
        ],
      ),
    );

    return WalletSkeleton(
      showAddFundsWidget: false,
      txHistory: txHistory,
      footerButtons: buttons,
    );
  }
}
