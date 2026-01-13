import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/models/contact_field.dart';
import 'package:danawallet/services/contacts_service.dart';
import 'package:danawallet/widgets/buttons/footer/footer_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddEditFieldSheet extends StatefulWidget {
  final ContactField?
      field; // If null, we're adding; if not null, we're editing
  final int contactId;

  const AddEditFieldSheet({
    super.key,
    this.field,
    required this.contactId,
  });

  @override
  State<AddEditFieldSheet> createState() => _AddEditFieldSheetState();
}

class _AddEditFieldSheetState extends State<AddEditFieldSheet> {
  final TextEditingController _fieldTypeController = TextEditingController();
  final TextEditingController _fieldValueController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _errorMessage;
  bool _isCustomType = false;
  String? _selectedFieldType;

  // Common field types
  static const List<String> commonFieldTypes = [
    'Email',
    'X',
    'Telegram',
    'GitHub',
    'Phone',
    'Website',
    'Nostr',
    'Notes',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.field != null) {
      _fieldValueController.text = widget.field!.fieldValue;
      _isCustomType = !commonFieldTypes.contains(widget.field!.fieldType);
      if (_isCustomType) {
        _fieldTypeController.text = widget.field!.fieldType;
      } else {
        _selectedFieldType = widget.field!.fieldType;
        _fieldTypeController.text = widget.field!.fieldType;
      }
    }
  }

  @override
  void dispose() {
    _fieldTypeController.dispose();
    _fieldValueController.dispose();
    super.dispose();
  }

  Future<void> _saveField() async {
    String fieldType;

    if (_isCustomType) {
      fieldType = _fieldTypeController.text.trim();
    } else {
      fieldType = _selectedFieldType ?? '';
    }

    final fieldValue = _fieldValueController.text.trim();

    if (fieldType.isEmpty) {
      setState(() {
        _errorMessage = 'Field type is required';
      });
      return;
    }

    if (fieldValue.isEmpty) {
      setState(() {
        _errorMessage = 'Field value is required';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (widget.field != null) {
        // Update existing field
        final updatedField = ContactField(
          id: widget.field!.id,
          contactId: widget.contactId,
          fieldType: fieldType,
          fieldValue: fieldValue,
        );
        await ContactsService.instance.updateContactField(updatedField);
      } else {
        // Create new field
        await ContactsService.instance.addContactField(
          contactId: widget.contactId,
          fieldType: fieldType,
          fieldValue: fieldValue,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save field: $e';
        });
      }
    }
  }

  void _onFieldTypeChanged(String? value) {
    if (value == 'Custom') {
      setState(() {
        _isCustomType = true;
        _selectedFieldType = null;
        _fieldTypeController.clear();
      });
    } else if (value != null) {
      setState(() {
        _isCustomType = false;
        _selectedFieldType = value;
        _fieldTypeController.text = value;
      });
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
              widget.field == null ? 'Add Field' : 'Edit Field',
              style: BitcoinTextStyle.title4(Bitcoin.black),
            ),
            const SizedBox(height: 20),
            // Field Type dropdown or text field
            if (!_isCustomType)
              DropdownButtonFormField<String>(
                value: _selectedFieldType,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Field Type',
                ),
                items: commonFieldTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: _onFieldTypeChanged,
                validator: (value) {
                  if (value == null || value.isEmpty || value == 'Custom') {
                    return 'Please select a field type';
                  }
                  return null;
                },
              )
            else
              TextField(
                controller: _fieldTypeController,
                style: BitcoinTextStyle.body4(Bitcoin.black),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Field Type',
                  hintText: 'e.g., LinkedIn, Discord, etc.',
                ),
                textCapitalization: TextCapitalization.words,
              ),
            const SizedBox(height: 16),
            // Field Value
            TextField(
              controller: _fieldValueController,
              style: BitcoinTextStyle.body4(Bitcoin.black),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Value',
                hintText: 'Enter the field value',
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
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
              onPressed: _isSaving ? null : _saveField,
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
