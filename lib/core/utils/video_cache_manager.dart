import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheManager {
  VideoCacheManager._();

  static final CacheManager _cacheManager = CacheManager(
    Config(
      'toktakVideoCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    ),
  );

  static Future<File> getFile(String videoUrl) {
    return _cacheManager.getSingleFile(videoUrl);
  }
}
