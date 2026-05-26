// providers/transaction_provider.dart — Orang 1
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../db/transaction_dao.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionDao _dao = TransactionDao();

  List<Transaction> _transactions = [];
  bool _loading = false;
  int? _currentGroupId;

  List<Transaction> get transactions => _transactions;
  bool get loading => _loading;
  int? get currentGroupId => _currentGroupId;

  double get totalAmount =>
      _transactions.fold(0.0, (sum, tx) => sum + tx.amount);

  Future<void> loadByGroup(int groupId) async {
    _loading = true;
    _currentGroupId = groupId;
    notifyListeners();
    try {
      _transactions = await _dao.getByGroup(groupId);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    try {
      _transactions = await _dao.getAll();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<int> add(Transaction tx) async {
    final id = await _dao.insert(tx);
    if (_currentGroupId != null) await loadByGroup(_currentGroupId!);
    return id;
  }

  Future<void> updateTransaction(Transaction tx) async {
    await _dao.update(tx);
    if (_currentGroupId != null) await loadByGroup(_currentGroupId!);
  }

  Future<void> remove(int id) async {
    await _dao.delete(id);
    if (_currentGroupId != null) await loadByGroup(_currentGroupId!);
  }
}
