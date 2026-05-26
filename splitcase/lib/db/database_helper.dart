// db/database_helper.dart — shared SQLite setup
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
    // --- Orang 1: groups ---
    await db.execute('''
      CREATE TABLE $kTableGroups (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        currency   TEXT    NOT NULL DEFAULT 'IDR',
        created_at TEXT    NOT NULL
      )
    ''');

    // --- Orang 1: transactions ---
    await db.execute('''
      CREATE TABLE $kTableTransactions (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id         INTEGER NOT NULL,
        payer_contact_id INTEGER NOT NULL,
        amount           REAL    NOT NULL,
        description      TEXT    NOT NULL,
        date             TEXT    NOT NULL,
        FOREIGN KEY (group_id) REFERENCES $kTableGroups(id) ON DELETE CASCADE,
        FOREIGN KEY (payer_contact_id) REFERENCES $kTableContacts(id) ON DELETE CASCADE
      )
    ''');

    // --- Orang 2: contacts ---
    await db.execute('''
      CREATE TABLE $kTableContacts (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        name         TEXT    NOT NULL,
        phone        TEXT    NOT NULL DEFAULT '',
        avatar_color TEXT    NOT NULL DEFAULT '#2196F3'
      )
    ''');

    // --- Orang 2: settlements ---
    await db.execute('''
      CREATE TABLE $kTableSettlements (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        from_contact_id INTEGER NOT NULL,
        to_contact_id   INTEGER NOT NULL,
        amount          REAL    NOT NULL,
        date            TEXT    NOT NULL,
        note            TEXT    NOT NULL DEFAULT '',
        is_paid         INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (from_contact_id) REFERENCES $kTableContacts(id) ON DELETE CASCADE,
        FOREIGN KEY (to_contact_id)   REFERENCES $kTableContacts(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
