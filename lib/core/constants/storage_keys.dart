// core/constants/storage_keys.dart

/// Centralized registry of all GetStorage / SharedPreferences keys.
/// Prevents typo-driven bugs when reading or writing local storage.
class StorageKeys {
  StorageKeys._();

  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userProfile = 'user_profile';
  static const String feedCache = 'feed_cache';
  static const String likeQueue = 'like_queue';
  static const String likedVideos = 'liked_videos';
}
