import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/library_routine.dart';
import '../../data/models/enums.dart';
import '../../providers/global.dart';

final _libraryProvider = FutureProvider<List<LibraryRoutine>>((ref) async {
  return ref.watch(libraryRepoProvider).fetchAll();
});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_libraryProvider);
    return AppScaffold(
      title: 'Library',
      selectedIndex: 2,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (routines) => routines.isEmpty
            ? const _EmptyLibrary()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: routines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _LibraryCard(routine: routines[i]),
              ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_books_outlined, size: 64, color: kTextLight),
          const SizedBox(height: 16),
          Text('No routines in the library yet.', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _LibraryCard extends ConsumerWidget {
  final LibraryRoutine routine;
  const _LibraryCard({required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _categoryColor(routine.category);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(_categoryIcon(routine.category), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(routine.title, style: Theme.of(context).textTheme.titleMedium),
                  if (routine.description != null) ...[
                    const SizedBox(height: 2),
                    Text(routine.description!, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  Text('${routine.saves} saves · ${routine.frequency}', style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              color: kPrimary,
              tooltip: 'Add to my routines',
              onPressed: () async {
                await ref.read(libraryRepoProvider).incrementSaves(routine.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to your routines')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

Color _categoryColor(RoutineCategory c) {
  switch (c) {
    case RoutineCategory.sleep:      return kCatSleep;
    case RoutineCategory.movement:   return kCatMovement;
    case RoutineCategory.food:       return kCatFood;
    case RoutineCategory.mind:       return kCatMind;
    case RoutineCategory.social:     return kCatSocial;
    case RoutineCategory.work:       return kCatWork;
    case RoutineCategory.health:     return kCatHealth;
    case RoutineCategory.reflection: return kCatReflection;
  }
}

IconData _categoryIcon(RoutineCategory c) {
  switch (c) {
    case RoutineCategory.sleep:      return Icons.bedtime_outlined;
    case RoutineCategory.movement:   return Icons.directions_run_rounded;
    case RoutineCategory.food:       return Icons.restaurant_outlined;
    case RoutineCategory.mind:       return Icons.self_improvement_rounded;
    case RoutineCategory.social:     return Icons.people_outline_rounded;
    case RoutineCategory.work:       return Icons.work_outline_rounded;
    case RoutineCategory.health:     return Icons.favorite_outline_rounded;
    case RoutineCategory.reflection: return Icons.edit_note_rounded;
  }
}
