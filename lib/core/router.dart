// lib/core/router.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/sign_in_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/diary/diary_screen.dart';
import '../features/summary/weekly_summary_screen.dart';
import '../features/routines/routine_list_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/library/library_screen.dart';
import '../features/social/stories_screen.dart';
import '../features/social/follow_screen.dart';
import '../features/ai_assistant/ai_assistant_screen.dart';
import '../features/groups/groups_screen.dart';
import '../features/groups/group_detail_screen.dart';
import '../features/challenges/challenges_screen.dart';
import '../features/challenges/challenge_detail_screen.dart';
import '../features/expert/expert_routines_screen.dart';

/// Listenable wrapper so GoRouter refreshes when auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

const _authRoutes = {'/sign-in', '/register'};

GoRouter buildRouter() => GoRouter(
  initialLocation: '/',
  refreshListenable:
      GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    final loggedIn   = FirebaseAuth.instance.currentUser != null;
    final onAuthPage = _authRoutes.contains(state.matchedLocation);
    if (!loggedIn && !onAuthPage) return '/sign-in';
    if (loggedIn && onAuthPage) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/',          builder: (c, s) => const DiaryScreen()),
    GoRoute(path: '/summary',   builder: (c, s) => const WeeklySummaryScreen()),
    GoRoute(path: '/routines',  builder: (c, s) => const RoutineListScreen()),
    GoRoute(path: '/settings',  builder: (c, s) => const SettingsScreen()),
    GoRoute(path: '/library',   builder: (c, s) => const LibraryScreen()),
    GoRoute(path: '/stories',   builder: (c, s) => const StoriesScreen()),
    GoRoute(path: '/community', builder: (c, s) => const FollowScreen()),
    GoRoute(path: '/sign-in',   builder: (c, s) => const SignInScreen()),
    GoRoute(path: '/register',  builder: (c, s) => const RegisterScreen()),
    GoRoute(path: '/assistant', builder: (c, s) => const AiAssistantScreen()),
    GoRoute(path: '/groups',    builder: (c, s) => const GroupsScreen()),
    GoRoute(
      path: '/groups/:id',
      builder: (c, s) => GroupDetailScreen(groupId: s.pathParameters['id']!),
    ),
    GoRoute(path: '/challenges', builder: (c, s) => const ChallengesScreen()),
    GoRoute(
      path: '/challenges/:id',
      builder: (c, s) =>
          ChallengeDetailScreen(challengeId: s.pathParameters['id']!),
    ),
    GoRoute(path: '/expert',    builder: (c, s) => const ExpertRoutinesScreen()),
  ],
);
