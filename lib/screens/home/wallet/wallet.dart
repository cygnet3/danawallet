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
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
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

  Widget buildBottomButtons(WalletState walletState) {
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
              _showReceiveDialog(context, walletState.address);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = Provider.of<WalletState>(context);
    final chainState = Provider.of<ChainState>(context);
    final scanProgress = Provider.of<ScanProgressNotifier>(context);

    ApiAmount amount =
        ApiAmount(field0: walletState.amount + walletState.unconfirmedChange);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                  visible: scanProgress.scanning,
                  maintainAnimation: true,
                  maintainSize: true,
                  maintainState: true,
                  child: Row(
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
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  amount.displayBtc(),
                  style: BitcoinTextStyle.body1(Bitcoin.neutral8).apply(
                      fontSizeDelta: 3,
                      fontFeatures: [const FontFeature.slashedZero()]),
                ),
                Text(
                  '\$ 0.00',
                  style: BitcoinTextStyle.body3(Bitcoin.neutral6)
                      .apply(fontFeatures: [const FontFeature.slashedZero()]),
                ),
                const Spacer(),
                const SizedBox(height: 2),
                BitcoinButtonFilled(
                  cornerRadius: 10,
                  body: Text(scanProgress.scanning ? 'Stop scanning' : 'Scan'),
                  disabled: !chainState.initiated ||
                      chainState.tip == walletState.lastScan,
                  onPressed: () async {
                    try {
                      if (scanProgress.scanning) {
                        await scanProgress.interruptScan();
                      } else {
                        await chainState.updateChainTip();
                        await scanProgress.scan(walletState);
                      }
                    } catch (e) {
                      displayNotification(exceptionToString(e));
                    }
                  },
                ),
                const SizedBox(height: 5.0),
                buildBottomButtons(walletState),
                const SizedBox(
                  height: 20.0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
