import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routines_repo.dart';
import 'entries_repo.dart';
import 'outcomes_repo.dart';

final routinesRepoProvider = Provider((_) => RoutinesRepo());
final entriesRepoProvider  = Provider((_) => EntriesRepo());
final outcomesRepoProvider = Provider((_) => OutcomesRepo());
