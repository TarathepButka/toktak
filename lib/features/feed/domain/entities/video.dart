// features/feed/domain/entities/video.dart

/// Pure domain entity for a Video — no JSON parsing, no Flutter imports.
/// Use this type in use cases, BLoC states, and domain repository contracts.
class Video {
  final String id;
  final String userId;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final int durationMs;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final bool isLiked;
  final DateTime? createdAt;
  final VideoAuthor? author;

  const Video({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.thumbnailUrl,
    this.caption = '',
    this.durationMs = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.isLiked = false,
    this.createdAt,
    this.author,
  });

  Video copyWith({
    String? id,
    String? userId,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    int? durationMs,
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    bool? isLiked,
    DateTime? createdAt,
    VideoAuthor? author,
  }) {
    return Video(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      durationMs: durationMs ?? this.durationMs,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Video && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Nested author info embedded in a Video entity.
class VideoAuthor {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const VideoAuthor({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });
}
