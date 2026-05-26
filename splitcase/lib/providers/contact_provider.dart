// providers/contact_provider.dart — Orang 2
import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../db/contact_dao.dart';

class ContactProvider extends ChangeNotifier {
  final ContactDao _dao = ContactDao();

  List<Contact> _contacts = [];
  bool _loading = false;
  String? _error;

  List<Contact> get contacts => _contacts;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _contacts = await _dao.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<int> add(Contact contact) async {
    final id = await _dao.insert(contact);
    await loadAll();
    return id;
  }

  Future<void> updateContact(Contact contact) async {
    await _dao.update(contact);
    await loadAll();
  }

  Future<void> remove(int id) async {
    await _dao.delete(id);
    await loadAll();
  }

  Contact? getById(int id) {
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  String nameById(int id) => getById(id)?.name ?? 'Unknown';
}
