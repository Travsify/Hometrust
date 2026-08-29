import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _nairaFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 0,
  );

  static String format(num? amount) {
    if (amount == null) return '₦0';
    return _nairaFormat.format(amount);
  }

  static String formatCompact(num? amount) {
    if (amount == null) return '₦0';
    if (amount >= 1000000000) {
      return '₦${(amount / 1000000000).toStringAsFixed(1)}B';
    }
    if (amount >= 1000000) {
      return '₦${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '₦${(amount / 1000).toStringAsFixed(0)}K';
    }
    return format(amount);
  }
}
