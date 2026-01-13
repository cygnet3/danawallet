import 'dart:async';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/contact.dart';
import 'package:danawallet/services/bip353_resolver.dart';
import 'package:danawallet/screens/home/contacts/add_contact_sheet.dart';
import 'package:danawallet/screens/home/contacts/contact_details.dart';
import 'package:danawallet/services/dana_address_service.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/contacts_state.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _remoteDanaAddresses = []; // Dana addresses from server search
  bool _isSearchingRemote = false;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.trim();

    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Clear remote results if query is empty
    if (query.isEmpty) {
      setState(() {
        _remoteDanaAddresses = [];
        _isSearchingRemote = false;
      });
      return;
    }

    // Debounce remote search to avoid too many API calls
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchRemoteAddresses(query);
    });

    setState(() {
      // Trigger rebuild to update filtered list
    });
  }

  Future<void> _searchRemoteAddresses(String prefix) async {
    if (prefix.isEmpty) return;

    // Get set of existing dana addresses from our contacts
    final knownDanaAddresses =
        Provider.of<ContactsState>(context, listen: false)
            .getKnownDanaAddresses();

    setState(() {
      _isSearchingRemote = true;
    });

    try {
      final network = Provider.of<ChainState>(context, listen: false).network;
      final danaAddresses =
          await DanaAddressService(network: network).searchPrefix(prefix);

      if (mounted) {
        // Filter out addresses that are already in our contacts
        final newAddresses = danaAddresses
            .where((address) =>
                !knownDanaAddresses.contains(address.toLowerCase()))
            .toList();

        setState(() {
          _remoteDanaAddresses = newAddresses;
          _isSearchingRemote = false;
        });
      }
    } catch (e) {
      Logger().w('Failed to search remote addresses: $e');
      if (mounted) {
        setState(() {
          _remoteDanaAddresses = [];
          _isSearchingRemote = false;
        });
      }
    }
  }

  List<Contact> _getFilteredOtherContacts(List<Contact> otherContacts) {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      return otherContacts;
    }

    return otherContacts.where((contact) {
      final displayName =
          (contact.nym ?? contact.danaAddress ?? contact.spAddress)
              .toLowerCase();
      return displayName.contains(query) ||
          contact.danaAddress != null &&
              contact.danaAddress!.toLowerCase().contains(query);
    }).toList();
  }

  String _getDisplayName(Contact contact) {
    return contact.nym ?? contact.danaAddress ?? contact.spAddress;
  }

  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  Color _getAvatarColor(String name) {
    // Generate a consistent color based on the name
    final hash = name.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
    ];
    return colors[hash.abs() % colors.length];
  }

  Widget _buildContactItem(Contact contact) {
    final displayName = _getDisplayName(contact);
    final initial = _getInitial(displayName);
    final avatarColor = _getAvatarColor(displayName);

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: avatarColor,
        child: Text(
          initial,
          style:
              BitcoinTextStyle.body3(Bitcoin.white).apply(fontWeightDelta: 2),
        ),
      ),
      title: Text(
        displayName,
        style: BitcoinTextStyle.body3(Bitcoin.black).apply(fontWeightDelta: 2),
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContactDetailsScreen(contact: contact),
          ),
        );
      },
    );
  }

  Widget _buildRemoteAddressItem(String danaAddress) {
    final initial = _getInitial(danaAddress);
    final avatarColor = _getAvatarColor(danaAddress);

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: avatarColor,
        child: Text(
          initial,
          style:
              BitcoinTextStyle.body3(Bitcoin.white).apply(fontWeightDelta: 2),
        ),
      ),
      title: Text(
        danaAddress,
        style: BitcoinTextStyle.body3(Bitcoin.black).apply(fontWeightDelta: 2),
      ),
      subtitle: Text(
        'Not in contacts',
        style: BitcoinTextStyle.body5(Bitcoin.neutral7),
      ),
      onTap: () async {
        // Resolve SP address and open add contact sheet
        String? spAddress;
        try {
          final network =
              Provider.of<ChainState>(context, listen: false).network;
          final resolved =
              await Bip353Resolver.resolveFromAddress(danaAddress, network);
          if (resolved != null) {
            spAddress = resolved;
          }
        } catch (e) {
          Logger().w('Failed to resolve SP address for $danaAddress: $e');
        }

        if (mounted) {
          await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddContactSheet(
              initialDanaAddress: danaAddress,
              initialSpAddress: spAddress,
            ),
          );
        }
      },
    );
  }

  void _openAddContactSheet() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddContactSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = Provider.of<ContactsState>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Contacts',
          style: BitcoinTextStyle.title4(Bitcoin.black),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddContactSheet,
        backgroundColor: Bitcoin.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 'You' contact at the top
            _buildContactItem(contactsState.getYouContact()),
            const SizedBox(height: 20),
            // Search bar
            TextField(
              controller: _searchController,
              style: BitcoinTextStyle.body4(Bitcoin.black),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Search contacts',
                hintText: 'Search by name or address',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _filterContacts();
              },
            ),
            const SizedBox(height: 20),
            // List of contacts and remote addresses
            Expanded(
              child: _buildSearchResults(contactsState.getOtherContacts()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<Contact> otherContacts) {
    final filteredContacts = _getFilteredOtherContacts(otherContacts);

    final query = _searchController.text.trim();
    final hasLocalResults = filteredContacts.isNotEmpty;
    final hasRemoteResults = _remoteDanaAddresses.isNotEmpty;
    final hasAnyResults = hasLocalResults || hasRemoteResults;

    if (query.isEmpty) {
      // No search query - show all contacts
      if (filteredContacts.isEmpty) {
        return Center(
          child: Text(
            otherContacts.isEmpty ? 'No contacts yet' : 'No contacts found',
            style: BitcoinTextStyle.body3(Bitcoin.neutral6),
          ),
        );
      }

      return ListView.separated(
        itemCount: filteredContacts.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return _buildContactItem(filteredContacts[index]);
        },
      );
    }

    // Search query exists
    if (!hasAnyResults && !_isSearchingRemote) {
      return Center(
        child: Text(
          'No contacts found',
          style: BitcoinTextStyle.body3(Bitcoin.neutral6),
        ),
      );
    }

    // Build combined list: local contacts first, then remote addresses
    final List<Widget> items = [];

    // Add local contacts
    if (hasLocalResults) {
      for (var contact in filteredContacts) {
        items.add(_buildContactItem(contact));
        items.add(const Divider());
      }
    }

    // Add remote addresses (not in contacts)
    if (hasRemoteResults) {
      for (var address in _remoteDanaAddresses) {
        items.add(_buildRemoteAddressItem(address));
        items.add(const Divider());
      }
    }

    // Remove last divider if exists
    if (items.isNotEmpty && items.last is Divider) {
      items.removeLast();
    }

    // Show loading indicator if searching remote
    if (_isSearchingRemote && !hasLocalResults && !hasRemoteResults) {
      return Center(
        child: Text(
          'Searching...',
          style: BitcoinTextStyle.body3(Bitcoin.neutral6),
        ),
      );
    }

    return ListView(
      children: items,
    );
  }
}
