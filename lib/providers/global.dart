import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/routines_repo.dart';
import '../data/repositories/entries_repo.dart';
import '../data/repositories/outcomes_repo.dart';
import '../data/repositories/library_repo.dart';

// Re-export auth providers so screens only need one import
export '../features/auth/auth_controller.dart' show authStateProvider, userIdProvider;

final routinesRepoProvider = Provider((_) => RoutinesRepo());
final entriesRepoProvider  = Provider((_) => EntriesRepo());
final outcomesRepoProvider = Provider((_) => OutcomesRepo());
final libraryRepoProvider  = Provider((_) => LibraryRepo());
