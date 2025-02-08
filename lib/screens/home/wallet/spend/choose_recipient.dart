import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/screens/home/wallet/spend/amount_selection.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:flutter/material.dart';

class ChooseRecipientScreen extends StatefulWidget {
  const ChooseRecipientScreen({super.key});

  @override
  ChooseRecipientScreenState createState() => ChooseRecipientScreenState();
}

class ChooseRecipientScreenState extends State<ChooseRecipientScreen> {
  final TextEditingController addressController = TextEditingController();
  String? _addressErrorText;

  @override
  Widget build(BuildContext context) {
    return SpendSkeleton(
        showBackButton: true,
        title: 'Choose recipient(s)',
        body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pay to'),
                  const SizedBox(
                    height: 20.0,
                  ),
                  TextField(
                    style: BitcoinTextStyle.body4(Bitcoin.black),
                    controller: addressController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Enter any payment info you have',
                      hintText: 'satoshi@bitcoin.org, sp1q..., bc1q...',
                      errorText: _addressErrorText,
                    ),
                  ),
                ],
              ),
              const Center(child: Text('or')),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  BitcoinButtonOutlined(
                    tintColor: Bitcoin.neutral5,
                    textStyle: BitcoinTextStyle.title4(Bitcoin.black),
                    title: 'Paste from clipboard',
                    onPressed: () => (),
                    cornerRadius: 5.0,
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  BitcoinButtonOutlined(
                      disabledTintColor: Bitcoin.neutral5,
                      textStyle: BitcoinTextStyle.title4(Bitcoin.black),
                      title: 'Choose from Contacts',
                      onPressed: () => (),
                      cornerRadius: 5.0,
                      disabled: true),
                  const SizedBox(
                    height: 10.0,
                  ),
                  BitcoinButtonOutlined(
                    tintColor: Bitcoin.neutral5,
                    textStyle: BitcoinTextStyle.title4(Bitcoin.black),
                    title: 'Scan from image',
                    onPressed: () => (),
                    cornerRadius: 5.0,
                  ),
                ],
              ),
              // these work as spacers, will remove them later
              const SizedBox(),
              const SizedBox(),
              const SizedBox(),
            ]),
        footer: BitcoinButtonFilled(
          textStyle: BitcoinTextStyle.body2(Bitcoin.neutral1),
          title: 'Continue',
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AmountSelectionScreen())),
          cornerRadius: 5.0,
        ));
  }
}
