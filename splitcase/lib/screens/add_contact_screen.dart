import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/contact.dart';
import '../providers/contact_provider.dart';

class AddContactScreen extends StatefulWidget {
  final Contact? existing;
  const AddContactScreen({super.key, this.existing});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _avatarColor = '#2196F3';
  bool _submitting = false;

  bool get isEdit => widget.existing != null;

  static const _colorOptions = [
    '#2196F3', '#E91E63', '#4CAF50', '#FF9800',
    '#9C27B0', '#F44336', '#009688', '#607D8B',
  ];

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _nameCtrl.text = widget.existing!.name;
      _phoneCtrl.text = widget.existing!.phone;
      _avatarColor = widget.existing!.avatarColor;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final cp = context.read<ContactProvider>();
    final contact = Contact(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      avatarColor: _avatarColor,
    );

    if (isEdit) {
      await cp.updateContact(contact);
    } else {
      await cp.add(contact);
    }

    if (mounted) Navigator.pop(context);
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        title: Text(isEdit ? 'Edit Data Kontak' : 'Tambah Kontak Baru', style: const TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _parseColor(_avatarColor).withOpacity(0.3), width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: _parseColor(_avatarColor),
                      child: Text(
                        _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim()[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Icon(Icons.palette_rounded, size: 20, color: _parseColor(_avatarColor)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
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
                  TextFormField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      labelStyle: const TextStyle(color: Color(0xFF4A00E0)),
                      filled: true,
                      fillColor: const Color(0xFFF4F6F9),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF4A00E0)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 1.5)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Nomor WhatsApp / HP',
                      labelStyle: const TextStyle(color: Color(0xFF4A00E0)),
                      filled: true,
                      fillColor: const Color(0xFFF4F6F9),
                      prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF4A00E0)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 1.5)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nomor HP wajib diisi' : null,
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
                  const Text('Tema Warna Avatar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                  const SizedBox(height: 16),
                  Center(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _colorOptions
                          .map((hex) => GestureDetector(
                                onTap: () => setState(() => _avatarColor = hex),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _parseColor(hex),
                                    shape: BoxShape.circle,
                                    border: _avatarColor == hex ? Border.all(width: 3, color: Colors.white) : null,
                                    boxShadow: _avatarColor == hex
                                        ? [BoxShadow(color: _parseColor(hex).withOpacity(0.4), blurRadius: 8, spreadRadius: 2)]
                                        : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                                  ),
                                  child: _avatarColor == hex ? const Icon(Icons.check_rounded, color: Colors.white, size: 24) : null,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 22),
              label: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Kontak', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
    );
  }
}