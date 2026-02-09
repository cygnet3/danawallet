import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/data/models/recipient_form.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/wallet/spend/fee_selection.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/fiat_exchange_rate_state.dart';
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

  void onContinue(
      ApiAmount availableBalance, FiatExchangeRateState exchangeRate) {
    setState(() {
      _amountErrorText = null;
    });

    final BigInt amount;
    try {
      amount =
          _parseAmountToSats(amountController.text, exchangeRate.bitcoinUnit);
    } on FormatException catch (e) {
      setState(() {
        _amountErrorText = 'Invalid amount: $e';
      });
      return;
    } catch (e) {
      setState(() {
        _amountErrorText = 'Unknown error: $e';
      });
      return;
    }

    if (amount > availableBalance.field0) {
      setState(() {
        _amountErrorText = 'Not enough available funds';
      });
      return;
    }

    if (amount < BigInt.from(defaultDustLimit)) {
      setState(() {
        _amountErrorText =
            'Please send at least ${_formatDustLimit(exchangeRate.bitcoinUnit)}';
      });
      return;
    }

    RecipientForm().amount = ApiAmount(field0: amount);

    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const FeeSelectionScreen()));
  }

  BigInt _parseAmountToSats(String input, BitcoinUnit unit) {
    try {
      switch (unit) {
        case BitcoinUnit.btc:
          final double btcAmount = double.parse(input);
          if (btcAmount <= 0) {
            throw const FormatException('Amount must be positive');
          }
          // Truncate to whole satoshis using floor()
          final int sats = (btcAmount * bitcoinUnits).floor();
          return BigInt.from(sats);

        case BitcoinUnit.sats:
        case BitcoinUnit.bitcoinSymbol:
          final int satsAmount = int.parse(input);
          if (satsAmount <= 0) {
            throw const FormatException('Amount must be positive');
          }
          return BigInt.from(satsAmount);
      }
    } on FormatException {
      rethrow;
    }
  }

  String _formatDustLimit(BitcoinUnit unit) {
    final dustAmount = ApiAmount(field0: BigInt.from(defaultDustLimit));
    return dustAmount.formatWithUnit(unit: unit);
  }

  String _getSuffixText(BitcoinUnit unit) {
    switch (unit) {
      case BitcoinUnit.btc:
        return 'BTC';
      case BitcoinUnit.sats:
        return 'sats';
      case BitcoinUnit.bitcoinSymbol:
        return '₿';
    }
  }

  @override
  Widget build(BuildContext context) {
    RecipientForm form = RecipientForm();

    final walletState = Provider.of<WalletState>(context, listen: false);
    final chainState = Provider.of<ChainState>(context, listen: false);
    final exchangeRate =
        Provider.of<FiatExchangeRateState>(context, listen: false);

    final availableBalance = walletState.amount;
    final blocksToScan = chainState.tip - walletState.lastScan;

    String recipientName = form.recipient!.displayName;
    TextStyle recipientTextStyle = BitcoinTextStyle.body4(Bitcoin.neutral7);

    if (recipientName == form.recipient!.paymentCode) {
      // format static address nicely
      recipientName =
          displayAddress(context, recipientName, recipientTextStyle, 0.86);
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
                    suffixText: _getSuffixText(exchangeRate.bitcoinUnit),
                  ),
                  keyboardType: exchangeRate.bitcoinUnit == BitcoinUnit.btc
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.number,
                ),
                const SizedBox(
                  height: 10.0,
                ),
                if (exchangeRate.bitcoinUnit == BitcoinUnit.btc)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      'Extra decimals removed - satoshis are the smallest unit',
                      style: BitcoinTextStyle.body5(Bitcoin.neutral6),
                    ),
                  ),
                Text(
                    'Available Balance: ${exchangeRate.displayBitcoin(availableBalance)}',
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
          FooterButton(
            title: 'Proceed to fee selection',
            onPressed: () => onContinue(availableBalance, exchangeRate),
          ),
        ],
      ),
    );
  }
}
