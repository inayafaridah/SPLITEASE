// lib/screens/group_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/group.dart';
import '../models/transaction.dart';
import '../models/contact.dart';
import '../models/settlement.dart';
import '../providers/transaction_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/group_member_provider.dart';
import '../providers/settlement_provider.dart';
import '../services/split_calculator.dart';
import '../utils/currency_formatter.dart';
import '../widgets/debt_balance_card.dart';
import 'add_transaction_screen.dart';
import 'settle_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Contact> _filteredGroupContacts = [];
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllScreenData();
  }

  Future<void> _loadAllScreenData() async {
    final tp = context.read<TransactionProvider>();
    final cp = context.read<ContactProvider>();
    final mp = context.read<GroupMemberProvider>();
    final sp = context.read<SettlementProvider>();

    await tp.loadByGroup(widget.group.id!);
    await sp.loadByGroup(widget.group.id!); // load settlement grup ini
    await cp.loadAll();
    final memberIds = await mp.getMembers(widget.group.id!);

    if (mounted) {
      setState(() {
        _filteredGroupContacts = cp.contacts
            .where((c) => memberIds.contains(c.id))
            .toList();
        _isLoadingMembers = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TransactionProvider>();
    final sp = context.watch<SettlementProvider>();

    // Kalkulasi hutang sudah memperhitungkan pelunasan (settlements)
    final debts = SplitCalculator.calculate(
      transactions: tp.transactions,
      contacts: _filteredGroupContacts,
      settlements: sp.settlements,
    );

    final summaries = SplitCalculator.balanceSummaries(
      transactions: tp.transactions,
      contacts: _filteredGroupContacts,
      settlements: sp.settlements,
    );

    final total = SplitCalculator.totalExpense(tp.transactions);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addTransaction(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Transaksi'),
            Tab(icon: Icon(Icons.balance), text: 'Hutang'),
          ],
        ),
      ),
      body: _isLoadingMembers
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Pengeluaran',
                              style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            CurrencyFormatter.format(total,
                                currency: widget.group.currency),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Transaksi',
                              style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('${tp.transactions.length}',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionTab(context, tp),
                      _buildDebtTab(context, debts, summaries, sp.settlements),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(group: widget.group),
      ),
    ).then((_) => _loadAllScreenData());
  }

  Widget _buildTransactionTab(BuildContext context, TransactionProvider tp) {
    if (tp.loading) return const Center(child: CircularProgressIndicator());
    if (tp.transactions.isEmpty) {
      return const Center(
          child: Text('Belum ada transaksi.\nTekan + untuk tambah.',
              textAlign: TextAlign.center));
    }

    final cp = context.read<ContactProvider>();
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: tp.transactions.length,
      itemBuilder: (ctx, i) {
        final tx = tp.transactions[i];
        final payerName = cp.nameById(tx.payerContactId);
        return Card(
          child: ListTile(
            leading: CircleAvatar(
                child: Text(payerName.isNotEmpty ? payerName[0] : '?')),
            title: Text(tx.description,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                '$payerName · ${DateFormat('dd MMM').format(DateTime.tryParse(tx.date) ?? DateTime.now())}'),
            trailing: Text(
              CurrencyFormatter.format(tx.amount,
                  currency: widget.group.currency),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green),
            ),
            onLongPress: () => _showTxOptions(context, tx, tp),
          ),
        );
      },
    );
  }

  Widget _buildDebtTab(
    BuildContext context,
    List<DebtEntry> debts,
    List<BalanceSummary> summaries,
    List<Settlement> settlements,
  ) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        ...summaries
            .map((s) => DebtBalanceCard(summary: s, currency: widget.group.currency)),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Siapa Bayar Siapa',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        if (debts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Semua sudah lunas! 🎉',
                style: TextStyle(color: Colors.green)),
          ),
        ...debts.map((d) => Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading:
                    const Icon(Icons.arrow_forward, color: Colors.orange),
                title: Text('${d.debtor.name} → ${d.creditor.name}'),
                trailing: Text(
                  CurrencyFormatter.format(d.amount,
                      currency: widget.group.currency),
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
                // Tap untuk langsung catat pelunasan
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettleScreen(
                      groupId: widget.group.id,
                      presetFromId: d.debtor.id,
                      presetToId: d.creditor.id,
                      presetAmount: d.amount,
                    ),
                  ),
                ).then((_) => _loadAllScreenData()),
              ),
            )),
        // Riwayat pelunasan di grup ini
        if (settlements.isNotEmpty) ...[
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Riwayat Pelunasan Grup Ini',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...settlements.map((s) {
            final cp = context.read<ContactProvider>();
            final fromName = cp.nameById(s.fromContactId);
            final toName = cp.nameById(s.toContactId);
            return Card(
              color: Colors.green.shade50,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white, size: 18),
                ),
                title: Text('$fromName → $toName',
                    style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                    DateFormat('dd MMM yyyy')
                        .format(DateTime.tryParse(s.date) ?? DateTime.now()),
                    style: const TextStyle(fontSize: 11)),
                trailing: Text(
                  CurrencyFormatter.format(s.amount,
                      currency: widget.group.currency),
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  void _showTxOptions(
      BuildContext context, Transaction tx, TransactionProvider tp) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddTransactionScreen(group: widget.group, existing: tx),
                ),
              ).then((_) => _loadAllScreenData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title:
                const Text('Hapus', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(ctx);
              await tp.remove(tx.id!);
              _loadAllScreenData();
            },
          ),
        ],
      ),
    );
  }
}
