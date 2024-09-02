import 'package:dart_bip353/dart_bip353.dart';
import 'package:donationwallet/states/spend_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AddRecipientWidget extends StatefulWidget {
  const AddRecipientWidget({
    super.key,
  });

  @override
  AddRecipientWidgetState createState() => AddRecipientWidgetState();
}

class AddRecipientWidgetState extends State<AddRecipientWidget> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String? addressErrorText;
  String? amountErrorText;

  AddRecipientWidgetState();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Recipient'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            controller: addressController,
            decoration: InputDecoration(
              labelText: 'Recipient',
              hintText: 'satoshi@bitcoin.org, sp1q..., bc1q...',
              errorText: addressErrorText,
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
            decoration: InputDecoration(
              labelText: 'Amount',
              errorText: amountErrorText,
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
            // reset errors
            setState(() {
              amountErrorText = null;
              addressErrorText = null;
            });

            String address = addressController.text;
            BigInt amount;
            try {
              amount = BigInt.from(int.parse(amountController.text));
            } on FormatException {
              setState(() {
                amountErrorText = 'Invalid amount';
              });
              return;
            }

            if (address.contains('@')) {
              // we interpret the address as a bip353 address
              try {
                final data = await Bip353.getAdressResolve(address);
                if (data.silentpayment != null) {
                  address = data.silentpayment!;
                }
              } catch (e) {
                setState(() {
                  addressErrorText = 'Failed to look up address';
                });
                return;
              }
            }

            if (context.mounted) {
              final spendState =
                  Provider.of<SpendState>(context, listen: false);
              spendState.addRecipients(address, amount, 1);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
