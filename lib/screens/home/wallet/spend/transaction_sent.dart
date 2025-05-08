import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/contacts.dart';
import 'package:danawallet/data/models/payment_address.dart';
import 'package:danawallet/data/models/recipient_form.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/repositories/contact_dao.dart';
import 'package:danawallet/screens/home/home.dart';
import 'package:danawallet/screens/home/wallet/spend/spend_skeleton.dart';
import 'package:flutter/material.dart';

class TransactionSentScreen extends StatelessWidget {
  const TransactionSentScreen({super.key});

  Future<void> addToContacts(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    // Show a dialog to get the user's input for the contact name
    String? contactName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Enter Contact Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Contact Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(nameController.text);
              },
            ),
          ],
        );
      },
    );

    if (contactName == null || contactName.isEmpty) {
      return;
    }
    // Take the recipient form
    RecipientForm form = RecipientForm();

    // We should always have the recipientAddress available
    if (form.recipientAddress == null) {
      // Show an error message to user
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Recipient address is missing. Cannot add to contacts.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Map<PaymentAddress, List<String>> addressesMap = {};

    ApiSilentPaymentAddress spAddress;

    // We parse the address in the form into an ApiSilentPaymentAddress
    // It would fail if this is a regular one-time address, and that's fine we don't want to register that
    try {
      spAddress = ApiSilentPaymentAddress.fromStringRepresentation(address: form.recipientAddress!);
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Recipient address is not a silent payment address. Cannot add to contacts.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Also check if we already have this address in db
    final contactDao = ContactDAO();

    final existingContact = await contactDao.addressExistsIn(PaymentAddress(spAddress));
    if (existingContact != null) {
      // We show user the contact that already have this address
      messenger.showSnackBar(
        SnackBar(
          content: Text('Address found in contact ${existingContact.nym}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // We put it into the addresses map
    // TODO allow user to add labels to the address
    addressesMap[PaymentAddress(spAddress)] = [];

    final newContact = Contact(
      nym: contactName,
      addresses: addressesMap,
    );

    try {
      await contactDao.insertContact(newContact);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to add new contact: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    String estimatedTime = RecipientForm().fee!.toEstimatedTime;
    // If we already have a contact, we don't need to ask user to add to contact
    PaymentAddress? sentAddress = RecipientForm().contact != null ? null : RecipientForm().spAddress;

    return SpendSkeleton(
      showBackButton: false,
      body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 20.0,
            ),
            CircleAvatar(
              backgroundColor: Bitcoin.green,
              radius: 30, // Adjust size as needed
              child: Image(
                image: const AssetImage("icons/2.0x/share.png",
                    package: "bitcoin_ui"),
                color: Bitcoin.white,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            Text(
              "Transaction sent",
              style: BitcoinTextStyle.title4(Bitcoin.black),
            ),
            const SizedBox(
              height: 10.0,
            ),
            Text(
              "Your transfer should be completed in $estimatedTime.",
              textAlign: TextAlign.center,
              style: BitcoinTextStyle.body3(Bitcoin.neutral7),
            ),
          ]),
      footer: Column(
        children: [
          if (isDevEnv())
            BitcoinButtonOutlined(
              textStyle: BitcoinTextStyle.title4(Bitcoin.black),
              title: 'View transaction',
              onPressed: () => (),
              cornerRadius: 5.0,
            ),
          const SizedBox(
            height: 10.0,
          ),
          BitcoinButtonFilled(
            body: Text('Done', style: BitcoinTextStyle.body2(Bitcoin.neutral1)),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(sentAddress: sentAddress),
                ),
                (route) => false,
              );
            },
            cornerRadius: 5.0,
          )
        ],
      ),
    );
  }
}
