import 'dart:async';

import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/services/synchronization_service.dart';
import 'package:danawallet/screens/home/wallet/spend/spend.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
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

  Future<void> _updateOwnedOutputs(
      WalletState walletState, Function(Exception? e) callback) async {
    try {
      await walletState.updateWalletStatus();
      callback(null);
    } on Exception catch (e) {
      callback(e);
    } catch (e) {
      rethrow;
    }
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

  Widget showWalletStateText(WalletState walletState, ChainState chainState,
      ScanProgressNotifier scanProgress) {
    String text;

    if (chainState.isInitialized()) {
      if (scanProgress.scanning) {
        final progressPercentage = scanProgress.progress * 100;
        text =
            '${scanProgress.current} (${progressPercentage.toStringAsFixed(0)}%)';
      } else if (chainState.tip == walletState.lastScan) {
        text = 'Up to date!';
      } else {
        text = '${chainState.tip - walletState.lastScan} new blocks';
      }
    } else {
      text = 'Unable to get block height';
    }

    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge,
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
              title: 'Receive',
              cornerRadius: 10,
              onPressed: () {
                _showReceiveDialog(context, walletState.address);
              },
            ),
          ),
          const SizedBox(width: 10), // Spacing between the buttons
          Expanded(
            child: BitcoinButtonFilled(
              title: 'Send',
              cornerRadius: 10,
              onPressed: () async {
                // Logic for send button
                await _updateOwnedOutputs(walletState, (Exception? e) async {
                  if (e != null) {
                    throw e;
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SpendScreen()));
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = Provider.of<WalletState>(context);
    final chainState = Provider.of<ChainState>(context);
    final scanProgress = Provider.of<ScanProgressNotifier>(context);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10.0),
                Text(
                  '${walletState.amount} sats',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const Spacer(),
                showWalletStateText(walletState, chainState, scanProgress),
                Visibility(
                  visible: scanProgress.scanning,
                  maintainAnimation: true,
                  maintainSize: true,
                  maintainState: true,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey[300],
                    value: scanProgress.progress,
                    minHeight: 10.0,
                  ),
                ),
                const SizedBox(height: 2),
                BitcoinButtonFilled(
                  cornerRadius: 10,
                  title: scanProgress.scanning ? 'Stop scanning' : 'Scan',
                  disabled: !chainState.isInitialized() ||
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
