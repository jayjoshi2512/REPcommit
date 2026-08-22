import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/app_scaffold.dart';
import 'features/today/screens/today_screen.dart';
import 'features/signal/screens/signal_screen.dart';
import 'features/crew/screens/crew_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/screens/username_screen.dart';
import 'providers/app_providers.dart';

/// RepCommit root application widget.
///
/// Three states:
///   1. Not signed in → AuthScreen
///   2. Signed in but no username → UsernameScreen
///   3. Signed in + username → Main app
class RepCommitApp extends ConsumerWidget {
  const RepCommitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return MaterialApp(
            title: 'RepCommit',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            home: const AuthScreen(),
          );
        }

        // User is signed in — check if they have a username.
        final hasUsername = ref.watch(hasUsernameProvider);

        return hasUsername.when(
          data: (hasName) {
            if (!hasName) {
              // No username yet → onboarding.
              return MaterialApp(
                title: 'RepCommit',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.dark,
                home: const UsernameScreen(),
              );
            }

            // Fully onboarded → main app.
            final router = GoRouter(
              initialLocation: '/today',
              routes: [
                ShellRoute(
                  builder: (context, state, child) => AppScaffold(child: child),
                  routes: [
                    GoRoute(
                      path: '/today',
                      pageBuilder: (context, state) => const NoTransitionPage(
                        child: TodayScreen(),
                      ),
                    ),
                    GoRoute(
                      path: '/signal',
                      pageBuilder: (context, state) => const NoTransitionPage(
                        child: SignalScreen(),
                      ),
                    ),
                    GoRoute(
                      path: '/crew',
                      pageBuilder: (context, state) => const NoTransitionPage(
                        child: CrewScreen(),
                      ),
                    ),
                    GoRoute(
                      path: '/profile',
                      pageBuilder: (context, state) => const NoTransitionPage(
                        child: ProfileScreen(),
                      ),
                    ),
                  ],
                ),
              ],
            );

            return MaterialApp.router(
              title: 'RepCommit',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              routerConfig: router,
            );
          },
          loading: () => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            home: const _SplashScreen(),
          ),
          error: (err, stack) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            home: const _SplashScreen(),
          ),
        );
      },
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _SplashScreen(),
      ),
      error: (err, stack) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AuthScreen(),
      ),
    );
  }
}

/// Minimal splash screen while Firebase Auth initializes.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0F0F),
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFE8613A),
          ),
        ),
      ),
    );
  }
}
