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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Text(isEdit ? 'Edit Data Kontak' : 'Tambah Kontak Baru', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: _parseColor(_avatarColor),
                    child: Text(
                      _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.palette_rounded, size: 20, color: _parseColor(_avatarColor)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 28),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Nomor WhatsApp / HP',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.phone_android_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nomor HP wajib diisi' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tema Warna Avatar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _colorOptions
                            .map((hex) => GestureDetector(
                                  onTap: () => setState(() => _avatarColor = hex),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _parseColor(hex),
                                      shape: BoxShape.circle,
                                      border: _avatarColor == hex ? Border.all(width: 3, color: Colors.white) : null,
                                      boxShadow: _avatarColor == hex
                                          ? [BoxShadow(color: _parseColor(hex).withOpacity(0.4), blurRadius: 6, spreadRadius: 2)]
                                          : null,
                                    ),
                                    child: _avatarColor == hex ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Kontak', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}