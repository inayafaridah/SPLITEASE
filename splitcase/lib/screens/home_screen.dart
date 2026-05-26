// screens/home_screen.dart — Orang 1
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/group.dart';
import '../providers/group_provider.dart';
import '../providers/contact_provider.dart';
import '../utils/currency_formatter.dart';
import 'group_detail_screen.dart';
import 'settings_screen.dart';
import 'contacts_screen.dart';

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

  void _showAddGroupDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String currency = 'IDR';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Buat Grup Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Grup',
                  hintText: 'Contoh: Liburan Bali',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: currency,
                decoration: const InputDecoration(
                  labelText: 'Mata Uang',
                  border: OutlineInputBorder(),
                ),
                items: ['IDR', 'USD', 'EUR']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setLocal(() => currency = v ?? 'IDR'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await context.read<GroupProvider>().add(
                      Group(name: nameCtrl.text.trim(), currency: currency),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Buat'),
            ),
          ],
        ),
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
            tooltip: 'Kontak',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: gp.loading
          ? const Center(child: CircularProgressIndicator())
          : gp.groups.isEmpty
              ? _buildEmpty(context)
              : _buildList(context, gp),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGroupDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Grup Baru'),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Belum ada grup',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    )),
            const SizedBox(height: 8),
            const Text('Buat grup untuk mulai split tagihan',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget _buildList(BuildContext context, GroupProvider gp) => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: gp.groups.length,
        itemBuilder: (ctx, i) {
          final group = gp.groups[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  group.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(group.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                DateFormat('dd MMM yyyy').format(
                  DateTime.tryParse(group.createdAt) ?? DateTime.now(),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    label: Text(group.currency,
                        style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailScreen(group: group),
                ),
              ).then((_) => gp.loadAll()),
              onLongPress: () => _showGroupOptions(context, group, gp),
            ),
          );
        },
      );

  void _showGroupOptions(
      BuildContext context, Group group, GroupProvider gp) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Ubah Nama'),
            onTap: () {
              Navigator.pop(ctx);
              _showRenameDialog(context, group, gp);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Hapus Grup', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(context, group, gp);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, Group group, GroupProvider gp) {
    final ctrl = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Grup'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await gp.rename(group.id!, ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Group group, GroupProvider gp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Grup?'),
        content: Text('Semua transaksi di "${group.name}" juga akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await gp.remove(group.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
