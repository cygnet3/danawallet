import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/global_functions.dart';
import 'package:flutter/material.dart';

class TransactionHistoryWidget extends StatelessWidget {
  final List<ApiRecordedTransaction> transactions;

  const TransactionHistoryWidget({super.key, required this.transactions});

  ListTile toListTile(ApiRecordedTransaction tx, double maxWidth) {
    Color? color;
    String amount;
    String amountFiat;
    String amountprefix;
    String title;
    String text;
    Image image;
    String recipient;
    String date;

    switch (tx) {
      case ApiRecordedTransaction_Incoming(:final field0):
        recipient = field0.label ?? 'Oslo Freedom Forum';
        date = field0.confirmedAt?.toString() ?? 'Unconfirmed';
        // example values used on the onboarding screen
        if (field0.confirmedAt == 3) {
          date = "A few minutes ago";
        } else if (field0.confirmedAt == 2) {
          date = "Yesterday";
        } else if (field0.confirmedAt == 1) {
          date = "Last week";
        }
        color = Bitcoin.green;
        amount = field0.amount.displaySats();
        amountFiat = field0.amount.displayEuro();
        amountprefix = '+';
        title = 'Incoming transaction';
        text = field0.toString();
        image = Image(
            image: const AssetImage("icons/receive.png", package: "bitcoin_ui"),
            color: Bitcoin.neutral3Dark);
      case ApiRecordedTransaction_Outgoing(:final field0):
        recipient = displayAddress(field0.recipients[0].address,
            BitcoinTextStyle.body4(Bitcoin.black), maxWidth);
        date = field0.confirmedAt?.toString() ?? 'Unconfirmed';
        if (field0.confirmedAt == null) {
          color = Bitcoin.neutral4;
        } else {
          color = Bitcoin.red;
        }
        amount = field0.totalOutgoing().displaySats();
        amountFiat = field0.totalOutgoing().displayEuro();
        amountprefix = '-';
        title = 'Outgoing transaction';
        text = field0.toString();
        image = Image(
            image: const AssetImage("icons/send.png", package: "bitcoin_ui"),
            color: Bitcoin.neutral3Dark);
    }
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: image,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
              child: Text(
            recipient,
            style: BitcoinTextStyle.body4(Bitcoin.black),
            overflow: TextOverflow.ellipsis,
          )),
          const SizedBox(
            width: 12.0,
          ),
          Text('$amountprefix $amount', style: BitcoinTextStyle.body4(color)),
        ],
      ),
      subtitle: Row(
        children: [
          Text(date, style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
          const Spacer(),
          Text(amountFiat, style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        reverse: false,
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final maxWidth = MediaQuery.of(context).size.width * 0.53;
          return toListTile(
              transactions[transactions.length - 1 - index], maxWidth);
        });
  }
}
