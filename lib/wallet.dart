import 'dart:async';

import 'package:donationwallet/global_functions.dart';
import 'package:donationwallet/main.dart';
import 'package:donationwallet/spend.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  Future<void> _updateOwnedOutputs(
      WalletState walletState, Function(Exception? e) callback) async {
    try {
      walletState.updateOwnedOutputs();
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

  Widget showWalletStateText(context) {
    final walletState = Provider.of<WalletState>(context);
    final toScan = walletState.tip - walletState.lastScan;

    String text;

    if (walletState.scanning) {
      text = 'Scanning: $toScan blocks';
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
              shape: CircleBorder(),
              padding: EdgeInsets.all(60.0),
            ),
            onPressed: () async {
              try {
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
                Spacer(),
                progressWidget,
                Spacer(),
                showWalletStateText(context),
                Spacer(),
                buildBottomButtons(context),
                Spacer(),
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
              onPressed: () async {
                // Logic for send button
                final walletState =
                    Provider.of<WalletState>(context, listen: false);
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
              child: Text('Send'),
            ),
          ),
        ],
      ),
    );
  }
}
