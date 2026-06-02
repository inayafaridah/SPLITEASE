// widgets/debt_balance_card.dart
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
    return 'Lunas ✓';
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
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _balanceColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          s.contact.initials,
                          style: TextStyle(
                            color: _balanceColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.contact.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2D3142))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _balanceColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(_statusLabel,
                                style: TextStyle(
                                    color: _balanceColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
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
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade400,
                      size: 24,
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
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 16),
                  child: Column(
                    children: [
                      Divider(color: Colors.grey.shade100, height: 1),
                      const SizedBox(height: 12),
                      _detailRow(
                        'Total Dibayar',
                        CurrencyFormatter.format(s.paid,
                            currency: widget.currency),
                        Colors.blue.shade600,
                      ),
                      const SizedBox(height: 8),
                      _detailRow(
                        'Bagian Fair',
                        CurrencyFormatter.format(s.share,
                            currency: widget.currency),
                        Colors.grey.shade700,
                      ),
                      if (s.settled != 0) ...[
                        const SizedBox(height: 8),
                        _detailRow(
                          'Sudah Dilunasi',
                          CurrencyFormatter.format(s.settled.abs(),
                              currency: widget.currency),
                          Colors.green.shade600,
                        ),
                      ],
                      const SizedBox(height: 16),
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
          Text(label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 13)),
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
                  border:
                      Border.all(color: Colors.orange, width: 2),
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
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Colors.grey)),
        ],
      );
}
