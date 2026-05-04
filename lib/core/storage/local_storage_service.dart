// core/storage/local_storage_service.dart
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class LocalStorageService {
  static const String _containerName = 'toktak';
  late final GetStorage _box;

  LocalStorageService() : _box = GetStorage(_containerName);

  static Future<void> init() async {
    await GetStorage.init(_containerName);
  }

  // ─── Auth Tokens ───────────────────────────────────────────

  Future<void> saveAuthToken(String token) => _box.write(_Keys.authToken, token);
  String? getAuthToken() => _box.read<String>(_Keys.authToken);

  Future<void> saveRefreshToken(String token) => _box.write(_Keys.refreshToken, token);
  String? getRefreshToken() => _box.read<String>(_Keys.refreshToken);

  Future<void> clearTokens() async {
    await _box.remove(_Keys.authToken);
    await _box.remove(_Keys.refreshToken);
  }

  bool get isLoggedIn => getAuthToken() != null;

  // ─── User Profile ──────────────────────────────────────────

  Future<void> saveUserProfile(Map<String, dynamic> profile) =>
      _box.write(_Keys.userProfile, json.encode(profile));

  Map<String, dynamic>? getUserProfile() {
    final raw = _box.read<String>(_Keys.userProfile);
    if (raw == null) return null;
    return json.decode(raw) as Map<String, dynamic>;
  }

  // ─── Feed Cache ────────────────────────────────────────────

  Future<void> cacheFeedMeta(List<Map<String, dynamic>> feed) =>
      _box.write(_Keys.feedCache, json.encode(feed));

  List<Map<String, dynamic>>? getCachedFeed() {
    final raw = _box.read<String>(_Keys.feedCache);
    if (raw == null) return null;
    final decoded = json.decode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  // ─── Like Queue (Offline Sync) ─────────────────────────────

  Future<void> queueLikeAction(String videoId, bool liked) async {
    final queue = getLikeQueue();
    // Remove any existing action for same video (deduplicate)
    queue.removeWhere((item) => item['videoId'] == videoId);
    queue.add({
      'videoId': videoId,
      'liked': liked,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _box.write(_Keys.likeQueue, json.encode(queue));
  }

  List<Map<String, dynamic>> getLikeQueue() {
    final raw = _box.read<String>(_Keys.likeQueue);
    if (raw == null) return [];
    final decoded = json.decode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> clearLikeQueue() => _box.remove(_Keys.likeQueue);

  // ─── Liked Video IDs (Local State) ─────────────────────────

  Future<void> saveLikedVideoIds(Set<String> ids) =>
      _box.write(_Keys.likedVideos, json.encode(ids.toList()));

  Set<String> getLikedVideoIds() {
    final raw = _box.read<String>(_Keys.likedVideos);
    if (raw == null) return {};
    final decoded = json.decode(raw) as List;
    return decoded.cast<String>().toSet();
  }

  // ─── Clear All ─────────────────────────────────────────────

  Future<void> clearAll() => _box.erase();
}

class _Keys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userProfile = 'user_profile';
  static const String feedCache = 'feed_cache';
  static const String likeQueue = 'like_queue';
  static const String likedVideos = 'liked_videos';
}
