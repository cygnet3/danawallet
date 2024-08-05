import 'package:donationwallet/global_functions.dart';
import 'package:donationwallet/outputs.dart';
import 'package:donationwallet/destination.dart';
import 'package:donationwallet/rust/api/psbt.dart';
import 'package:donationwallet/rust/api/structs.dart';
import 'package:donationwallet/rust/api/wallet.dart';
import 'package:donationwallet/states/wallet_state.dart';
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

  String _newTransactionWithFees(
      String wallet,
      Map<String, OwnedOutput> selectedOutputs,
      List<Recipient> recipients,
      int feeRate) {
    try {
      final psbt = createNewPsbt(
          encodedWallet: wallet,
          inputs: selectedOutputs,
          recipients: recipients);
      final fee = addFeeForFeeRate(
          psbt: psbt, feeRate: feeRate, payer: recipients[0].address);
      return fillSpOutputs(encodedWallet: wallet, psbt: fee);
    } catch (e) {
      rethrow;
    }
  }

  String _signPsbt(
    String wallet,
    String unsignedPsbt,
  ) {
    return signPsbt(encodedWallet: wallet, psbt: unsignedPsbt, finalize: true);
  }

  String _broadcastSignedPsbt(String signedPsbt, String network) {
    try {
      final tx = extractTxFromPsbt(psbt: signedPsbt);
      print(tx);
      final txid = broadcastTx(tx: tx, network: network);
      return txid;
    } catch (e) {
      rethrow;
    }
  }

  String _markAsSpent(
    String wallet,
    String txid,
    Map<String, OwnedOutput> selectedOutputs,
  ) {
    try {
      final updatedWallet = markOutpointsSpent(
          encodedWallet: wallet,
          spentBy: txid,
          spent: selectedOutputs.keys.toList());
      return updatedWallet;
    } catch (e) {
      rethrow;
    }
  }

  String _addTxToHistory(String wallet, String txid,
      List<String> selectedOutpoints, List<Recipient> recipients) {
    try {
      final updatedWallet = addOutgoingTxToHistory(
          encodedWallet: wallet,
          txid: txid,
          spentOutpoints: selectedOutpoints,
          recipients: recipients);
      return updatedWallet;
    } catch (e) {
      rethrow;
    }
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
                final wallet = await walletState.getWalletFromSecureStorage();
                try {
                  final unsignedPsbt = _newTransactionWithFees(
                      wallet,
                      walletState.selectedOutputs,
                      walletState.recipients,
                      fees);
                  final signedPsbt = _signPsbt(wallet, unsignedPsbt);
                  final sentTxId =
                      _broadcastSignedPsbt(signedPsbt, walletState.network);
                  final markedAsSpentWallet = _markAsSpent(
                      wallet, sentTxId, walletState.selectedOutputs);
                  final updatedWallet = _addTxToHistory(
                      markedAsSpentWallet,
                      sentTxId,
                      walletState.selectedOutputs.keys.toList(),
                      walletState.recipients);

                  // Clear selections
                  walletState.selectedOutputs.clear();
                  walletState.recipients.clear();

                  // save the updated wallet
                  walletState.saveWalletToSecureStorage(updatedWallet);
                  await walletState.updateWalletStatus();

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
