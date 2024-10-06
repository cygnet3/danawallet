import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/screens/home/wallet/spend/add_recipient.dart';
import 'package:danawallet/states/spend_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DestinationScreen extends StatelessWidget {
  const DestinationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spendState = Provider.of<SpendState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment destinations'),
      ),
      body: Stack(
        children: [
          ListView.builder(
              itemCount: spendState.recipients.length,
              itemBuilder: (context, index) {
                ApiRecipient recipient = spendState.recipients[index];
                return GestureDetector(
                    onTap: () {
                      spendState.rmRecipient(recipient.address);
                    },
                    child: Card(
                      color: Colors.blue[100],
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Address: ${recipient.address}"),
                              Text("Amount: ${recipient.amount.field0}"),
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
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return const AddRecipientWidget();
                    },
                  );
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
