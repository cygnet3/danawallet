import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/contacts.dart';
import 'package:danawallet/repositories/contacts_repository.dart';
import 'package:danawallet/repositories/name_server_repository.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class AddContactSheet extends StatefulWidget {
  final String? initialDanaAddress;
  final String? initialSpAddress;

  const AddContactSheet({
    super.key,
    this.initialDanaAddress,
    this.initialSpAddress,
  });

  @override
  State<AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<AddContactSheet> {
  final TextEditingController _nymController = TextEditingController();
  final TextEditingController _danaAddressController = TextEditingController();
  final TextEditingController _spAddressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isResolving = false;
  String? _errorMessage;
  bool _hasDanaAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDanaAddress != null) {
      _danaAddressController.text = widget.initialDanaAddress!;
      _hasDanaAddress = widget.initialDanaAddress!.isNotEmpty;
    }
    if (widget.initialSpAddress != null) {
      _spAddressController.text = widget.initialSpAddress!;
    }
    _danaAddressController.addListener(() {
      final hasDanaAddress = _danaAddressController.text.trim().isNotEmpty;
      setState(() {
        _hasDanaAddress = hasDanaAddress;
      });
      
      // If dana address is filled, clear and resolve SP address
      if (hasDanaAddress) {
        _spAddressController.clear();
        _resolveDanaAddress();
      }
    });
    
    // Automatically resolve SP address if dana address is provided but SP address is not
    if (widget.initialDanaAddress != null && 
        widget.initialDanaAddress!.isNotEmpty && 
        (widget.initialSpAddress == null || widget.initialSpAddress!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveDanaAddress();
      });
    }
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
      final nameServerRepository = Provider.of<NameServerRepository>(context, listen: false);
      final resolved = await nameServerRepository.getAddressResolve(danaAddress);
      
      if (mounted && resolved != null && resolved.silentpayment != null) {
        setState(() {
          _spAddressController.text = resolved.silentpayment!;
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

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
        _errorMessage = 'Either dana address or static address must be provided';
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
          final nameServerRepository = Provider.of<NameServerRepository>(context, listen: false);
          final resolved = await nameServerRepository.getAddressResolve(danaAddress);
          if (resolved != null && resolved.silentpayment != null) {
            finalSpAddress = resolved.silentpayment!;
          } else {
            setState(() {
              _isSaving = false;
              _errorMessage = 'Could not resolve SP address for this dana address';
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

      // If we have SP address but no dana address, use empty string
      // (database allows empty strings for danaAddress)
      final contact = Contact(
        nym: nym,
        danaAddress: danaAddress,
        spAddress: finalSpAddress,
      );

      await ContactsRepository.instance.insertContact(contact);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      Logger().e('Failed to save contact: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save contact: $e';
        });
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
              'Add Contact',
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
                (_hasDanaAddress || _isResolving) ? Bitcoin.neutral6 : Bitcoin.black,
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Static Address (SP)',
                hintText: _hasDanaAddress ? 'Resolved from dana address' : 'sp1q...',
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
              onPressed: _isSaving ? null : _saveContact,
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}

