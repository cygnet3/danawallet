import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:danawallet/data/models/contacts.dart';
import 'package:danawallet/repositories/contact_dao.dart';
import 'package:provider/provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late Future<List<Contact>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    final walletState = Provider.of<WalletState>(context, listen: false);
    _contactsFuture = _fetchContacts(walletState);
  }

  Future<List<Contact>> _fetchContacts(WalletState walletState) async {
    final frenDAO = ContactDAO();
    List<Contact> frens = await frenDAO.getContacts();

    if (frens.isEmpty) {
      final wallet = await walletState.getWalletFromSecureStorage();
      Map<ApiSilentPaymentAddress, List<String>> addressesMap = {};
      addressesMap[wallet.getSilentPaymentAddressForLabel(label: null)] = [];
      // We don't want to expose the change address to user
      final myContact = Contact(
        nym: "My Wallet",
        addresses: addressesMap,
      );

      await frenDAO.insertContact(myContact);

      frens = await frenDAO.getContacts();
    }
    return frens;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Contact>>(
      future: _contactsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final frens = snapshot.data!;
          return ListView.builder(
              itemCount: frens.length,
              itemBuilder: (context, index) {
                final fren = frens[index];
                return ListTile(
                    title: Text(fren.nym),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ContactDetailPage(fren: fren),
                        ),
                      );
                    });
              });
        }
      },
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
            title: Text(addr.stringRepresentation),
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
