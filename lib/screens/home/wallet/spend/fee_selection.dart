import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/recipient_form.dart';
import 'package:danawallet/data/models/recipient_form_filled.dart';
import 'package:danawallet/data/enums/selected_fee.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/wallet/spend/ready_to_send.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:danawallet/screens/home/wallet/spend/custom_fee_screen.dart';
import 'package:danawallet/states/fiat_exchange_rate_state.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeeSelectionScreen extends StatefulWidget {
  const FeeSelectionScreen({super.key});
  @override
  State<FeeSelectionScreen> createState() {
    return FeeSelectionScreenState();
  }
}

class FeeSelectionScreenState extends State<FeeSelectionScreen> {
  SelectedFee _selected = SelectedFee.normal;
  final Map<SelectedFee, ApiAmount> _feeAmounts = {};
  bool _isLoadingFees = true;

  @override
  void initState() {
    super.initState();
    _computeFeeAmounts();
  }

  void _computeFeeAmounts() async {
    final walletState = Provider.of<WalletState>(context, listen: false);
    RecipientForm form = RecipientForm();

    for (SelectedFee fee in [
      SelectedFee.fast,
      SelectedFee.normal,
      SelectedFee.slow
    ]) {
      form.selectedFee = fee;
      final filled = form.toFilled();
      final feeEstimationTx =
          await walletState.createUnsignedTxToThisRecipient(filled);
      BigInt inputSum = BigInt.from(0);
      for (var (_, utxo) in feeEstimationTx.selectedUtxos) {
        inputSum += utxo.amount.field0;
      }
      BigInt outputSum = BigInt.from(0);
      for (var recipient in feeEstimationTx.recipients) {
        outputSum += recipient.amount.field0;
      }
      _feeAmounts[fee] = ApiAmount(field0: inputSum - outputSum);
    }

    if (mounted) {
      setState(() {
        _isLoadingFees = false;
      });
    }
  }

  // Get the fee amount for a specific fee type
  ApiAmount? getFeeAmount(SelectedFee fee) {
    return _feeAmounts[fee];
  }

  // Get the fee amount for the currently selected fee
  ApiAmount? getCurrentSelectedFeeAmount() {
    return _feeAmounts[_selected];
  }

  Future<void> onContinue() async {
    RecipientForm().selectedFee = _selected;

    final walletState = Provider.of<WalletState>(context, listen: false);
    final changeAddress = walletState.changeAddress;
    RecipientForm form = RecipientForm();

    RecipientFormFilled filled = form.toFilled();

    final unsignedTx =
        await walletState.createUnsignedTxToThisRecipient(filled);
    form.unsignedTx = unsignedTx;

    // update the send amount to the actual sent amount (can be different e.g. dust)
    // this should probably be done already on the amount screen?
    form.amount = form.unsignedTx!.getSendAmount(changeAddress: changeAddress);

    if (mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ReadyToSendScreen()));
    }
  }

  ListTile toListTile(SelectedFee fee, FiatExchangeRateState exchangeRate) {
    switch (fee) {
      case SelectedFee.fast:
      case SelectedFee.normal:
      case SelectedFee.slow:
        if (_isLoadingFees) {
          return ListTile(
            title: Row(
              children: [
                Text(
                  fee.toName,
                  style: BitcoinTextStyle.body3(Bitcoin.black),
                ),
                const Spacer(),
                Text(fee.toEstimatedTime,
                    style: BitcoinTextStyle.body3(Bitcoin.black)),
              ],
            ),
            subtitle: Text('Loading...',
                style: BitcoinTextStyle.body3(Bitcoin.black)),
            leading: Radio<SelectedFee>(
              groupValue: _selected,
              value: fee,
              onChanged: null, // Disabled while loading
            ),
          );
        }

        final estimatedFee = _feeAmounts[fee];
        if (estimatedFee == null) {
          throw Exception('Fee amount not computed for $fee');
        }
        return ListTile(
          title: Row(
            children: [
              Text(
                fee.toName,
                style: BitcoinTextStyle.body3(Bitcoin.black),
              ),
              const Spacer(),
              Text(fee.toEstimatedTime,
                  style: BitcoinTextStyle.body3(Bitcoin.black)),
            ],
          ),
          subtitle: Row(
            children: [
              Text(estimatedFee.displaySats(),
                  style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
              const Spacer(),
              Text(exchangeRate.displayFiat(estimatedFee),
                  style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
            ],
          ),
          leading: Radio<SelectedFee>(
            groupValue: _selected,
            value: fee,
            onChanged: (SelectedFee? value) {
              if (value != null) {
                setState(() {
                  _selected = value;
                });
              }
            },
          ),
        );
      case SelectedFee.custom:
        return ListTile(
          title: Text(
            SelectedFee.custom.toName,
            style: BitcoinTextStyle.body3(Bitcoin.black),
          ),
          trailing: const Image(
            image: AssetImage("icons/caret_right.png", package: "bitcoin_ui"),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CustomFeeScreen()),
            );
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exchangeRate =
        Provider.of<FiatExchangeRateState>(context, listen: false);

    return SpendSkeleton(
      showBackButton: true,
      title: 'Confirmation time',
      body: Column(children: [
        const Divider(),
        toListTile(SelectedFee.fast, exchangeRate),
        const Divider(),
        toListTile(SelectedFee.normal, exchangeRate),
        const Divider(),
        toListTile(SelectedFee.slow, exchangeRate),
        const Divider(),
        if (isDevEnv) toListTile(SelectedFee.custom, exchangeRate),
        if (isDevEnv) const Divider(),
      ]),
      footer: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const SizedBox(
            height: 10.0,
          ),
          FooterButton(title: 'Continue', onPressed: onContinue)
        ],
      ),
    );
  }
}
