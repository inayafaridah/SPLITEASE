// lib/db/group_member_dao.dart
import 'package:sqflite/sqflite.dart';
import '../models/group_member.dart';
import '../utils/constants.dart';
import 'database_helper.dart';

class GroupMemberDao {
  final DatabaseHelper _helper = DatabaseHelper();

  Future<Database> get _db async => _helper.database;

  Future<void> insertAll(int groupId, List<int> contactIds) async {
    final db = await _db;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final contactId in contactIds) {
      batch.insert(
        kTableGroupMembers,
        {
          'group_id': groupId,
          'contact_id': contactId,
          'joined_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit();
  }

  Future<List<int>> getContactIdsByGroup(int groupId) async {
    final db = await _db;
    final maps = await db.query(
      kTableGroupMembers,
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
    return maps.map((m) => m['contact_id'] as int).toList();
  }

  Future<void> deleteByGroup(int groupId) async {
    final db = await _db;
    await db.delete(
      kTableGroupMembers,
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }
}