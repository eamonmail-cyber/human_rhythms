import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'routines_repo.dart';

import 'entries_repo.dart';

import 'outcomes_repo.dart';



// Your repos don't take any constructor arguments, so just create them plainly.

final routinesRepoProvider = Provider<RoutinesRepo>((ref) => RoutinesRepo());

final entriesRepoProvider  = Provider<EntriesRepo>((ref)  => EntriesRepo());

final outcomesRepoProvider = Provider<OutcomesRepo>((ref) => OutcomesRepo());


