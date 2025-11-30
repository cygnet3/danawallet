import 'package:danawallet/data/enums/network.dart';
import 'package:danawallet/data/models/contacts.dart';
import 'package:danawallet/repositories/contacts_repository.dart';
import 'package:danawallet/services/bip353_resolver.dart';
import 'package:danawallet/services/dana_address_service.dart';
import 'package:logger/logger.dart';

class ContactsService {
  final ContactsRepository _repository = ContactsRepository.instance;
  final DanaAddressService _danaService = DanaAddressService();

  // private constructor
  ContactsService._();

  // singleton instance
  static final instance = ContactsService._();

  /// Validates dana address format (username@domain)
  bool _isValidDanaAddress(String danaAddress) {
    final pattern = RegExp(r'^[a-z0-9._-]+@[a-z0-9.-]+\.[a-z]+$', caseSensitive: false);
    return pattern.hasMatch(danaAddress);
  }

  /// Validates silent payment address format
  bool _isValidSpAddress(String spAddress) {
    // SP addresses start with 'sp1' and are bech32m encoded
    // Basic validation - could be more strict
    return spAddress.startsWith('sp1') && spAddress.length > 10;
  }

  /// Adds a new contact by dana address
  /// Resolves the dana address to SP address via DNS before saving
  /// 
  /// Throws [ArgumentError] if dana address format is invalid
  /// Throws [Exception] if dana address cannot be resolved or contact already exists
  Future<Contact> addContactByDanaAddress({
    required String danaAddress,
    required Network network,
    String? nym,
  }) async {
    // 1. Validate dana address format
    if (!_isValidDanaAddress(danaAddress)) {
      throw ArgumentError('Invalid dana address format: $danaAddress');
    }

    // 2. Check for duplicates
    final existing = await _repository.getContactByDanaAddress(danaAddress);
    if (existing != null) {
      throw Exception('Contact with dana address $danaAddress already exists');
    }

    // 3. Resolve to SP address via DNS
    Logger().i('Resolving dana address: $danaAddress');
    final parts = danaAddress.split('@');
    if (parts.length != 2) {
      throw ArgumentError('Invalid dana address format: $danaAddress');
    }

    final username = parts[0];
    final domain = parts[1];
    
    final spAddress = await Bip353Resolver.resolve(username, domain, network);
    if (spAddress == null) {
      throw Exception('Dana address not found: $danaAddress');
    }

    // 4. Save
    final contact = Contact(
      danaAddress: danaAddress,
      spAddress: spAddress,
      nym: nym,
    );

    final id = await _repository.insertContact(contact);
    contact.id = id;
    
    Logger().i('Contact added successfully: $danaAddress -> $spAddress');
    return contact;
  }

  /// Adds a new contact by silent payment address
  /// Optionally looks up the dana address from the name server
  /// 
  /// Throws [ArgumentError] if SP address format is invalid
  /// Throws [Exception] if contact already exists
  Future<Contact> addContactBySpAddress({
    required String spAddress,
    required Network network,
    String? nym,
    bool lookupDanaAddress = true,
  }) async {
    // 1. Validate SP address format
    if (!_isValidSpAddress(spAddress)) {
      throw ArgumentError('Invalid silent payment address format');
    }

    // 2. Check for duplicates by SP address
    final existing = await _repository.getContactBySpAddress(spAddress);
    if (existing != null) {
      throw Exception('Contact with this silent payment address already exists');
    }

    String? danaAddress;
    
    // 3. Optionally lookup dana address
    if (lookupDanaAddress) {
      try {
        Logger().i('Looking up dana address for SP address');
        danaAddress = await _danaService.lookupDanaAddress(spAddress, network);
        if (danaAddress != null) {
          // Check if dana address already exists
          final existingByDana = await _repository.getContactByDanaAddress(danaAddress);
          if (existingByDana != null) {
            throw Exception('Contact with dana address $danaAddress already exists');
          }
        }
      } catch (e) {
        Logger().w('Failed to lookup dana address: $e');
        // Continue without dana address
      }
    }

    // Use SP address as dana address if lookup failed or was skipped
    danaAddress ??= spAddress;

    // 4. Save
    final contact = Contact(
      danaAddress: danaAddress,
      spAddress: spAddress,
      nym: nym,
    );

    final id = await _repository.insertContact(contact);
    contact.id = id;
    
    Logger().i('Contact added successfully: ${contact.danaAddress}');
    return contact;
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
  }

  /// Deletes a contact by id
  /// 
  /// Returns true if contact was deleted, false if not found
  Future<bool> deleteContact(int id) async {
    final rowsDeleted = await _repository.deleteContact(id);
    final deleted = rowsDeleted > 0;
    
    if (deleted) {
      Logger().i('Contact deleted successfully: id=$id');
    } else {
      Logger().w('Contact not found for deletion: id=$id');
    }
    
    return deleted;
  }

  /// Gets a contact by id
  Future<Contact?> getContact(int id) async {
    return await _repository.getContact(id);
  }

  /// Gets a contact by dana address
  Future<Contact?> getContactByDanaAddress(String danaAddress) async {
    return await _repository.getContactByDanaAddress(danaAddress);
  }

  /// Gets a contact by silent payment address
  Future<Contact?> getContactBySpAddress(String spAddress) async {
    return await _repository.getContactBySpAddress(spAddress);
  }

  /// Gets all contacts, sorted by name (nym if available, otherwise dana address)
  Future<List<Contact>> getAllContactsSortedByName() async {
    final contacts = await _repository.getAllContacts();
    
    // Sort by nym if available, otherwise by dana address
    contacts.sort((a, b) {
      final aName = (a.nym?.isNotEmpty ?? false) ? a.nym! : a.danaAddress;
      final bName = (b.nym?.isNotEmpty ?? false) ? b.nym! : b.danaAddress;
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });
    
    return contacts;
  }

  /// Gets all contacts in the order they were added (most recent first)
  Future<List<Contact>> getAllContactsByRecent() async {
    final contacts = await _repository.getAllContacts();
    // Reverse to get most recent first (highest id first)
    return contacts.reversed.toList();
  }

  /// Searches contacts by name or dana address
  /// Returns contacts where nym or danaAddress contains the query (case-insensitive)
  Future<List<Contact>> searchContacts(String query) async {
    if (query.isEmpty) {
      return await getAllContactsSortedByName();
    }

    final allContacts = await _repository.getAllContacts();
    final lowerQuery = query.toLowerCase();
    
    return allContacts.where((contact) {
      final nym = contact.nym?.toLowerCase() ?? '';
      final danaAddress = contact.danaAddress.toLowerCase();
      return nym.contains(lowerQuery) || danaAddress.contains(lowerQuery);
    }).toList();
  }

  /// Deletes all contacts
  /// 
  /// Returns the number of contacts deleted
  Future<int> deleteAllContacts() async {
    final count = await _repository.deleteAllContacts();
    Logger().i('Deleted $count contacts');
    return count;
  }

  /// Gets the total number of contacts
  Future<int> getContactCount() async {
    return await _repository.getContactCount();
  }
}
