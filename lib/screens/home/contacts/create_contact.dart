import 'package:danawallet/data/models/contacts.dart';
import 'package:danawallet/data/models/payment_address.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/repositories/contact_dao.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreateContactScreen extends StatefulWidget {
  final PaymentAddress? newAddress;

  const CreateContactScreen({Key? key, this.newAddress}) : super(key: key);

  @override
  _CreateContactScreenState createState() => _CreateContactScreenState();
}

class _CreateContactScreenState extends State<CreateContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  String? _addressErrorText;

  @override
  void initState() {
    super.initState();
    if (widget.newAddress != null) {
      _addressController.text = widget.newAddress!.inner.stringRepresentation;
    }
  }

  @override
  void dispose() {
    _contactNameController.dispose();
    _addressController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  void _validateAddress(String address) {
    try {
      ApiSilentPaymentAddress.fromStringRepresentation(address: address);
      setState(() {
        _addressErrorText = null;
      });
    } catch (e) {
      setState(() {
        _addressErrorText = 'Invalid address format';
      });
    }
  }

  Future<void> _saveContact() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Retrieve the address from the text controller
      final addressText = _addressController.text.trim();
      final accountName = _accountNameController.text.trim().isEmpty
          ? "Default"
          : _accountNameController.text.trim();

      // Convert the address text to ApiSilentPaymentAddress
      ApiSilentPaymentAddress? address;
      try {
        address = ApiSilentPaymentAddress.fromStringRepresentation(
            address: addressText);
      } catch (e) {
        // Handle the error if the address is not valid
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid address format.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Map<PaymentAddress, String> addresses = {
        PaymentAddress(address): accountName
      };

      final newContact = Contact(
        nym: _contactNameController.text.trim(),
        addresses: addresses,
      );
      final contactDao = Provider.of<ContactDAO>(context, listen: false);

      await contactDao.insertContact(newContact);

      if (mounted) {
        Navigator.of(context).pop(newContact);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a New Contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _contactNameController,
                decoration: const InputDecoration(
                  labelText: 'Contact Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name for this contact';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _accountNameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _addressController,
                readOnly: widget.newAddress != null,
                decoration: InputDecoration(
                  labelText: 'Contact Address',
                  border: const OutlineInputBorder(),
                  fillColor:
                      widget.newAddress != null ? Colors.grey[200] : null,
                  filled: widget.newAddress != null,
                  errorText: _addressErrorText,
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                style: TextStyle(
                  color: widget.newAddress != null ? Colors.grey : null,
                ),
                onChanged: _validateAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveContact,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(48),
                ),
                child: const Text('Save Contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
