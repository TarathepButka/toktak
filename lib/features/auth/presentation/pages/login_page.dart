// features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:toktak/core/theme/app_theme.dart';
import 'package:toktak/features/auth/presentation/bloc/auth_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          state.when(
            initial: () {},
            loading: () {},
            authenticated: (user) {
              // Navigation handled by app.dart
            },
            unauthenticated: () {},
            error: (failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(failure.when(
                    server: (message, code) => message,
                    network: (message) => message,
                    cache: (message) => message,
                    auth: (message) => message,
                    unknown: (message) => message,
                  )),
                  backgroundColor: AppTheme.error,
                ),
              );
            },
          );
        },
        child: Container(
          decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ─── Logo ────────────────────────────
                  _buildLogo(),
                  const SizedBox(height: 16),
                  Text(
                    'TokTak',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Spacer(flex: 2),

                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state.maybeWhen(
                        loading: () => true,
                        orElse: () => false,
                      );
                      return Column(
                        children: [
                          _SocialLoginButton(
                            onPressed: isLoading
                                ? null
                                : () => context.read<AuthBloc>().add(const AuthEvent.loginWithGoogle()),
                            icon: FontAwesomeIcons.google,
                            label: 'Continue with Google',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                          ),
                          const SizedBox(height: 12),

                          _SocialLoginButton(
                            onPressed: isLoading
                                ? null
                                : () => context.read<AuthBloc>().add(const AuthEvent.loginWithLine()),
                            icon: FontAwesomeIcons.line,
                            label: 'Continue with LINE',
                            backgroundColor: const Color(0xFF06C755),
                            foregroundColor: Colors.white,
                          ),
                          if (isLoading) ...[
                            const SizedBox(height: 24),
                            const CircularProgressIndicator(color: AppTheme.primary),
                          ],
                        ],
                      );
                    },
                  ),

                  const Spacer(),

                  // ─── Terms ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Text(
                      'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.play_arrow_rounded, size: 56, color: Colors.white),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _SocialLoginButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, size: 20, color: foregroundColor),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
