// screens/contacts_screen.dart — Orang 2
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
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ContactProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Daftar Kontak',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${cp.contacts.length} Teman Tersimpan',
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
            child: cp.loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0))),
                  )
                : cp.contacts.isEmpty
                    ? Padding(
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
                                child: const Icon(Icons.people_outline, size: 80, color: Color(0xFF4A00E0)),
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'Belum ada kontak',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tambah temanmu untuk mulai\npatungan bersama!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cp.contacts.length,
                        itemBuilder: (ctx, i) {
                          final contact = cp.contacts[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddContactScreen(existing: contact),
                                  ),
                                ).then((_) => cp.loadAll()),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: _parseColor(contact.avatarColor),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Center(
                                          child: Text(
                                            contact.initials,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              contact.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                                color: Color(0xFF2D3142),
                                              ),
                                            ),
                                            if (contact.phone.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade500),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    contact.phone,
                                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, size: 24, color: Colors.red.shade300),
                                        onPressed: () => _confirmDelete(context, contact, cp),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4A00E0),
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddContactScreen()),
        ).then((_) => cp.loadAll()),
        icon: const Icon(Icons.person_add_rounded, size: 24),
        label: const Text('Tambah Kontak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Contact c, ContactProvider cp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kontak?'),
        content: Text('Hapus "${c.name}" dari daftar kontak?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await cp.remove(c.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
