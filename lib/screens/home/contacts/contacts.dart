import 'dart:io';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/payment_address.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/screens/home/contacts/create_contact.dart';
import 'package:danawallet/screens/home/wallet/spend/choose_recipient.dart';
import 'package:danawallet/widgets/qr_code_scanner_widget.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:provider/provider.dart';
import 'package:danawallet/data/models/contacts.dart';
import 'package:danawallet/repositories/contact_dao.dart';

class ContactsScreen extends StatelessWidget {
  final bool pickAddress;
  const ContactsScreen({super.key, this.pickAddress = false});

  @override
  Widget build(BuildContext context) {
    // Watch the DAO so this widget rebuilds on any change:
    final dao = context.watch<ContactDAO>();
    final contacts = dao.contacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
      ),
      body: contacts.isEmpty
          ? const Center(
              child: Text('No contacts yet.\nTap below to add your first one.',
                  textAlign: TextAlign.center),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ListTile(
                          leading: contact.imagePath != null &&
                                  contact.imagePath!.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage:
                                      FileImage(File(contact.imagePath!)),
                                )
                              : const CircleAvatar(
                                  backgroundImage: AssetImage(
                                      'assets/images/default_avatar.png'),
                                ),
                          title: Text(contact.nym),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            if (!pickAddress) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ContactDetailPage(contact: contact),
                                ),
                              );
                            } else {
                              final PaymentAddress? addr =
                                  await Navigator.of(context)
                                      .push<PaymentAddress>(
                                MaterialPageRoute(
                                  builder: (_) => ContactDetailPage(
                                    contact: contact,
                                    onAddressSelected: (a) =>
                                        Navigator.of(context).pop(a),
                                  ),
                                ),
                              );
                              if (addr != null && context.mounted)
                                Navigator.of(context).pop(addr);
                            }
                          });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'With Dana wallet, you can store payment information of your friends, '
                    'clients, customers and even favourite projects for donations!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => _showCreateOptions(context),
          icon: const Icon(Icons.person_add),
          label: const Text('Create Contact', style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Add Manually'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateContactScreen(newAddress: null),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan'),
              onTap: () async {
                final result = await Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (ctx) => const QRCodeScannerWidget(),
                  ),
                );
                if (result is String && result != "") {
                  // Check that it's a valid address
                  try {
                    final scannedAddress =
                        ApiSilentPaymentAddress.fromStringRepresentation(
                            address: result);
                    CreateContactScreen(
                        newAddress: PaymentAddress(scannedAddress));
                  } catch (e) {
                    Logger().e('Not an address');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ContactDetailPage extends StatelessWidget {
  final Contact contact;
  final void Function(PaymentAddress)? onAddressSelected;

  const ContactDetailPage(
      {Key? key, required this.contact, this.onAddressSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final addresses = contact.addresses.keys.toList();
    return Scaffold(
      appBar: AppBar(title: Text(contact.nym)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 48,
            backgroundImage:
                contact.imagePath != null && contact.imagePath!.isNotEmpty
                    ? FileImage(File(contact.imagePath!))
                    : const AssetImage('assets/images/default_avatar.png')
                        as ImageProvider,
          ),
          const SizedBox(height: 16),
          Text(
            contact.nym,
            style: BitcoinTextStyle.title1(Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Divider(),
          Expanded(
            child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: addresses.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final addr = addresses[i];
                  final label = contact.addresses[addr]!;
                  final displayLabel = label.isNotEmpty ? label : 'Unknown';

                  return ListTile(
                    title: Text(
                      displayLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(addr.inner.stringRepresentation),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      if (onAddressSelected != null) {
                        onAddressSelected!(addr);
                      } else {
                        // We initialize spending with this address
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChooseRecipientScreen(
                                    initialAddress:
                                        addr.inner.stringRepresentation)));
                      }
                    },
                  );
                }),
          ),
        ],
      ),
    );
  }
}
