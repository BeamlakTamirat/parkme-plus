import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    symbol: 'ETB ',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormatter = NumberFormat.compactCurrency(
    symbol: 'ETB ',
    decimalDigits: 0,
  );

  /// Format amount with full currency symbol
  /// Example: 250.50 -> "ETB 250.50"
  static String format(double amount) {
    return _formatter.format(amount);
  }

  /// Format amount without decimal places
  /// Example: 250.50 -> "ETB 251"
  static String formatWithoutDecimals(double amount) {
    return NumberFormat.currency(
      symbol: 'ETB ',
      decimalDigits: 0,
    ).format(amount);
  }

  /// Format amount in compact form
  /// Example: 1500.00 -> "ETB 1.5K"
  static String formatCompact(double amount) {
    return _compactFormatter.format(amount);
  }

  /// Format amount per hour rate
  /// Example: 25.00 -> "ETB 25/hr"
  static String formatHourlyRate(double amount) {
    return '${formatWithoutDecimals(amount)}/hr';
  }

  /// Parse formatted currency string to double
  /// Example: "ETB 250.50" -> 250.50
  static double? parse(String formattedAmount) {
    try {
      final cleanAmount =
          formattedAmount.replaceAll('ETB', '').replaceAll(',', '').trim();
      return double.parse(cleanAmount);
    } catch (e) {
      return null;
    }
  }

  /// Format amount range
  /// Example: (20.0, 50.0) -> "ETB 20 - ETB 50"
  static String formatRange(double minAmount, double maxAmount) {
    return '${formatWithoutDecimals(minAmount)} - ${formatWithoutDecimals(maxAmount)}';
  }

  /// Check if amount is valid for Ethiopian currency
  static bool isValidAmount(double amount) {
    return amount >= 0 && amount <= 999999999.99;
  }
}
