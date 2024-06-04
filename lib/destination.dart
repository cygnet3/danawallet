import 'package:donationwallet/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:donationwallet/rust/api/simple.dart';

Future<void> _showAddRecipientDialog(
    BuildContext context,
    TextEditingController addressController,
    TextEditingController amountController) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Add New Recipient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: () async {
                    ClipboardData? data =
                        await Clipboard.getData(Clipboard.kTextPlain);
                    if (data != null) {
                      addressController.text = data.text ?? '';
                    }
                  },
                ),
              ),
            ),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                addressController.clear();
                amountController.clear();
              }),
          TextButton(
            child: const Text('Add'),
            onPressed: () async {
              String address = addressController.text;
              BigInt amount;
              try {
                amount = BigInt.from(int.parse(amountController.text));
              } on FormatException {
                rethrow;
              }

              final walletState =
                  Provider.of<WalletState>(context, listen: false);
              walletState.addRecipients(address, amount, 1);

              addressController.clear();
              amountController.clear();
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class DestinationScreen extends StatelessWidget {
  const DestinationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletState = Provider.of<WalletState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment destinations'),
      ),
      body: Stack(
        children: [
          ListView.builder(
              itemCount: walletState.recipients.length,
              itemBuilder: (context, index) {
                Recipient recipient = walletState.recipients[index];
                return GestureDetector(
                    onTap: () {
                      walletState.rmRecipient(recipient.address);
                    },
                    child: Card(
                      color: Colors.blue[100],
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Address: ${recipient.address}"),
                              Text("Amount: ${recipient.amount}"),
                              Text("# outputs: ${recipient.nbOutputs}"),
                            ],
                          )),
                    ));
              }),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: () async {
                  final addressController = TextEditingController();
                  final amountController = TextEditingController();
                  try {
                    await _showAddRecipientDialog(
                        context, addressController, amountController);
                  } catch (e) {
                    rethrow;
                  }
                },
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
