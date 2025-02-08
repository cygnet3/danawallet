import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/home/wallet/spend/fee_selection.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:flutter/material.dart';

class AmountSelectionScreen extends StatefulWidget {
  const AmountSelectionScreen({super.key});

  @override
  AmountSelectionScreenState createState() => AmountSelectionScreenState();
}

class AmountSelectionScreenState extends State<AmountSelectionScreen> {
  final TextEditingController amountController = TextEditingController();
  String? _amountErrorText;

  @override
  Widget build(BuildContext context) {
    return SpendSkeleton(
      showBackButton: true,
      title: 'Enter amount',
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(children: [
              SizedBox(
                  height: 50.0,
                  width: 50.0,
                  child: Image(
                    fit: BoxFit.contain,
                    image: const AssetImage("icons/3.0x/bitcoin_circle.png",
                        package: "bitcoin_ui"),
                    color: Bitcoin.orange,
                  )),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To', style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
                  const Text('tsp1qqt7hcamq5z2....cnx7zfrxn3uq9fdkan'),
                ],
              )
            ]),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount',
                  style: BitcoinTextStyle.body5(Bitcoin.black),
                ),
                const SizedBox(
                  height: 10.0,
                ),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Enter an amount',
                    errorText: _amountErrorText,
                    suffixText: 'sats',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            // just here for spacing, replace with fractionallysizedbox later
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
          ]),
      footer: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          BitcoinButtonOutlined(
            tintColor: Bitcoin.neutral5,
            textStyle: BitcoinTextStyle.title4(Bitcoin.black),
            title: 'Select coins manually',
            onPressed: () => (),
            cornerRadius: 5.0,
          ),
          const SizedBox(
            height: 10.0,
          ),
          BitcoinButtonFilled(
            textStyle: BitcoinTextStyle.body2(Bitcoin.neutral1),
            title: 'Proceed to fee selection',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FeeSelectionScreen())),
            cornerRadius: 5.0,
          )
        ],
      ),
    );
  }
}
