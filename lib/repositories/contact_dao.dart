import 'package:danawallet/data/models/contacts.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'database_helper.dart';

class ContactDAO {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> insertContact(Contact contact) async {
    final db = await _databaseHelper.database;
    return await db.insert('contacts', contact.toMap());
  }

  Future<List<Contact>> getContacts() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('contacts');
    return maps.map((map) => Contact.fromMap(map)).toList();
  }

  Future<bool> nymExists(String name) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'contacts',
      where: 'nym = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty;
  }

  Future<Contact?> addressExistsIn(ApiSilentPaymentAddress address) async {
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
  }

  Future<void> deleteContact(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
