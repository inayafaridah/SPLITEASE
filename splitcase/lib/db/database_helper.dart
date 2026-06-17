// lib/db/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _db;

  DatabaseHelper._();
  factory DatabaseHelper() => _instance ??= DatabaseHelper._();

  Future<Database> get database async => _db ??= await _initDb();

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, kDbName);
    return openDatabase(
      path,
      version: kDbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Groups
    await db.execute('''
      CREATE TABLE $kTableGroups (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        currency   TEXT    NOT NULL DEFAULT 'IDR',
        created_at TEXT    NOT NULL
      )
    ''');

    // Group Members
    await db.execute('''
      CREATE TABLE $kTableGroupMembers (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id    INTEGER NOT NULL,
        contact_id  INTEGER NOT NULL,
        joined_at   TEXT    NOT NULL,
        FOREIGN KEY (group_id) REFERENCES $kTableGroups(id) ON DELETE CASCADE,
        FOREIGN KEY (contact_id) REFERENCES $kTableContacts(id) ON DELETE CASCADE,
        UNIQUE(group_id, contact_id)
      )
    ''');

    // Transactions
    await db.execute('''
      CREATE TABLE $kTableTransactions (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id           INTEGER NOT NULL,
        payer_contact_id   INTEGER NOT NULL,
        amount             REAL    NOT NULL,
        description        TEXT    NOT NULL,
        date               TEXT    NOT NULL,
        receipt_image_path TEXT,
        FOREIGN KEY (group_id) REFERENCES $kTableGroups(id) ON DELETE CASCADE,
        FOREIGN KEY (payer_contact_id) REFERENCES $kTableContacts(id) ON DELETE SET NULL
      )
    ''');

    // Contacts
    await db.execute('''
      CREATE TABLE $kTableContacts (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        name         TEXT    NOT NULL,
        phone        TEXT    NOT NULL DEFAULT '',
        avatar_color TEXT    NOT NULL DEFAULT '#2196F3'
      )
    ''');

    // Settlements
    await db.execute('''
      CREATE TABLE $kTableSettlements (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id        INTEGER,
        from_contact_id INTEGER NOT NULL,
        to_contact_id   INTEGER NOT NULL,
        amount          REAL    NOT NULL,
        date            TEXT    NOT NULL,
        note            TEXT    NOT NULL DEFAULT '',
        is_paid         INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (group_id) REFERENCES $kTableGroups(id) ON DELETE SET NULL,
        FOREIGN KEY (from_contact_id) REFERENCES $kTableContacts(id) ON DELETE CASCADE,
        FOREIGN KEY (to_contact_id)   REFERENCES $kTableContacts(id) ON DELETE CASCADE
      )
    ''');
  }

    Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Tambah tabel group_members
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $kTableGroupMembers (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id    INTEGER NOT NULL,
          contact_id  INTEGER NOT NULL,
          joined_at   TEXT    NOT NULL,
          FOREIGN KEY (group_id) REFERENCES $kTableGroups(id) ON DELETE CASCADE,
          FOREIGN KEY (contact_id) REFERENCES $kTableContacts(id) ON DELETE CASCADE,
          UNIQUE(group_id, contact_id)
        )
      ''');
    }

    if (oldVersion < 3) {
      // Tambah kolom group_id di settlements (kalau belum ada)
      try {
        await db.execute('ALTER TABLE $kTableSettlements ADD COLUMN group_id INTEGER');
      } catch (_) {
        // Kolom sudah ada
      }
    }

    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE $kTableTransactions ADD COLUMN receipt_image_path TEXT');
      } catch (_) {}
    }
  }
}