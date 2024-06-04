import 'dart:async';

import 'package:donationwallet/rust/api/simple.dart';
import 'package:donationwallet/global_functions.dart';
import 'package:donationwallet/main.dart';
import 'package:donationwallet/outputs.dart';
import 'package:donationwallet/destination.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TxDestination {
  final String address;
  int amount;

  TxDestination({
    required this.address,
    this.amount = 0,
  });
}

class SpendingRequest {
  final List<OwnedOutput> inputs;
  final List<String> outputs;
  final int fee;

  SpendingRequest({
    required this.inputs,
    required this.outputs,
    required this.fee,
  });

  Map<String, dynamic> toJson() => {
        'inputs': inputs,
        'outputs': outputs,
        'fee': fee,
      };
}

class SummaryWidget extends StatelessWidget {
  final String displayText;
  final VoidCallback? onTap;

  const SummaryWidget(
      {Key? key, required this.displayText, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayText, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ));
  }
}

class SpendScreen extends StatelessWidget {
  const SpendScreen({super.key});

  Future<String> _newTransactionWithFees(
      String path,
      String label,
      Map<String, OwnedOutput> selectedOutputs,
      List<Recipient> recipients,
      int feeRate) async {
    String psbt = await createNewPsbt(
        path: path, label: label, inputs: selectedOutputs, recipients: recipients);
    String fee = await addFeeForFeeRate(
        psbt: psbt, feeRate: feeRate, payer: recipients[0].address);
    String filled = await fillSpOutputs(path: path, label: label, psbt: fee);
    return filled;
  }

  Future<String> _signPsbt(
    String path,
    String label,
    String unsignedPsbt,
  ) async {
    return await signPsbt(
        path: path, label: label, psbt: unsignedPsbt, finalize: true);
  }

  Future<String> _broadcastSignedPsbtAndMarkAsSpent(String path, String label,
      String signedPsbt, Map<String, OwnedOutput> selectedOutputs) async {
    final tx = await extractTxFromPsbt(psbt: signedPsbt);
    final txid = await broadcastTx(tx: tx);
    for (final outpoint in selectedOutputs.keys) {
      try {
        markOutpointSpent(path: path, label: label, outpoint: outpoint, txid: txid);
      } catch (error) {
        rethrow;
      }
    }
    return txid;
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController feeRateController = TextEditingController();

    final walletState = Provider.of<WalletState>(context);
    final selectedOutputs = walletState.selectedOutputs;
    final recipients = walletState.recipients;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            SummaryWidget(
                displayText: selectedOutputs.isEmpty
                    ? "Tap here to choose which coin to spend"
                    : "Spending ${selectedOutputs.length} output(s) for a total of ${walletState.outputSelectionTotalAmt()} sats available",
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const OutputsScreen()),
                  );
                }),
            const Spacer(),
            SummaryWidget(
                displayText: recipients.isEmpty
                    ? "Tap here to add destinations"
                    : "Sending to ${recipients.length} output(s) for a total of ${walletState.recipientTotalAmt()} sats",
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const DestinationScreen()),
                  );
                }),
            const Spacer(),
            const Text('Fee Rate (satoshis/vB)'),
            TextField(
              controller: feeRateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              decoration: const InputDecoration(
                hintText: 'Enter fee rate',
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                final int? fees = int.tryParse(feeRateController.text);
                if (fees == null) {
                  throw Exception("No fees input");
                }
                final walletState =
                    Provider.of<WalletState>(context, listen: false);
                try {
                  final unsignedPsbt = await _newTransactionWithFees(
                      walletState.dir.path,
                      walletState.label,
                      walletState.selectedOutputs,
                      walletState.recipients,
                      fees);
                  final signedPsbt = await _signPsbt(
                      walletState.dir.path, walletState.label, unsignedPsbt);
                  final sentTxId = await _broadcastSignedPsbtAndMarkAsSpent(
                      walletState.dir.path,
                      walletState.label,
                      signedPsbt,
                      walletState.selectedOutputs);

                  // Clear selections
                  walletState.selectedOutputs.clear();
                  walletState.recipients.clear();

                  if (!context.mounted) return;

                  // navigate to main screen
                  Navigator.popUntil(context, (route) => route.isFirst);

                  showAlertDialog('Transaction successfully sent', sentTxId);
                } catch (e) {
                  rethrow;
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Spend'),
            ),
            const Spacer()
          ],
        ),
      ),
    );
  }
}
