import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/wallet/spend/outputs.dart';
import 'package:danawallet/screens/home/wallet/spend/destination.dart';
import 'package:danawallet/screens/home/wallet/spend/summary_widget.dart';
import 'package:danawallet/states/spend_state.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SpendScreen extends StatefulWidget {
  const SpendScreen({super.key});

  @override
  SpendScreenState createState() => SpendScreenState();
}

class SpendScreenState extends State<SpendScreen> {
  final TextEditingController feeRateController = TextEditingController();
  bool _isSending = false;
  String? _error;

  Future<void> onSpendButtonPressed(
      WalletState walletState, SpendState spendState) async {
    {
      setState(() {
        _isSending = true;
        _error = null;
      });

      final int? fees = int.tryParse(feeRateController.text);
      if (fees == null) {
        setState(() {
          _isSending = false;
          _error = "No fees input";
        });
        return;
      }
      try {
        final txid = await spendState.createSpendTx(walletState, fees);

        if (mounted) {
          // navigate to main screen
          Navigator.popUntil(context, (route) => route.isFirst);

          showAlertDialog('Transaction successfully sent', txid);
        }
      } catch (e) {
        setState(() {
          _isSending = false;
          _error = exceptionToString(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spendState = Provider.of<SpendState>(context, listen: true);
    final walletState = Provider.of<WalletState>(context, listen: false);

    final selectedOutputs = spendState.selectedOutputs;
    final recipients = spendState.recipients;

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
                    : "Spending ${selectedOutputs.length} output(s) for a total of ${spendState.outputSelectionTotalAmt()} sats available",
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
                    : "Sending to ${recipients.length} output(s) for a total of ${spendState.recipientTotalAmt()} sats",
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
              onPressed: _isSending
                  ? null
                  : () => onSpendButtonPressed(walletState, spendState),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Spend'),
            ),
            const SizedBox(height: 10.0),
            if (_error != null) Center(child: Text('Error: $_error')),
            if (_isSending) const Center(child: CircularProgressIndicator()),
            const Spacer()
          ],
        ),
      ),
    );
  }
}
