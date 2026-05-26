// utils/currency_formatter.dart — shared
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String currency = 'IDR'}) {
    final formatter = NumberFormat.currency(
      locale: currency == 'IDR' ? 'id_ID' : 'en_US',
      symbol: _symbol(currency),
      decimalDigits: currency == 'IDR' ? 0 : 2,
    );
    return formatter.format(amount);
  }

  static String _symbol(String currency) {
    switch (currency) {
      case 'IDR':
        return 'Rp ';
      case 'USD':
        return '\$ ';
      case 'EUR':
        return '€ ';
      default:
        return '$currency ';
    }
  }

  static String compact(double amount, {String currency = 'IDR'}) {
    if (amount >= 1000000) {
      return '${_symbol(currency)}${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return '${_symbol(currency)}${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return format(amount, currency: currency);
  }
}
