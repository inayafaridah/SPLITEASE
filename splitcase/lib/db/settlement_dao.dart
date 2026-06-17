// db/settlement_dao.dart
import 'package:sqflite/sqflite.dart';
import '../models/settlement.dart';
import '../utils/constants.dart';
import 'database_helper.dart';

class SettlementDao {
  final DatabaseHelper _helper = DatabaseHelper();
  Future<Database> get _db async => _helper.database;

  Future<int> insert(Settlement settlement) async {
    final db = await _db;
    return db.insert(
      kTableSettlements,
      settlement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Ambil SEMUA settlement (dipakai oleh loadAll di provider) 
  Future<List<Settlement>> getAll() async {
    final db = await _db;
    final maps = await db.query(kTableSettlements, orderBy: 'date DESC');
    return maps.map(Settlement.fromMap).toList();
  }

  // Ambil pelunasan berdasarkan grup
  Future<List<Settlement>> getByGroup(int groupId) async {
    final db = await _db;
    final maps = await db.query(
      kTableSettlements,
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'date DESC',
    );
    return maps.map(Settlement.fromMap).toList();
  }

  Future<int> update(Settlement settlement) async {
    final db = await _db;
    return db.update(
      kTableSettlements,
      settlement.toMap(),
      where: 'id = ?',
      whereArgs: [settlement.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete(
      kTableSettlements,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
