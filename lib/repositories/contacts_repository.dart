import 'package:danawallet/data/models/contact_field.dart';
import 'package:danawallet/data/models/contacts.dart';
import 'package:danawallet/repositories/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class ContactsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // private constructor
  ContactsRepository._();

  // singleton instance
  static final instance = ContactsRepository._();

  Future<int> insertContact(Contact contact) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Contact?> getContact(int id, {bool loadCustomFields = false}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    
    final contact = Contact.fromMap(maps.first);
    
    if (loadCustomFields && contact.id != null) {
      final customFields = await getContactFields(contact.id!);
      return Contact(
        id: contact.id,
        nym: contact.nym,
        danaAddress: contact.danaAddress,
        spAddress: contact.spAddress,
        customFields: customFields,
      );
    }
    
    return contact;
  }

  Future<Contact?> getContactByDanaAddress(String danaAddress) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'contacts',
      where: 'danaAddress = ?',
      whereArgs: [danaAddress],
    );

    if (maps.isEmpty) return null;
    return Contact.fromMap(maps.first);
  }

  Future<Contact?> getContactBySpAddress(String spAddress) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'contacts',
      where: 'spAddress = ?',
      whereArgs: [spAddress],
    );

    if (maps.isEmpty) return null;
    return Contact.fromMap(maps.first);
  }

  Future<List<Contact>> getAllContacts({bool loadCustomFields = false}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'contacts',
      orderBy: 'nym ASC, id ASC',
    );

    final contacts = maps.map((map) => Contact.fromMap(map)).toList();
    
    if (loadCustomFields) {
      // Load custom fields for all contacts
      for (var contact in contacts) {
        if (contact.id != null) {
          final customFields = await getContactFields(contact.id!);
          final index = contacts.indexOf(contact);
          contacts[index] = Contact(
            id: contact.id,
            nym: contact.nym,
            danaAddress: contact.danaAddress,
            spAddress: contact.spAddress,
            customFields: customFields,
          );
        }
      }
    }
    
    return contacts;
  }

  Future<int> updateContact(Contact contact) async {
    final db = await _dbHelper.database;
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await _dbHelper.database;
    // Custom fields will be deleted automatically due to CASCADE
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllContacts() async {
    final db = await _dbHelper.database;
    // Custom fields will be deleted automatically due to CASCADE
    return await db.delete('contacts');
  }

  // Contact Fields CRUD operations

  Future<int> insertContactField(ContactField field) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'contact_fields',
      field.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ContactField>> getContactFields(int contactId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'contact_fields',
      where: 'contact_id = ?',
      whereArgs: [contactId],
      orderBy: 'field_type ASC, id ASC',
    );

    return maps.map((map) => ContactField.fromMap(map)).toList();
  }

  Future<ContactField?> getContactField(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'contact_fields',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return ContactField.fromMap(maps.first);
  }

  Future<List<ContactField>> getContactFieldsByType(
    int contactId,
    String fieldType,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'contact_fields',
      where: 'contact_id = ? AND field_type = ?',
      whereArgs: [contactId, fieldType],
      orderBy: 'id ASC',
    );

    return maps.map((map) => ContactField.fromMap(map)).toList();
  }

  Future<int> updateContactField(ContactField field) async {
    final db = await _dbHelper.database;
    return await db.update(
      'contact_fields',
      field.toMap(),
      where: 'id = ?',
      whereArgs: [field.id],
    );
  }

  Future<int> deleteContactField(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'contact_fields',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteContactFields(int contactId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'contact_fields',
      where: 'contact_id = ?',
      whereArgs: [contactId],
    );
  }
}

