// screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/group.dart';
import '../models/transaction.dart';
import '../models/contact.dart';
import '../providers/transaction_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/group_member_provider.dart';

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
  List<Contact> _groupMembersContacts = [];
  bool _isLoadingMembers = true;

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
    _loadFilteredGroupMembers();
  }

  Future<void> _loadFilteredGroupMembers() async {
    final contactProvider = context.read<ContactProvider>();
    final memberProvider = context.read<GroupMemberProvider>();

    await contactProvider.loadAll();
    final memberIds = await memberProvider.getMembers(widget.group.id!);

    if (mounted) {
      setState(() {
        _groupMembersContacts = contactProvider.contacts
            .where((c) => memberIds.contains(c.id))
            .toList();
        _isLoadingMembers = false;
      });
    }
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
        SnackBar(
          content: const Text('Silakan pilih siapa yang membayar terlebih dahulu.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.amber.shade800,
        ),
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingMembers
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.receipt_rounded, color: Colors.indigo, size: 20),
                              SizedBox(width: 8),
                              Text('Detail Tagihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descCtrl,
                            decoration: InputDecoration(
                              labelText: 'Keterangan',
                              hintText: 'Contoh: Makan ramen',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Icon(Icons.description_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Keterangan wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountCtrl,
                            decoration: InputDecoration(
                              labelText: 'Jumlah (${widget.group.currency})',
                              hintText: '150000',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Icon(Icons.payments_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                          DropdownButtonFormField<int>(
                            value: _selectedPayerId,
                            decoration: InputDecoration(
                              labelText: 'Yang Membayar',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _groupMembersContacts
                                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedPayerId = v),
                            hint: _groupMembersContacts.isEmpty
                                ? const Text('Tidak ada anggota di grup ini')
                                : const Text('Pilih pembayar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.withOpacity(0.1), 
                        child: const Icon(Icons.calendar_today_rounded, color: Colors.indigo, size: 20)
                      ),
                      title: const Text('Tanggal Transaksi', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                      subtitle: Text(DateFormat('dd MMMM yyyy').format(_date), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
                      trailing: const Icon(Icons.edit_calendar_rounded, color: Colors.indigo),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded),
                    label: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Transaksi', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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