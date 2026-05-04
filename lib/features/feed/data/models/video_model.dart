// features/feed/data/models/video_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:toktak/features/auth/data/models/user_model.dart';

part 'video_model.freezed.dart';
part 'video_model.g.dart';

@freezed
class VideoModel with _$VideoModel {
  const factory VideoModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'video_url') required String videoUrl,
    @JsonKey(name: 'thumbnail_url') required String thumbnailUrl,
    @Default('') String caption,
    @JsonKey(name: 'duration_ms') @Default(0) int durationMs,
    @JsonKey(name: 'likes_count') @Default(0) int likesCount,
    @JsonKey(name: 'comments_count') @Default(0) int commentsCount,
    @JsonKey(name: 'views_count') @Default(0) int viewsCount,
    @JsonKey(name: 'is_liked') @Default(false) bool isLiked,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    UserModel? author,
  }) = _VideoModel;

  factory VideoModel.fromJson(Map<String, dynamic> json) =>
      _$VideoModelFromJson(json);
}

@freezed
class FeedResponse with _$FeedResponse {
  const factory FeedResponse({
    required List<VideoModel> videos,
    @JsonKey(name: 'has_more') @Default(false) bool hasMore,
    @Default(1) int page,
  }) = _FeedResponse;

  factory FeedResponse.fromJson(Map<String, dynamic> json) =>
      _$FeedResponseFromJson(json);
}
