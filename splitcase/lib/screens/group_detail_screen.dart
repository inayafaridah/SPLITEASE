// lib/screens/group_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/group.dart';
import '../models/transaction.dart';
import '../models/contact.dart';
import '../models/settlement.dart';
import '../providers/transaction_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/group_member_provider.dart';
import '../providers/settlement_provider.dart';
import '../providers/theme_provider.dart';
import '../services/split_calculator.dart';
import '../services/pdf_export_service.dart';
import '../widgets/split_pie_chart.dart';
import '../widgets/debt_balance_card.dart';
import '../widgets/receipt_border_painter.dart';
import '../widgets/wave_background_painter.dart';
import '../utils/currency_formatter.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final themeProvider = context.watch<ThemeProvider>();
    final _primaryColor = themeProvider.primaryColor;
    final _gradientEndColor = themeProvider.gradientEndColor;

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
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: _primaryColor,
                    iconTheme: const IconThemeData(color: Colors.white),
                    title: Text(widget.group.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        tooltip: 'Export PDF',
                        onPressed: () => PdfExportService.showGroupReport(
                          group: widget.group,
                          transactions: tp.transactions,
                          contacts: _filteredGroupContacts,
                          settlements: sp.settlements,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_card_rounded),
                        tooltip: 'Tambah Transaksi',
                        onPressed: () => _addTransaction(),
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: WaveBackground(
                        primaryColor: _primaryColor,
                        gradientEndColor: _gradientEndColor,
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
                          indicatorColor: _primaryColor,
                          indicatorWeight: 3,
                          labelColor: _primaryColor,
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
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _tabController,
                  children: [
                    _buildTransactionTab(context, tp, _primaryColor, _gradientEndColor),
                    _buildDebtTab(context, debts, summaries, sp.settlements, _primaryColor, _gradientEndColor),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
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

  void _confirmDeleteTransaction(BuildContext context, Transaction tx, TransactionProvider tp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Transaksi?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Apakah kamu yakin ingin menghapus transaksi "${tx.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await tp.remove(tx.id!);
              _loadAllScreenData();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTab(BuildContext context, TransactionProvider tp, Color primaryColor, Color gradientEndColor) {
    if (tp.loading) return Center(child: CircularProgressIndicator(color: primaryColor));
    if (tp.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long_outlined, size: 64, color: primaryColor),
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Slidable(
            key: ValueKey(tx.id),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) => _confirmDeleteTransaction(context, tx, tp),
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_rounded,
                  label: 'Hapus',
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
            startActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTransactionScreen(group: widget.group, existing: tx),
                      ),
                    ).then((_) => _loadAllScreenData());
                  },
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
            child: ReceiptCard(
              color: Colors.white,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTransactionScreen(group: widget.group, existing: tx),
                      ),
                    ).then((_) => _loadAllScreenData());
                  },
                  child: Row(
                    children: [
                      _buildTransactionIcon(tx.description, primaryColor, gradientEndColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                if (tx.receiptImagePath != null)
                                  const SizedBox(width: 4), // Placeholder if needed
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Oleh $payerName · ${DateFormat('dd MMM').format(DateTime.tryParse(tx.date) ?? DateTime.now())}',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                            if (tx.receiptImagePath != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding: const EdgeInsets.all(16),
                                        child: Stack(
                                          alignment: Alignment.topRight,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: Image.file(File(tx.receiptImagePath!)),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, color: Colors.white, size: 32),
                                              onPressed: () => Navigator.pop(ctx),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.receipt_long, size: 14, color: Colors.orange),
                                        SizedBox(width: 4),
                                        Text('Lihat Struk', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CurrencyFormatter.format(tx.amount, currency: widget.group.currency),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate(delay: (i * 50).ms).slideX(begin: 0.1, duration: 300.ms, curve: Curves.easeOutQuad).fadeIn(),
        );
      },
    );
  }

  Widget _buildDebtTab(
    BuildContext context,
    List<DebtEntry> debts,
    List<BalanceSummary> summaries,
    List<Settlement> settlements,
    Color primaryColor,
    Color gradientEndColor,
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showReceiptDialog(context, s, primaryColor, gradientEndColor),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                  ),
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTransactionIcon(String description, Color defaultPrimary, Color defaultGradient) {
    final descLower = description.toLowerCase();
    String emoji = '🛍️'; // Default belanja
    Color bgGradientStart = defaultPrimary;
    Color bgGradientEnd = defaultGradient;

    if (descLower.contains('makan') || 
        descLower.contains('ramen') || 
        descLower.contains('kopi') || 
        descLower.contains('cafe') || 
        descLower.contains('dinner') || 
        descLower.contains('lunch') || 
        descLower.contains('pizza') ||
        descLower.contains('kuliner') ||
        descLower.contains('food')) {
      emoji = '🍜';
      bgGradientStart = const Color(0xFFFF5F6D);
      bgGradientEnd = const Color(0xFFFFC371);
    } else if (descLower.contains('bensin') || 
               descLower.contains('grab') || 
               descLower.contains('gojek') || 
               descLower.contains('taxi') || 
               descLower.contains('parkir') || 
               descLower.contains('tol') ||
               descLower.contains('car') ||
               descLower.contains('motor')) {
      emoji = '🚗';
      bgGradientStart = const Color(0xFF2193b0);
      bgGradientEnd = const Color(0xFF6dd5ed);
    } else if (descLower.contains('tiket') || 
               descLower.contains('hotel') || 
               descLower.contains('penginapan') || 
               descLower.contains('villa') ||
               descLower.contains('staycation')) {
      emoji = '🏨';
      bgGradientStart = const Color(0xFF11998e);
      bgGradientEnd = const Color(0xFF38ef7d);
    } else if (descLower.contains('netflix') || 
               descLower.contains('nonton') || 
               descLower.contains('game') || 
               descLower.contains('spotify') ||
               descLower.contains('bioskop') ||
               descLower.contains('cinema') ||
               descLower.contains('karoke')) {
      emoji = '🎬';
      bgGradientStart = const Color(0xFF833ab4);
      bgGradientEnd = const Color(0xFFfd1d1d);
    } else if (descLower.contains('belanja') ||
               descLower.contains('shop') ||
               descLower.contains('baju') ||
               descLower.contains('supermarket') ||
               descLower.contains('indomaret') ||
               descLower.contains('alfamart')) {
      emoji = '🛍️';
      bgGradientStart = const Color(0xFFec008c);
      bgGradientEnd = const Color(0xFFfc6767);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgGradientStart, bgGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: bgGradientStart.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.indigo;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.indigo;
    }
  }

  void _showReceiptDialog(BuildContext context, Settlement s, Color primaryColor, Color gradientEndColor) {
    final cp = context.read<ContactProvider>();
    final fromContact = cp.contacts.firstWhere(
      (c) => c.id == s.fromContactId,
      orElse: () => Contact(name: cp.nameById(s.fromContactId), phone: '', avatarColor: '#607D8B'),
    );
    final toContact = cp.contacts.firstWhere(
      (c) => c.id == s.toContactId,
      orElse: () => Contact(name: cp.nameById(s.toContactId), phone: '', avatarColor: '#607D8B'),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        final dateStr = DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.tryParse(s.date) ?? DateTime.now());
        final sltId = 'SPT-${1000 + (s.id ?? 0)}';

        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          content: Container(
            width: double.maxFinite,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Signature Theme Success Header
                  Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, gradientEndColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: primaryColor,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'PELUNASAN BERHASIL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(s.amount, currency: widget.group.currency),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Receipt Body
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Flow
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Debtor
                            Expanded(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: _parseColor(fromContact.avatarColor),
                                    child: Text(
                                      fromContact.initials,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    fromContact.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  const Text('Pengirim', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                            ),
                            
                            // Arrow
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 20),
                            ),

                            // Creditor
                            Expanded(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: _parseColor(toContact.avatarColor),
                                    child: Text(
                                      toContact.initials,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    toContact.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  const Text('Penerima', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        _buildDashedDivider(),
                        const SizedBox(height: 20),

                        // Detail fields
                        _buildReceiptDetailRow('No. Referensi', sltId),
                        const SizedBox(height: 12),
                        _buildReceiptDetailRow('Waktu Transaksi', dateStr),
                        const SizedBox(height: 12),
                        _buildReceiptDetailRow('Nama Grup', widget.group.name),
                        if (s.note.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildReceiptDetailRow('Catatan', s.note),
                        ],

                        const SizedBox(height: 24),

                        // Share / Close actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text(
                                  'Tutup',
                                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  final shareTxt = 
                                      '=== BUKTI TRANSFER SPLITEASE ===\n'
                                      'No. Ref: $sltId\n'
                                      'Grup: ${widget.group.name}\n'
                                      'Pengirim: ${fromContact.name}\n'
                                      'Penerima: ${toContact.name}\n'
                                      'Nominal: Rp ${NumberFormat('#,###', 'id_ID').format(s.amount)}\n'
                                      'Tanggal: $dateStr\n'
                                      '${s.note.isNotEmpty ? "Catatan: ${s.note}\n" : ""}'
                                      '-----------------------------\n'
                                      'Patungan praktis dengan Splitase!';
                                  Share.share(shareTxt);
                                },
                                icon: const Icon(Icons.share_rounded, size: 18),
                                label: const Text(
                                  'Bagikan',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashedDivider() {
    return Row(
      children: List.generate(
        15,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF2D3142), fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}