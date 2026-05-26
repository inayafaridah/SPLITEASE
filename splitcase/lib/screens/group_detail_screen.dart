// screens/group_detail_screen.dart — Orang 1
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/group.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/contact_provider.dart';
import '../services/split_calculator.dart';
import '../utils/currency_formatter.dart';
import '../widgets/debt_balance_card.dart';
import 'add_transaction_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadByGroup(widget.group.id!);
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
    final tp = context.watch<TransactionProvider>();
    final cp = context.watch<ContactProvider>();

    final debts = SplitCalculator.calculate(
      transactions: tp.transactions,
      contacts: cp.contacts,
    );
    final summaries = SplitCalculator.balanceSummaries(
      transactions: tp.transactions,
      contacts: cp.contacts,
    );
    final total = SplitCalculator.totalExpense(tp.transactions);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddTransactionScreen(group: widget.group),
              ),
            ).then((_) =>
                context.read<TransactionProvider>().loadByGroup(widget.group.id!)),
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
      body: Column(
        children: [
          // Summary header
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
                    Text(
                      '${tp.transactions.length}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionTab(context, tp),
                _buildDebtTab(context, debts, summaries),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(group: widget.group),
          ),
        ).then((_) =>
            context.read<TransactionProvider>().loadByGroup(widget.group.id!)),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTransactionTab(BuildContext context, TransactionProvider tp) {
    if (tp.loading) return const Center(child: CircularProgressIndicator());
    if (tp.transactions.isEmpty) {
      return const Center(
        child: Text('Belum ada transaksi.\nKetuk + untuk tambah.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey)),
      );
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
              child: Text(payerName.isNotEmpty ? payerName[0] : '?'),
            ),
            title: Text(tx.description,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '$payerName · ${DateFormat('dd MMM').format(DateTime.tryParse(tx.date) ?? DateTime.now())}',
            ),
            trailing: Text(
              CurrencyFormatter.format(tx.amount,
                  currency: widget.group.currency),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green),
            ),
            onLongPress: () => _txOptions(context, tx, tp),
          ),
        );
      },
    );
  }

  Widget _buildDebtTab(BuildContext context, List<DebtEntry> debts,
      List<BalanceSummary> summaries) {
    if (debts.isEmpty && summaries.isEmpty) {
      return const Center(
          child: Text('Tidak ada hutang.', style: TextStyle(color: Colors.grey)));
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // Balance cards
        ...summaries.map((s) => DebtBalanceCard(
              summary: s,
              currency: widget.group.currency,
            )),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text('Siapa Bayar Siapa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        if (debts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Semua sudah lunas! 🎉',
                style: TextStyle(color: Colors.green)),
          ),
        ...debts.map((d) => Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(Icons.arrow_forward, color: Colors.orange),
                title: Text(
                  '${d.debtor.name} → ${d.creditor.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  CurrencyFormatter.format(d.amount,
                      currency: widget.group.currency),
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            )),
      ],
    );
  }

  void _txOptions(
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
                  builder: (_) => AddTransactionScreen(
                    group: widget.group,
                    existing: tx,
                  ),
                ),
              ).then((_) =>
                  context.read<TransactionProvider>().loadByGroup(widget.group.id!));
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(ctx);
              await tp.remove(tx.id!);
            },
          ),
        ],
      ),
    );
  }
}
