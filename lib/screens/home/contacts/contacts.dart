import 'dart:io';
import 'package:danawallet/screens/home/contacts/create_contact.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:danawallet/data/models/contacts.dart';
import 'package:danawallet/repositories/contact_dao.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

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
                      final fren = contacts[index];
                      return ListTile(
                        leading: fren.imagePath != null &&
                                fren.imagePath!.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage:
                                    FileImage(File(fren.imagePath!)),
                              )
                            : const CircleAvatar(
                                backgroundImage:
                                    AssetImage('assets/images/default_avatar.png'),
                              ),
                        title: Text(fren.nym),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ContactDetailPage(fren: fren),
                          ),
                        ),
                      );
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
                    builder: (_) =>
                        const CreateContactScreen(sentAddress: null),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan'),
              onTap: () {
                Navigator.of(ctx).pop();
                // TODO: hook up scan flow
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ContactDetailPage extends StatelessWidget {
  final Contact fren;

  const ContactDetailPage({Key? key, required this.fren}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final addresses = fren.addresses.keys.toList();
    return Scaffold(
      appBar: AppBar(title: Text(fren.nym)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: addresses.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, i) {
          final addr = addresses[i];
          final labels = fren.addresses[addr];
          return ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(addr.inner.stringRepresentation),
            subtitle: labels != null 
            ? Wrap(
              spacing: 8.0,
              children: labels.map<Widget>((label) {
                return Chip(
                  label: Text(label),
                  backgroundColor: Colors.blueAccent, 
                  labelStyle: TextStyle(color: Colors.white),
                );
              }).toList()
            )
            : const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
