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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Riwayat Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: sp.loading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey('filter_${gp.groups.length}_${gp.groups.map((g) => g.id).join(',')}'),
                    value: _filterGroupId,
                    decoration: InputDecoration(
                      labelText: 'Filter Berdasarkan Grup',
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      prefixIcon: const Icon(Icons.filter_list_rounded, color: Colors.indigo),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Semua Grup')),
                      ...gp.groups.map((g) => DropdownMenuItem<int?>(value: g.id, child: Text(g.name))),
                    ],
                    onChanged: (v) => setState(() => _filterGroupId = v),
                  ),
                ),
                if (displayedSettlements.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('Belum ada riwayat pembayaran', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ), // Di sini komponen bordernya sudah dibuang sepenuhnya agar aman 100%
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: CircularProgressIndicator(
                                value: totalSettled > 0 ? 1.0 : 0.0,
                                strokeWidth: 6,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                              ),
                            ),
                            const Icon(Icons.assignment_turned_in_rounded, size: 32, color: Colors.green),
                          ],
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Dana Selesai Dibayar',
                                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('Rp ${totalSettled.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                              Text('Berdasarkan ${displayedSettlements.length} data pelunasan',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Align(alignment: Alignment.centerLeft, child: Text('Daftar Pelunasan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  ),
                  Expanded(child: _buildList(context, displayedSettlements)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettleScreen()),
        ).then((_) => context.read<SettlementProvider>().loadAll()),
        icon: const Icon(Icons.post_add_rounded),
        label: const Text('Catat Baru', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Settlement> settlements) {
    final sp = context.read<SettlementProvider>();
    final cp = context.read<ContactProvider>();
    final gp = context.read<GroupProvider>();

    return ListView.builder(
      itemCount: settlements.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade50,
              child: const Icon(Icons.check_rounded, color: Colors.green),
            ),
            title: Text('$fromName ➔ $toName', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text('Jumlah: Rp ${s.amount.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                if (groupName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Grup: $groupName', style: TextStyle(fontSize: 11, color: Colors.indigo.shade400, fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.indigo),
            title: const Text('Edit Catatan Pembayaran'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettleScreen(existing: s)))
                  .then((_) => context.read<SettlementProvider>().loadAll());
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            title: const Text('Hapus Pembayaran', style: TextStyle(color: Colors.red)),
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