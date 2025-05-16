import 'package:danawallet/data/models/contacts.dart';
import 'package:danawallet/data/models/payment_address.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/repositories/contact_dao.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Screen for creating a new contact, adding the passed-in address with optional labels.
class CreateContactScreen extends StatefulWidget {
  final PaymentAddress? sentAddress;

  const CreateContactScreen({Key? key, this.sentAddress}) : super(key: key);

  @override
  _CreateContactScreenState createState() => _CreateContactScreenState();
}

class _CreateContactScreenState extends State<CreateContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _addressErrorText;
  // final TextEditingController _labelController = TextEditingController();
  // final List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    if (widget.sentAddress != null) {
      _addressController.text = widget.sentAddress!.inner.stringRepresentation;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    // _labelController.dispose();
    super.dispose();
  }

  void _validateAddress(String address) {
    try {
      ApiSilentPaymentAddress.fromStringRepresentation(address: address);
      setState(() {
        _addressErrorText = null; // Clear error if valid
      });
    } catch (e) {
      setState(() {
        _addressErrorText = 'Invalid address format'; // Set error message
      });
    }
  }

  // void _addLabel() {
  //   final text = _labelController.text.trim();
  //   if (text.isNotEmpty && !_labels.contains(text)) {
  //     setState(() {
  //       _labels.add(text);
  //       _labelController.clear();
  //     });
  //   }
  // }

  // void _removeLabel(String label) {
  //   setState(() {
  //     _labels.remove(label);
  //   });
  // }

  Future<void> _saveContact() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Retrieve the address from the text controller
      final addressText = _addressController.text.trim();

      // Convert the address text to ApiSilentPaymentAddress
      ApiSilentPaymentAddress? address;
      try {
        address = ApiSilentPaymentAddress.fromStringRepresentation(address: addressText);
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

      Map<PaymentAddress, List<String>> addresses = {
        PaymentAddress(address): []
      };

      final newContact = Contact(
        nym: _nameController.text.trim(),
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
        title: const Text('Create New Contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Contact Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              TextFormField(
                controller: _addressController,
                readOnly: widget.sentAddress != null,
                decoration: InputDecoration(
                  labelText: 'Contact Address',
                  border: const OutlineInputBorder(),
                  fillColor: widget.sentAddress != null ? Colors.grey[200] : null,
                  filled: widget.sentAddress != null,
                  errorText: _addressErrorText,  
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                style: TextStyle(
                  color: widget.sentAddress != null ? Colors.grey : null,
                ),
                onChanged: _validateAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              // Text(
              //   'Labels for this address (optional)',
              // ),
              // SizedBox(height: 8),

              // Wrap(
              //   spacing: 8,
              //   children: _labels
              //       .map(
              //         (label) => Chip(
              //           label: Text(label),
              //           onDeleted: () => _removeLabel(label),
              //         ),
              //       )
              //       .toList(),
              // ),
              // Row(
              //   children: [
              //     Expanded(
              //       child: TextField(
              //         controller: _labelController,
              //         decoration: InputDecoration(
              //           hintText: 'Add a label',
              //           border: OutlineInputBorder(),
              //         ),
              //         onSubmitted: (_) => _addLabel(),
              //       ),
              //     ),
              //     SizedBox(width: 8),
              //     ElevatedButton(
              //       onPressed: _addLabel,
              //       child: Text('Add'),
              //     ),
              //   ],
              // ),

              SizedBox(height: 32),
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
