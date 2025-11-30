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

  Future<Contact?> getContact(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Contact.fromMap(maps.first);
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

  Future<List<Contact>> getAllContacts() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'contacts',
      orderBy: 'nym ASC, id ASC',
    );

    return maps.map((map) => Contact.fromMap(map)).toList();
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
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllContacts() async {
    final db = await _dbHelper.database;
    return await db.delete('contacts');
  }
}

