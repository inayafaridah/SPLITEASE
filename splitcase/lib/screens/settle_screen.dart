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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih grup terlebih dahulu')));
      return;
    }
    if (_fromId == null || _toId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih pembayar dan penerima')));
      return;
    }
    if (_fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayar dan penerima harus berbeda')));
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
      appBar: AppBar(title: Text(isEdit ? 'Edit Pelunasan' : 'Catat Pelunasan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int?>(
              value: _groupId,
              decoration: const InputDecoration(
                labelText: 'Pilih Grup',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
              hint: const Text('-- Pilih Grup --'),
              items: gp.groups.map((g) => DropdownMenuItem<int?>(value: g.id, child: Text(g.name))).toList(),
              onChanged: (v) async {
                setState(() => _groupId = v);
                if (v != null) await _loadGroupMembers(v);
              },
              validator: (v) => v == null ? 'Wajib pilih grup' : null,
            ),
            const SizedBox(height: 16),

            if (_loadingMembers)
              const Center(child: CircularProgressIndicator())
            else if (_groupId == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Pilih grup dulu untuk melihat anggota.', style: TextStyle(color: Colors.grey)),
              )
            else if (contactsToShow.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Grup ini belum punya anggota.', style: TextStyle(color: Colors.orange)),
              )
            else ...[
              DropdownButtonFormField<int>(
                value: _fromId,
                decoration: const InputDecoration(
                  labelText: 'Dari (Yang Membayar)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                hint: const Text('-- Pilih Pembayar --'),
                items: contactsToShow.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _fromId = v),
                validator: (v) => v == null ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _toId,
                decoration: const InputDecoration(
                  labelText: 'Ke (Yang Menerima)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                hint: const Text('-- Pilih Penerima --'),
                items: contactsToShow.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _toId = v),
                validator: (v) => v == null ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  (v == null || double.tryParse(v) == null || double.parse(v) <= 0) ? 'Masukkan jumlah valid' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.grey),
              ),
              leading: const Icon(Icons.calendar_today),
              title: const Text('Tanggal'),
              subtitle: Text(DateFormat('dd MMMM yyyy').format(_date)),
              onTap: _pickDate,
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(isEdit ? 'Simpan Perubahan' : 'Catat Pelunasan'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }
}
