// core/utils/number_formatter.dart

class NumberFormatter {
  NumberFormatter._();

  /// Converts a raw count to a compact display string.
  /// e.g. 1200 → "1.2K", 2500000 → "2.5M"
  static String compact(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
