import 'package:intl/intl.dart';

/// Wraps [NumberFormat.currency] with the app's currently selected
/// `AppSettings.currencyCode` so screens never format money ad hoc.
class CurrencyFormatter {
  CurrencyFormatter(this.currencyCode);

  final String currencyCode;

  static const Map<String, String> _symbols = <String, String>{
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'JPY': '¥',
  };

  String format(num amount) {
    final NumberFormat formatter = NumberFormat.currency(
      symbol: _symbols[currencyCode] ?? '$currencyCode ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String formatCompact(num amount) {
    final NumberFormat formatter = NumberFormat.compactCurrency(
      symbol: _symbols[currencyCode] ?? '$currencyCode ',
    );
    return formatter.format(amount);
  }
}
