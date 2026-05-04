// shared/widgets/app_avatar.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:toktak/core/theme/app_theme.dart';

/// Circular avatar that gracefully falls back to an initials badge
/// when no [imageUrl] is provided or the image fails to load.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? displayName;
  final double radius;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.radius = 20,
  });

  String get _initials {
    if (displayName == null || displayName!.isEmpty) return '?';
    return displayName!.trim().substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.surfaceVariant,
      backgroundImage: imageUrl != null
          ? CachedNetworkImageProvider(imageUrl!)
          : null,
      child: imageUrl == null
          ? Text(
              _initials,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            )
          : null,
    );
  }
}
