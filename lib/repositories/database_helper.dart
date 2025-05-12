import 'package:danawallet/data/models/contacts.dart';
import 'package:danawallet/data/models/payment_address.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  String? _myAddress;

  void setMyAddress(String address) {
    _myAddress = address;
  }

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('contacts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1) Create your tables
        await _createDB(db, version);
        // 2) Seed the “My Wallet” contact
        await _setMyWallet(db);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';

    await db.execute('''
    CREATE TABLE contacts (
      id $idType,
      nym $textType,
      addresses $textType,
      imagePath $textNullableType
    )
    ''');
  }

  Future _setMyWallet(Database db) async {
    final apiAddress = ApiSilentPaymentAddress.fromStringRepresentation(address: _myAddress!);

    final Map<PaymentAddress, List<String>> addresses = {
      PaymentAddress(apiAddress): []
    };

    final contact = Contact(
      nym: 'My Wallet',
      addresses: addresses,
      imagePath: null,
    );
    await db.insert(
      'contacts',
      contact.toMap()
    );
  }
}
