import 'dart:async';
import 'dart:convert';

import 'package:donationwallet/ffi.dart';
import 'package:donationwallet/main.dart';
import 'package:donationwallet/outputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class SpendScreen extends StatelessWidget {
  const SpendScreen({super.key});

  Future<String> _spend(List<OwnedOutput> spentOutputs, List<String> addresses,
      int feeRate) async {
    UnimplementedError;
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController addressController = TextEditingController();
    final TextEditingController feeRateController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to the new screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const OutputsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Choose outputs to spend'),
            ),
            const Text('Destination Address'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: addressController,
                    readOnly: true, // Makes the field read-only
                    decoration: const InputDecoration(
                      hintText: 'Paste destination address here',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () async {
                    ClipboardData? data =
                        await Clipboard.getData(Clipboard.kTextPlain);
                    addressController.text = data?.text ?? '';
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Fee Rate (satoshis/vB)'),
            TextField(
              controller: feeRateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              decoration: const InputDecoration(
                hintText: 'Enter fee rate',
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final String address = addressController.text;
                final int? fees = int.tryParse(feeRateController.text);
                if (fees == null) {
                  throw Exception("Invalid fees");
                }
                List<String> addresses = List.filled(1, address);
                final walletState = Provider.of<WalletState>(context);
                final tx =
                    await _spend(walletState.selectedOutputs, addresses, fees);
                print("$tx");
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Spend'),
            ),
          ],
        ),
      ),
    );
  }
}
