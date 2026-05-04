// app.dart — Main App Widget with navigation shell
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktak/core/theme/app_theme.dart';
import 'package:toktak/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:toktak/features/auth/presentation/pages/login_page.dart';
import 'package:toktak/features/feed/presentation/bloc/feed_bloc.dart';
import 'package:toktak/features/feed/presentation/pages/feed_page.dart';
import 'package:toktak/features/profile/presentation/pages/profile_page.dart';
import 'package:toktak/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:toktak/features/search/presentation/pages/search_page.dart';
import 'package:toktak/features/upload/presentation/pages/upload_page.dart';
import 'package:toktak/injection.dart';

class TokTakApp extends StatelessWidget {
  const TokTakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
            create: (_) => getIt<AuthBloc>()..add(const AuthEvent.checkAuth())),
        BlocProvider<FeedBloc>(create: (_) => getIt<FeedBloc>()),
        BlocProvider<ProfileBloc>(create: (_) => getIt<ProfileBloc>()),
      ],
      child: MaterialApp(
        title: 'TokTak',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return state.when(
              initial: () => const _SplashScreen(),
              loading: () => const _SplashScreen(),
              authenticated: (_) => const _MainShell(),
              unauthenticated: () => const LoginPage(),
              error: (_) => const LoginPage(),
            );
          },
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: AppTheme.primaryGradient,
              ),
              child: const Center(
                  child: Icon(Icons.play_arrow_rounded,
                      size: 44, color: Colors.white)),
            ),
            const SizedBox(height: 16),
            Text('TokTak',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Navigation Shell ─────────────────────────────────

class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  // Pages are now built dynamically in build() to reflect tab visibility
  List<Widget> _getPages() => [
        FeedPage(isPageVisible: _currentIndex == 0),
        SearchPage(isPageVisible: _currentIndex == 1),
        const SizedBox(), // index 2 is handled via push navigation
        ProfilePage(isPageVisible: _currentIndex == 3),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _getPages()),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) async {
            if (index == 2) {
              final uploaded = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const UploadPage()),
              );
              // Refresh feed & profile if upload succeeded
              if (uploaded == true && context.mounted) {
                context.read<FeedBloc>().add(const FeedEvent.refreshFeed());
                final userId = context
                    .read<AuthBloc>()
                    .state
                    .mapOrNull(authenticated: (s) => s.user.id);
                if (userId != null) {
                  context
                      .read<ProfileBloc>()
                      .add(ProfileEvent.refreshProfile(userId));
                }
              }
              return;
            }

            // --- ถ้ากดปุ่มเดิมซ้ำ ---
            if (_currentIndex == index) {
              if (index == 0) {
                // ถ้าย้ำปุ่ม Home
                context.read<FeedBloc>().add(const FeedEvent.refreshFeed());
              } else if (index == 3) {
                // ถ้าย้ำ Profile
                final userId = context
                    .read<AuthBloc>()
                    .state
                    .mapOrNull(authenticated: (s) => s.user.id);
                if (userId != null) {
                  context
                      .read<ProfileBloc>()
                      .add(ProfileEvent.refreshProfile(userId));
                }
              }
            } else {
              // --- ถ้ากดเปลี่ยนหน้าปกติ ---
              setState(() => _currentIndex = index);
              if (index == 3) {
                final userId = context
                    .read<AuthBloc>()
                    .state
                    .mapOrNull(authenticated: (s) => s.user.id);
                if (userId != null) {
                  context
                      .read<ProfileBloc>()
                      .add(ProfileEvent.loadProfile(userId));
                }
              }
            }
          },
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home_filled), label: 'Home'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(
              icon: Container(
                width: 40,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
              label: '',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
