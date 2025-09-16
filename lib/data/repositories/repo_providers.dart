import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your repository classes.
// Make sure these file paths match your project structure.
import 'routines_repo.dart';
import 'entries_repo.dart';
import 'outcomes_repo.dart';

/// Provides a shared Firestore instance for the whole app.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for routines.
final routinesRepoProvider = Provider<RoutinesRepo>((ref) {
  final db = ref.read(firestoreProvider);
  return RoutinesRepo(db); // or just RoutinesRepo() if your constructor takes no args
});

/// Provider for diary entries.
final entriesRepoProvider = Provider<EntriesRepo>((ref) {
  final db = ref.read(firestoreProvider);
  return EntriesRepo(db);
});

/// Provider for outcomes.
final outcomesRepoProvider = Provider<OutcomesRepo>((ref) {
  final db = ref.read(firestoreProvider);
  return OutcomesRepo(db);
});
