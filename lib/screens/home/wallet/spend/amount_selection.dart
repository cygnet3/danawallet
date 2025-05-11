import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/recipient_form.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/wallet/spend/fee_selection.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AmountSelectionScreen extends StatefulWidget {
  const AmountSelectionScreen({super.key});

  @override
  AmountSelectionScreenState createState() => AmountSelectionScreenState();
}

class AmountSelectionScreenState extends State<AmountSelectionScreen> {
  final TextEditingController amountController = TextEditingController();
  String? _amountErrorText;

  Future<void> onContinue(BigInt availableBalance) async {
    setState(() {
      _amountErrorText = null;
    });

    final BigInt amount;
    try {
      amount = BigInt.from(int.parse(amountController.text));
    } on FormatException {
      setState(() {
        _amountErrorText = 'Invalid amount';
      });
      return;
    }

    if (amount > availableBalance) {
      setState(() {
        _amountErrorText = 'Not enough available funds';
      });
      return;
    }

    RecipientForm().amount = ApiAmount(field0: amount);

    // get fee rates, these are needed for the next screen
    // todo: make a chainstate, get the fee rates from the chainstate instead
    final walletState = Provider.of<WalletState>(context, listen: false);
    final currentFeeRates = await walletState.getCurrentFeeRates();
    RecipientForm().currentFeeRates = currentFeeRates;

    if (mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const FeeSelectionScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    RecipientForm form = RecipientForm();

    final walletState = Provider.of<WalletState>(context, listen: false);
    final chainState = Provider.of<ChainState>(context, listen: false);

    final availableBalance = walletState.amount;
    final blocksToScan = chainState.tip - walletState.lastScan;

    String recipientName;
    TextStyle recipientTextStyle = BitcoinTextStyle.body4(Bitcoin.neutral7);

    if (form.recipientBip353 != null) {
      recipientName = form.recipientBip353!;
    } else {
      final maxWidth = MediaQuery.of(context).size.width * 0.86;
      recipientName =
          displayAddress(form.recipientAddress!, recipientTextStyle, maxWidth);
    }

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
                  Text(recipientName, style: recipientTextStyle),
                ],
              )
            ]),
            Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Amount',
                    style: BitcoinTextStyle.body5(Bitcoin.black),
                  ),
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
                const SizedBox(
                  height: 10.0,
                ),
                Text('Available Balance: $availableBalance',
                    style: BitcoinTextStyle.body3(Bitcoin.black)
                        .apply(fontWeightDelta: 1)),
                if (blocksToScan != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Warning: $blocksToScan block(s) to scan, balance might be inaccurate.',
                      style: BitcoinTextStyle.body5(Bitcoin.orange),
                      textAlign: TextAlign.center,
                    ),
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
          if (isDevEnv())
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
          FooterButton(
            title: 'Proceed to fee selection',
            onPressed: () => onContinue(availableBalance),
          ),
        ],
      ),
    );
  }
}
