// providers/settlement_provider.dart — Orang 2
import 'package:flutter/material.dart';
import '../models/settlement.dart';
import '../db/settlement_dao.dart';

class SettlementProvider extends ChangeNotifier {
  final SettlementDao _dao = SettlementDao();

  List<Settlement> _settlements = [];
  bool _loading = false;
  String? _error;

  List<Settlement> get settlements => _settlements;
  List<Settlement> get pending => _settlements.where((s) => !s.paid).toList();
  List<Settlement> get paid => _settlements.where((s) => s.paid).toList();
  bool get loading => _loading;
  String? get error => _error;

  double get totalPendingAmount =>
      pending.fold(0.0, (sum, s) => sum + s.amount);

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

  Future<int> add(Settlement settlement) async {
    final id = await _dao.insert(settlement);
    await loadAll();
    return id;
  }

  Future<void> markPaid(int id) async {
    await _dao.updateStatus(id, 1);
    await loadAll();
  }

  Future<void> markUnpaid(int id) async {
    await _dao.updateStatus(id, 0);
    await loadAll();
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
