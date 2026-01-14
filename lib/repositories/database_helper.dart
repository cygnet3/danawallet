import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

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
        await _createDB(db, version);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    Logger().i("Creating Database");
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
    CREATE TABLE contacts (
      id $idType,
      nym $textTypeNullable,
      danaAddress $textTypeNullable UNIQUE,
      spAddress $textType UNIQUE
    )
    ''');

    // Create indexes for faster lookups on contacts table
    await db.execute('''
    CREATE INDEX idx_contacts_dana_address ON contacts(danaAddress)
    ''');

    await db.execute('''
    CREATE INDEX idx_contacts_sp_address ON contacts(spAddress)
    ''');

    await db.execute('''
    CREATE TABLE contact_fields (
      id $idType,
      contact_id $intType,
      field_type $textType,
      field_value $textType,
      FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
    )
    ''');

    // Create index for faster queries on contact_fields table
    await db.execute('''
    CREATE INDEX idx_contact_fields_contact_id ON contact_fields(contact_id)
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
