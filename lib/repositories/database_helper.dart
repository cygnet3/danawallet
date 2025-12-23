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
      version: 2,
      onCreate: (db, version) async {
        await _createDB(db, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _upgradeDB(db, oldVersion, newVersion);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
    CREATE TABLE contacts (
      id $idType,
      nym $textTypeNullable,
      danaAddress $textType,
      spAddress $textType
    )
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

    // Create index for faster queries
    await db.execute('''
    CREATE INDEX idx_contact_fields_contact_id ON contact_fields(contact_id)
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const intType = 'INTEGER NOT NULL';
      const textType = 'TEXT NOT NULL';
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';

      // Create contact_fields table
      await db.execute('''
      CREATE TABLE contact_fields (
        id $idType,
        contact_id $intType,
        field_type $textType,
        field_value $textType,
        FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
      )
      ''');

      // Create index for faster queries
      await db.execute('''
      CREATE INDEX idx_contact_fields_contact_id ON contact_fields(contact_id)
      ''');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
