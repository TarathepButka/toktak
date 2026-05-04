// features/feed/domain/repositories/feed_repository.dart
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/feed/data/models/video_model.dart';

abstract class FeedRepository {
  Future<Either<Failure, FeedResponse>> getFeed({int page = 1, int limit = 10});
  Future<Either<Failure, VideoModel>> likeVideo(String videoId);
  Future<Either<Failure, VideoModel>> unlikeVideo(String videoId);
  Future<Either<Failure, VideoModel>> getVideoDetail(String videoId);
}
