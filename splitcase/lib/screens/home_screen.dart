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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().loadAll();
      context.read<ContactProvider>().loadAll();
    });
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Splitage', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Kelola Kontak',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddContactScreen()))
                .then((_) => context.read<ContactProvider>().loadAll()),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: gp.loading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : gp.groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.group_outlined, size: 80, color: Colors.indigo),
                      ),
                      const SizedBox(height: 24),
                      const Text('Belum ada grup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text('Buat grup untuk mulai split tagihan', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: gp.groups.length,
                  itemBuilder: (ctx, i) {
                    final group = gp.groups[i];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              group.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ),
                        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd MMM yyyy').format(DateTime.parse(group.createdAt)),
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade600),
                              tooltip: 'Edit Grup',
                              onPressed: () => _showEditGroupDialog(context, group),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                              tooltip: 'Hapus Grup',
                              onPressed: () => _confirmDelete(context, group),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey.shade400),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
                        ).then((_) => gp.loadAll()),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => _showAddGroupDialog(context),
        icon: const Icon(Icons.add, size: 22),
        label: const Text('Grup Baru', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3)),
      ),
    );
  }
}