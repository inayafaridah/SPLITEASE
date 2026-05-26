// screens/add_transaction_screen.dart — Orang 1
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/group.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/contact_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final Group group;
  final Transaction? existing;

  const AddTransactionScreen({super.key, required this.group, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  int? _selectedPayerId;
  DateTime _date = DateTime.now();
  bool _submitting = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final tx = widget.existing!;
      _descCtrl.text = tx.description;
      _amountCtrl.text = tx.amount.toStringAsFixed(0);
      _selectedPayerId = tx.payerContactId;
      _date = DateTime.tryParse(tx.date) ?? DateTime.now();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih siapa yang membayar')),
      );
      return;
    }

    setState(() => _submitting = true);
    final tp = context.read<TransactionProvider>();
    final tx = Transaction(
      id: widget.existing?.id,
      groupId: widget.group.id!,
      payerContactId: _selectedPayerId!,
      amount: double.parse(_amountCtrl.text.replaceAll(',', '')),
      description: _descCtrl.text.trim(),
      date: _date.toIso8601String(),
    );

    if (isEdit) {
      await tp.updateTransaction(tx);
    } else {
      await tp.add(tx);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactProvider>().contacts;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Description
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Keterangan',
                hintText: 'Contoh: Makan ramen',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Keterangan wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              decoration: InputDecoration(
                labelText: 'Jumlah (${widget.group.currency})',
                hintText: '150000',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                if (double.tryParse(v) == null || double.parse(v) <= 0) {
                  return 'Masukkan jumlah yang valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Payer
            DropdownButtonFormField<int>(
              value: _selectedPayerId,
              decoration: const InputDecoration(
                labelText: 'Yang Membayar',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: contacts
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedPayerId = v),
              hint: contacts.isEmpty
                  ? const Text('Belum ada kontak — tambah dulu')
                  : const Text('Pilih pembayar'),
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              leading: const Icon(Icons.calendar_today),
              title: const Text('Tanggal'),
              subtitle: Text(DateFormat('dd MMMM yyyy').format(_date)),
              onTap: _pickDate,
            ),
            const SizedBox(height: 24),

            // Submit
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Transaksi'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
