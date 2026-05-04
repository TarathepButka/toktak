// features/feed/domain/usecases/like_video_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:toktak/core/error/failures.dart';
import 'package:toktak/features/feed/data/models/video_model.dart';
import 'package:toktak/features/feed/domain/repositories/feed_repository.dart';

class LikeVideoUseCase {
  final FeedRepository _repository;

  const LikeVideoUseCase(this._repository);

  Future<Either<Failure, VideoModel>> call(String videoId) =>
      _repository.likeVideo(videoId);
}

class UnlikeVideoUseCase {
  final FeedRepository _repository;

  const UnlikeVideoUseCase(this._repository);

  Future<Either<Failure, VideoModel>> call(String videoId) =>
      _repository.unlikeVideo(videoId);
}
