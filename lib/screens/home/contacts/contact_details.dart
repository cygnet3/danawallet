import 'package:barcode_widget/barcode_widget.dart';
import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:danawallet/data/models/contact.dart';
import 'package:danawallet/data/models/recipient_form.dart';
import 'package:danawallet/exceptions.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/generated/rust/api/validate.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/data/models/contact_field.dart';
import 'package:danawallet/services/bip353_resolver.dart';
import 'package:danawallet/screens/home/contacts/add_edit_field_sheet.dart';
import 'package:danawallet/screens/home/contacts/edit_contact_sheet.dart';
import 'package:danawallet/screens/home/wallet/spend/amount_selection.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/contacts_state.dart';
import 'package:danawallet/states/fiat_exchange_rate_state.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class ContactDetailsScreen extends StatefulWidget {
  final Contact contact;

  const ContactDetailsScreen({super.key, required this.contact});

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  late Contact _currentContact;
  bool _contactWasUpdated = false;
  List<ContactField> _customFields = [];

  @override
  void initState() {
    super.initState();
    _currentContact = widget.contact;
    _loadCustomFields();
  }

  Future<void> _loadCustomFields() async {
    if (_currentContact.id != null) {
      final fields = await Provider.of<ContactsState>(context, listen: false)
          .getContactFields(_currentContact.id!);
      if (mounted) {
        setState(() {
          _customFields = fields;
        });
      }
    }
  }

  Future<void> _reloadContact() async {
    if (_currentContact.id != null) {
      final updatedContact =
          await Provider.of<ContactsState>(context, listen: false)
              .getContact(_currentContact.id!);
      if (updatedContact != null && mounted) {
        setState(() {
          _currentContact = updatedContact;
        });
        await _loadCustomFields();
      }
    }
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

  String _formatAddress(String address) {
    if (address.length <= 20) {
      // If address is short, just group by 4
      return _groupByFour(address);
    }

    // First 12 characters grouped by 4
    final firstPart = _groupByFour(address.substring(0, 12));
    // Last 8 characters grouped by 4
    final lastPart = _groupByFour(address.substring(address.length - 8));

    return '$firstPart ... $lastPart';
  }

  String _groupByFour(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i += 4) {
      if (i > 0) buffer.write(' ');
      final end = (i + 4 < text.length) ? i + 4 : text.length;
      buffer.write(text.substring(i, end));
    }
    return buffer.toString();
  }

  Future<void> _copyDanaAddress() async {
    if (_currentContact.danaAddress != null) {
      await Clipboard.setData(
          ClipboardData(text: _currentContact.danaAddress!));
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dana address copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showEditContactSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditContactSheet(
        contact: _currentContact,
        onContactUpdated: () {
          Navigator.pop(context, 'updated');
        },
      ),
    );

    if (result == 'deleted' && mounted) {
      // Contact was deleted, close contact details and return true to refresh list
      Navigator.pop(context, true);
    } else if (result == 'updated' && mounted) {
      await _reloadContact();
      setState(() {
        _contactWasUpdated = true;
      });
    }
  }

  Widget _buildCustomFieldItem(ContactField field) {
    return ListTile(
      title: Text(
        field.fieldType,
        style: BitcoinTextStyle.body3(Bitcoin.black).apply(fontWeightDelta: 1),
      ),
      subtitle: Text(
        field.fieldValue,
        style: BitcoinTextStyle.body5(Bitcoin.neutral7),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: Bitcoin.neutral7),
        onSelected: (value) async {
          if (value == 'edit') {
            _showEditFieldSheet(field);
          } else if (value == 'delete') {
            _deleteField(field);
          } else if (value == 'copy') {
            await Clipboard.setData(ClipboardData(text: field.fieldValue));
            HapticFeedback.lightImpact();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${field.fieldType} copied to clipboard'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'copy',
            child: Row(
              children: [
                Icon(Icons.copy, size: 20),
                SizedBox(width: 8),
                Text('Copy'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      onTap: () {
        _showEditFieldSheet(field);
      },
    );
  }

  void _showAddFieldSheet() async {
    if (_currentContact.id == null) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditFieldSheet(
        contactId: _currentContact.id!,
      ),
    );

    if (result == true && mounted) {
      await _loadCustomFields();
      setState(() {
        _contactWasUpdated = true;
      });
    }
  }

  void _showEditFieldSheet(ContactField field) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditFieldSheet(
        field: field,
        contactId: _currentContact.id!,
      ),
    );

    if (result == true && mounted) {
      await _loadCustomFields();
      setState(() {
        _contactWasUpdated = true;
      });
    }
  }

  Future<void> _deleteField(ContactField field) async {
    if (field.id == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Field'),
        content: Text('Are you sure you want to delete "${field.fieldType}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<ContactsState>(context, listen: false)
            .deleteContactField(field.id!);
        if (mounted) {
          await _loadCustomFields();
          setState(() {
            _contactWasUpdated = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Field deleted'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete field: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToSendFlow() async {
    try {
      final form = RecipientForm();
      form.reset();

      // Use dana address if available, otherwise use SP address
      String address = (_currentContact.danaAddress != null &&
              _currentContact.danaAddress!.isNotEmpty)
          ? _currentContact.danaAddress!
          : _currentContact.spAddress;

      if (address.contains('@')) {
        // Resolve dana address to SP address
        try {
          Logger().d('Resolving dana address: "$address"');

          final network =
              Provider.of<ChainState>(context, listen: false).network;

          final resolvedAddress =
              await Bip353Resolver.resolveFromAddress(address, network);

          if (resolvedAddress == null) {
            throw Exception('Dana address not found or not registered');
          }

          form.recipientBip353 = address;
          address = resolvedAddress;

          Logger().d('Successfully resolved dana address to SP address');
        } catch (e) {
          Logger().e('Failed to resolve dana address "$address": $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to resolve dana address: $e'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      // Validate address
      try {
        final network =
            Provider.of<WalletState>(context, listen: false).network;
        validateAddressWithNetwork(
            address: address, network: network.toCoreArg);
      } catch (e) {
        if (e.toString().contains('network')) {
          throw InvalidNetworkException();
        } else {
          throw InvalidAddressException();
        }
      }

      form.recipientAddress = address;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AmountSelectionScreen(),
          ),
        );
      }
    } catch (e) {
      Logger().e('Failed to set up send flow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exceptionToString(e)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _copyStaticAddress() async {
    await Clipboard.setData(ClipboardData(text: _currentContact.spAddress));
    HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Static address copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showStaticAddressSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Bitcoin.neutral4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Text(
              'Static Address',
              style: BitcoinTextStyle.title4(Bitcoin.black),
            ),
            const SizedBox(height: 20),
            // QR Code
            GestureDetector(
              onTap: _copyStaticAddress,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Bitcoin.neutral2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: BarcodeWidget(
                  data: _currentContact.spAddress,
                  barcode: Barcode.qrCode(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Address text
            GestureDetector(
              onTap: _copyStaticAddress,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Bitcoin.neutral2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      'tap to copy',
                      style: BitcoinTextStyle.body5(Bitcoin.neutral5),
                    ),
                    const SizedBox(height: 8),
                    addressAsRichText(_currentContact.spAddress, 14.0),
                  ],
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _getDisplayName(_currentContact);
    final initial = _getInitial(displayName);
    final avatarColor = _getAvatarColor(displayName);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: InkResponse(
          onTap: () {
            Navigator.of(context).pop(_contactWasUpdated);
          },
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: RichText(
              text: TextSpan(
                children: [
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Image(
                      image: AssetImage("icons/caret_left.png",
                          package: "bitcoin_ui"),
                    ),
                  ),
                  TextSpan(
                    text: 'Back',
                    style: BitcoinTextStyle.title5(Bitcoin.black)
                        .apply(fontFamily: 'Space Grotesk'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Bitcoin.black),
            onPressed: () {
              _showEditContactSheet();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: avatarColor,
              child: Text(
                initial,
                style: BitcoinTextStyle.body1(Bitcoin.white)
                    .apply(fontWeightDelta: 2, fontSizeDelta: 3),
              ),
            ),
            const SizedBox(height: 20),
            // Nym in bold (if any)
            if (_currentContact.nym != null)
              Text(
                _currentContact.nym!,
                style: BitcoinTextStyle.body2(Bitcoin.black)
                    .apply(fontWeightDelta: 2),
              ),
            if (_currentContact.nym != null) const SizedBox(height: 8),
            // Dana address slightly smaller - tappable to copy
            GestureDetector(
              onTap: _copyDanaAddress,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentContact.danaAddress ?? '',
                    style: BitcoinTextStyle.body4(Bitcoin.neutral7),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.copy,
                    size: 16,
                    color: Bitcoin.neutral7,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Send Bitcoin button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: BitcoinButtonFilled(
                tintColor: danaBlue,
                body: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Send Bitcoin  ',
                      style: BitcoinTextStyle.body3(Bitcoin.white),
                    ),
                    Image(
                      image: const AssetImage("icons/send.png",
                          package: "bitcoin_ui"),
                      color: Bitcoin.white,
                    ),
                  ],
                ),
                cornerRadius: 6,
                onPressed: () {
                  _navigateToSendFlow();
                },
              ),
            ),
            const SizedBox(height: 30),
            // List of items
            Expanded(
              child: ListView(
                children: [
                  // Static Address item
                  ListTile(
                    title: Text(
                      'Static Address',
                      style: BitcoinTextStyle.body3(Bitcoin.black)
                          .apply(fontWeightDelta: 1),
                    ),
                    subtitle: Text(
                      _formatAddress(_currentContact.spAddress),
                      style: BitcoinTextStyle.body5(Bitcoin.neutral7),
                    ),
                    trailing:
                        Icon(Icons.chevron_right, color: Bitcoin.neutral7),
                    onTap: () {
                      _showStaticAddressSheet();
                    },
                  ),
                  const Divider(),
                  // Sent item
                  ListTile(
                    title: Text(
                      'Sent',
                      style: BitcoinTextStyle.body3(Bitcoin.black)
                          .apply(fontWeightDelta: 1),
                    ),
                    trailing:
                        Icon(Icons.chevron_right, color: Bitcoin.neutral7),
                    onTap: () {
                      _showSentTransactionsSheet();
                    },
                  ),
                  const Divider(),
                  // Custom Fields Section
                  if (_customFields.isNotEmpty ||
                      _currentContact.id != null) ...[
                    ..._customFields
                        .map((field) => _buildCustomFieldItem(field)),
                    if (_currentContact.id != null)
                      ListTile(
                        leading: Icon(Icons.add, color: Bitcoin.blue),
                        title: Text(
                          'Add Field',
                          style: BitcoinTextStyle.body3(Bitcoin.blue)
                              .apply(fontWeightDelta: 1),
                        ),
                        onTap: () {
                          _showAddFieldSheet();
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ApiRecordedTransaction> _getSentTransactions() {
    final walletState = Provider.of<WalletState>(context, listen: false);
    final allTransactions = walletState.txHistory.toApiTransactions();
    final contactSpAddress = _currentContact.spAddress;

    // Filter to only outgoing transactions where recipient matches this contact's SP address
    return allTransactions.where((tx) {
      if (tx is ApiRecordedTransaction_Outgoing) {
        // Check if any recipient matches the contact's SP address
        return tx.field0.recipients
            .any((recipient) => recipient.address == contactSpAddress);
      }
      return false;
    }).toList();
  }

  ListTile _buildTransactionTile(
      ApiRecordedTransaction tx, FiatExchangeRateState exchangeRate) {
    // Only handle outgoing transactions (we filter for those)
    if (tx is! ApiRecordedTransaction_Outgoing) {
      throw Exception('Expected outgoing transaction');
    }

    final field0 = tx.field0;
    final recipient = _currentContact.nym ??
        _currentContact.danaAddress ??
        _currentContact.spAddress;
    final date = field0.confirmedAt?.toString() ?? 'Unconfirmed';
    final color = field0.confirmedAt == null ? Bitcoin.neutral4 : Bitcoin.red;
    final amount = field0.totalOutgoing().displayBtc();
    const amountprefix = '-';
    final amountFiat = exchangeRate.displayFiat(field0.totalOutgoing());
    const title = 'Outgoing transaction';
    final text = field0.toString();
    final image = Image(
        image: const AssetImage("icons/send.png", package: "bitcoin_ui"),
        color: Bitcoin.neutral3Dark);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: image,
      title: Row(
        children: [
          Text(
            recipient,
            style: BitcoinTextStyle.body4(Bitcoin.black),
          ),
          const Spacer(),
          Text('$amountprefix $amount', style: BitcoinTextStyle.body4(color)),
        ],
      ),
      subtitle: Row(
        children: [
          Text(date, style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
          const Spacer(),
          Text(amountFiat, style: BitcoinTextStyle.body5(Bitcoin.neutral7)),
        ],
      ),
      trailing: InkResponse(
          onTap: () {
            showAlertDialog(title, text);
          },
          child: Image(
            image: const AssetImage("icons/caret_right.png",
                package: "bitcoin_ui"),
            color: Bitcoin.neutral7,
          )),
    );
  }

  void _showSentTransactionsSheet() {
    final exchangeRate =
        Provider.of<FiatExchangeRateState>(context, listen: false);
    final sentTransactions = _getSentTransactions();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Bitcoin.neutral4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Text(
              'Sent to ${_currentContact.nym ?? _currentContact.danaAddress}',
              style: BitcoinTextStyle.title4(Bitcoin.black),
            ),
            const SizedBox(height: 20),
            // Transactions list
            Flexible(
              child: sentTransactions.isEmpty
                  ? Center(
                      child: Text(
                        'No transactions sent to this contact',
                        style: BitcoinTextStyle.body3(Bitcoin.neutral6),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      separatorBuilder: (context, index) => const Divider(),
                      reverse: false,
                      itemCount: sentTransactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionTile(
                          sentTransactions[sentTransactions.length - 1 - index],
                          exchangeRate,
                        );
                      },
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
