// features/profile/data/models/profile_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:toktak/features/profile/domain/entities/profile.dart';
import 'package:toktak/features/feed/data/models/video_model.dart';
import 'package:toktak/features/feed/domain/entities/video.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    required String id,
    required String username,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String? bio,
    @JsonKey(name: 'videos_count') @Default(0) int videosCount,
    @JsonKey(name: 'likes_count') @Default(0) int likesCount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @Default([]) List<VideoModel> videos,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
}

extension ProfileModelMapper on ProfileModel {
  /// Maps this data model to the pure domain [Profile] entity.
  Profile toDomain() => Profile(
        id: id,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
        videosCount: videosCount,
        likesCount: likesCount,
        createdAt: createdAt,
        videos: videos.map((v) => Video(
          id: v.id,
          userId: v.userId,
          videoUrl: v.videoUrl,
          thumbnailUrl: v.thumbnailUrl,
          caption: v.caption,
          durationMs: v.durationMs,
          likesCount: v.likesCount,
          commentsCount: v.commentsCount,
          viewsCount: v.viewsCount,
          isLiked: v.isLiked,
          createdAt: v.createdAt,
          author: v.author != null ? VideoAuthor(
            id: v.author!.id,
            username: v.author!.username,
            displayName: v.author!.displayName,
            avatarUrl: v.author!.avatarUrl,
          ) : null,
        )).toList(),
      );
}
