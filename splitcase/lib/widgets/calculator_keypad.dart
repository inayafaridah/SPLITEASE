import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';

class CalculatorKeypad extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final Color primaryColor;

  const CalculatorKeypad({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.onSubmitted,
    required this.primaryColor,
  });

  @override
  State<CalculatorKeypad> createState() => _CalculatorKeypadState();
}

class _CalculatorKeypadState extends State<CalculatorKeypad> {
  late String _expression;

  @override
  void initState() {
    super.initState();
    _expression = widget.initialValue.isEmpty ? '' : widget.initialValue;
  }

  void _onKeyPress(String key) {
    Vibration.vibrate(duration: 30);
    setState(() {
      if (key == 'C') {
        _expression = '';
      } else if (key == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (key == '=') {
        _expression = _evaluate(_expression);
      } else if ('+-*/'.contains(key)) {
        // Jika sudah ada operator (selain minus di awal), evaluasi dulu seperti kalkulator fisik
        if (_hasOperator(_expression)) {
          _expression = _evaluate(_expression);
        }
        
        // Mencegah operator ganda berjejer
        if (_expression.isNotEmpty && '+-*/'.contains(_expression[_expression.length - 1])) {
          _expression = _expression.substring(0, _expression.length - 1) + key;
        } else {
          _expression += key;
        }
      } else {
        _expression += key;
      }
      widget.onChanged(_expression);
    });
  }

  bool _hasOperator(String exp) {
    if (exp.isEmpty) return false;
    // Cek apakah ada operator di tengah string (abaikan indeks 0 kalau itu minus)
    for (int i = 1; i < exp.length; i++) {
      if ('+-*/'.contains(exp[i])) return true;
    }
    return false;
  }

  String _evaluate(String exp) {
    try {
      String parsed = exp.replaceAll(',', '').replaceAll(' ', '');
      if (parsed.isEmpty) return '';
      
      // Hapus operator yang menggantung di akhir
      if ('+-*/'.contains(parsed[parsed.length - 1])) {
        parsed = parsed.substring(0, parsed.length - 1);
      }
      
      final match = RegExp(r'^(-?\d+(?:\.\d+)?)([\+\-\*\/])(-?\d+(?:\.\d+)?)$').firstMatch(parsed);
      if (match != null) {
        double a = double.parse(match.group(1)!);
        String op = match.group(2)!;
        double b = double.parse(match.group(3)!);
        
        double result = 0;
        if (op == '+') result = a + b;
        if (op == '-') result = a - b;
        if (op == '*') result = a * b;
        if (op == '/') result = b != 0 ? a / b : 0;
        
        // Jika hasilnya bulat, hilangkan .0
        return result == result.toInt() ? result.toInt().toString() : result.toStringAsFixed(2);
      }
      
      return parsed; // Kembalikan string awal jika tidak ada operasi
    } catch (e) {
      return '';
    }
  }

  Widget _buildKey(String text, {Color? textColor, Color? bgColor, VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: bgColor ?? Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap ?? () => _onKeyPress(text),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? const Color(0xFF2D3142),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildKey('C', textColor: Colors.red),
              _buildKey('⌫', textColor: Colors.orange),
              _buildKey('/'),
              _buildKey('*'),
            ],
          ),
          Row(
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
              _buildKey('-'),
            ],
          ),
          Row(
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
              _buildKey('+'),
            ],
          ),
          Row(
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
              _buildKey('=', textColor: Colors.white, bgColor: widget.primaryColor),
            ],
          ),
          Row(
            children: [
              _buildKey('000'),
              _buildKey('0'),
              _buildKey('.'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: widget.onSubmitted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ].animate(interval: 40.ms).fadeIn(duration: 200.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutQuad),
      ),
    );
  }
}
