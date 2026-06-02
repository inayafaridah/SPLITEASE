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
    await sp.loadByGroup(widget.group.id!); 
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Text(widget.group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card_rounded),
            tooltip: 'Tambah Transaksi',
            onPressed: () => _addTransaction(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Transaksi'),
            Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Hutang'),
          ],
        ),
      ),
      body: _isLoadingMembers
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo, Colors.indigo.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.indigo.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Pengeluaran Grup',
                              style: TextStyle(color: Colors.indigo.shade100, fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(total, currency: widget.group.currency),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            Text('${tp.transactions.length}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('Transaksi', style: TextStyle(color: Colors.indigo.shade100, fontSize: 10)),
                          ],
                        ),
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
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: _addTransaction,
        child: const Icon(Icons.add_rounded, size: 28),
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
    if (tp.loading) return const Center(child: CircularProgressIndicator(color: Colors.indigo));
    if (tp.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Belum ada transaksi', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            Text('Tekan tombol + untuk menambahkan', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }

    final cp = context.read<ContactProvider>();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: tp.transactions.length,
      itemBuilder: (ctx, i) {
        final tx = tp.transactions[i];
        final payerName = cp.nameById(tx.payerContactId);
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade50,
              foregroundColor: Colors.indigo,
              child: Text(payerName.isNotEmpty ? payerName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            subtitle: Text(
              'Dibayar oleh $payerName · ${DateFormat('dd MMM').format(DateTime.tryParse(tx.date) ?? DateTime.now())}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            trailing: Text(
              CurrencyFormatter.format(tx.amount, currency: widget.group.currency),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        ...summaries.map((s) => DebtBalanceCard(summary: s, currency: widget.group.currency)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Divider(),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Perhitungan Penyelesaian Otomatis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
        ),
        if (debts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 10),
                Text('Semua tagihan sudah lunas! 🎉', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ...debts.map((d) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber.shade200)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.arrow_forward_rounded, color: Colors.amber, size: 24),
                title: Text('${d.debtor.name} → ${d.creditor.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                subtitle: const Text('Ketuk untuk mencatat pelunasan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                trailing: Text(
                  CurrencyFormatter.format(d.amount, currency: widget.group.currency),
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                ),
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
        if (settlements.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text('Riwayat Pembayaran Selesai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
          ),
          ...settlements.map((s) {
            final cp = context.read<ContactProvider>();
            final fromName = cp.nameById(s.fromContactId);
            final toName = cp.nameById(s.toContactId);
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.green.shade50.withOpacity(0.5), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.shade100)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(Icons.check_rounded, color: Colors.green, size: 18),
                ),
                title: Text('$fromName → $toName', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(
                    DateFormat('dd MMM yyyy').format(DateTime.tryParse(s.date) ?? DateTime.now()),
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                trailing: Text(
                  CurrencyFormatter.format(s.amount, currency: widget.group.currency),
                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  void _showTxOptions(BuildContext context, Transaction tx, TransactionProvider tp) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.indigo),
              title: const Text('Edit Transaksi', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddTransactionScreen(group: widget.group, existing: tx)),
                ).then((_) => _loadAllScreenData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Hapus Transaksi', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(ctx);
                await tp.remove(tx.id!);
                _loadAllScreenData();
              },
            ),
          ],
        ),
      ),
    );
  }
}