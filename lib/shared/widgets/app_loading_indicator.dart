// shared/widgets/app_loading_indicator.dart
import 'package:flutter/material.dart';
import 'package:toktak/core/theme/app_theme.dart';

/// Centered circular loading indicator using the app's primary colour.
/// Use this wherever you need a full-area loading state.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primary),
    );
  }
}
