// features/profile/presentation/widgets/profile_stats_row.dart
import 'package:flutter/material.dart';
import 'package:toktak/core/theme/app_theme.dart';

/// Displays a horizontal row of profile statistics (Likes, Videos, etc.)
/// Extracted from profile_page to keep the page widget lean.
class ProfileStatsRow extends StatelessWidget {
  final List<ProfileStat> stats;

  const ProfileStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final divider = Container(
      width: 1,
      height: 24,
      color: AppTheme.divider,
      margin: const EdgeInsets.symmetric(horizontal: 24),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) divider,
          _StatItem(stat: stats[i]),
        ],
      ],
    );
  }
}

class ProfileStat {
  final String label;
  final String value;

  const ProfileStat({required this.label, required this.value});
}

class _StatItem extends StatelessWidget {
  final ProfileStat stat;
  const _StatItem({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stat.value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          stat.label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
