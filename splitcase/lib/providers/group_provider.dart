// providers/group_provider.dart — Orang 1
import 'package:flutter/material.dart';
import '../models/group.dart';
import '../db/group_dao.dart';

class GroupProvider extends ChangeNotifier {
  final GroupDao _dao = GroupDao();

  List<Group> _groups = [];
  bool _loading = false;
  String? _error;

  List<Group> get groups => _groups;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _groups = await _dao.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<int> add(Group group) async {
    final id = await _dao.insert(group);
    await loadAll();
    return id;
  }

  Future<void> updateGroup(Group group) async {
    await _dao.update(group);
    await loadAll();
  }

  Future<void> rename(int id, String newName, {String? currency}) async {
    await _dao.updateName(id, newName, currency: currency);
    await loadAll();
  }

  Future<void> remove(int id) async {
    await _dao.delete(id);
    await loadAll();
  }

  Group? getById(int id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}
