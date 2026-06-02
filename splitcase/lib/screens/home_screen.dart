// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/contact.dart';
import '../models/group.dart';
import '../providers/group_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/group_member_provider.dart';
import '../services/preferences_service.dart';
import 'group_detail_screen.dart';
import 'add_contact_screen.dart';
import 'settings_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Pengguna';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().loadAll();
      context.read<ContactProvider>().loadAll();
    });
  }

  Future<void> _loadUserName() async {
    final prefs = PreferencesService();
    final name = await prefs.getUserName();
    if (name.isNotEmpty && mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  Future<int?> _ensureCreatorContact() async {
    final prefs = PreferencesService();
    final myName = (await prefs.getUserName()).trim();

    if (myName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Nama belum diatur! Isi di halaman Pengaturan dahulu.')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.amber.shade800,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return null;
    }

    final cp = context.read<ContactProvider>();
    await cp.loadAll();

    final existing = cp.contacts.where(
      (c) => c.name.trim().toLowerCase() == myName.toLowerCase(),
    );

    if (existing.isNotEmpty) return existing.first.id;

    final newId = await cp.add(Contact(name: myName, phone: ''));
    return newId;
  }

  Future<void> _showAddGroupDialog(BuildContext context) async {
    await context.read<ContactProvider>().loadAll();
    if (!mounted) return;

    final nameCtrl = TextEditingController();
    String currency = 'IDR';
    final selectedIds = ValueNotifier<List<int>>([]);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return ValueListenableBuilder<List<int>>(
          valueListenable: selectedIds,
          builder: (_, selected, __) {
            final cp = context.read<ContactProvider>();
            return StatefulBuilder(builder: (ctx, setLocal) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.group_add_rounded, color: Colors.indigo),
                    SizedBox(width: 10),
                    Text('Buat Grup Baru', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nama Grup',
                            hintText: 'e.g., Dinner Fancy Bali',
                            prefixIcon: const Icon(Icons.edit_road_rounded),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: currency,
                          decoration: InputDecoration(
                            labelText: 'Mata Uang',
                            prefixIcon: const Icon(Icons.payments_outlined),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: ['IDR', 'USD', 'EUR'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setLocal(() => currency = v ?? 'IDR'),
                        ),
                        const SizedBox(height: 20),
                        const Text('Pilih Anggota Tambahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Kamu (creator) otomatis masuk sebagai anggota.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 12),
                        cp.contacts.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                    SizedBox(width: 8),
                                    Text('Tambah kontak terlebih dahulu', style: TextStyle(color: Colors.orange)),
                                  ],
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: cp.contacts.map((c) {
                                  final isSel = selected.contains(c.id);
                                  return FilterChip(
                                    label: Text(c.name),
                                    selected: isSel,
                                    selectedColor: Colors.indigo.shade100,
                                    checkmarkColor: Colors.indigo,
                                    labelStyle: TextStyle(
                                      color: isSel ? Colors.indigo.shade900 : Colors.black87,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    onSelected: (sel) {
                                      final next = List<int>.from(selected);
                                      sel ? next.add(c.id!) : next.remove(c.id);
                                      selectedIds.value = next;
                                    },
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Nama grup tidak boleh kosong'), behavior: SnackBarBehavior.floating),
                        );
                        return;
                      }
                      Navigator.pop(dialogContext);
                      final gp = context.read<GroupProvider>();
                      final gmp = context.read<GroupMemberProvider>();
                      try {
                        final groupId = await gp.add(Group(name: name, currency: currency));
                        final creatorId = await _ensureCreatorContact();
                        final allMemberIds = <int>{
                          ...selectedIds.value,
                          if (creatorId != null) creatorId,
                        }.toList();
                        if (allMemberIds.isNotEmpty) await gmp.addMembers(groupId, allMemberIds);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Grup berhasil dibuat 🎉'), behavior: SnackBarBehavior.floating),
                          );
                          gp.loadAll();
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                      }
                    },
                    child: const Text('Buat'),
                  ),
                ],
              );
            });
          },
        );
      },
    );
  }

  Future<void> _showEditGroupDialog(BuildContext context, Group group) async {
    final cp = context.read<ContactProvider>();
    final gmp = context.read<GroupMemberProvider>();
    await cp.loadAll();
    final existingMemberIds = await gmp.getMembers(group.id!);

    if (!mounted) return;

    final nameCtrl = TextEditingController(text: group.name);
    String currency = group.currency;
    final selectedIds = ValueNotifier<List<int>>(List<int>.from(existingMemberIds));

    showDialog(
      context: context,
      builder: (dialogContext) {
        return ValueListenableBuilder<List<int>>(
          valueListenable: selectedIds,
          builder: (_, selected, __) {
            return StatefulBuilder(builder: (ctx, setLocal) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.edit_rounded, color: Colors.indigo),
                    SizedBox(width: 10),
                    Text('Edit Data Grup', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nama Grup',
                            prefixIcon: const Icon(Icons.edit),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: currency,
                          decoration: InputDecoration(
                            labelText: 'Mata Uang',
                            prefixIcon: const Icon(Icons.payments_outlined),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: ['IDR', 'USD', 'EUR'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setLocal(() => currency = v ?? 'IDR'),
                        ),
                        const SizedBox(height: 20),
                        const Text('Anggota Grup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        cp.contacts.isEmpty
                            ? const Text('Belum ada kontak.')
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: cp.contacts.map((c) {
                                  final isSel = selected.contains(c.id);
                                  return FilterChip(
                                    label: Text(c.name),
                                    selected: isSel,
                                    selectedColor: Colors.indigo.shade100,
                                    checkmarkColor: Colors.indigo,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    onSelected: (sel) {
                                      final next = List<int>.from(selected);
                                      sel ? next.add(c.id!) : next.remove(c.id);
                                      selectedIds.value = next;
                                    },
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final newName = nameCtrl.text.trim();
                      if (newName.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Nama grup tidak boleh kosong'), behavior: SnackBarBehavior.floating),
                        );
                        return;
                      }
                      Navigator.pop(dialogContext);
                      final gp = context.read<GroupProvider>();
                      try {
                        await gp.rename(group.id!, newName, currency: currency);
                        await gmp.replaceMembers(group.id!, selectedIds.value);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Grup berhasil di-update ✓'), behavior: SnackBarBehavior.floating),
                          );
                          gp.loadAll();
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              );
            });
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Grup?'),
          ],
        ),
        content: Text('Semua transaksi dan data di "${group.name}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: Colors.grey.shade600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final gp = context.read<GroupProvider>();
              await gp.remove(group.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GroupProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Soft premium background
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF4A00E0),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SplitEase',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Row(
                              children: [
                                _buildGlassIconButton(
                                  icon: Icons.people_alt_outlined,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddContactScreen())).then((_) => context.read<ContactProvider>().loadAll()),
                                ),
                                const SizedBox(width: 12),
                                _buildGlassIconButton(
                                  icon: Icons.settings_outlined,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                                ),
                              ],
                            )
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Kelola tagihanmu',
                          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Mudah & Cepat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: gp.loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0))),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDashboardCard(context),
                      if (gp.groups.isEmpty)
                        _buildEmptyState()
                      else ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 24, top: 24, bottom: 4),
                          child: Text(
                            'Grup Patunganmu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                        ),
                        ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: gp.groups.length,
                          itemBuilder: (ctx, i) {
                            final group = gp.groups[i];
                            return _buildGroupCard(context, group);
                          },
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4A00E0),
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _showAddGroupDialog(context),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('Grup Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF4A00E0).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group_outlined, size: 80, color: Color(0xFF4A00E0)),
            ),
            const SizedBox(height: 32),
            const Text(
              'Belum ada grup',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
            ),
            const SizedBox(height: 12),
            Text(
              'Buat grup pertamamu untuk mulai\npatungan dengan teman-teman!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, Group group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
          ).then((_) => context.read<GroupProvider>().loadAll()),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildGroupIcon(group.name),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy').format(DateTime.parse(group.createdAt)),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 22, color: Colors.grey.shade400),
                      tooltip: 'Edit Grup',
                      onPressed: () => _showEditGroupDialog(context, group),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 22, color: Colors.red.shade300),
                      tooltip: 'Hapus Grup',
                      onPressed: () => _confirmDelete(context, group),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupIcon(String groupName) {
    final nameLower = groupName.toLowerCase();
    String emoji = '👥';
    Color startColor = const Color(0xFF4A00E0);
    Color endColor = const Color(0xFF8E2DE2);

    if (nameLower.contains('makan') || 
        nameLower.contains('dinner') || 
        nameLower.contains('lunch') || 
        nameLower.contains('cafe') || 
        nameLower.contains('kuliner') || 
        nameLower.contains('ramen') || 
        nameLower.contains('food') || 
        nameLower.contains('kopi') ||
        nameLower.contains('coffee')) {
      emoji = '🍜';
      startColor = const Color(0xFFFF5F6D);
      endColor = const Color(0xFFFFC371);
    } else if (nameLower.contains('libur') || 
               nameLower.contains('trip') || 
               nameLower.contains('bali') || 
               nameLower.contains('jalan') || 
               nameLower.contains('travel') || 
               nameLower.contains('wisata')) {
      emoji = '✈️';
      startColor = const Color(0xFF2193b0);
      endColor = const Color(0xFF6dd5ed);
    } else if (nameLower.contains('kost') || 
               nameLower.contains('kontrakan') || 
               nameLower.contains('rumah') || 
               nameLower.contains('home') || 
               nameLower.contains('rent') ||
               nameLower.contains('apart')) {
      emoji = '🏠';
      startColor = const Color(0xFF11998e);
      endColor = const Color(0xFF38ef7d);
    } else if (nameLower.contains('nonton') || 
               nameLower.contains('game') || 
               nameLower.contains('bioskop') || 
               nameLower.contains('cinema') || 
               nameLower.contains('play') ||
               nameLower.contains('fun')) {
      emoji = '🎮';
      startColor = const Color(0xFF833ab4);
      endColor = const Color(0xFFfd1d1d);
    } else if (nameLower.contains('belanja') || 
               nameLower.contains('shop') || 
               nameLower.contains('mall') || 
               nameLower.contains('kado') || 
               nameLower.contains('gift')) {
      emoji = '🛍️';
      startColor = const Color(0xFFec008c);
      endColor = const Color(0xFFfc6767);
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(
            fontSize: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context) {
    final gp = context.watch<GroupProvider>();
    final cp = context.watch<ContactProvider>();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A00E0).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white.withOpacity(0.08),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.face_retouching_natural_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, $_userName! 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Selamat datang di SplitEase',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Grup',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.group_work_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${gp.groups.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white24,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Kontak',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.contacts_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${cp.contacts.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}