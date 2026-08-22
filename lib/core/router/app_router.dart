import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/app_scaffold.dart';
import '../../features/today/screens/today_screen.dart';
import '../../features/signal/screens/signal_screen.dart';
import '../../features/crew/screens/crew_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/username_screen.dart';

/// Create a GoRouter that watches auth state.
///
/// Routes:
///   /auth         → Sign-in screen (unauthenticated)
///   /onboarding   → Username selection (authenticated, no username)
///   /today        → Dashboard (authenticated + onboarded)
///   /signal       → Activity history
///   /crew         → Social
///   /profile      → Personal records
GoRouter createRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final isOnAuth = state.matchedLocation == '/auth';

      // Not logged in → go to auth.
      if (!isLoggedIn) {
        return isOnAuth ? null : '/auth';
      }

      // Logged in but on auth → go to today.
      if (isOnAuth) {
        return '/today';
      }

      return null;
    },
    routes: [
      // Auth screen
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const UsernameScreen(),
      ),
      // Main app (authenticated)
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
}

/// Fallback router used before Ref is available.
final appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
  ],
);
