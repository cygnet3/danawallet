import 'dart:async';
import 'dart:convert';

import 'package:donationwallet/main.dart';
import 'package:donationwallet/spend.dart';
import 'package:flutter/material.dart';
import 'package:donationwallet/ffi.dart';
import 'package:provider/provider.dart';

class OutputsScreen extends StatelessWidget {
  const OutputsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final walletState = Provider.of<WalletState>(context);

    return Scaffold(
        appBar: AppBar(
          title: const Text('My spendable outputs'),
        ),
        body: Column(
          children: [
            Expanded(
                child: Center(
                    child: SizedBox(
              width: screenWidth * 0.90,
              child: ListView.builder(
                  itemCount: walletState.getSpendableOutputs().length,
                  itemBuilder: (context, index) {
                    OwnedOutput output =
                        walletState.getSpendableOutputs()[index];
                    bool isSelected =
                        walletState.selectedOutputs.contains(output);
                    return GestureDetector(
                        onTap: () {
                          walletState.toggleOutputSelection(output);
                        },
                        child: Card(
                          color: isSelected ? Colors.blue[100] : null,
                          child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("TxOutpoint: ${output.txoutpoint}"),
                                  Text("Blockheight: ${output.blockheight}"),
                                  Text("Amount: ${output.amount}"),
                                  Text("Script: ${output.script}"),
                                ],
                              )),
                        ));
                  }),
            ))),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    final outputs = walletState.getSpendableOutputs();
                    print(outputs[0].script);
                    // print(output)
                    // final walletState = Provider.of<WalletState>(context);
                    // Navigator.of(context).push(MaterialPageRoute(
                    //     builder: (context) =>
                    //         SpendScreen(spendingOutputs: outputs)));
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Spend selected outputs'),
                ),
              ),
            ),
          ],
        ));
  }
}
