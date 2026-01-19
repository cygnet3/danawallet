import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/data/enums/network.dart';
import 'package:danawallet/data/models/contact.dart';
import 'package:danawallet/data/models/contact_field.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/repositories/contacts_repository.dart';
import 'package:danawallet/services/bip353_resolver.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ContactsState extends ChangeNotifier {
  Contact? _youContact;
  final List<Contact> _contacts = List.empty(growable: true);
  final ContactsRepository _repository = ContactsRepository.instance;

  ContactsState();

  Future<void> initialize(String spAddress, String? danaAddress) async {
    // Initialize the 'you' contact
    _youContact = Contact(
      nym: 'you',
      spAddress: spAddress,
      danaAddress: danaAddress,
    );

    await refreshContacts();
  }

  Future<void> refreshContacts() async {
    // make sure we save no old state
    _contacts.clear();

    // then populate the rest of the contacts
    _contacts.addAll(await _repository.getAllContacts());

    notifyListeners();
  }

  /// Adds a new contact by dana address
  /// Resolves the dana address to SP address via DNS before saving
  ///
  /// Throws [ArgumentError] if dana address format is invalid
  /// Throws [Exception] if dana address cannot be resolved or contact already exists
  Future<void> addContact({
    required String spAddress,
    required Network network,
    String? danaAddress,
    String? nym,
  }) async {
    if (spAddress == _youContact!.spAddress) {
      throw Exception("Adding yourself is not allowed");
    }
    // First check for duplicates
    final existing = await _repository.getContactBySpAddress(spAddress);
    if (existing != null) {
      throw Exception('Contact with sp address $spAddress already exists');
    }

    if (danaAddress != null && danaAddress.isEmpty) {
      // set dana address to null if empty
      danaAddress = null;
    }

    // Resolve the SP address via DNS
    // Verify that the address is correct
    if (danaAddress != null) {
      if (!await Bip353Resolver.verifyAddress(
          danaAddress, spAddress, network)) {
        throw Exception("Dana address does not point to expected sp address");
      }
    }

    // Store and update cached contact list
    final contact = Contact(
      danaAddress: danaAddress,
      spAddress: spAddress,
      nym: nym,
    );

    final id = await _repository.insertContact(contact);
    contact.id = id;

    _contacts.add(contact);

    Logger().i('Contact added successfully: $danaAddress -> $spAddress');

    await refreshContacts();
  }

  Set<String> getKnownDanaAddresses() {
    Set<String> result = {};
    // add your own dana address
    if (_youContact?.danaAddress != null) {
      result.add(_youContact!.danaAddress!);
    }

    // add contacts dana address
    for (var contact in _contacts) {
      if (contact.danaAddress != null) {
        result.add(contact.danaAddress!.toLowerCase());
      }
    }
    return result;
  }

  Contact getYouContact() {
    return _youContact!;
  }

  List<Contact> getOtherContacts() {
    return _contacts;
  }

  /// Creates the appropriate display widget for a given silent payment address, using data from the contact list
  /// Priority: contact name (nym) > contact dana address > SP address
  /// note: this may not be the best place to put this function, may be refactored out later
  Widget getDisplayNameWidget(BuildContext context, String spAddress) {
    final Contact? contact =
        _contacts.firstWhereOrNull((contact) => contact.spAddress == spAddress);

    if (contact != null) {
      if (contact.nym != null) {
        return Text(
          contact.nym!,
          style: BitcoinTextStyle.body4(Bitcoin.black),
        );
      } else if (contact.danaAddress != null) {
        return danaAddressAsRichText(contact.danaAddress!, 15.0);
      } else {
        return Text(
            displayAddress(context, spAddress,
                BitcoinTextStyle.body4(Bitcoin.black), 0.53),
            style: BitcoinTextStyle.body4(Bitcoin.black));
      }
    } else {
      return Text(
        displayAddress(
            context, spAddress, BitcoinTextStyle.body4(Bitcoin.black), 0.53),
        style: BitcoinTextStyle.body4(Bitcoin.black),
      );
    }
  }

  /// Updates an existing contact
  ///
  /// Throws [ArgumentError] if contact id is null
  /// Throws [Exception] if contact doesn't exist or update fails
  Future<void> updateContact(Contact contact) async {
    if (contact.id == null) {
      throw ArgumentError('Cannot update contact without id');
    }

    // Verify contact exists
    final existing = await _repository.getContact(contact.id!);
    if (existing == null) {
      throw Exception('Contact with id ${contact.id} not found');
    }

    final rowsUpdated = await _repository.updateContact(contact);
    if (rowsUpdated == 0) {
      throw Exception('Failed to update contact');
    }

    Logger().i('Contact updated successfully: ${contact.danaAddress}');

    await refreshContacts();
  }

  /// Deletes a contact by id
  Future<void> deleteContact(int id) async {
    final rowsDeleted = await _repository.deleteContact(id);
    final deleted = rowsDeleted > 0;

    if (deleted) {
      Logger().i('Contact deleted successfully: id=$id');
    } else {
      Logger().w('Contact not found for deletion: id=$id');
    }

    await refreshContacts();
  }

  // Contact Fields Management

  /// Adds a new custom field to a contact
  ///
  /// Throws [ArgumentError] if field type or value is empty
  /// Throws [Exception] if contact doesn't exist
  Future<ContactField> addContactField({
    required int contactId,
    required String fieldType,
    required String fieldValue,
  }) async {
    // Validate inputs
    if (fieldType.trim().isEmpty) {
      throw ArgumentError('Field type cannot be empty');
    }

    if (fieldValue.trim().isEmpty) {
      throw ArgumentError('Field value cannot be empty');
    }

    // Verify contact exists
    final contact = await _repository.getContact(contactId);
    if (contact == null) {
      throw Exception('Contact with id $contactId not found');
    }

    final field = ContactField(
      contactId: contactId,
      fieldType: fieldType.trim(),
      fieldValue: fieldValue.trim(),
    );

    final id = await _repository.insertContactField(field);
    field.id = id;

    Logger().i('Contact field added: $fieldType for contact $contactId');

    await refreshContacts();
    return field;
  }

  /// Updates an existing contact field
  ///
  /// Throws [ArgumentError] if field id is null or values are empty
  /// Throws [Exception] if field doesn't exist
  Future<void> updateContactField(ContactField field) async {
    if (field.id == null) {
      throw ArgumentError('Cannot update contact field without id');
    }

    if (field.fieldType.trim().isEmpty) {
      throw ArgumentError('Field type cannot be empty');
    }

    if (field.fieldValue.trim().isEmpty) {
      throw ArgumentError('Field value cannot be empty');
    }

    // Verify field exists
    final existing = await _repository.getContactField(field.id!);
    if (existing == null) {
      throw Exception('Contact field with id ${field.id} not found');
    }

    final rowsUpdated = await _repository.updateContactField(field);
    if (rowsUpdated == 0) {
      throw Exception('Failed to update contact field');
    }

    Logger().i('Contact field updated: ${field.fieldType} (id=${field.id})');

    await refreshContacts();
  }

  /// Deletes a contact field by id
  ///
  /// Returns true if field was deleted, false if not found
  Future<bool> deleteContactField(int id) async {
    final rowsDeleted = await _repository.deleteContactField(id);
    final deleted = rowsDeleted > 0;

    if (deleted) {
      Logger().i('Contact field deleted: id=$id');
    } else {
      Logger().w('Contact field not found for deletion: id=$id');
    }

    await refreshContacts();
    return deleted;
  }

  Future<Contact?> getContact(int id) async {
    return await _repository.getContact(id, loadCustomFields: false);
  }

  Future<Contact?> getContactBySpAddress(String spAddress) async {
    return await _repository.getContactBySpAddress(spAddress);
  }

  /// Gets all custom fields for a contact
  Future<List<ContactField>> getContactFields(int contactId) async {
    return await _repository.getContactFields(contactId);
  }

  Future<void> reset() async {
    await _repository.deleteAllContacts();

    // extra precaution, shouldn't be needed
    _youContact = null;
    _contacts.clear();
  }
}
