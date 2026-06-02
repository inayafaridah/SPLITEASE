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
      backgroundColor: const Color(0xFFF4F6F9),
      body: _isLoadingMembers
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: const Color(0xFF4A00E0),
                    iconTheme: const IconThemeData(color: Colors.white),
                    title: Text(widget.group.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.add_card_rounded),
                        tooltip: 'Tambah Transaksi',
                        onPressed: () => _addTransaction(),
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Total Pengeluaran Grup',
                                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Text(
                                  CurrencyFormatter.format(total, currency: widget.group.currency),
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Text('${tp.transactions.length} Transaksi',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: const Color(0xFF4A00E0),
                          indicatorWeight: 3,
                          labelColor: const Color(0xFF4A00E0),
                          unselectedLabelColor: Colors.grey.shade500,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          tabs: const [
                            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Transaksi'),
                            Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Hutang'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: Container(
                color: Colors.white,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionTab(context, tp),
                    _buildDebtTab(context, debts, summaries, sp.settlements),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A00E0),
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    if (tp.loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)));
    if (tp.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF4A00E0).withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFF4A00E0)),
            ),
            const SizedBox(height: 16),
            const Text('Belum ada transaksi', style: TextStyle(color: Color(0xFF2D3142), fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Tekan tombol + untuk menambahkan', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      );
    }

    final cp = context.read<ContactProvider>();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: tp.transactions.length,
      itemBuilder: (ctx, i) {
        final tx = tp.transactions[i];
        final payerName = cp.nameById(tx.payerContactId);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onLongPress: () => _showTxOptions(context, tx, tp),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A00E0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          payerName.isNotEmpty ? payerName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Color(0xFF4A00E0), fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                          const SizedBox(height: 4),
                          Text(
                            'Oleh $payerName · ${DateFormat('dd MMM').format(DateTime.tryParse(tx.date) ?? DateTime.now())}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(tx.amount, currency: widget.group.currency),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        ...summaries.map((s) => DebtBalanceCard(summary: s, currency: widget.group.currency)),
        const SizedBox(height: 20),
        const Text('Penyelesaian Otomatis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142))),
        const SizedBox(height: 12),
        if (debts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade100)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                  child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Semua Lunas! 🎉', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Tidak ada hutang yang tersisa di grup ini.', style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ...debts.map((d) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.amber.shade200)),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.amber, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${d.debtor.name} → ${d.creditor.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142))),
                              const SizedBox(height: 4),
                              const Text('Ketuk untuk mencatat pelunasan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(d.amount, currency: widget.group.currency),
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
        if (settlements.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Riwayat Pelunasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142))),
          const SizedBox(height: 12),
          ...settlements.map((s) {
            final cp = context.read<ContactProvider>();
            final fromName = cp.nameById(s.fromContactId);
            final toName = cp.nameById(s.toContactId);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.check_rounded, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$fromName → $toName', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(DateTime.tryParse(s.date) ?? DateTime.now()),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(s.amount, currency: widget.group.currency),
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 32),
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