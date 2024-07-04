import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:donationwallet/src/presentation/notifiers/transaction_notifier.dart';
import 'package:donationwallet/src/utils/global_functions.dart';
import 'package:donationwallet/src/presentation/notifiers/wallet_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:donationwallet/src/presentation/utils/wallet_utils.dart';
import 'package:donationwallet/src/utils/constants.dart';
import 'package:donationwallet/src/domain/entities/spendingrequest_entity.dart';

class TxDestination {
  final String address;
  int amount;

  TxDestination({
    required this.address,
    this.amount = 0,
  });
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

  @override
  Widget build(BuildContext context) {
    final TextEditingController feeRateController = TextEditingController();

    final walletNotifier = context.watch<WalletNotifier>();
    final transactionNotifer = context.watch<TransactionNotifier>();

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
                displayText: transactionNotifer.getInputs().isEmpty
                    ? "Tap here to choose which coin to spend"
                    : "Spending ${transactionNotifer.getInputs().length} output(s) for a total of ${transactionNotifer.getTotalAvailable()} sats available",
                onTap: () {
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //       builder: (context) => const OutputsScreen()),
                  // );
                }),
            const Spacer(),
            SummaryWidget(
                displayText: transactionNotifer.recipientsLength() == 0
                    ? "Tap here to add destinations"
                    : "Sending to ${transactionNotifer.recipientsLength()} output(s) for a total of ${transactionNotifer.getTotalSpent()} sats",
                onTap: () {
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //       builder: (context) => const DestinationScreen()),
                  // );
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
                final wallet = await walletNotifier.loadWalletUseCase(defaultLabel);
                try {
                  // transactionNotifer.createTransactionUsecase();

                  if (!context.mounted) return;

                  // navigate to main screen
                  Navigator.popUntil(context, (route) => route.isFirst);

                  // showAlertDialog('Transaction successfully sent', sentTxId);
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
