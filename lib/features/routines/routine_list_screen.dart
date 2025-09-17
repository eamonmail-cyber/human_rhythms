import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/repo_providers.dart' as repos;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/enums.dart';
import '../../data/models/routine.dart';
import '../../features/auth/auth_controller.dart';
import 'routine_editor.dart';
import '../../data/repositories/entries_repo.dart';
import '../../data/repositories/outcomes_repo.dart';
import '../../data/repositories/routines_repo.dart';

class RoutineListScreen extends ConsumerWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider);
    if (userId == null) return const SizedBox.shrink();
    final repo = ref.watch(repos.routinesRepoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Routines")),
      body: FutureBuilder(
        future: repo.byUser(userId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final routines = snap.data as List<Routine>;
          return ListView.builder(
            itemCount: routines.length,
            itemBuilder: (c, i) {
              final r = routines[i];
              return ListTile(
                title: Text(r.title),
                subtitle: Text("${r.frequency} • ${r.targetTime ?? '-'} • ${r.category.name}"),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
                  await repo.delete(r.id);
                  (context as Element).markNeedsBuild();
                }),
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_)=> RoutineEditor(routine: r)));
                  (context as Element).markNeedsBuild();
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final r = Routine(
            id: const Uuid().v4(),
            userId: userId,
            title: "New Routine",
            category: RoutineCategory.mind,
            targetTime: null,
            frequency: "daily",
            daysOfWeek: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await Navigator.push(context, MaterialPageRoute(builder: (_)=> RoutineEditor(routine: r, isNew: true)));
          (context as Element).markNeedsBuild();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
