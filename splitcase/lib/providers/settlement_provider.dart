// providers/settlement_provider.dart
import 'package:flutter/material.dart';
import '../models/settlement.dart';
import '../db/settlement_dao.dart';

class SettlementProvider extends ChangeNotifier {
  final SettlementDao _dao = SettlementDao();

  List<Settlement> _settlements = [];
  bool _loading = false;
  String? _error;
  int? _currentGroupId;

  List<Settlement> get settlements => _settlements;
  bool get loading => _loading;
  String? get error => _error;

  /// Load semua settlement (untuk HistoryScreen yang tidak terikat grup tertentu)
  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _settlements = await _dao.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadByGroup(int groupId) async {
    _loading = true;
    _currentGroupId = groupId;
    _error = null;
    notifyListeners();
    try {
      _settlements = await _dao.getByGroup(groupId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<int> add(Settlement settlement) async {
    final id = await _dao.insert(settlement);
    // Reload semua agar history langsung tampil
    await loadAll();
    return id;
  }

  Future<void> updateSettlement(Settlement settlement) async {
    await _dao.update(settlement);
    await loadAll();
  }

  Future<void> remove(int id) async {
    await _dao.delete(id);
    await loadAll();
  }
}
