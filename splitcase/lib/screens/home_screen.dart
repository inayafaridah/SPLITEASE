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
          const SnackBar(
            content: Text('\u26A0\uFE0F Nama kamu belum diset. Isi nama di halaman Pengaturan agar ikut masuk grup.'),
            duration: Duration(seconds: 3),
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
                title: const Text('Buat Grup Baru'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Grup',
                            hintText: 'Dinner Fancy Bali',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: currency,
                          decoration: const InputDecoration(labelText: 'Mata Uang', border: OutlineInputBorder()),
                          items: ['IDR', 'USD', 'EUR'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setLocal(() => currency = v ?? 'IDR'),
                        ),
                        const SizedBox(height: 16),
                        const Text('Pilih Anggota Tambahan', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Kamu (creator) otomatis masuk sebagai anggota.',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        cp.contacts.isEmpty
                            ? const Text('Tambah kontak terlebih dahulu')
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: cp.contacts.map((c) {
                                  final isSel = selected.contains(c.id);
                                  return FilterChip(
                                    label: Text(c.name),
                                    selected: isSel,
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
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(dialogContext)
                            .showSnackBar(const SnackBar(content: Text('Nama grup tidak boleh kosong')));
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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grup berhasil dibuat \u2713')));
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
                title: const Text('Edit Grup'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Nama Grup', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: currency,
                          decoration: const InputDecoration(labelText: 'Mata Uang', border: OutlineInputBorder()),
                          items: ['IDR', 'USD', 'EUR'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setLocal(() => currency = v ?? 'IDR'),
                        ),
                        const SizedBox(height: 16),
                        const Text('Anggota Grup', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
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
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
                  ElevatedButton(
                    onPressed: () async {
                      final newName = nameCtrl.text.trim();
                      if (newName.isEmpty) {
                        ScaffoldMessenger.of(dialogContext)
                            .showSnackBar(const SnackBar(content: Text('Nama grup tidak boleh kosong')));
                        return;
                      }
                      Navigator.pop(dialogContext);
                      final gp = context.read<GroupProvider>();
                      try {
                        await gp.rename(group.id!, newName, currency: currency);
                        await gmp.replaceMembers(group.id!, selectedIds.value);
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Grup berhasil diupdate \u2713')));
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
        title: const Text('Hapus Grup?'),
        content: Text('Semua transaksi dan data di "${group.name}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      appBar: AppBar(
        title: const Text('Splitage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddContactScreen()))
                .then((_) => context.read<ContactProvider>().loadAll()),
          ),
        ],
      ),
      body: gp.loading
          ? const Center(child: CircularProgressIndicator())
          : gp.groups.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada grup', style: TextStyle(fontSize: 18)),
                      Text('Buat grup untuk mulai split tagihan', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: gp.groups.length,
                  itemBuilder: (ctx, i) {
                    final group = gp.groups[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(group.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('dd MMM yyyy').format(DateTime.parse(group.createdAt))),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: 'Edit Grup',
                              onPressed: () => _showEditGroupDialog(context, group),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              tooltip: 'Hapus Grup',
                              onPressed: () => _confirmDelete(context, group),
                            ),
                            const Icon(Icons.chevron_right),
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
        onPressed: () => _showAddGroupDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Grup Baru'),
      ),
    );
  }
}
