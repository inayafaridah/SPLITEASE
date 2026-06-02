// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settlement.dart';
import '../providers/settlement_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/group_provider.dart';
import 'settle_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int? _filterGroupId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettlementProvider>().loadAll();
      context.read<ContactProvider>().loadAll();
      context.read<GroupProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettlementProvider>();
    final cp = context.watch<ContactProvider>();
    final gp = context.watch<GroupProvider>();

    // Validasi: kalau grup sudah dihapus, reset filter agar dropdown tidak crash
    final validGroupIds = gp.groups.map((g) => g.id).toSet();
    if (_filterGroupId != null && !validGroupIds.contains(_filterGroupId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _filterGroupId = null);
      });
      _filterGroupId = null;
    }

    final displayedSettlements = _filterGroupId == null
        ? sp.settlements
        : sp.settlements.where((s) => s.groupId == _filterGroupId).toList();

    final double totalSettled =
        displayedSettlements.fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pembayaran')),
      body: sp.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey('filter_${gp.groups.length}_${gp.groups.map((g) => g.id).join(',')}'),
                    value: _filterGroupId,
                    decoration: const InputDecoration(
                      labelText: 'Filter Grup',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.filter_list),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Semua Grup')),
                      ...gp.groups.map((g) => DropdownMenuItem<int?>(value: g.id, child: Text(g.name))),
                    ],
                    onChanged: (v) => setState(() => _filterGroupId = v),
                  ),
                ),
                if (displayedSettlements.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('Belum ada riwayat pembayaran.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else ...[
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
                      ],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 75,
                              height: 75,
                              child: CircularProgressIndicator(
                                value: totalSettled > 0 ? 1.0 : 0.0,
                                strokeWidth: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                              ),
                            ),
                            const Icon(Icons.donut_large, size: 36, color: Colors.green),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Dana Selesai Dibayar',
                                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('Rp ${totalSettled.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                              Text('Dari ${displayedSettlements.length} transaksi pelunasan',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildList(context, displayedSettlements)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettleScreen()),
        ).then((_) => context.read<SettlementProvider>().loadAll()),
        icon: const Icon(Icons.add),
        label: const Text('Catat'),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Settlement> settlements) {
    final sp = context.read<SettlementProvider>();
    final cp = context.read<ContactProvider>();
    final gp = context.read<GroupProvider>();

    return ListView.builder(
      itemCount: settlements.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final s = settlements[index];

        final fromName = cp.contacts
            .where((c) => c.id == s.fromContactId)
            .map((c) => c.name)
            .firstWhere((_) => true, orElse: () => 'Tidak Diketahui');

        final toName = cp.contacts
            .where((c) => c.id == s.toContactId)
            .map((c) => c.name)
            .firstWhere((_) => true, orElse: () => 'Tidak Diketahui');

        final groupName = s.groupId != null
            ? gp.groups
                .where((g) => g.id == s.groupId)
                .map((g) => g.name)
                .firstWhere((_) => true, orElse: () => 'Grup dihapus')
            : '';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.greenAccent,
              child: Icon(Icons.check, color: Colors.green),
            ),
            title: Text('$fromName \u2192 $toName', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jumlah: Rp ${s.amount.toStringAsFixed(0)}'),
                if (groupName.isNotEmpty)
                  Text('Grup: $groupName', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _settlementOptions(context, s, sp),
            ),
          ),
        );
      },
    );
  }

  void _settlementOptions(BuildContext ctx, Settlement s, SettlementProvider sp) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettleScreen(existing: s)))
                  .then((_) => context.read<SettlementProvider>().loadAll());
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(ctx);
              await sp.remove(s.id!);
            },
          ),
        ],
      ),
    );
  }
}
