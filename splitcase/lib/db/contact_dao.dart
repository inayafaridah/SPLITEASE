// db/contact_dao.dart — Orang 2: CRUD for contacts
import 'package:sqflite/sqflite.dart';
import '../models/contact.dart';
import '../utils/constants.dart';
import 'database_helper.dart';

class ContactDao {
  final DatabaseHelper _helper = DatabaseHelper();

  Future<Database> get _db async => _helper.database;

  // CREATE
  Future<int> insert(Contact contact) async {
    final db = await _db;
    return db.insert(
      kTableContacts,
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ ALL
  Future<List<Contact>> getAll() async {
    final db = await _db;
    final maps = await db.query(kTableContacts, orderBy: 'name ASC');
    return maps.map(Contact.fromMap).toList();
  }

  // READ ONE
  Future<Contact?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      kTableContacts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : Contact.fromMap(maps.first);
  }

  // READ MULTIPLE by IDs
  Future<List<Contact>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await _db;
    final placeholders = ids.map((_) => '?').join(',');
    final maps = await db.query(
      kTableContacts,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return maps.map(Contact.fromMap).toList();
  }

  // UPDATE
  Future<int> update(Contact contact) async {
    final db = await _db;
    return db.update(
      kTableContacts,
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  // DELETE
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete(
      kTableContacts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
