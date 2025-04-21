import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/wallet/spend/choose_recipient.dart';
import 'package:danawallet/services/synchronization_service.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/receive_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  bool hideAmount = false;
  late SynchronizationService _synchronizationService;

  @override
  void initState() {
    super.initState();
    _synchronizationService = SynchronizationService(context);
    _synchronizationService.startSyncTimer();
  }

  @override
  void dispose() {
    _synchronizationService.stopSyncTimer();
    super.dispose();
  }

  void _showReceiveDialog(BuildContext context, String address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Your address'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleChildScrollView(
                child: BarcodeWidget(data: address, barcode: Barcode.qrCode()),
              ),
              const SizedBox(height: 20),
              SelectableText(address),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void onScanPressed() async {
    final walletState = Provider.of<WalletState>(context, listen: false);
    final chainState = Provider.of<ChainState>(context, listen: false);
    final scanProgress =
        Provider.of<ScanProgressNotifier>(context, listen: false);

    if (!chainState.initiated) {
      return;
    }

    await chainState.updateChainTip();

    if (chainState.tip == walletState.lastScan) {
      return;
    }

    try {
      if (scanProgress.scanning) {
        await scanProgress.interruptScan();
      } else {
        await scanProgress.scan(walletState);
      }
    } catch (e) {
      displayNotification(exceptionToString(e));
    }
  }

  Widget buildScanProgress(double scanProgress) {
    return Row(
      children: [
        Text('Scanning: ${(scanProgress * 100.0).toStringAsFixed(0)} %  ',
            style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
        Expanded(
          child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Bitcoin.blue),
                backgroundColor: Bitcoin.neutral4,
                value: scanProgress,
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
  }

  Widget buildAmountDisplay(ApiAmount amount) {
    String btcAmount = hideAmount ? '*****' : amount.displayBtc();
    String fiatAmount = hideAmount ? '*****' : '\$ 0.00';

    return GestureDetector(
      onTap: () => setState(() {
        hideAmount = !hideAmount;
      }),
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

  ListTile toListTile(ApiRecordedTransaction tx) {
    Color? color;
    String amount;
    String amountprefix;
    String title;
    String text;
    Image image;
    String recipient;
    String date;

    switch (tx) {
      case ApiRecordedTransaction_Incoming(:final field0):
        recipient = 'Incoming';
        date = field0.confirmedAt?.toString() ?? 'Unconfirmed';
        color = Bitcoin.green;
        amount = field0.amount.displayBtc();
        amountprefix = '+';
        title = 'Incoming transaction';
        text = field0.toString();
        image = Image(
            image: const AssetImage("icons/receive.png", package: "bitcoin_ui"),
            color: Bitcoin.neutral3Dark);
      case ApiRecordedTransaction_Outgoing(:final field0):
        recipient = displayAddress(context, field0.recipients[0].address,
            BitcoinTextStyle.body4(Bitcoin.black), 0.53);
        date = field0.confirmedAt?.toString() ?? 'Unconfirmed';
        if (field0.confirmedAt == null) {
          color = Bitcoin.neutral4;
        } else {
          color = Bitcoin.red;
        }
        amount = field0.totalOutgoing().displayBtc();
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
        children: [
          Text(
            recipient,
            style: BitcoinTextStyle.body4(Bitcoin.black),
          ),
          const Spacer(),
          Text('$amountprefix $amount', style: BitcoinTextStyle.body4(color)),
        ],
      ),
      subtitle: Row(
        children: [
          Text(date, style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
          const Spacer(),
          Text('\$ 0.00', style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
        ],
      ),
      trailing: InkResponse(
          onTap: () {
            showAlertDialog(title, text);
          },
          child: Image(
            image: const AssetImage("icons/caret_right.png",
                package: "bitcoin_ui"),
            color: Bitcoin.neutral7,
          )),
    );
  }

  Widget buildTransactionHistory(List<ApiRecordedTransaction> transactions) {
    Widget history;
    if (transactions.isEmpty) {
      history = Center(
          child: Text('No transactions yet.',
              style: BitcoinTextStyle.body3(Bitcoin.neutral6)));
    } else {
      history = ListView.separated(
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
          reverse: false,
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return toListTile(transactions[transactions.length - 1 - index]);
          });
    }

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

  Widget buildBottomButtons(String address) {
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
            onPressed: () {
              _showReceiveDialog(context, address);
            },
          )
        ],
      ),
    );
  }

  AppBar buildAppBar(bool isScanning, Color networkColor) {
    return AppBar(
      forceMaterialTransparency: true,
      title: Row(
        children: [
          const Spacer(),
          InkResponse(
            onTap: onScanPressed,
            child: isScanning
                ? SpinKitFadingCircle(
                    color: Bitcoin.neutral8,
                    size: 20.0,
                  )
                : SizedBox(
                    height: 30.0,
                    width: 30.0,
                    child: SvgPicture.asset(
                      "assets/icons/refresh.svg",
                      colorFilter:
                          ColorFilter.mode(Bitcoin.neutral8, BlendMode.srcIn),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          SizedBox(
              height: 30.0,
              width: 30.0,
              child: Image(
                fit: BoxFit.contain,
                image: const AssetImage("icons/3.0x/bitcoin_circle.png",
                    package: "bitcoin_ui"),
                color: networkColor,
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = Provider.of<WalletState>(context);
    final scanProgress = Provider.of<ScanProgressNotifier>(context);

    ApiAmount amount =
        ApiAmount(field0: walletState.amount + walletState.unconfirmedChange);

    return Scaffold(
        appBar: buildAppBar(scanProgress.scanning, walletState.network.toColor),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Visibility(
                        visible: scanProgress.scanning,
                        maintainAnimation: true,
                        maintainSize: true,
                        maintainState: true,
                        child: buildScanProgress(scanProgress.progress)),
                    const SizedBox(height: 20.0),
                    buildAmountDisplay(amount),
                    const Spacer(),
                    buildTransactionHistory(
                        walletState.txHistory.toApiTransactions()),
                    buildBottomButtons(walletState.address),
                    const SizedBox(
                      height: 20.0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
