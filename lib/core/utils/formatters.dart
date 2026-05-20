import 'package:intl/intl.dart';

class Formatters {
  /// Format number as currency: ₹1,234.56
  static String currency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
    );
    return formatter.format(amount);
  }

  /// Compact currency: ₹1.2K, ₹12.3L
  static String compactCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  /// Format date: May 19, 2026
  static String date(DateTime dt) {
    return DateFormat('MMM d, yyyy').format(dt);
  }

  /// Format date short: 19 May
  static String dateShort(DateTime dt) {
    return DateFormat('d MMM').format(dt);
  }

  /// Format date and time: May 19, 2026 at 4:30 PM
  static String dateTime(DateTime dt) {
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(dt);
  }

  /// Format time: 4:30 PM
  static String time(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  /// Format date range: May 19 - May 25, 2026
  static String dateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('d, yyyy').format(end)}';
    }
    return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
  }

  /// Format percentage: 45.2%
  static String percentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  /// Relative time: "2 hours ago", "3 days ago"
  static String relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return DateFormat('MMM d').format(dt);
  }
}
