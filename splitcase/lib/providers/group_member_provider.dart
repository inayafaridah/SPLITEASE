// lib/providers/group_member_provider.dart
import 'package:flutter/material.dart';
import '../db/group_member_dao.dart';

class GroupMemberProvider extends ChangeNotifier {
  final GroupMemberDao _dao = GroupMemberDao();

  Future<void> addMembers(int groupId, List<int> contactIds) async {
    await _dao.insertAll(groupId, contactIds);
    notifyListeners();
  }

  Future<List<int>> getMembers(int groupId) async {
    return await _dao.getContactIdsByGroup(groupId);
  }

  /// Replace seluruh member grup (hapus semua lama, insert baru)
  Future<void> replaceMembers(int groupId, List<int> contactIds) async {
    await _dao.deleteByGroup(groupId);
    if (contactIds.isNotEmpty) {
      await _dao.insertAll(groupId, contactIds);
    }
    notifyListeners();
  }
}
