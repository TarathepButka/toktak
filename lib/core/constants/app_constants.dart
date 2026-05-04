// core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // ─── Pagination ────────────────────────────────────────────
  static const int feedPageSize = 10;
  static const int searchPageSize = 20;

  // ─── Timeouts ──────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ─── Cache ────────────────────────────────────────────────
  static const Duration feedCacheTtl = Duration(minutes: 5);

  // ─── Video ────────────────────────────────────────────────
  static const int preloadAheadCount = 2;
  static const double gridChildAspectRatio = 9 / 16;
}
