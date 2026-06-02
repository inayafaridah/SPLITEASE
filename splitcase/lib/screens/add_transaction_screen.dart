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
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        title: Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi', style: const TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
        ),
      ),
      body: _isLoadingMembers
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                              child: const Icon(Icons.receipt_rounded, color: Color(0xFF4A00E0), size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text('Detail Tagihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _descCtrl,
                          decoration: InputDecoration(
                            labelText: 'Keterangan',
                            labelStyle: const TextStyle(color: Color(0xFF4A00E0)),
                            hintText: 'Contoh: Makan ramen',
                            filled: true,
                            fillColor: const Color(0xFFF4F6F9),
                            prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFF4A00E0)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 1.5)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Keterangan wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountCtrl,
                          decoration: InputDecoration(
                            labelText: 'Jumlah (${widget.group.currency})',
                            labelStyle: const TextStyle(color: Color(0xFF4A00E0)),
                            hintText: '150000',
                            filled: true,
                            fillColor: const Color(0xFFF4F6F9),
                            prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF4A00E0)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 1.5)),
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
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4A00E0)),
                          decoration: InputDecoration(
                            labelText: 'Yang Membayar',
                            labelStyle: const TextStyle(color: Color(0xFF4A00E0)),
                            filled: true,
                            fillColor: const Color(0xFFF4F6F9),
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF4A00E0)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 1.5)),
                          ),
                          items: _groupMembersContacts
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w500))))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedPayerId = v),
                          hint: _groupMembersContacts.isEmpty
                              ? const Text('Tidak ada anggota di grup ini')
                              : const Text('Pilih pembayar'),
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
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _pickDate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFF4A00E0).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF4A00E0), size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tanggal Transaksi', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(DateFormat('dd MMMM yyyy').format(_date), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142), fontSize: 16)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.edit_calendar_rounded, color: Color(0xFF4A00E0)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 22),
                    label: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Transaksi', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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