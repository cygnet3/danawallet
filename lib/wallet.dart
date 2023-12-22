import 'dart:async';

import 'package:donationwallet/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  Future<void> _scanToTip() async {
    UnimplementedError();
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
              SizedBox(height: 20),
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

  Widget showScanText(context) {
    final walletState = Provider.of<WalletState>(context);
    final toScan = walletState.tip - walletState.lastScan;

    String text;
    if (walletState.peercount == 0) {
      text = 'Waiting for peers';
    } else if (toScan == 0) {
      text = 'Up to date!';
    } else {
      text = 'New blocks: $toScan';
    }

    return Text(
      text,
      style: Theme.of(context).textTheme.displaySmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = Provider.of<WalletState>(context);

    Widget progressWidget = walletState.progress != 0.0
        ? SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: walletState.progress,
              strokeWidth: 6.0,
            ),
          )
        : ElevatedButton(
            style: ElevatedButton.styleFrom(
              textStyle: Theme.of(context).textTheme.headlineLarge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              minimumSize: const Size(double.infinity, 60),
            ),
            onPressed: () async {
              await _scanToTip();
            },
            child: const Text('Scan chain'));

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
                Text('Nakamoto peer count: ${walletState.peercount}'),
                // Spacer(),
                Text(
                  'Balance: ${walletState.amount}',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                Spacer(),
                progressWidget,
                Spacer(),
                showScanText(context),
                Spacer(),
                buildBottomButtons(context),
                const SizedBox(
                  height: 20.0,
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildBottomButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                final walletState =
                    Provider.of<WalletState>(context, listen: false);
                _showReceiveDialog(context, walletState.address);
              },
              child: Text('Receive'),
            ),
          ),
          SizedBox(width: 10), // Spacing between the buttons
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Logic for send button
              },
              child: Text('Send'),
            ),
          ),
        ],
      ),
    );
  }
}
