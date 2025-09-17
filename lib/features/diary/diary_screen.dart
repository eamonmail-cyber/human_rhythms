import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/repo.providers.dart' as repos;
import 'package:uuid/uuid.dart';
import '../../core/utils/date.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/enums.dart';
import '../../data/models/entry.dart';
import '../../data/models/outcome.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/entries_repo.dart';
import '../../data/repositories/outcomes_repo.dart';
import '../../data/repositories/routines_repo.dart';
import '../../features/auth/auth_controller.dart';
import 'edit_entry_sheet.dart';
import 'bubble.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  DateTime day = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    final dateStr = ymd(day);

    return AppScaffold(
      title: "Today",
      body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : _DiaryBody(userId: userId, dateStr: dateStr, onPrev: (){
              setState(()=> day = day.subtract(const Duration(days:1)));
            }, onNext: (){
              setState(()=> day = day.add(const Duration(days:1)));
            }),
    );
  }
}

class _DiaryBody extends ConsumerWidget {
  final String userId;
  final String dateStr;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _DiaryBody({required this.userId, required this.dateStr, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesRepo = ref.watch(routinesRepoProvider);
    final entriesRepo  = ref.watch(entriesRepoProvider);
    final outcomesRepo = ref.watch(outcomesRepoProvider);

    return FutureBuilder(
      future: Future.wait([
        routinesRepo.byUser(userId),
        entriesRepo.byUserAndDate(userId, dateStr),
        outcomesRepo.getForDate(userId, dateStr),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data as List;
        final routines = (data[0] as List<Routine>);
        final entries  = (data[1] as List<Entry>);
        final outcome  = (data[2] as Outcome?);

        final byBucket = <TimeBucket, List<_RoutineWithEntry>>{
          TimeBucket.morning: [], TimeBucket.midday: [], TimeBucket.evening: [], TimeBucket.custom: []
        };

        for (final r in routines) {
          // naive: assign bucket by targetTime (MVP)
          final bucket = _bucketFor(r.targetTime);
          final e = entries.where((x) => x.routineId == r.id).toList();
          final picked = e.isNotEmpty ? e.first : null;
          byBucket[bucket]!.add(_RoutineWithEntry(routine: r, entry: picked));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
                Expanded(child: Center(child: Text(dateStr, style: Theme.of(context).textTheme.titleMedium))),
                IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 8),
            _OutcomeBar(userId: userId, dateStr: dateStr, initial: outcome),
            const SizedBox(height: 12),
            _BucketSection(label: "Morning", items: byBucket[TimeBucket.morning]!, userId: userId, dateStr: dateStr),
            const SizedBox(height: 12),
            _BucketSection(label: "Midday", items: byBucket[TimeBucket.midday]!, userId: userId, dateStr: dateStr),
            const SizedBox(height: 12),
            _BucketSection(label: "Evening", items: byBucket[TimeBucket.evening]!, userId: userId, dateStr: dateStr),
          ],
        );
      },
    );
  }

  TimeBucket _bucketFor(String? hhmm) {
    if (hhmm == null) return TimeBucket.custom;
    try {
      final parts = hhmm.split(':');
      final h = int.parse(parts[0]);
      if (h < 12) return TimeBucket.morning;
      if (h < 17) return TimeBucket.midday;
      return TimeBucket.evening;
    } catch (_) {
      return TimeBucket.custom;
    }
  }
}

class _BucketSection extends ConsumerWidget {
  final String label;
  final List<_RoutineWithEntry> items;
  final String userId;
  final String dateStr;
  const _BucketSection({required this.label, required this.items, required this.userId, required this.dateStr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final it in items) ...[
                Bubble(
                  color: _colorFor(it.routine.category),
                  size: _sizeFor(it.entry),
                  state: _stateFor(it.entry),
                  onTap: () async {
                    final saved = await showModalBottomSheet<Entry?>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => EditEntrySheet(
                        initial: it.entry,
                        routine: it.routine,
                        dateStr: dateStr,
                        userId: userId,
                      ),
                    );
                    if (saved != null) {
                      // Trigger rebuild by popping and setState at upper level; using FutureBuilder, simplest is setState upstream (handled by setState on DiaryScreen date change). For MVP do nothing.
                    }
                  },
                ),
                const SizedBox(width: 12),
              ],
              if (items.isEmpty)
                const Text("No routines here yet"),
            ],
          ),
        ),
      ],
    );
  }

  Color _colorFor(RoutineCategory c) {
    switch (c) {
      case RoutineCategory.sleep: return const Color(0xFF5B8DEF);
      case RoutineCategory.movement: return const Color(0xFF4CAF50);
      case RoutineCategory.food: return const Color(0xFFFFB300);
      case RoutineCategory.mind: return const Color(0xFF7E57C2);
      case RoutineCategory.social: return const Color(0xFFFF7043);
      case RoutineCategory.work: return const Color(0xFF29B6F6);
      case RoutineCategory.health: return const Color(0xFFEC407A);
      case RoutineCategory.reflection: return const Color(0xFF78909C);
    }
  }

  double _sizeFor(Entry? e) {
    if (e?.durationMin != null) {
      final d = e!.durationMin!.clamp(0, 60);
      return 28 + (d/60.0)*36; // 28..64
    }
    if (e?.intensity != null) {
      final i = e!.intensity!.clamp(0, 10);
      return 28 + (i/10.0)*20; // 28..48
    }
    return 36;
  }

  BubbleState _stateFor(Entry? e) {
    if (e == null) return BubbleState.planned;
    switch (e.status) {
      case EntryStatus.done: return BubbleState.done;
      case EntryStatus.skipped: return BubbleState.skipped;
      case EntryStatus.partial: return BubbleState.partial;
      case EntryStatus.planned: return BubbleState.planned;
      case EntryStatus.unknown: return BubbleState.unknown;
    }
  }
}

class _RoutineWithEntry {
  final Routine routine;
  final Entry? entry;
  _RoutineWithEntry({required this.routine, required this.entry});
}

class _OutcomeBar extends ConsumerStatefulWidget {
  final String userId;
  final String dateStr;
  final Outcome? initial;
  const _OutcomeBar({required this.userId, required this.dateStr, this.initial, super.key});

  @override
  ConsumerState<_OutcomeBar> createState() => _OutcomeBarState();
}

class _OutcomeBarState extends ConsumerState<_OutcomeBar> {
  int mood = 0;
  @override
  void initState() {
    super.initState();
    mood = widget.initial?.mood ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text("Mood:"),
        const SizedBox(width: 8),
        for (final m in [2, 5, 8]) ...[
          ChoiceChip(label: Text(_labelFor(m)), selected: mood == m, onSelected: (_) => _save(m)),
          const SizedBox(width: 6),
        ],
      ],
    );
  }

  String _labelFor(int v) => switch (v) { 2 => "🙁", 5 => "😐", 8 => "🙂", _ => "😐" };

  Future<void> _save(int v) async {
    setState(()=> mood = v);
    final repo = ref.read(outcomesRepoProvider);
    await repo.upsert(Outcome(
      id: "${widget.userId}-${widget.dateStr}",
      userId: widget.userId,
      date: widget.dateStr,
      mood: v,
      energy: null, sleepQuality: null, pain: null, focus: null, notes: null
    ));
  }
}
