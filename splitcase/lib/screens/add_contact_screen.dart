// screens/add_contact_screen.dart — Orang 2
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
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Kontak' : 'Tambah Kontak')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar preview
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: _parseColor(_avatarColor),
                child: Text(
                  _nameCtrl.text.isNotEmpty
                      ? _nameCtrl.text[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor HP (opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),

            // Color picker
            const Text('Warna Avatar',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _colorOptions
                  .map((hex) => GestureDetector(
                        onTap: () => setState(() => _avatarColor = hex),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _parseColor(hex),
                            shape: BoxShape.circle,
                            border: _avatarColor == hex
                                ? Border.all(width: 3, color: Colors.black)
                                : null,
                          ),
                          child: _avatarColor == hex
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(isEdit ? 'Simpan' : 'Tambah Kontak'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }
}
