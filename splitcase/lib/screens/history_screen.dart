// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settlement.dart';
import '../providers/settlement_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/group_provider.dart';
import '../providers/theme_provider.dart';
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
    final themeProvider = context.watch<ThemeProvider>();
    final _primaryColor = themeProvider.primaryColor;
    final _gradientEndColor = themeProvider.gradientEndColor;

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
      backgroundColor: const Color(0xFFF4F6F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: _primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _gradientEndColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Riwayat Pelunasan',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${displayedSettlements.length} transaksi pelunasan selesai',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: sp.loading
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: _primaryColor)),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: DropdownButtonFormField<int?>(
                            key: ValueKey('filter_${gp.groups.length}_${gp.groups.map((g) => g.id).join(',')}'),
                            value: _filterGroupId,
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
                            decoration: InputDecoration(
                              labelText: 'Filter Grup',
                              labelStyle: TextStyle(color: _primaryColor),
                              filled: true,
                              fillColor: Colors.transparent,
                              isDense: true,
                              prefixIcon: Icon(Icons.filter_list_rounded, color: _primaryColor),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Semua Grup', style: TextStyle(fontWeight: FontWeight.w600))),
                              ...gp.groups.map((g) => DropdownMenuItem<int?>(value: g.id, child: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w500)))),
                            ],
                            onChanged: (v) => setState(() => _filterGroupId = v),
                          ),
                        ),
                      ),
                      if (displayedSettlements.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(color: _primaryColor.withOpacity(0.05), shape: BoxShape.circle),
                                  child: Icon(Icons.history_toggle_off_rounded, size: 80, color: _primaryColor),
                                ),
                                const SizedBox(height: 32),
                                const Text('Belum ada pelunasan', style: TextStyle(color: Color(0xFF2D3142), fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Text('Riwayat pembayaranmu akan\nmuncul di sini.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.5)),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade50, Colors.green.shade100],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.assignment_turned_in_rounded, size: 32, color: Colors.green),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total Dana Lunas', style: TextStyle(fontSize: 13, color: Colors.green.shade800, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    Text('Rp ${totalSettled.toStringAsFixed(0)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green.shade700, letterSpacing: -0.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Align(alignment: Alignment.centerLeft, child: Text('Daftar Pelunasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142)))),
                        ),
                        _buildList(context, displayedSettlements, _primaryColor),
                        const SizedBox(height: 80),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettleScreen()),
        ).then((_) => context.read<SettlementProvider>().loadAll()),
        icon: const Icon(Icons.post_add_rounded, size: 24),
        label: const Text('Catat Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Settlement> settlements, Color primaryColor) {
    final sp = context.read<SettlementProvider>();
    final cp = context.read<ContactProvider>();
    final gp = context.read<GroupProvider>();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: settlements.length,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _settlementOptions(context, s, sp),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.check_rounded, color: Colors.green, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$fromName ➔ $toName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                          const SizedBox(height: 6),
                          Text('Rp ${s.amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold)),
                          if (groupName.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(groupName, style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
                  ],
                ),
              ),
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