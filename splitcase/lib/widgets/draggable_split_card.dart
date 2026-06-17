// lib/widgets/draggable_split_card.dart — Anggota 2
// Custom Widget Interaktif: Drag & Drop kontak untuk menentukan peserta split bill
import 'package:flutter/material.dart';
import '../models/contact.dart';

class DraggableSplitCard extends StatefulWidget {
  /// Daftar semua kontak anggota grup yang bisa dipilih
  final List<Contact> availableContacts;

  /// Daftar contactId yang sudah terpilih (initial state)
  final List<int> initialSelectedIds;

  /// Total amount transaksi (untuk menghitung split per orang)
  final double totalAmount;

  /// Currency label
  final String currency;

  /// Callback saat daftar peserta berubah
  final ValueChanged<List<int>> onChanged;

  /// Warna tema
  final Color primaryColor;
  final Color gradientEndColor;

  const DraggableSplitCard({
    super.key,
    required this.availableContacts,
    this.initialSelectedIds = const [],
    this.totalAmount = 0,
    this.currency = 'IDR',
    required this.onChanged,
    this.primaryColor = Colors.indigo,
    this.gradientEndColor = Colors.indigoAccent,
  });

  @override
  State<DraggableSplitCard> createState() => _DraggableSplitCardState();
}

class _DraggableSplitCardState extends State<DraggableSplitCard>
    with TickerProviderStateMixin {
  late List<int> _selectedIds;
  bool _isDragOverTarget = false;
  bool _isDragOverSource = false;

  // Animation controllers for bounce effect
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _selectedIds = List<int>.from(widget.initialSelectedIds);
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  List<Contact> get _unselectedContacts =>
      widget.availableContacts
          .where((c) => !_selectedIds.contains(c.id))
          .toList();

  List<Contact> get _selectedContacts =>
      widget.availableContacts
          .where((c) => _selectedIds.contains(c.id))
          .toList();

  double get _splitPerPerson =>
      _selectedIds.isEmpty ? 0 : widget.totalAmount / _selectedIds.length;

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.indigo;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.indigo;
    }
  }

  void _addToSelected(int contactId) {
    if (!_selectedIds.contains(contactId)) {
      setState(() {
        _selectedIds.add(contactId);
        _isDragOverTarget = false;
      });
      _bounceController.forward().then((_) => _bounceController.reverse());
      widget.onChanged(_selectedIds);
    }
  }

  void _removeFromSelected(int contactId) {
    if (_selectedIds.contains(contactId)) {
      setState(() {
        _selectedIds.remove(contactId);
        _isDragOverSource = false;
      });
      widget.onChanged(_selectedIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.primaryColor.withOpacity(0.08),
                  widget.gradientEndColor.withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.people_alt_rounded,
                      color: widget.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Peserta Patungan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      Text(
                        'Seret kontak ke bawah untuk menambahkan',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Source Zone — Unselected contacts (draggable)
          _buildSourceZone(),

          // Divider with arrow
          _buildDividerArrow(),

          // Target Zone — Selected contacts (drop target)
          _buildTargetZone(),

          // Split calculation result
          if (_selectedIds.isNotEmpty) _buildSplitResult(),
        ],
      ),
    );
  }

  /// Zona sumber: kontak yang belum dipilih
  Widget _buildSourceZone() {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        // Hanya terima jika contact sudah ada di selected (artinya mau remove)
        if (_selectedIds.contains(details.data)) {
          setState(() => _isDragOverSource = true);
          return true;
        }
        return false;
      },
      onLeave: (_) => setState(() => _isDragOverSource = false),
      onAcceptWithDetails: (details) {
        _removeFromSelected(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isDragOverSource
                ? Colors.orange.shade50
                : const Color(0xFFF4F6F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDragOverSource
                  ? Colors.orange.shade300
                  : Colors.grey.shade200,
              width: _isDragOverSource ? 2 : 1,
            ),
          ),
          child: _unselectedContacts.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'Semua kontak sudah dipilih ✓',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _unselectedContacts.map((contact) {
                    return _buildDraggableAvatar(contact, isSelected: false);
                  }).toList(),
                ),
        );
      },
    );
  }

  /// Zona target: tempat drop kontak
  Widget _buildTargetZone() {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        // Hanya terima jika contact belum ada di selected
        if (!_selectedIds.contains(details.data)) {
          setState(() => _isDragOverTarget = true);
          return true;
        }
        return false;
      },
      onLeave: (_) => setState(() => _isDragOverTarget = false),
      onAcceptWithDetails: (details) {
        _addToSelected(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            color: _isDragOverTarget
                ? widget.primaryColor.withOpacity(0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDragOverTarget
                  ? widget.primaryColor
                  : _selectedIds.isEmpty
                      ? Colors.grey.shade300
                      : widget.primaryColor.withOpacity(0.3),
              width: _isDragOverTarget ? 2.5 : 1.5,
            ),
          ),
          child: _selectedContacts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Icon(
                          _isDragOverTarget
                              ? Icons.add_circle_rounded
                              : Icons.swipe_down_alt_rounded,
                          color: _isDragOverTarget
                              ? widget.primaryColor
                              : Colors.grey.shade400,
                          size: 32,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isDragOverTarget
                              ? 'Lepaskan di sini!'
                              : 'Drop kontak di sini',
                          style: TextStyle(
                            color: _isDragOverTarget
                                ? widget.primaryColor
                                : Colors.grey.shade400,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ScaleTransition(
                  scale: _bounceAnimation,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _selectedContacts.map((contact) {
                      return _buildDraggableAvatar(contact, isSelected: true);
                    }).toList(),
                  ),
                ),
        );
      },
    );
  }

  /// Avatar yang bisa di-drag
  Widget _buildDraggableAvatar(Contact contact, {required bool isSelected}) {
    final avatarColor = _parseColor(contact.avatarColor);

    final avatarWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                avatarColor,
                avatarColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: avatarColor.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              contact.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 56,
          child: Text(
            contact.name.split(' ').first,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected ? widget.primaryColor : Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Draggable<int>(
      data: contact.id!,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.2,
          child: Opacity(opacity: 0.85, child: avatarWidget),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: avatarWidget,
      ),
      child: GestureDetector(
        onTap: () {
          // Tap juga bisa toggle, tidak hanya drag
          if (isSelected) {
            _removeFromSelected(contact.id!);
          } else {
            _addToSelected(contact.id!);
          }
        },
        child: avatarWidget,
      ),
    );
  }

  Widget _buildDividerArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade200)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_double_arrow_down_rounded,
                color: widget.primaryColor,
                size: 18,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade200)),
        ],
      ),
    );
  }

  Widget _buildSplitResult() {
    final formattedSplit = widget.currency == 'IDR'
        ? 'Rp ${_splitPerPerson.toStringAsFixed(0)}'
        : '${_splitPerPerson.toStringAsFixed(2)} ${widget.currency}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.primaryColor.withOpacity(0.06),
            widget.gradientEndColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.calculate_rounded,
                color: widget.primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Split per orang (${_selectedIds.length} orang)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedSplit,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              '${_selectedIds.length} orang',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
