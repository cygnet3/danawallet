import 'dart:async';

import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:donationwallet/global_functions.dart';
import 'package:donationwallet/services/synchronization_service.dart';
import 'package:donationwallet/screens/home/wallet/spend/spend.dart';
import 'package:donationwallet/states/chain_state.dart';
import 'package:donationwallet/states/wallet_state.dart';
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

  Widget showWalletStateText(WalletState walletState, ChainState chainState) {
    final toScan = chainState.tip - walletState.lastScan;
    String text;
    String subtext;

    if (walletState.scanning) {
      text = 'Scanning: $toScan blocks';
      subtext = '(${walletState.lastScan}-${chainState.tip})';
    } else if (toScan == 0) {
      text = 'Up to date!';
      subtext = '(${chainState.tip})';
    } else {
      text = 'New blocks: $toScan';
      subtext = '(${walletState.lastScan}-${chainState.tip})';
    }
    return Column(
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        Text(
          subtext,
          style: Theme.of(context).textTheme.bodyLarge,
        )
      ],
    );
  }

  Widget buildBottomButtons(WalletState walletState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: BitcoinButtonFilled(
              title: 'Receive',
              onPressed: () {
                _showReceiveDialog(context, walletState.address);
              },
            ),
          ),
          const SizedBox(width: 10), // Spacing between the buttons
          Expanded(
            child: BitcoinButtonFilled(
              title: 'Send',
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

    Widget progressWidget = walletState.scanning
        ? SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              backgroundColor: Colors.grey[200],
              value: walletState.progress,
              strokeWidth: 6.0,
            ),
          )
        : ElevatedButton(
            style: ElevatedButton.styleFrom(
              textStyle: Theme.of(context).textTheme.headlineLarge,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(60.0),
            ),
            onPressed: () async {
              try {
                await chainState.updateChainTip();
                await walletState.scan();
              } catch (e) {
                displayNotification(e.toString());
              }
            },
            child: const Text('Scan'));

    if (!walletState.walletLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10.0),
                // Spacer(),
                Text(
                  'Balance: ${walletState.amount}',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const Spacer(),
                progressWidget,
                const Spacer(),
                showWalletStateText(walletState, chainState),
                const Spacer(),
                buildBottomButtons(walletState),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
