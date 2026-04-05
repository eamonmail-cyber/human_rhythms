import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/routines_repo.dart';
import '../data/repositories/entries_repo.dart';
import '../data/repositories/outcomes_repo.dart';
import '../data/repositories/library_repo.dart';
import '../data/repositories/groups_repo.dart';
import '../data/repositories/challenges_repo.dart';
import '../features/assistant/assistant_service.dart';

// Re-export auth providers so screens only need one import
export '../features/auth/auth_controller.dart' show authStateProvider, userIdProvider;

final routinesRepoProvider     = Provider((_) => RoutinesRepo());
final entriesRepoProvider      = Provider((_) => EntriesRepo());
final outcomesRepoProvider     = Provider((_) => OutcomesRepo());
final libraryRepoProvider      = Provider((_) => LibraryRepo());
final groupsRepoGlobalProvider = Provider((_) => GroupsRepo());
final challengesRepoGlobalProvider = Provider((_) => ChallengesRepo());
final assistantServiceProvider = Provider((_) => AssistantService());
