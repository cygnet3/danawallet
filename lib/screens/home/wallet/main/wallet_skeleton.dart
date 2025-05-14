import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/screens/home/wallet/spend/choose_recipient.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/add_funds_widget.dart';
import 'package:danawallet/widgets/receive_widget.dart';
import 'package:danawallet/widgets/transaction_history.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WalletSkeleton extends StatelessWidget {
  final bool showBottomButtons;
  final bool showAddFundsWidget;
  final bool showTxHistory;

  const WalletSkeleton(
      {super.key,
      required this.showBottomButtons,
      required this.showAddFundsWidget,
      required this.showTxHistory});

  AppBar buildAppBar(Network network) {
    return AppBar(
      forceMaterialTransparency: true,
      title: Row(
        children: [
          const Spacer(),
          SizedBox(
              height: 30.0,
              width: 30.0,
              child: Image(
                fit: BoxFit.contain,
                image: const AssetImage("icons/3.0x/bitcoin_circle.png",
                    package: "bitcoin_ui"),
                color: network.toColor,
              )),
        ],
      ),
    );
  }

  Widget buildScanProgress(ScanProgressNotifier scanProgress) {
    final inner = Row(
      children: [
        Text(
            'Scanning: ${(scanProgress.progress * 100.0).toStringAsFixed(0)} %  ',
            style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
        Expanded(
          child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Bitcoin.blue),
                backgroundColor: Bitcoin.neutral4,
                value: scanProgress.progress,
                minHeight: 6.0,
              )),
        ),
        const SizedBox(
          width: 20,
        ),
        Image(
          width: 20.0,
          image: const AssetImage("icons/2.0x/caret_right.png",
              package: "bitcoin_ui"),
          color: Bitcoin.neutral7,
        )
      ],
    );

    return Visibility(
        visible: scanProgress.scanning,
        maintainAnimation: true,
        maintainSize: true,
        maintainState: true,
        child: inner);
  }

  Widget buildAmountDisplay(ApiAmount amount, bool hideAmount) {
    String btcAmount = hideAmount ? '*****' : amount.displayBtc();
    String fiatAmount = hideAmount ? '*****' : '\$ 0.00';

    return GestureDetector(
      onTap: () => (),
      // onTap: () => setState(() {
      //   hideAmount = !hideAmount;
      // }),
      child: Column(
        children: [
          Text(
            btcAmount,
            style: BitcoinTextStyle.body1(Bitcoin.neutral8).apply(
                fontSizeDelta: 3,
                fontFeatures: [const FontFeature.slashedZero()]),
          ),
          Text(
            fiatAmount,
            style: BitcoinTextStyle.body3(Bitcoin.neutral6)
                .apply(fontFeatures: [const FontFeature.slashedZero()]),
          ),
        ],
      ),
    );
  }

  Widget buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: BitcoinButtonFilled(
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
            onPressed: () {},
          )
        ],
      ),
    );
  }

  Widget buildTransactionOverview(List<ApiRecordedTransaction> transactions) {
    if (transactions.isEmpty) {
      // the user has not made any transactions yet
      return Column(
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

      // history = Center(
      //     child: Text('No transactions yet.',
      //         style: BitcoinTextStyle.body3(Bitcoin.neutral6)));
    } else {
      final history = TransactionHistoryWidget(transactions: transactions);
      return Column(children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Recent transactions',
              style: BitcoinTextStyle.body2(Bitcoin.neutral8)
                  .apply(fontWeightDelta: 2),
            )),
        LimitedBox(maxHeight: 240, child: history),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletState = Provider.of<WalletState>(context);
    final scanProgress = Provider.of<ScanProgressNotifier>(context);

    ApiAmount amount =
        ApiAmount(field0: walletState.amount + walletState.unconfirmedChange);

    return Scaffold(
        appBar: buildAppBar(walletState.network),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    buildScanProgress(scanProgress),
                    const SizedBox(height: 30.0),
                    Expanded(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildAmountDisplay(amount, false),
                              showAddFundsWidget
                                  ? AddFundsWidget()
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                        showTxHistory
                            ? Flexible(
                                child: buildTransactionOverview(
                                    walletState.txHistory.toApiTransactions()),
                              )
                            : const SizedBox(),
                        if (showBottomButtons) buildBottomButtons(context),
                        const SizedBox(
                          height: 20.0,
                        ),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
