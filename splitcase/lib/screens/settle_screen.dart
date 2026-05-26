// screens/settle_screen.dart — Orang 2: catat pelunasan
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/settlement.dart';
import '../providers/settlement_provider.dart';
import '../providers/contact_provider.dart';

class SettleScreen extends StatefulWidget {
  final Settlement? existing;
  const SettleScreen({super.key, this.existing});

  @override
  State<SettleScreen> createState() => _SettleScreenState();
}

class _SettleScreenState extends State<SettleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  int? _fromId;
  int? _toId;
  DateTime _date = DateTime.now();
  bool _submitting = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final s = widget.existing!;
      _fromId = s.fromContactId;
      _toId = s.toContactId;
      _amountCtrl.text = s.amount.toStringAsFixed(0);
      _noteCtrl.text = s.note;
      _date = DateTime.tryParse(s.date) ?? DateTime.now();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
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
    if (_fromId == null || _toId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pembayar dan penerima')),
      );
      return;
    }
    if (_fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayar dan penerima harus berbeda')),
      );
      return;
    }

    setState(() => _submitting = true);
    final sp = context.read<SettlementProvider>();
    final settlement = Settlement(
      id: widget.existing?.id,
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
    final contacts = context.watch<ContactProvider>().contacts;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Pelunasan' : 'Catat Pelunasan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // From contact
            DropdownButtonFormField<int>(
              value: _fromId,
              decoration: const InputDecoration(
                labelText: 'Dari (yang membayar hutang)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: contacts
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _fromId = v),
              validator: (v) => v == null ? 'Pilih pembayar' : null,
            ),
            const SizedBox(height: 16),

            // To contact
            DropdownButtonFormField<int>(
              value: _toId,
              decoration: const InputDecoration(
                labelText: 'Ke (yang menerima)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: contacts
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _toId = v),
              validator: (v) => v == null ? 'Pilih penerima' : null,
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                if (double.tryParse(v) == null || double.parse(v) <= 0) {
                  return 'Masukkan jumlah valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
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

            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle),
              label: Text(isEdit ? 'Simpan' : 'Catat Pelunasan'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }
}
