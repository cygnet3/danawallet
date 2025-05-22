import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/recipient_form.dart';
import 'package:danawallet/data/models/recipient_form_filled.dart';
import 'package:danawallet/data/enums/selected_fee.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/wallet/spend/ready_to_send.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
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
  SelectedFee? _selected = SelectedFee.normal;

  Future<void> onContinue() async {
    RecipientForm().fee = _selected!;

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

  ListTile toListTile(SelectedFee fee) {
    final currentFeeRates = RecipientForm().currentFeeRates!;
    switch (fee) {
      case SelectedFee.fast:
      case SelectedFee.normal:
      case SelectedFee.slow:
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
              Text(fee.toEstimatedSats(currentFeeRates),
                  style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
              const Spacer(),
              Text(fee.toEstimatedEuro,
                  style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
            ],
          ),
          leading: Radio<SelectedFee>(
            groupValue: _selected,
            value: fee,
            onChanged: (SelectedFee? value) {
              setState(() {
                _selected = value;
              });
            },
          ),
        );
      case SelectedFee.custom:
        return ListTile(
          title: Text(
            SelectedFee.custom.toName,
            style: BitcoinTextStyle.body3(Bitcoin.black),
          ),
          leading: Radio<SelectedFee>(
            groupValue: _selected,
            value: SelectedFee.custom,
            onChanged: (SelectedFee? value) {
              setState(() {
                _selected = value;
              });
            },
          ),
          trailing: const Image(
            image: AssetImage("icons/caret_right.png", package: "bitcoin_ui"),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SpendSkeleton(
      showBackButton: true,
      title: 'Confirmation time',
      body: Column(children: [
        const Divider(),
        toListTile(SelectedFee.fast),
        const Divider(),
        toListTile(SelectedFee.normal),
        const Divider(),
        toListTile(SelectedFee.slow),
        const Divider(),
        if (isDevEnv()) toListTile(SelectedFee.custom),
        if (isDevEnv()) const Divider(),
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
