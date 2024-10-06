import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TxHistoryscreen extends StatelessWidget {
  const TxHistoryscreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final walletState = Provider.of<WalletState>(context);
    final transactions = walletState.txHistory;

    return ListView.builder(
        reverse: false,
        itemCount: transactions.length,
        padding: EdgeInsets.all(screenWidth * 0.05),
        itemBuilder: (context, index) {
          ApiRecordedTransaction tx = transactions[index];
          Color? color;
          BigInt amount;
          String title;
          String text;
          Image image;

          switch (tx) {
            case ApiRecordedTransaction_Incoming(:final field0):
              color = Bitcoin.green;
              amount = field0.amount.toInt();
              title = 'Incoming transaction';
              text = field0.toString();
              image = Image(
                  image: const AssetImage("icons/receive.png",
                      package: "bitcoin_ui"),
                  color: Bitcoin.neutral3Dark);
            case ApiRecordedTransaction_Outgoing(:final field0):
              if (field0.confirmedAt == null) {
                color = Bitcoin.neutral4;
              } else {
                color = Bitcoin.red;
              }
              amount = field0.recipients
                  .fold(BigInt.zero, (acc, x) => acc + x.amount.toInt());
              title = 'Outgoing transaction';
              text = field0.toString();
              image = Image(
                  image:
                      const AssetImage("icons/send.png", package: "bitcoin_ui"),
                  color: Bitcoin.neutral3Dark);
          }
          return GestureDetector(
              onTap: () {
                showAlertDialog(title, text);
              },
              child: Card(
                color: color,
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        image,
                        Text("$amount"),
                      ],
                    )),
              ));
        });
  }
}
