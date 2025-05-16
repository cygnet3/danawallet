import 'package:danawallet/data/models/contacts.dart';
import 'package:danawallet/data/models/payment_address.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'database_helper.dart';

class ContactDAO extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<Contact> _contacts = [];

  List<Contact> get contacts => List.unmodifiable(_contacts);

  ContactDAO() {
    _loadAll();
  }

  Future<void> _loadAll() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('contacts');
    _contacts = maps.map((m) => Contact.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> insertContact(Contact contact) async {
    final db = await _databaseHelper.database;
    await db.insert('contacts', contact.toMap());
    await _loadAll();
  }

  Future<List<Contact>> getContacts() async => contacts;

  Future<bool> nymExists(String nym) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'contacts',
      columns: ['id'],
      where: 'nym = ?',
      whereArgs: [nym],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<Contact?> addressExistsIn(PaymentAddress address) async {
    final db = await _databaseHelper.database;
    final result = await db.query('contacts');

    for (var map in result) {
      final contact = Contact.fromMap(map);
      if (contact.addresses.containsKey(address)) {
        return contact;
      }
    }
    return null;
  }

  Future<void> updateContact(Contact contact) async {
    final db = await _databaseHelper.database;
    await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
    await _loadAll();
  }

  Future<void> deleteContact(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _loadAll();
  }
}
