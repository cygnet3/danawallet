import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/bip353_address.dart';
import 'package:danawallet/data/models/contact.dart';
import 'package:danawallet/data/models/recipient_form.dart';
import 'package:danawallet/exceptions.dart';
import 'package:danawallet/generated/rust/api/validate.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/screens/home/wallet/spend/amount_selection.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:danawallet/services/bip353_resolver.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_outlined.dart';
import 'package:danawallet/widgets/qr_code_scanner_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class ChooseRecipientScreen extends StatefulWidget {
  final String? initialAddress;

  const ChooseRecipientScreen({super.key, this.initialAddress});

  @override
  ChooseRecipientScreenState createState() => ChooseRecipientScreenState();
}

class ChooseRecipientScreenState extends State<ChooseRecipientScreen> {
  late final TextEditingController textFieldController;
  String? _addressErrorText;

  @override
  void initState() {
    super.initState();
    textFieldController = TextEditingController(
      text: widget.initialAddress ?? '',
    );
  }

  @override
  void dispose() {
    textFieldController.dispose();
    super.dispose();
  }

  Future<void> onContinue() async {
    RecipientForm form = RecipientForm();
    // reset all fields
    form.reset();

    setState(() {
      _addressErrorText = null;
    });

    final network = Provider.of<ChainState>(context, listen: false).network;
    try {
      Bip353Address? bip353Address;
      String onchainAddress;

      String textField = textFieldController.text.trim();

      if (textField.contains('@')) {
        // we interpret the input as a bip353 address
        try {
          Logger().d('Resolving dana address: "$textField"');

          bip353Address = Bip353Address.fromString(textField);

          final resolvedAddress =
              await Bip353Resolver.resolve(bip353Address, network);

          if (resolvedAddress == null) {
            // DNS resolution returned null - address not registered
            Logger().w('Dana address "$textField" not found in DNS');
            throw Exception('Dana address not found or not registered');
          }

          // Store the original dana address for the form
          onchainAddress = resolvedAddress;

          Logger().d(
              'Successfully resolved dana address to SP address: ${textField.substring(0, 20)}...');
        } catch (e) {
          displayError('Failed to resolve dana address "$textField"', e);
          return;
        }
      } else {
        // we interpret the input field as an on-chain address
        onchainAddress = textField;
      }

      try {
        if (context.mounted) {
          validateAddressWithNetwork(
              address: onchainAddress, network: network.toCoreArg);
        }
      } catch (e) {
        if (e.toString().contains('network')) {
          throw InvalidNetworkException();
        } else {
          throw InvalidAddressException();
        }
      }

      // note: in this case, we set the spAddress as a on-chain address.
      // this means we have to be careful at the end of the send-flow, to not allow users
      // to add this contact to their contact list, as regular on-chain addresses are not allowed.
      form.recipient =
          Contact(bip353Address: bip353Address, paymentCode: onchainAddress);

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
      textFieldController.text = data.text ?? '';
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
      textFieldController.text = result;
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
              const SizedBox(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pay to'),
                  const SizedBox(
                    height: 20.0,
                  ),
                  TextField(
                    onTap: () => setState(() => _addressErrorText = null),
                    style: BitcoinTextStyle.body4(Bitcoin.black),
                    controller: textFieldController,
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
                  FooterButtonOutlined(
                      title: "Paste from clipboard",
                      onPressed: onPasteFromClipboard),
                  const SizedBox(
                    height: 10.0,
                  ),
                  FooterButtonOutlined(
                      title: "Scan QR Code", onPressed: onScanWithCamera)
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
