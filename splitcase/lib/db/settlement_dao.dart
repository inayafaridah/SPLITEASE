// db/settlement_dao.dart — Orang 2: CRUD for settlements
import 'package:sqflite/sqflite.dart';
import '../models/settlement.dart';
import '../utils/constants.dart';
import 'database_helper.dart';

class SettlementDao {
  final DatabaseHelper _helper = DatabaseHelper();

  Future<Database> get _db async => _helper.database;

  // CREATE
  Future<int> insert(Settlement settlement) async {
    final db = await _db;
    return db.insert(
      kTableSettlements,
      settlement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ HISTORY (all)
  Future<List<Settlement>> getAll() async {
    final db = await _db;
    final maps = await db.query(kTableSettlements, orderBy: 'date DESC');
    return maps.map(Settlement.fromMap).toList();
  }

  // READ by contact (as payer or receiver)
  Future<List<Settlement>> getByContact(int contactId) async {
    final db = await _db;
    final maps = await db.query(
      kTableSettlements,
      where: 'from_contact_id = ? OR to_contact_id = ?',
      whereArgs: [contactId, contactId],
      orderBy: 'date DESC',
    );
    return maps.map(Settlement.fromMap).toList();
  }

  // READ pending only
  Future<List<Settlement>> getPending() async {
    final db = await _db;
    final maps = await db.query(
      kTableSettlements,
      where: 'is_paid = 0',
      orderBy: 'date DESC',
    );
    return maps.map(Settlement.fromMap).toList();
  }

  // UPDATE STATUS (mark as paid/unpaid)
  Future<int> updateStatus(int id, int isPaid) async {
    final db = await _db;
    return db.update(
      kTableSettlements,
      {'is_paid': isPaid},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // UPDATE (full)
  Future<int> update(Settlement settlement) async {
    final db = await _db;
    return db.update(
      kTableSettlements,
      settlement.toMap(),
      where: 'id = ?',
      whereArgs: [settlement.id],
    );
  }

  // DELETE
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete(
      kTableSettlements,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
