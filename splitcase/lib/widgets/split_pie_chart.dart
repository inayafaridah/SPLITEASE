// widgets/split_pie_chart.dart — Orang 2: custom drawing + widget interaktif
// Menggunakan CustomPainter dari scratch (bukan wrapper fl_chart)
// - Pie chart siapa yang paling banyak berhutang
// - Tap slice untuk highlight & lihat detail
// - Animasi sweep angle
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/settlement.dart';
import '../models/contact.dart';
import '../utils/currency_formatter.dart';

class SplitPieChart extends StatefulWidget {
  final List<Settlement> settlements;
  final List<Contact> contacts;

  const SplitPieChart({
    super.key,
    required this.settlements,
    required this.contacts,
  });

  @override
  State<SplitPieChart> createState() => _SplitPieChartState();
}

class _SplitPieChartState extends State<SplitPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _sweepAnim;
  int? _tappedIndex;

  static const _colors = [
    Color(0xFF2196F3), Color(0xFFE91E63), Color(0xFF4CAF50),
    Color(0xFFFF9800), Color(0xFF9C27B0), Color(0xFF00BCD4),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sweepAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void didUpdateWidget(SplitPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settlements != widget.settlements) {
      _animCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /// Hitung total hutang per kontak (sebagai payer)
  Map<int, double> _computeData() {
    final totals = <int, double>{};
    for (final s in widget.settlements) {
      totals[s.fromContactId] =
          (totals[s.fromContactId] ?? 0) + s.amount;
    }
    return totals;
  }

  String _nameById(int id) {
    try {
      return widget.contacts.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return 'Unknown';
    }
  }

  void _handleTap(Offset localPos, List<_Slice> slices, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final radius = size.width / 2 - 8;

    if (dist < 30 || dist > radius + 8) {
      setState(() => _tappedIndex = null);
      return;
    }

    double angle = math.atan2(dy, dx);
    if (angle < -math.pi / 2) angle += 2 * math.pi;
    final rotated = angle + math.pi / 2;
    final normalised = rotated < 0 ? rotated + 2 * math.pi : rotated;

    double cumulative = 0;
    for (int i = 0; i < slices.length; i++) {
      cumulative += slices[i].sweep;
      if (normalised <= cumulative) {
        setState(() => _tappedIndex = i == _tappedIndex ? null : i);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _computeData();
    if (data.isEmpty) return const SizedBox.shrink();

    final total = data.values.fold(0.0, (a, b) => a + b);
    final slices = data.entries.toList().asMap().entries.map((e) {
      final idx = e.key;
      final entry = e.value;
      return _Slice(
        contactId: entry.key,
        amount: entry.value,
        sweep: (entry.value / total) * 2 * math.pi,
        color: _colors[idx % _colors.length],
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Text('Distribusi Hutang',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              // Pie
              Expanded(
                child: AnimatedBuilder(
                  animation: _sweepAnim,
                  builder: (_, __) {
                    return GestureDetector(
                      onTapDown: (d) {
                        // get render box size
                        final box = context.findRenderObject() as RenderBox?;
                        if (box == null) return;
                      },
                      onTapUp: (d) {
                        final box = context.findRenderObject() as RenderBox?;
                        if (box == null) return;
                        // approximate chart area — 140x140 starting left
                        _handleTap(d.localPosition, slices,
                            const Size(140, 140));
                      },
                      child: CustomPaint(
                        size: const Size(140, 140),
                        painter: _PiePainter(
                          slices: slices,
                          progress: _sweepAnim.value,
                          tappedIndex: _tappedIndex,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: slices.asMap().entries.map((e) {
                    final i = e.key;
                    final s = e.value;
                    final isSelected = _tappedIndex == i;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _tappedIndex = isSelected ? null : i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? s.color.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: s.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nameById(s.contactId),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    CurrencyFormatter.compact(s.amount),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: s.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          // Detail saat slice di-tap
          if (_tappedIndex != null && _tappedIndex! < slices.length)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: slices[_tappedIndex!].color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_nameById(slices[_tappedIndex!].contactId)}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    CurrencyFormatter.format(slices[_tappedIndex!].amount),
                    style: TextStyle(color: slices[_tappedIndex!].color),
                  ),
                  Text(
                    ' (${(slices[_tappedIndex!].amount / total * 100).toStringAsFixed(1)}%)',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Slice {
  final int contactId;
  final double amount;
  final double sweep;
  final Color color;

  const _Slice({
    required this.contactId,
    required this.amount,
    required this.sweep,
    required this.color,
  });
}

/// CustomPainter untuk pie chart dari scratch
class _PiePainter extends CustomPainter {
  final List<_Slice> slices;
  final double progress; // 0.0 → 1.0 animasi
  final int? tappedIndex;

  const _PiePainter({
    required this.slices,
    required this.progress,
    this.tappedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 8;
    final innerRadius = radius * 0.45; // donut hole
    final startAngle = -math.pi / 2; // mulai dari atas

    double cumulative = startAngle;
    final totalSweep = 2 * math.pi * progress;
    double remaining = totalSweep;

    for (int i = 0; i < slices.length; i++) {
      if (remaining <= 0) break;
      final s = slices[i];
      final sweep = s.sweep < remaining ? s.sweep : remaining;
      remaining -= s.sweep;

      final isSelected = tappedIndex == i;
      final explode = isSelected ? 8.0 : 0.0;

      // Explode: offset slice ke luar
      final midAngle = cumulative + sweep / 2;
      final ox = explode * math.cos(midAngle);
      final oy = explode * math.sin(midAngle);

      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(cx + ox + innerRadius * math.cos(cumulative),
            cy + oy + innerRadius * math.sin(cumulative))
        ..lineTo(cx + ox + radius * math.cos(cumulative),
            cy + oy + radius * math.sin(cumulative))
        ..arcTo(
          Rect.fromCircle(center: Offset(cx + ox, cy + oy), radius: radius),
          cumulative,
          sweep,
          false,
        )
        ..arcTo(
          Rect.fromCircle(center: Offset(cx + ox, cy + oy), radius: innerRadius),
          cumulative + sweep,
          -sweep,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);

      // Gap stroke
      final gapPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, gapPaint);

      cumulative += sweep;
    }

    // Center label
    if (progress >= 1.0) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${slices.length}\nkontak',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: innerRadius * 1.6);
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.progress != progress || old.tappedIndex != tappedIndex;
}
