// lib/features/reminders/reminders_screen.dart
//
// Reminder times are stored as "HH:mm" in Routine.targetTime — no platform
// notification plugin is required, eliminating the PlatformException crash.
// Users set preferred times here; actual notification scheduling can be
// added in a future phase once flutter_local_notifications is configured.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/enums.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/repo_providers.dart' as repos;
import '../../features/auth/auth_controller.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _remindersProvider =
    FutureProvider.autoDispose<List<Routine>>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) throw Exception('Not signed in');
  return ref.read(repos.routinesRepoProvider).byUser(userId);
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(_remindersProvider),
        ),
        data: (routines) => routines.isEmpty
            ? const _EmptyState()
            : _RemindersList(routines: routines),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List of routines with time tiles
// ---------------------------------------------------------------------------

class _RemindersList extends ConsumerWidget {
  final List<Routine> routines;
  const _RemindersList({required this.routines});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group by category
    final grouped = <RoutineCategory, List<Routine>>{};
    for (final r in routines) {
      grouped.putIfAbsent(r.category, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            'Set preferred times for your routines. '
            'Times are saved to your schedule.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        for (final entry in grouped.entries) ...[
          _CategoryHeader(category: entry.key),
          for (final routine in entry.value)
            _ReminderTile(routine: routine),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Category header
// ---------------------------------------------------------------------------

class _CategoryHeader extends StatelessWidget {
  final RoutineCategory category;
  const _CategoryHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        _catLabel(category),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _catColor(category),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _catLabel(RoutineCategory c) => switch (c) {
        RoutineCategory.sleep => 'SLEEP',
        RoutineCategory.movement => 'MOVEMENT',
        RoutineCategory.food => 'FOOD',
        RoutineCategory.mind => 'MIND',
        RoutineCategory.social => 'SOCIAL',
        RoutineCategory.work => 'WORK',
        RoutineCategory.health => 'HEALTH',
        RoutineCategory.reflection => 'REFLECTION',
      };

  Color _catColor(RoutineCategory c) => switch (c) {
        RoutineCategory.sleep => const Color(0xFF5B8DEF),
        RoutineCategory.movement => const Color(0xFF4CAF50),
        RoutineCategory.food => const Color(0xFFFFB300),
        RoutineCategory.mind => const Color(0xFF7E57C2),
        RoutineCategory.social => const Color(0xFFFF7043),
        RoutineCategory.work => const Color(0xFF29B6F6),
        RoutineCategory.health => const Color(0xFFEC407A),
        RoutineCategory.reflection => const Color(0xFF78909C),
      };
}

// ---------------------------------------------------------------------------
// Individual routine reminder tile
// ---------------------------------------------------------------------------

class _ReminderTile extends ConsumerStatefulWidget {
  final Routine routine;
  const _ReminderTile({required this.routine});

  @override
  ConsumerState<_ReminderTile> createState() => _ReminderTileState();
}

class _ReminderTileState extends ConsumerState<_ReminderTile> {
  bool _saving = false;
  late String? _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = widget.routine.targetTime;
  }

  TimeOfDay? get _timeOfDay {
    final t = _currentTime;
    if (t == null) return null;
    try {
      final parts = t.split(':');
      return TimeOfDay(
          hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime() async {
    final initial = _timeOfDay ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Set reminder for ${widget.routine.title}',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00897B)),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    await _save(_formatTime(picked));
  }

  Future<void> _clearTime() async => _save(null);

  Future<void> _save(String? newTime) async {
    setState(() {
      _saving = true;
      _currentTime = newTime;
    });

    try {
      final updated = Routine(
        id: widget.routine.id,
        userId: widget.routine.userId,
        title: widget.routine.title,
        category: widget.routine.category,
        targetTime: newTime,
        frequency: widget.routine.frequency,
        daysOfWeek: widget.routine.daysOfWeek,
        captureIntensity: widget.routine.captureIntensity,
        captureDuration: widget.routine.captureDuration,
        captureNote: widget.routine.captureNote,
        active: widget.routine.active,
        version: widget.routine.version,
        createdAt: widget.routine.createdAt,
        updatedAt: DateTime.now(),
      );
      await ref.read(repos.routinesRepoProvider).save(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
        // Roll back optimistic update
        setState(() => _currentTime = widget.routine.targetTime);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tod = _timeOfDay;

    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFF00897B).withOpacity(0.12),
        child: Icon(Icons.notifications_outlined,
            size: 18, color: const Color(0xFF00897B)),
      ),
      title: Text(widget.routine.title,
          style: const TextStyle(fontSize: 14)),
      subtitle: tod != null
          ? Text(tod.format(context),
              style: const TextStyle(
                  color: Color(0xFF00897B), fontWeight: FontWeight.w500))
          : Text('No reminder set',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      trailing: _saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF00897B)))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.access_time, size: 20),
                  color: const Color(0xFF00897B),
                  tooltip: 'Set time',
                  onPressed: _pickTime,
                ),
                if (tod != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    color: Colors.grey,
                    tooltip: 'Clear reminder',
                    onPressed: _clearTime,
                  ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / error states
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off_outlined,
                size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No routines yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Add routines first, then come back to set reminder times.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Color(0xFFFF6B6B)),
            const SizedBox(height: 16),
            const Text('Could not load reminders',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B)),
            ),
          ],
        ),
      ),
    );
  }
}
