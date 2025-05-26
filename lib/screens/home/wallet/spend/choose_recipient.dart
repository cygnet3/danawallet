import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/payment_address.dart';
import 'package:danawallet/data/models/recipient_form.dart';
import 'package:danawallet/exceptions.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/generated/rust/api/validate.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/repositories/contact_dao.dart';
import 'package:danawallet/screens/home/contacts/contacts.dart';
import 'package:danawallet/screens/home/wallet/spend/amount_selection.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button_outlined.dart';
import 'package:danawallet/widgets/qr_code_scanner_widget.dart';
import 'package:dart_bip353/dart_bip353.dart';
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
  final TextEditingController addressController = TextEditingController();
  String? _addressErrorText;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      addressController.text = widget.initialAddress!;
      onContinue();
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

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
            address = data.silentpayment!;
          }
        } catch (e) {
          // todo wrap bip353 logic in a separate class that throws custom errors
          throw Exception('Failed to look up address');
        }
      }

      if (!validateAddress(address: address)) {
        throw InvalidAddressException();
      }

      form.recipientAddress = address;

      // Check if we have a contact associated to that address
      try {
        form.spAddress = PaymentAddress(
            ApiSilentPaymentAddress.fromStringRepresentation(
                address: form.recipientAddress!));
      } catch (e) {
        // This is a regular, disposable address, we just continue
        if (mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AmountSelectionScreen()));
        }
      }

      if (mounted) {
        final contactDao = Provider.of<ContactDAO>(context, listen: false);
        final existingContact =
            await contactDao.addressExistsIn(form.spAddress!);

        if (existingContact != null) {
          // We already know about that address, keep the contact
          form.contact = existingContact;
        }
      }

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

  Future<void> onSelectFromContact() async {
    final PaymentAddress? chosen =
        await Navigator.of(context).push<PaymentAddress>(
      MaterialPageRoute(
        builder: (_) => const ContactsScreen(pickAddress: true),
      ),
    );
    if (chosen != null) {
      addressController.text = chosen.inner.stringRepresentation;
      await onContinue();
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
              const SizedBox(),
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
                  FooterButtonOutlined(
                      title: "Paste from clipboard",
                      onPressed: onPasteFromClipboard),
                  const SizedBox(
                    height: 10.0,
                  ),
                  FooterButtonOutlined(
                    title: 'Choose from Contacts',
                    onPressed: onSelectFromContact,
                  ),
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
