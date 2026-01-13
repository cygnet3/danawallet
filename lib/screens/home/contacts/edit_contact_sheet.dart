import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/contact.dart';
import 'package:danawallet/services/bip353_resolver.dart';
import 'package:danawallet/states/chain_state.dart';
import 'package:danawallet/states/contacts_state.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class EditContactSheet extends StatefulWidget {
  final Contact contact;
  final VoidCallback onContactUpdated;

  const EditContactSheet({
    super.key,
    required this.contact,
    required this.onContactUpdated,
  });

  @override
  State<EditContactSheet> createState() => _EditContactSheetState();
}

class _EditContactSheetState extends State<EditContactSheet> {
  late TextEditingController _nymController;
  late TextEditingController _danaAddressController;
  late TextEditingController _spAddressController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isResolving = false;
  String? _errorMessage;
  bool _hasDanaAddress = false;

  @override
  void initState() {
    super.initState();
    _nymController = TextEditingController(text: widget.contact.nym ?? '');
    _danaAddressController =
        TextEditingController(text: widget.contact.danaAddress);
    _spAddressController =
        TextEditingController(text: widget.contact.spAddress);
    _hasDanaAddress = widget.contact.danaAddress != null &&
        widget.contact.danaAddress!.isNotEmpty;

    _danaAddressController.addListener(() {
      final hasDanaAddress = _danaAddressController.text.trim().isNotEmpty;
      setState(() {
        _hasDanaAddress = hasDanaAddress;
      });

      // If dana address is filled, clear and resolve SP address
      if (hasDanaAddress &&
          _danaAddressController.text.trim() != widget.contact.danaAddress) {
        _spAddressController.clear();
        _resolveDanaAddress();
      }
    });
  }

  @override
  void dispose() {
    _nymController.dispose();
    _danaAddressController.dispose();
    _spAddressController.dispose();
    super.dispose();
  }

  Future<void> _resolveDanaAddress() async {
    final danaAddress = _danaAddressController.text.trim();
    if (danaAddress.isEmpty) return;

    setState(() {
      _errorMessage = null;
      _isResolving = true;
    });

    try {
      final network = Provider.of<ChainState>(context, listen: false).network;
      final resolved =
          await Bip353Resolver.resolveFromAddress(danaAddress, network);

      if (mounted && resolved != null) {
        setState(() {
          _spAddressController.text = resolved;
          _isResolving = false;
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Could not resolve SP address for this dana address';
          _isResolving = false;
        });
      }
    } catch (e) {
      Logger().w('Failed to resolve dana address: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to resolve dana address: $e';
          _isResolving = false;
        });
      }
    }
  }

  Future<void> _updateContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final contacts = Provider.of<ContactsState>(context, listen: false);
    final nym = _nymController.text.trim();
    final danaAddress = _danaAddressController.text.trim();
    final spAddress = _spAddressController.text.trim();

    // Validation: at least dana address OR static address must be filled, and nym must be filled
    if (nym.isEmpty) {
      setState(() {
        _errorMessage = 'Nym is required';
      });
      return;
    }

    if (danaAddress.isEmpty && spAddress.isEmpty) {
      setState(() {
        _errorMessage =
            'Either dana address or static address must be provided';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // If we have dana address but no SP address, try to resolve it
      String finalSpAddress = spAddress;
      if (danaAddress.isNotEmpty && spAddress.isEmpty) {
        try {
          final network =
              Provider.of<ChainState>(context, listen: false).network;
          final resolved =
              await Bip353Resolver.resolveFromAddress(danaAddress, network);
          if (resolved != null) {
            finalSpAddress = resolved;
          } else {
            setState(() {
              _isSaving = false;
              _errorMessage =
                  'Could not resolve SP address for this dana address';
            });
            return;
          }
        } catch (e) {
          setState(() {
            _isSaving = false;
            _errorMessage = 'Failed to resolve SP address: $e';
          });
          return;
        }
      }

      // Update the contact
      final updatedContact = Contact(
        id: widget.contact.id,
        nym: nym,
        danaAddress: danaAddress,
        spAddress: finalSpAddress,
      );

      await contacts.updateContact(updatedContact);

      if (mounted) {
        widget.onContactUpdated(); // This already pops with 'updated'
      }
    } catch (e) {
      Logger().e('Failed to update contact: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to update contact: $e';
        });
      }
    }
  }

  Future<void> _deleteContact() async {
    if (widget.contact.id == null) return;

    final contacts = Provider.of<ContactsState>(context, listen: false);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text(
            'Are you sure you want to delete "${widget.contact.nym ?? widget.contact.danaAddress}"? This action cannot be undone.'),
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
        await contacts.deleteContact(widget.contact.id!);
        if (mounted) {
          // Return 'deleted' to indicate contact was deleted
          Navigator.pop(context, 'deleted');
        }
      } catch (e) {
        Logger().e('Failed to delete contact: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete contact: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              'Edit Contact',
              style: BitcoinTextStyle.title4(Bitcoin.black),
            ),
            const SizedBox(height: 20),
            // Nym field
            TextField(
              controller: _nymController,
              style: BitcoinTextStyle.body4(Bitcoin.black),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Nym',
                hintText: 'Contact name',
              ),
            ),
            const SizedBox(height: 16),
            // Dana address field
            TextField(
              controller: _danaAddressController,
              style: BitcoinTextStyle.body4(Bitcoin.black),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Dana Address',
                hintText: 'user@domain.com',
                suffixIcon: _hasDanaAddress
                    ? IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _resolveDanaAddress,
                        tooltip: 'Resolve SP address',
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            // Static address field
            TextField(
              controller: _spAddressController,
              style: BitcoinTextStyle.body4(
                (_hasDanaAddress || _isResolving)
                    ? Bitcoin.neutral6
                    : Bitcoin.black,
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Static Address (SP)',
                hintText:
                    _hasDanaAddress ? 'Resolved from dana address' : 'sp1q...',
                suffixIcon: _isResolving
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                filled: _hasDanaAddress,
                fillColor: _hasDanaAddress ? Bitcoin.neutral2 : null,
              ),
              readOnly: _hasDanaAddress || _isResolving,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: BitcoinTextStyle.body5(Bitcoin.red),
              ),
            ],
            const SizedBox(height: 20),
            // Save button
            FooterButton(
              title: _isSaving ? 'Saving...' : 'Save',
              onPressed: _isSaving ? null : _updateContact,
            ),
            const SizedBox(height: 12),
            // Delete button
            FooterButton(
              title: 'Delete Contact',
              onPressed: _deleteContact,
              color: Colors.red,
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
