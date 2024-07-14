import 'dart:convert';

import 'package:donationwallet/global_functions.dart';
import 'package:donationwallet/main.dart';
import 'package:donationwallet/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TxHistoryscreen extends StatelessWidget {
  const TxHistoryscreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final walletState = Provider.of<WalletState>(context);
    final transactions = walletState.txHistory;

    return Column(
      children: [
        Expanded(
            child: Center(
                child: SizedBox(
          width: screenWidth * 0.90,
          child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                RecordedTransaction tx = transactions[index];
                Color? color;
                BigInt amount;
                String title;
                String text;

                switch (tx) {
                  case RecordedTransaction_Incoming(:final field0):
                    color = Colors.green[300];
                    amount = field0.amount.toInt();
                    title = 'Incoming transaction';
                    text = field0.toString();
                  case RecordedTransaction_Outgoing(:final field0):
                    color = Colors.red[300];
                    amount = field0.recipients
                        .fold(BigInt.zero, (acc, x) => acc + x.amount.toInt());
                    title = 'Outgoing transaction';
                    text = field0.toString();
                }
                return GestureDetector(
                    onTap: () {
                      showAlertDialog(title, text);
                    },
                    child: Card(
                      color: color,
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text("$amount"),
                            ],
                          )),
                    ));
              }),
        ))),
      ],
    );
  }
}
