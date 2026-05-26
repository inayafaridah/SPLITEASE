// screens/settings_screen.dart — Orang 1 (SharedPreferences: nama & mata uang)
import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prefs = PreferencesService();
  final _nameCtrl = TextEditingController();
  String _currency = 'IDR';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await _prefs.getUserName();
    final currency = await _prefs.getDefaultCurrency();
    setState(() {
      _nameCtrl.text = name;
      _currency = currency;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _prefs.setUserName(_nameCtrl.text.trim());
    await _prefs.setDefaultCurrency(_currency);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan disimpan ✓')),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama Kamu',
              hintText: 'Masukkan namamu',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Preferensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _currency,
            decoration: const InputDecoration(
              labelText: 'Mata Uang Default',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.money),
            ),
            items: ['IDR', 'USD', 'EUR']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _currency = v ?? 'IDR'),
          ),
          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Simpan'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }
}
