// db/transaction_dao.dart — Orang 1: CRUD for transactions
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../models/transaction.dart';
import '../utils/constants.dart';
import 'database_helper.dart';

class TransactionDao {
  final DatabaseHelper _helper = DatabaseHelper();

  Future<Database> get _db async => _helper.database;

  // CREATE
  Future<int> insert(Transaction tx) async {
    final db = await _db;
    return db.insert(
      kTableTransactions,
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ ALL by group
  Future<List<Transaction>> getByGroup(int groupId) async {
    final db = await _db;
    final maps = await db.query(
      kTableTransactions,
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'date DESC',
    );
    return maps.map(Transaction.fromMap).toList();
  }

  // READ ALL
  Future<List<Transaction>> getAll() async {
    final db = await _db;
    final maps = await db.query(kTableTransactions, orderBy: 'date DESC');
    return maps.map(Transaction.fromMap).toList();
  }

  // READ ONE
  Future<Transaction?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      kTableTransactions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : Transaction.fromMap(maps.first);
  }

  // UPDATE
  Future<int> update(Transaction tx) async {
    final db = await _db;
    return db.update(
      kTableTransactions,
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  // DELETE
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete(
      kTableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE ALL by group (cascade helper)
  Future<int> deleteByGroup(int groupId) async {
    final db = await _db;
    return db.delete(
      kTableTransactions,
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }
}
