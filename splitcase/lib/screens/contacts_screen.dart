// screens/contacts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contact_provider.dart';
import '../models/contact.dart';
import 'add_contact_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactProvider>().loadAll();
    });
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ContactProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Kontak Global', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Tambah Kontak',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddContactScreen()),
            ).then((_) => cp.loadAll()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: cp.loading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : cp.contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.people_outline_rounded, size: 64, color: Colors.indigo),
                      ),
                      const SizedBox(height: 16),
                      Text('Belum ada daftar kontak', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Tambahkan kontak untuk dimasukkan ke grup', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: cp.contacts.length,
                  itemBuilder: (ctx, i) {
                    final contact = cp.contacts[i];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
                      color: Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: _parseColor(contact.avatarColor),
                          child: Text(
                            contact.initials,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                        subtitle: contact.phone.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.phone_android_rounded, size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(contact.phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  ],
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade600),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddContactScreen(existing: contact)),
                              ).then((_) => cp.loadAll()),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red.shade400),
                              onPressed: () => _confirmDelete(context, contact, cp),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddContactScreen()),
        ).then((_) => cp.loadAll()),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Contact c, ContactProvider cp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Kontak?'),
          ],
        ),
        content: Text('Apakah kamu yakin ingin menghapus "${c.name}" dari daftar kontak global?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: Colors.grey.shade600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              await cp.remove(c.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}