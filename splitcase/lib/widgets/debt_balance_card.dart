// widgets/debt_balance_card.dart — Orang 1: custom widget dengan animasi
// Menampilkan ringkasan saldo hutang masuk/keluar dengan:
// - Animated counter saat nilai berubah
// - Expandable untuk detail
// - Tap untuk lihat breakdown
import 'package:flutter/material.dart';
import '../services/split_calculator.dart';
import '../utils/currency_formatter.dart';

class DebtBalanceCard extends StatefulWidget {
  final BalanceSummary summary;
  final String currency;

  const DebtBalanceCard({
    super.key,
    required this.summary,
    this.currency = 'IDR',
  });

  @override
  State<DebtBalanceCard> createState() => _DebtBalanceCardState();
}

class _DebtBalanceCardState extends State<DebtBalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _valueAnim;
  late Animation<double> _fadeAnim;
  double _prevBalance = 0;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _valueAnim = Tween<double>(
      begin: 0,
      end: widget.summary.balance,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn),
    );
    _prevBalance = widget.summary.balance;
    _animCtrl.forward();
  }

  @override
  void didUpdateWidget(DebtBalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary.balance != widget.summary.balance) {
      _valueAnim = Tween<double>(
        begin: _prevBalance,
        end: widget.summary.balance,
      ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
      _prevBalance = widget.summary.balance;
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

  Color get _balanceColor {
    final b = widget.summary.balance;
    if (b > 0) return Colors.green.shade700;
    if (b < 0) return Colors.red.shade700;
    return Colors.grey;
  }

  String get _statusLabel {
    final b = widget.summary.balance;
    if (b > 1) return 'Berpiutang';
    if (b < -1) return 'Berhutang';
    return 'Lunas';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    return FadeTransition(
      opacity: _fadeAnim,
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: _balanceColor.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _balanceColor.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _balanceColor.withOpacity(0.15),
                      child: Text(
                        s.contact.initials,
                        style: TextStyle(
                          color: _balanceColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.contact.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(_statusLabel,
                              style: TextStyle(
                                  color: _balanceColor, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Animated balance
                    AnimatedBuilder(
                      animation: _valueAnim,
                      builder: (_, __) => Text(
                        CurrencyFormatter.format(
                          _valueAnim.value.abs(),
                          currency: widget.currency,
                        ),
                        style: TextStyle(
                          color: _balanceColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
              // Expanded detail
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  child: Column(
                    children: [
                      const Divider(),
                      _detailRow(
                        'Total Dibayar',
                        CurrencyFormatter.format(s.paid,
                            currency: widget.currency),
                        Colors.blue,
                      ),
                      const SizedBox(height: 4),
                      _detailRow(
                        'Bagian Fair',
                        CurrencyFormatter.format(s.share,
                            currency: widget.currency),
                        Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      // Mini progress bar: paid vs share
                      _buildProgressBar(s.paid, s.share),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color color) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
        ],
      );

  Widget _buildProgressBar(double paid, double share) {
    final max = paid > share ? paid : share;
    if (max <= 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Proporsi Bayar vs Bagian',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (paid / max).clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (share / max).clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            _legendDot(Colors.blue, 'Bayar'),
            const SizedBox(width: 8),
            _legendDot(Colors.orange, 'Bagian'),
          ],
        )
      ],
    );
  }

  Widget _legendDot(Color color, String label) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      );
}