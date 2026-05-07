import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/diary/diary_screen.dart';
import '../features/summary/weekly_summary_screen.dart';
import '../features/routines/routine_list_screen.dart';
import '../features/settings/settings_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}

GoRouter buildRouter() => GoRouter(
  initialLocation: '/loading',
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final loc = state.matchedLocation;
    if (loc == '/loading') {
      if (user == null) return '/signin';
      return '/';
    }
    if (user == null && loc != '/signin') return '/signin';
    if (user != null && loc == '/signin') return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/loading',  builder: (c, s) => const _LoadingScreen()),
    GoRoute(path: '/signin',   builder: (c, s) => const SignInScreen()),
    GoRoute(path: '/',         builder: (c, s) => const DiaryScreen()),
    GoRoute(path: '/routines', builder: (c, s) => const RoutineListScreen()),
    GoRoute(path: '/summary',  builder: (c, s) => const WeeklySummaryScreen()),
    GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
  ],
);

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HRLogo(size: 64, light: true),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              'Human Rhythms',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
