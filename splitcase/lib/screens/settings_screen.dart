// screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_gradient_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prefs = PreferencesService();
  final _nameCtrl = TextEditingController();
  String _currency = 'IDR';
  String _theme = 'purple'; // Menampung state tema sementara sebelum disimpan
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await _prefs.getUserName();
    final currency = await _prefs.getDefaultCurrency();
    
    final theme = await _prefs.getColorTheme(); 
    
    setState(() {
      _nameCtrl.text = name;
      _currency = currency;
      _theme = theme; 
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _prefs.setUserName(_nameCtrl.text.trim());
    await _prefs.setDefaultCurrency(_currency);
    
    if (mounted) {
      // Update global theme state
      await context.read<ThemeProvider>().setTheme(_theme);

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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final themeProvider = context.watch<ThemeProvider>();
    final _primaryColor = themeProvider.primaryColor;
    final _gradientEndColor = themeProvider.gradientEndColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: _primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _gradientEndColor],
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
                  // CARD PROFIL
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
                              decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.person_rounded, color: _primaryColor, size: 22),
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
                            labelStyle: TextStyle(color: _primaryColor),
                            hintText: 'Masukkan namamu',
                            prefixIcon: Icon(Icons.badge_outlined, color: _primaryColor),
                            filled: true,
                            fillColor: const Color(0xFFF4F6F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // CARD PREFERENSI (Mata Uang & Tema Aplikasi)
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
                              decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.tune_rounded, color: _primaryColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text('Preferensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Dropdown Mata Uang
                        DropdownButtonFormField<String>(
                          value: _currency,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
                          decoration: InputDecoration(
                            labelText: 'Mata Uang Default',
                            labelStyle: TextStyle(color: _primaryColor),
                            prefixIcon: Icon(Icons.currency_exchange_rounded, color: _primaryColor),
                            filled: true,
                            fillColor: const Color(0xFFF4F6F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                          ),
                          items: ['IDR', 'USD', 'EUR'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                          onChanged: (v) => setState(() => _currency = v ?? 'IDR'),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Dropdown Tema Warna (Disinkronkan dengan value string)
                        DropdownButtonFormField<String>(
                          value: _theme,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
                          decoration: InputDecoration(
                            labelText: 'Tema Warna Aplikasi',
                            labelStyle: TextStyle(color: _primaryColor),
                            prefixIcon: Icon(Icons.palette_rounded, color: _primaryColor),
                            filled: true,
                            fillColor: const Color(0xFFF4F6F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'purple',
                              child: Row(
                                children: [
                                  Container(
                                    width: 16, height: 16,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Ungu', style: TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'blue',
                              child: Row(
                                children: [
                                  Container(
                                    width: 16, height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade400]),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Biru', style: TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'green',
                              child: Row(
                                children: [
                                  Container(
                                    width: 16, height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade400]),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Hijau', style: TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _theme = v ?? 'purple'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  CustomGradientButton(
                    onPressed: _save,
                    label: 'Simpan Pengaturan',
                    icon: Icons.save_rounded,
                    primaryColor: _primaryColor,
                    gradientEndColor: _gradientEndColor,
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