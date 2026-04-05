import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/utils/date.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/enums.dart';
import '../../data/models/entry.dart';
import '../../data/models/outcome.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/repo_providers.dart' as repos;
import '../../features/auth/auth_controller.dart';
import 'bubble.dart';
import 'edit_entry_sheet.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});
  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  DateTime day = DateTime.now();

  bool get _isToday {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  String get _dayLabel {
    if (_isToday) return 'Today';
    final diff = DateTime.now().difference(day).inDays;
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(day);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    return AppScaffold(
      title: 'My Day',
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today_outlined, size: 20),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: day,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(primary: kPrimary),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => day = picked);
          },
        ),
      ],
      body: userId == null
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _DiaryBody(
              userId: userId,
              day: day,
              dayLabel: _dayLabel,
              isToday: _isToday,
              onPrev: () => setState(() => day = day.subtract(const Duration(days: 1))),
              onNext: () {
                if (!_isToday) setState(() => day = day.add(const Duration(days: 1)));
              },
              onRefresh: () => setState(() {}),
            ),
    );
  }
}

class _DiaryBody extends ConsumerStatefulWidget {
  final String userId;
  final DateTime day;
  final String dayLabel;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onRefresh;
  const _DiaryBody({
    required this.userId, required this.day, required this.dayLabel,
    required this.isToday, required this.onPrev, required this.onNext, required this.onRefresh,
  });
  @override
  ConsumerState<_DiaryBody> createState() => _DiaryBodyState();
}

class _DiaryBodyState extends ConsumerState<_DiaryBody> {
  late Future<List<dynamic>> _future;
  String? _loadedDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(_DiaryBody old) {
    super.didUpdateWidget(old);
    if (ymd(widget.day) != _loadedDate) _loadData();
  }

  void _loadData() {
    _loadedDate = ymd(widget.day);
    final routinesRepo = ref.read(repos.routinesRepoProvider);
    final entriesRepo  = ref.read(repos.entriesRepoProvider);
    final outcomesRepo = ref.read(repos.outcomesRepoProvider);
    _future = Future.wait<dynamic>([
      routinesRepo.byUser(widget.userId),
      entriesRepo.byUserAndDate(widget.userId, _loadedDate!),
      outcomesRepo.getForDate(widget.userId, _loadedDate!),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = ymd(widget.day);

    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return RefreshIndicator(
            color: kPrimary,
            onRefresh: () async => setState(_loadData),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          "Couldn't load your diary.\nPull down to try again.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kPrimary));
        final data = snap.data as List;
        final routines = data[0] as List<Routine>;
        final entries  = data[1] as List<Entry>;
        final outcome  = data[2] as Outcome?;

        final byBucket = <TimeBucket, List<_RoutineWithEntry>>{
          TimeBucket.morning: [], TimeBucket.midday: [], TimeBucket.evening: [], TimeBucket.custom: [],
        };
        for (final r in routines) {
          final bucket = _bucketFor(r.targetTime);
          final e = entries.where((x) => x.routineId == r.id).toList();
          byBucket[bucket]!.add(_RoutineWithEntry(routine: r, entry: e.isNotEmpty ? e.first : null));
        }

        final doneCount = entries.where((e) => e.status == EntryStatus.done).length;
        final totalCount = routines.length;

        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async { setState(_loadData); widget.onRefresh(); },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _DateHeader(
                      dayLabel: widget.dayLabel,
                      isToday: widget.isToday,
                      onPrev: widget.onPrev,
                      onNext: widget.onNext,
                      canGoNext: !widget.isToday,
                    ),
                    _OutcomeBar(userId: widget.userId, dateStr: dateStr, initial: outcome),
                    if (totalCount > 0)
                      _ProgressBar(done: doneCount, total: totalCount),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              ...[TimeBucket.morning, TimeBucket.midday, TimeBucket.evening].map((bucket) {
                final items = byBucket[bucket]!;
                return SliverToBoxAdapter(
                  child: _BucketSection(
                    bucket: bucket,
                    items: items,
                    userId: widget.userId,
                    dateStr: dateStr,
                    onSaved: widget.onRefresh,
                  ),
                );
              }),
              if (routines.isEmpty)
                SliverToBoxAdapter(child: _EmptyState()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  TimeBucket _bucketFor(String? hhmm) {
    if (hhmm == null) return TimeBucket.custom;
    try {
      final h = int.parse(hhmm.split(':')[0]);
      if (h < 12) return TimeBucket.morning;
      if (h < 17) return TimeBucket.midday;
      return TimeBucket.evening;
    } catch (_) { return TimeBucket.custom; }
  }
}

class _DateHeader extends StatelessWidget {
  final String dayLabel;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canGoNext;
  const _DateHeader({required this.dayLabel, required this.isToday, required this.onPrev, required this.onNext, required this.canGoNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: kTextMid,
            onPressed: onPrev,
          ),
          Expanded(
            child: Column(
              children: [
                Text(dayLabel, style: Theme.of(context).textTheme.headlineMedium),
                if (isToday)
                  Text(DateFormat('MMMM d, yyyy').format(DateTime.now()),
                      style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, size: 28),
            color: canGoNext ? kTextMid : kDivider,
            onPressed: canGoNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressBar({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$done of $total completed', style: Theme.of(context).textTheme.bodyMedium),
              Text('${(pct * 100).round()}%',
                  style: TextStyle(fontWeight: FontWeight.w700, color: kPrimary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: kDivider,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeBar extends ConsumerStatefulWidget {
  final String userId;
  final String dateStr;
  final Outcome? initial;
  const _OutcomeBar({required this.userId, required this.dateStr, this.initial});
  @override
  ConsumerState<_OutcomeBar> createState() => _OutcomeBarState();
}

class _OutcomeBarState extends ConsumerState<_OutcomeBar> {
  int? mood;
  @override
  void initState() { super.initState(); mood = widget.initial?.mood; }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: kCard, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kDivider),
        ),
        child: Row(
          children: [
            Text('How are you feeling?', style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            for (final entry in [
              (2, '😞'), (5, '😐'), (7, '🙂'), (10, '😄'),
            ]) ...[
              GestureDetector(
                onTap: () => _save(entry.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: mood == entry.$1 ? kPrimary.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(entry.$2, style: TextStyle(fontSize: mood == entry.$1 ? 22 : 18)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(int v) async {
    setState(() => mood = v);
    final repo = ref.read(repos.outcomesRepoProvider);
    await repo.upsert(Outcome(
      id: '${widget.userId}-${widget.dateStr}',
      userId: widget.userId,
      date: widget.dateStr,
      mood: v,
      energy: null, sleepQuality: null, pain: null, focus: null, notes: null,
    ));
  }
}

class _BucketSection extends ConsumerWidget {
  final TimeBucket bucket;
  final List<_RoutineWithEntry> items;
  final String userId;
  final String dateStr;
  final VoidCallback onSaved;
  const _BucketSection({required this.bucket, required this.items, required this.userId, required this.dateStr, required this.onSaved});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();
    final label = switch(bucket) {
      TimeBucket.morning => '🌅  Morning',
      TimeBucket.midday  => '☀️  Midday',
      TimeBucket.evening => '🌙  Evening',
      TimeBucket.custom  => '🎯  Other',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(label.toUpperCase(),
                style: Theme.of(context).textTheme.titleSmall),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: items.map((it) {
                final color = _colorFor(it.routine.category);
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Bubble(
                    color: color,
                    size: _sizeFor(it.entry),
                    state: _stateFor(it.entry),
                    label: it.routine.title,
                    onTap: () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => EditEntrySheet(
                          initial: it.entry,
                          routine: it.routine,
                          dateStr: dateStr,
                          userId: userId,
                        ),
                      );
                      onSaved();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
        ],
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

  double _sizeFor(Entry? e) {
    if (e?.durationMin != null) return 28 + (e!.durationMin!.clamp(0, 60) / 60.0) * 36;
    if (e?.intensity != null)   return 28 + (e!.intensity!.clamp(0, 10) / 10.0) * 20;
    return 56;
  }

  BubbleState _stateFor(Entry? e) {
    if (e == null) return BubbleState.planned;
    return switch(e.status) {
      EntryStatus.done    => BubbleState.done,
      EntryStatus.skipped => BubbleState.skipped,
      EntryStatus.partial => BubbleState.partial,
      _                   => BubbleState.planned,
    };
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.add_circle_outline_rounded, color: kPrimary, size: 36),
          ),
          const SizedBox(height: 16),
          Text('No routines yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Tap Routines below to build your first daily rhythm.',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _RoutineWithEntry {
  final Routine routine;
  final Entry? entry;
  _RoutineWithEntry({required this.routine, required this.entry});
}
