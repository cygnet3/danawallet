import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/data/enums/network.dart';
import 'package:danawallet/data/enums/warning_type.dart';
import 'package:danawallet/extensions/api_amount.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/wallet/receive/show_address.dart';
import 'package:danawallet/screens/home/wallet/spend/choose_recipient.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/fiat_exchange_rate_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/cta/cta_manager.dart';
import 'package:danawallet/widgets/receive_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const String mainnetWarning =
    "You are currently on Mainnet. This means you are using real funds. Please note that this wallet is still considered experimental, so there may be some risks involved. Don't use funds that you are unwilling to lose. You have been warned.";

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  bool hideAmount = false;

  @override
  void initState() {
    super.initState();

    // if we are on mainnet, show a warning message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletState = Provider.of<WalletState>(context, listen: false);
      if (walletState.network == Network.mainnet) {
        showWarningDialog(mainnetWarning, WarningType.warn);
      }
    });
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

  Widget buildOfflineStatus(ChainState chainState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Bitcoin.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Bitcoin.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Bitcoin.orange, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sync offline - balance may be outdated',
              style: BitcoinTextStyle.body5(Bitcoin.orange),
            ),
          ),
          GestureDetector(
            onTap: () async {
              // Show immediate feedback that retry is happening
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Bitcoin.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Retrying connection...'),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
              
              final success = await chainState.retryConnection();
              
              if (mounted) {
                // Clear the "retrying" message first
                ScaffoldMessenger.of(context).clearSnackBars();
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Bitcoin.green, size: 16),
                          const SizedBox(width: 8),
                          const Text('Successfully reconnected!'),
                        ],
                      ),
                      backgroundColor: Bitcoin.green.withOpacity(0.1),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Bitcoin.orange, size: 16),
                          const SizedBox(width: 8),
                          const Text('Still unable to connect. Please try again later.'),
                        ],
                      ),
                      backgroundColor: Bitcoin.red.withValues(alpha: 0.8),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Bitcoin.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Retry',
                style: BitcoinTextStyle.body5(Bitcoin.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAmountDisplay(ApiAmount amount, FiatExchangeRateState fiatState) {
    String btcAmount = hideAmount ? '*****' : amount.displayBtc();
    String fiatAmount;
    
    if (hideAmount) {
      fiatAmount = '*****';
    } else if (fiatState.hasExchangeRate) {
      fiatAmount = amount.displayFiat(exchangeRate: fiatState.exchangeRate!);
    } else {
      fiatAmount = fiatState.getUnavailableDisplay();
    }

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

  ListTile toListTile(
      ApiRecordedTransaction tx, FiatExchangeRateState fiatState) {
    Color? color;
    String amount;
    String amountprefix;
    String amountFiat;
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
        amountFiat = fiatState.hasExchangeRate
            ? field0.amount.displayFiat(exchangeRate: fiatState.exchangeRate!)
            : fiatState.getUnavailableDisplay();
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
        amountFiat = fiatState.hasExchangeRate
            ? field0.totalOutgoing().displayFiat(exchangeRate: fiatState.exchangeRate!)
            : fiatState.getUnavailableDisplay();
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
          Text(amountFiat, style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
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

  Widget buildTransactionHistory(List<ApiRecordedTransaction> transactions,
      FiatExchangeRateState fiatState) {
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
            return toListTile(
                transactions[transactions.length - 1 - index], fiatState);
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
                    builder: (context) => ShowAddressScreen(address: address))),
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
    final fiatExchangeRateState = Provider.of<FiatExchangeRateState>(context);
    final scanProgress = Provider.of<ScanProgressNotifier>(context);
    final chainState = Provider.of<ChainState>(context);

    ApiAmount amount = walletState.amount + walletState.unconfirmedChange;

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
                    // Show sync progress when actively scanning
                    Visibility(
                        visible: scanProgress.scanning,
                        maintainAnimation: true,
                        maintainSize: true,
                        maintainState: true,
                        child: buildScanProgress(scanProgress.progress)),
                    // Show offline status when chain sync has connection issues
                    Visibility(
                        visible: !chainState.isAvailable,
                        maintainAnimation: true,
                        maintainSize: true,
                        maintainState: true,
                        child: buildOfflineStatus(chainState)),
                    const SizedBox(height: 20.0),
                    // Call-to-Action messages
                    const CtaManager(),
                    buildAmountDisplay(amount, fiatExchangeRateState),
                    const Spacer(),
                    buildTransactionHistory(
                        walletState.txHistory.toApiTransactions(),
                        fiatExchangeRateState),
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
