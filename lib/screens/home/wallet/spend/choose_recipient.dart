import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/recipient_form.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/wallet/spend/amount_selection.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/qr_code_scanner_widget.dart';
import 'package:dart_bip353/dart_bip353.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChooseRecipientScreen extends StatefulWidget {
  const ChooseRecipientScreen({super.key});

  @override
  ChooseRecipientScreenState createState() => ChooseRecipientScreenState();
}

class ChooseRecipientScreenState extends State<ChooseRecipientScreen> {
  final TextEditingController addressController = TextEditingController();
  String? _addressErrorText;

  Future<void> onContinue() async {
    RecipientForm form = RecipientForm();
    // reset all fields
    form.reset();

    setState(() {
      _addressErrorText = null;
    });

    try {
      String address = addressController.text;
      if (address.contains('@')) {
        // we interpret the address as a bip353 address
        try {
          final data = await Bip353.getAdressResolve(address);
          if (data.silentpayment != null) {
            form.recipientBip353 = address;
            form.recipientAddress = data.silentpayment!;
          }
        } catch (e) {
          // todo wrap bip353 logic in a separate class that throws custom errors
          throw Exception('Failed to look up address');
        }
      } else {
        form.recipientAddress = addressController.text;
      }

      // todo: verify address

      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AmountSelectionScreen()));
      }
    } catch (e) {
      setState(() {
        _addressErrorText = exceptionToString(e);
      });
    }
  }

  Future<void> onPasteFromClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null) {
      addressController.text = data.text ?? '';
      await onContinue();
    }
  }

  Future<void> onScanWithCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRCodeScannerWidget(),
      ),
    );
    if (result is String && result != "") {
      addressController.text = result;
      await onContinue();
    }
  }

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
                    onPressed: onPasteFromClipboard,
                    cornerRadius: 5.0,
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  if (isDevEnv())
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
                    onPressed: onScanWithCamera,
                    cornerRadius: 5.0,
                  ),
                ],
              ),
              // these work as spacers, will remove them later
              const SizedBox(),
              const SizedBox(),
              const SizedBox(),
            ]),
        footer: FooterButton(
          title: 'Continue',
          onPressed: onContinue,
        ));
  }
}
