import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/enums.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/repo_providers.dart' as repos;
import '../../features/auth/auth_controller.dart';
import 'routine_editor.dart';

class RoutineListScreen extends ConsumerStatefulWidget {
  const RoutineListScreen({super.key});
  @override
  ConsumerState<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends ConsumerState<RoutineListScreen> {
  int _refresh = 0;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    return AppScaffold(
      title: 'My Routines',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNew(context, userId),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Routine', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : FutureBuilder<List<Routine>>(
              key: ValueKey(_refresh),
              future: ref.read(repos.routinesRepoProvider).byUser(userId),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kPrimary));
                final routines = snap.data!;
                if (routines.isEmpty) return _buildEmpty(context, userId);
                return _buildList(context, routines, userId);
              },
            ),
    );
  }

  Widget _buildEmpty(BuildContext context, String? userId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.loop_rounded, color: kPrimary, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Build your first routine', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              'Add the habits and practices that make up your day — exercise, meals, meditation, anything.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _createNew(context, userId),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add First Routine'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Routine> routines, String? userId) {
    // Group by category
    final grouped = <RoutineCategory, List<Routine>>{};
    for (final r in routines) grouped.putIfAbsent(r.category, () => []).add(r);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        for (final cat in RoutineCategory.values)
          if (grouped.containsKey(cat)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: _colorFor(cat), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(cat.name.toUpperCase(), style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
            for (final r in grouped[cat]!)
              _RoutineTile(
                routine: r,
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => RoutineEditor(routine: r, isNew: false),
                  ));
                  setState(() => _refresh++);
                },
                onDelete: () async {
                  await ref.read(repos.routinesRepoProvider).delete(r.id);
                  setState(() => _refresh++);
                },
              ),
          ],
      ],
    );
  }

  Future<void> _createNew(BuildContext context, String? userId) async {
    if (userId == null) return;
    final blank = Routine(
      id: const Uuid().v4(),
      userId: userId,
      title: '',
      category: RoutineCategory.movement,
      frequency: 'daily',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => RoutineEditor(routine: blank, isNew: true),
    ));
    setState(() => _refresh++);
  }

  Color _colorFor(RoutineCategory c) => switch(c) {
    RoutineCategory.sleep      => kCatSleep,
    RoutineCategory.movement   => kCatMovement,
    RoutineCategory.food       => kCatFood,
    RoutineCategory.mind       => kCatMind,
    RoutineCategory.social     => kCatSocial,
    RoutineCategory.work       => kCatWork,
    RoutineCategory.health     => kCatHealth,
    RoutineCategory.reflection => kCatReflection,
  };
}

class _RoutineTile extends StatelessWidget {
  final Routine routine;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _RoutineTile({required this.routine, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(routine.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(_iconFor(routine.category), color: color, size: 22),
        ),
        title: Text(routine.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${routine.frequency}  ·  ${routine.targetTime ?? 'Any time'}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), color: kTextMid, onPressed: onTap),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: kAccent,
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete routine?'),
                  content: Text('Remove "${routine.title}" from your routines?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () { Navigator.pop(context); onDelete(); },
                      style: ElevatedButton.styleFrom(backgroundColor: kAccent),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _colorFor(RoutineCategory c) => switch(c) {
    RoutineCategory.sleep      => kCatSleep,
    RoutineCategory.movement   => kCatMovement,
    RoutineCategory.food       => kCatFood,
    RoutineCategory.mind       => kCatMind,
    RoutineCategory.social     => kCatSocial,
    RoutineCategory.work       => kCatWork,
    RoutineCategory.health     => kCatHealth,
    RoutineCategory.reflection => kCatReflection,
  };

  IconData _iconFor(RoutineCategory c) => switch(c) {
    RoutineCategory.sleep      => Icons.bedtime_outlined,
    RoutineCategory.movement   => Icons.directions_run_rounded,
    RoutineCategory.food       => Icons.restaurant_outlined,
    RoutineCategory.mind       => Icons.self_improvement_outlined,
    RoutineCategory.social     => Icons.people_outline_rounded,
    RoutineCategory.work       => Icons.work_outline_rounded,
    RoutineCategory.health     => Icons.favorite_outline_rounded,
    RoutineCategory.reflection => Icons.auto_stories_outlined,
  };
}
