// lib/core/router.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/sign_in_screen.dart';
import '../features/diary/diary_screen.dart';
import '../features/summary/weekly_summary_screen.dart';
import '../features/routines/routine_list_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/auth/auth_controller.dart';

/// Listenable wrapper so GoRouter refreshes when auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Expose Firebase Auth state changes as a stream GoRouter can observe.
Stream<Object?> authStateChanges() => FirebaseAuth.instance.authStateChanges();

/// App router
GoRouter buildRouter() => GoRouter(
  refreshListenable: GoRouterRefreshStream(authStateChanges()),
  routes: [
    GoRoute(path: '/',        builder: (c, s) => const AuthGate(child: DiaryScreen())),
    GoRoute(path: '/summary', builder: (c, s) => const AuthGate(child: WeeklySummaryScreen())),
    GoRoute(path: '/routines',builder: (c, s) => const AuthGate(child: RoutineListScreen())),
    GoRoute(path: '/settings',builder: (c, s) => const AuthGate(child: SettingsScreen())),
    GoRoute(path: '/signin',  builder: (c, s) => const SignInScreen()),
  ],
);

/// Gates signed-out users to the SignIn screen.
class AuthGate extends ConsumerWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      data: (user) => user == null ? const SignInScreen() : child,
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SignInScreen(),
    );
  }
}
