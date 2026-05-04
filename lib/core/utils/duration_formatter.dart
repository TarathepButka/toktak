// core/utils/duration_formatter.dart

class DurationFormatter {
  DurationFormatter._();

  /// Formats milliseconds to mm:ss string.
  /// e.g. 75000 → "1:15"
  static String fromMs(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Formats a [Duration] to mm:ss string.
  static String fromDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
