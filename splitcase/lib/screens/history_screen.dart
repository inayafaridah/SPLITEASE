// screens/history_screen.dart — Orang 2: riwayat pelunasan
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/settlement_provider.dart';
import '../providers/contact_provider.dart';
import '../models/settlement.dart';
import '../utils/currency_formatter.dart';
import '../widgets/split_pie_chart.dart';
import 'settle_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettlementProvider>().loadAll();
      context.read<ContactProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettlementProvider>();
    final cp = context.watch<ContactProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pelunasan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettleScreen()),
            ).then((_) => sp.loadAll()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.history), text: 'Lunas'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary strip
          if (sp.settlements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SplitPieChart(
                settlements: sp.settlements,
                contacts: cp.contacts,
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(context, sp.pending, cp, isPending: true),
                _buildList(context, sp.paid, cp, isPending: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettleScreen()),
        ).then((_) => sp.loadAll()),
        icon: const Icon(Icons.add),
        label: const Text('Catat'),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Settlement> items,
      ContactProvider cp,
      {required bool isPending}) {
    final sp = context.read<SettlementProvider>();

    if (items.isEmpty) {
      return Center(
        child: Text(
          isPending ? 'Tidak ada hutang pending 🎉' : 'Belum ada yang lunas',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final s = items[i];
        final fromName = cp.nameById(s.fromContactId);
        final toName = cp.nameById(s.toContactId);
        final dateStr = DateFormat('dd MMM yyyy')
            .format(DateTime.tryParse(s.date) ?? DateTime.now());

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isPending ? Colors.orange : Colors.green,
              child: Icon(
                isPending ? Icons.access_time : Icons.check,
                color: Colors.white,
              ),
            ),
            title: Text(
              '$fromName → $toName',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr),
                if (s.note.isNotEmpty)
                  Text(s.note,
                      style: const TextStyle(
                          color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
            isThreeLine: s.note.isNotEmpty,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(s.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPending ? Colors.red : Colors.green,
                  ),
                ),
                if (isPending)
                  GestureDetector(
                    onTap: () => sp.markPaid(s.id!),
                    child: const Text('Tandai Lunas',
                        style: TextStyle(
                            color: Colors.blue, fontSize: 11)),
                  ),
              ],
            ),
            onLongPress: () => _settlementOptions(context, s, sp),
          ),
        );
      },
    );
  }

  void _settlementOptions(
      BuildContext context, Settlement s, SettlementProvider sp) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!s.paid)
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Tandai Lunas'),
              onTap: () async {
                Navigator.pop(ctx);
                await sp.markPaid(s.id!);
              },
            ),
          if (s.paid)
            ListTile(
              leading: const Icon(Icons.undo),
              title: const Text('Tandai Pending'),
              onTap: () async {
                Navigator.pop(ctx);
                await sp.markUnpaid(s.id!);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SettleScreen(existing: s)),
              ).then((_) => sp.loadAll());
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
