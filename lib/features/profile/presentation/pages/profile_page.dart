// features/profile/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktak/core/theme/app_theme.dart';
import 'package:toktak/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:toktak/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:toktak/core/widgets/video_grid_tile.dart';

class ProfilePage extends StatelessWidget {
  final bool isPageVisible;
  const ProfilePage({super.key, this.isPageVisible = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            onPressed: () => context.read<AuthBloc>().add(const AuthEvent.logout()),
          ),
        ],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (profile) => RefreshIndicator(
              onRefresh: () async {
                context.read<ProfileBloc>().add(ProfileEvent.refreshProfile(profile.id));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.surfaceVariant,
                      child: Text(
                        profile.displayLabel.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('@${profile.username}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    if (profile.displayName != null && profile.displayName!.isNotEmpty)
                      Text(profile.displayName!, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                    const SizedBox(height: 24),
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatItem(count: '${profile.likesCount}', label: 'Likes'),
                        Container(width: 1, height: 24, color: AppTheme.divider, margin: const EdgeInsets.symmetric(horizontal: 24)),
                        _StatItem(count: '${profile.videosCount}', label: 'Videos'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Video grid
                    if (profile.videos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Column(
                          children: [
                            Icon(Icons.video_library_outlined, size: 48, color: AppTheme.textMuted),
                            SizedBox(height: 8),
                            Text('No videos yet', style: TextStyle(color: AppTheme.textMuted)),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 9 / 16,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: profile.videos.length,
                        itemBuilder: (context, index) {
                          final video = profile.videos[index];
                          return VideoGridTile(
                            video: video,
                            isActive: false, // Don't play video on profile page, show only cover
                            onTap: () {
                              // TODO: Navigate to full screen video player
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            error: (_) => const Center(child: Text('Error loading profile', style: TextStyle(color: AppTheme.error))),
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}
