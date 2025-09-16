import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/routines_repo.dart';
import '../data/repositories/entries_repo.dart';
import '../data/repositories/outcomes_repo.dart';

final routinesRepoProvider = Provider((_) => RoutinesRepo());
final entriesRepoProvider  = Provider((_) => EntriesRepo());
final outcomesRepoProvider = Provider((_) => OutcomesRepo());
