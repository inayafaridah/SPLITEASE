// screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/group.dart';
import '../models/transaction.dart';
import '../models/contact.dart';
import '../providers/transaction_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/group_member_provider.dart';
import '../providers/theme_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:confetti/confetti.dart';
import '../widgets/custom_gradient_button.dart';
import '../widgets/draggable_split_card.dart';
import '../widgets/calculator_keypad.dart';

class AddTransactionScreen extends StatefulWidget {
  final Group group;
  final Transaction? existing;

  const AddTransactionScreen({super.key, required this.group, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  int? _selectedPayerId;
  DateTime _date = DateTime.now();
  bool _submitting = false;
  List<Contact> _groupMembersContacts = [];
  bool _isLoadingMembers = true;
  List<int> _splitParticipantIds = [];
  String? _receiptImagePath;

  late ConfettiController _confettiController;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    if (isEdit) {
      final tx = widget.existing!;
      _descCtrl.text = tx.description;
      _amountCtrl.text = tx.amount.toStringAsFixed(0);
      _selectedPayerId = tx.payerContactId;
      _date = DateTime.tryParse(tx.date) ?? DateTime.now();
      _receiptImagePath = tx.receiptImagePath;
    }
    _loadFilteredGroupMembers();
  }

  Future<void> _loadFilteredGroupMembers() async {
    final contactProvider = context.read<ContactProvider>();
    final memberProvider = context.read<GroupMemberProvider>();

    await contactProvider.loadAll();
    final memberIds = await memberProvider.getMembers(widget.group.id!);

    if (mounted) {
      setState(() {
        _groupMembersContacts = contactProvider.contacts
            .where((c) => memberIds.contains(c.id))
            .toList();
        _splitParticipantIds = _groupMembersContacts.map((c) => c.id!).toList();
        _isLoadingMembers = false;
      });
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickAndCropImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Ambil dari Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purple),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        // Cek apakah platform adalah desktop (Windows/Linux) karena image_cropper belum support desktop
        if (Platform.isWindows || Platform.isLinux) {
          setState(() {
            _receiptImagePath = image.path;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gambar ditambahkan (Cropper tidak didukung di Windows)')),
          );
          return;
        }

        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Potong Struk',
              toolbarColor: const Color(0xFF2196F3),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Potong Struk',
            ),
          ],
        );
        
        if (croppedFile != null) {
          setState(() {
            _receiptImagePath = croppedFile.path;
          });
        }
      }
    } catch (e) {
      debugPrint("Error picking/cropping image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka Galeri/Cropper. Apakah aplikasi sudah di-Rebuild?\nError: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCalculator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CalculatorKeypad(
        initialValue: _amountCtrl.text,
        primaryColor: const Color(0xFF2196F3),
        onChanged: (val) {
          setState(() {
            _amountCtrl.text = val;
          });
        },
        onSubmitted: () {
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan pilih siapa yang membayar terlebih dahulu.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.amber.shade800,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final tp = context.read<TransactionProvider>();
    final tx = Transaction(
      id: widget.existing?.id,
      groupId: widget.group.id!,
      payerContactId: _selectedPayerId!,
      amount: double.parse(_amountCtrl.text.replaceAll(',', '')),
      description: _descCtrl.text.trim(),
      date: _date.toIso8601String(),
      receiptImagePath: _receiptImagePath,
    );

    if (isEdit) {
      await tp.updateTransaction(tx);
    } else {
      await tp.add(tx);
    }

    _confettiController.play();
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final _primaryColor = themeProvider.primaryColor;
    final _gradientEndColor = themeProvider.gradientEndColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        title: Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi', style: const TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          _isLoadingMembers
              ? Center(child: CircularProgressIndicator(color: _primaryColor))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.receipt_rounded, color: _primaryColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text('Detail Tagihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _descCtrl,
                          decoration: InputDecoration(
                            labelText: 'Keterangan',
                            labelStyle: TextStyle(color: _primaryColor),
                            hintText: 'Contoh: Makan ramen',
                            filled: true,
                            fillColor: const Color(0xFFF4F6F9),
                            prefixIcon: Icon(Icons.description_outlined, color: _primaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Keterangan wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountCtrl,
                          readOnly: true,
                          onTap: _showCalculator,
                          decoration: InputDecoration(
                            labelText: 'Jumlah (${widget.group.currency})',
                            labelStyle: TextStyle(color: _primaryColor),
                            hintText: 'Ketuk untuk memasukkan jumlah',
                            filled: true,
                            fillColor: const Color(0xFFF4F6F9),
                            prefixIcon: Icon(Icons.payments_outlined, color: _primaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                            if (double.tryParse(v) == null || double.parse(v) <= 0) {
                              return 'Masukkan jumlah yang valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedPayerId,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
                          decoration: InputDecoration(
                            labelText: 'Yang Membayar',
                            labelStyle: TextStyle(color: _primaryColor),
                            filled: true,
                            fillColor: const Color(0xFFF4F6F9),
                            prefixIcon: Icon(Icons.person_outline_rounded, color: _primaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                          ),
                          items: _groupMembersContacts
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w500))))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedPayerId = v),
                          hint: _groupMembersContacts.isEmpty
                              ? const Text('Tidak ada anggota di grup ini')
                              : const Text('Pilih pembayar'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _pickDate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.calendar_today_rounded, color: _primaryColor, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tanggal Transaksi', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(DateFormat('dd MMMM yyyy').format(_date), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142), fontSize: 16)),
                                  ],
                                ),
                              ),
                              Icon(Icons.edit_calendar_rounded, color: _primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Receipt Image Picker
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _pickAndCropImage,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.receipt_long_rounded, color: Colors.orange, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Foto Struk', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _receiptImagePath != null ? 'Struk Terlampir' : 'Lampirkan Struk (Opsional)', 
                                      style: TextStyle(fontWeight: FontWeight.bold, color: _receiptImagePath != null ? Colors.green : const Color(0xFF2D3142), fontSize: 16)
                                    ),
                                  ],
                                ),
                              ),
                              if (_receiptImagePath != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(_receiptImagePath!), width: 40, height: 40, fit: BoxFit.cover),
                                )
                              else
                                const Icon(Icons.add_a_photo_rounded, color: Colors.orange),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Custom Widget Interaktif: DraggableSplitCard (Anggota 2)
                  DraggableSplitCard(
                    availableContacts: _groupMembersContacts,
                    initialSelectedIds: _splitParticipantIds,
                    totalAmount: double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0,
                    currency: widget.group.currency,
                    primaryColor: _primaryColor,
                    gradientEndColor: _gradientEndColor,
                    onChanged: (ids) {
                      setState(() => _splitParticipantIds = ids);
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomGradientButton(
                    onPressed: _submitting ? null : _submit,
                    label: isEdit ? 'Simpan Perubahan' : 'Simpan Transaksi',
                    icon: Icons.save_rounded,
                    primaryColor: _primaryColor,
                    gradientEndColor: _gradientEndColor,
                    isLoading: _submitting,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}