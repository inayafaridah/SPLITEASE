// lib/screens/settle_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/contact.dart';
import '../models/settlement.dart';
import '../providers/settlement_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/group_provider.dart';
import '../providers/group_member_provider.dart';

class SettleScreen extends StatefulWidget {
  final Settlement? existing;
  final int? groupId;
  final int? presetFromId;
  final int? presetToId;
  final double? presetAmount;

  const SettleScreen({
    super.key,
    this.existing,
    this.groupId,
    this.presetFromId,
    this.presetToId,
    this.presetAmount,
  });

  @override
  State<SettleScreen> createState() => _SettleScreenState();
}

class _SettleScreenState extends State<SettleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  int? _groupId;
  int? _fromId;
  int? _toId;
  DateTime _date = DateTime.now();
  bool _submitting = false;

  List<Contact> _groupContacts = [];
  bool _loadingMembers = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      final s = widget.existing!;
      _groupId = s.groupId;
      _fromId = s.fromContactId;
      _toId = s.toContactId;
      _amountCtrl.text = s.amount.toStringAsFixed(0);
      _noteCtrl.text = s.note;
      _date = DateTime.tryParse(s.date) ?? DateTime.now();
    }

    if (widget.presetFromId != null) _fromId = widget.presetFromId;
    if (widget.presetToId != null) _toId = widget.presetToId;
    if (widget.presetAmount != null) {
      _amountCtrl.text = widget.presetAmount!.toStringAsFixed(0);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<GroupProvider>().loadAll();
      await context.read<ContactProvider>().loadAll();

      if (widget.groupId != null) {
        setState(() => _groupId = widget.groupId);
        await _loadGroupMembers(widget.groupId!);
        if (mounted) {
          setState(() {
            if (widget.presetFromId != null) _fromId = widget.presetFromId;
            if (widget.presetToId != null) _toId = widget.presetToId;
          });
        }
      } else if (isEdit && _groupId != null) {
        await _loadGroupMembers(_groupId!);
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGroupMembers(int groupId) async {
    setState(() {
      _loadingMembers = true;
      if (widget.presetFromId == null) _fromId = null;
      if (widget.presetToId == null) _toId = null;
    });

    final mp = context.read<GroupMemberProvider>();
    final cp = context.read<ContactProvider>();
    final memberIds = await mp.getMembers(groupId);

    if (mounted) {
      setState(() {
        _groupContacts = cp.contacts.where((c) => memberIds.contains(c.id)).toList();
        _loadingMembers = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih grup terlebih dahulu'), behavior: SnackBarBehavior.floating));
      return;
    }
    if (_fromId == null || _toId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih pembayar dan penerima'), behavior: SnackBarBehavior.floating));
      return;
    }
    if (_fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayar dan penerima harus berbeda'), behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _submitting = true);
    final sp = context.read<SettlementProvider>();

    final settlement = Settlement(
      id: widget.existing?.id,
      groupId: _groupId,
      fromContactId: _fromId!,
      toContactId: _toId!,
      amount: double.parse(_amountCtrl.text),
      date: _date.toIso8601String(),
      note: _noteCtrl.text.trim(),
      isPaid: widget.existing?.isPaid ?? 0,
    );

    if (isEdit) {
      await sp.updateSettlement(settlement);
    } else {
      await sp.add(settlement);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GroupProvider>();
    final contactsToShow = _groupId != null && _groupContacts.isNotEmpty ? _groupContacts : <Contact>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        title: Text(isEdit ? 'Edit Transaksi Pelunasan' : 'Catat Pelunasan', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        child: const Icon(Icons.group_work_rounded, color: Color(0xFF4A00E0), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text('Pilih Lingkup Grup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<int?>(
                    value: _groupId,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4A00E0)),
                    decoration: InputDecoration(
                      labelText: 'Pilih Grup Utama',
                      labelStyle: const TextStyle(color: Color(0xFF4A00E0)),
                      filled: true,
                      fillColor: const Color(0xFFF4F6F9),
                      prefixIcon: const Icon(Icons.group_outlined, color: Color(0xFF4A00E0)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 1.5)),
                    ),
                    hint: const Text('-- Pilih Grup --'),
                    items: gp.groups.map((g) => DropdownMenuItem<int?>(value: g.id, child: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                    onChanged: (v) async {
                      setState(() => _groupId = v);
                      if (v != null) await _loadGroupMembers(v);
                    },
                    validator: (v) => v == null ? 'Wajib pilih grup' : null,
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
                        child: const Icon(Icons.swap_horizontal_circle_rounded, color: Color(0xFF4A00E0), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text('Alur Transaksi & Nominal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_loadingMembers)
                    const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Color(0xFF4A00E0))))
                  else if (_groupId == null)
                    Text('Silakan tentukan grup terlebih dahulu.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
                  else if (contactsToShow.isEmpty)
                    const Text('Grup pilihan belum memiliki data anggota.', style: TextStyle(color: Colors.orange, fontSize: 13))
                  else ...[
                    DropdownButtonFormField<int>(
                      value: _fromId,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4A00E0)),
                      decoration: InputDecoration(
                        labelText: 'Dari (Yang Membayar)',
                        labelStyle: const TextStyle(color: Color(0xFF4A00E0)),
                        filled: true,
                        fillColor: const Color(0xFFF4F6F9),
                        prefixIcon: const Icon(Icons.person_remove_outlined, color: Color(0xFF4A00E0)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 1.5)),
                      ),
                      hint: const Text('-- Pilih Pembayar --'),
                      items: contactsToShow.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                      onChanged: (v) => setState(() => _fromId = v),
                      validator: (v) => v == null ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _toId,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4A00E0)),
                      decoration: InputDecoration(
                        labelText: 'Ke (Yang Menerima)',
                        labelStyle: const TextStyle(color: Color(0xFF4A00E0)),
                        filled: true,
                        fillColor: const Color(0xFFF4F6F9),
                        prefixIcon: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF4A00E0)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 1.5)),
                      ),
                      hint: const Text('-- Pilih Penerima --'),
                      items: contactsToShow.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                      onChanged: (v) => setState(() => _toId = v),
                      validator: (v) => v == null ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _amountCtrl,
                    decoration: InputDecoration(
                      labelText: 'Total Dana Pelunasan',
                      labelStyle: const TextStyle(color: Color(0xFF4A00E0)),
                      filled: true,
                      fillColor: const Color(0xFFF4F6F9),
                      prefixIcon: const Icon(Icons.price_check_rounded, color: Color(0xFF4A00E0)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 1.5)),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        (v == null || double.tryParse(v) == null || double.parse(v) <= 0) ? 'Masukkan jumlah nominal valid' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Catatan Pendukung (opsional)',
                      labelStyle: const TextStyle(color: Color(0xFF4A00E0)),
                      filled: true,
                      fillColor: const Color(0xFFF4F6F9),
                      prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF4A00E0)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 1.5)),
                    ),
                    maxLines: 2,
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
                          child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF4A00E0), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tanggal Penyelesaian', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
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
                  : const Icon(Icons.done_all_rounded, size: 22),
              label: Text(isEdit ? 'Simpan Perubahan' : 'Selesaikan Pembayaran', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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