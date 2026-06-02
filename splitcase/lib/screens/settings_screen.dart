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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Pengaturan berhasil disimpan! ✓'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
        ),
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
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6F9),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF4A00E0),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Pengaturan',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF4A00E0).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.person_rounded, color: Color(0xFF4A00E0), size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nama Kamu',
                            labelStyle: const TextStyle(color: Color(0xFF4A00E0)),
                            hintText: 'Masukkan namamu',
                            prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF4A00E0)),
                            filled: true,
                            fillColor: const Color(0xFFF4F6F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF4A00E0).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.tune_rounded, color: Color(0xFF4A00E0), size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text('Preferensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _currency,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4A00E0)),
                          decoration: InputDecoration(
                            labelText: 'Mata Uang Default',
                            labelStyle: const TextStyle(color: Color(0xFF4A00E0)),
                            prefixIcon: const Icon(Icons.currency_exchange_rounded, color: Color(0xFF4A00E0)),
                            filled: true,
                            fillColor: const Color(0xFFF4F6F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 1.5)),
                          ),
                          items: ['IDR', 'USD', 'EUR'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                          onChanged: (v) => setState(() => _currency = v ?? 'IDR'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded, size: 22),
                    label: const Text('Simpan Pengaturan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A00E0),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: const Color(0xFF4A00E0).withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}