import 'package:danawallet/data/models/contacts.dart';
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
