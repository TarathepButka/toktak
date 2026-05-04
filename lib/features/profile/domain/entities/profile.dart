// features/profile/domain/entities/profile.dart

import 'package:toktak/features/feed/domain/entities/video.dart';

/// Pure domain entity for a user's public profile.
class Profile {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final int videosCount;
  final int likesCount;
  final DateTime? createdAt;
  final List<Video> videos;

  const Profile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.videosCount = 0,
    this.likesCount = 0,
    this.createdAt,
    this.videos = const [],
  });

  String get displayLabel => displayName ?? username;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Profile && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
