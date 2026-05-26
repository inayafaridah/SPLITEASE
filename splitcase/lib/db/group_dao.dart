// db/group_dao.dart — Orang 1: CRUD for groups
import 'package:sqflite/sqflite.dart';
import '../models/group.dart';
import '../utils/constants.dart';
import 'database_helper.dart';

class GroupDao {
  final DatabaseHelper _helper = DatabaseHelper();

  Future<Database> get _db async => _helper.database;

  // CREATE
  Future<int> insert(Group group) async {
    final db = await _db;
    return db.insert(
      kTableGroups,
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ ALL
  Future<List<Group>> getAll() async {
    final db = await _db;
    final maps = await db.query(kTableGroups, orderBy: 'created_at DESC');
    return maps.map(Group.fromMap).toList();
  }

  // READ ONE
  Future<Group?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      kTableGroups,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : Group.fromMap(maps.first);
  }

  // UPDATE NAME (& currency)
  Future<int> updateName(int id, String newName, {String? currency}) async {
    final db = await _db;
    final values = <String, dynamic>{'name': newName};
    if (currency != null) values['currency'] = currency;
    return db.update(
      kTableGroups,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // UPDATE (full)
  Future<int> update(Group group) async {
    final db = await _db;
    return db.update(
      kTableGroups,
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  // DELETE
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete(
      kTableGroups,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
