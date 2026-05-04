// features/feed/domain/usecases/get_feed_videos_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/feed/data/models/video_model.dart';
import 'package:toktak/features/feed/domain/repositories/feed_repository.dart';

class GetFeedVideosUseCase {
  final FeedRepository _repository;

  const GetFeedVideosUseCase(this._repository);

  Future<Either<Failure, FeedResponse>> call({
    int page = 1,
    int limit = 10,
  }) =>
      _repository.getFeed(page: page, limit: limit);
}
