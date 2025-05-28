import 'package:danawallet/constants.dart';
import 'package:danawallet/data/models/contacts.dart';
import 'package:danawallet/data/models/payment_address.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'database_helper.dart';

class ContactDAO extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  String? _myAddress;

  void setMyAddress(String address) {
    _myAddress = address;
  }

  List<Contact> _contacts = [];

  List<Contact> get contacts => List.unmodifiable(_contacts);

  ContactDAO();

  Future init() async {
    final exists = await nymExists(myWalletNym);
    if (!exists) {
      await _setMyWallet();
    }
    await _loadAll();
  }

  Future<void> _loadAll() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('contacts');
    _contacts = maps.map((m) => Contact.fromMap(m)).toList();
    notifyListeners();
  }

  Future _setMyWallet() async {
    final apiAddress =
        ApiSilentPaymentAddress.fromStringRepresentation(address: _myAddress!);

    final Map<PaymentAddress, String> addresses = {
      PaymentAddress(apiAddress): "Default"
    };

    final contact = Contact(
      nym: myWalletNym,
      addresses: addresses,
      imagePath: null,
    );
    await insertContact(contact);
  }

  Future<void> insertContact(Contact contact) async {
    final db = await _databaseHelper.database;
    await db.insert('contacts', contact.toMap());
    await _loadAll();
  }

  Future<List<Contact>> getContacts() async => contacts;

  Future<Contact?> getContactWithNym(String nym) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'contacts',
      where: 'nym = ?',
      whereArgs: [nym.trim()],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      final res = Contact.fromMap(rows.first);
      return res;
    } else {
      return null;
    }
  }

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

  Future<void> deleteAllContacts() async {
    final db = await _databaseHelper.database;
    final deletedRows = await db.delete('contacts');
    Logger().d('Deleted rows: $deletedRows');
    await _loadAll();
  }
}
