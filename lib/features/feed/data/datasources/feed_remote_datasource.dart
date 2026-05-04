// features/feed/data/datasources/feed_remote_datasource.dart
import 'package:toktak/features/feed/data/models/video_model.dart';

/// Contract for all remote feed operations.
abstract class FeedRemoteDataSource {
  Future<FeedResponse> getFeed({int page = 1, int limit = 10});
  Future<VideoModel> likeVideo(String videoId);
  Future<VideoModel> unlikeVideo(String videoId);
  Future<VideoModel> getVideoDetail(String videoId);
}
