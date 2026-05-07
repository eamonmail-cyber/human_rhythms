import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/utils/date.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/entry.dart';
import '../../data/models/enums.dart';
import '../../data/models/outcome.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/repo_providers.dart' as repos;
import '../../features/auth/auth_controller.dart';

class WeeklySummaryScreen extends ConsumerStatefulWidget {
  const WeeklySummaryScreen({super.key});
  @override
  ConsumerState<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends ConsumerState<WeeklySummaryScreen> {
  int _weeksBack = 0;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    if (userId == null) return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimary)));

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1 + (_weeksBack * 7)));
    final days = List.generate(7, (i) => ymd(weekStart.add(Duration(days: i))));
    final weekLabel = _weeksBack == 0
        ? 'This Week'
        : _weeksBack == 1
            ? 'Last Week'
            : '${_weeksBack} weeks ago';

    return AppScaffold(
      title: 'Insights',
      selectedIndex: 2,
      body: FutureBuilder(
        future: Future.wait<dynamic>([
          ref.read(repos.entriesRepoProvider).byUserAndDates(userId, days),
          Future.wait(days.map((d) => ref.read(repos.outcomesRepoProvider).getForDate(userId, d))),
          ref.read(repos.routinesRepoProvider).byUser(userId),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kPrimary));
          final data = snap.data as List;
          final entries  = data[0] as List<Entry>;
          final outcomes = data[1] as List<Outcome?>;
          final routines = data[2] as List<Routine>;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              // Week selector
              _WeekSelector(weekLabel: weekLabel, weeksBack: _weeksBack,
                  onPrev: () => setState(() => _weeksBack++),
                  onNext: _weeksBack > 0 ? () => setState(() => _weeksBack--) : null),
              const SizedBox(height: 16),
              // Completion ring card
              _CompletionCard(entries: entries, routines: routines, days: days),
              const SizedBox(height: 12),
              // Mood chart
              _MoodCard(outcomes: outcomes, days: days),
              const SizedBox(height: 12),
              // Category breakdown
              _CategoryCard(entries: entries, routines: routines),
              const SizedBox(height: 12),
              // Insights
              _InsightsCard(entries: entries, outcomes: outcomes, routines: routines),
              const SizedBox(height: 12),
              // 6-month lookback teaser
              _LookbackCard(userId: userId),
            ],
          );
        },
      ),
    );
  }
}

class _WeekSelector extends StatelessWidget {
  final String weekLabel;
  final int weeksBack;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  const _WeekSelector({required this.weekLabel, required this.weeksBack, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left_rounded, size: 28), color: kTextMid, onPressed: onPrev),
        Text(weekLabel, style: Theme.of(context).textTheme.titleLarge),
        IconButton(
          icon: Icon(Icons.chevron_right_rounded, size: 28),
          color: onNext != null ? kTextMid : kDivider,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _CompletionCard extends StatelessWidget {
  final List<Entry> entries;
  final List<Routine> routines;
  final List<String> days;
  const _CompletionCard({required this.entries, required this.routines, required this.days});

  @override
  Widget build(BuildContext context) {
    final done = entries.where((e) => e.status == EntryStatus.done).length;
    final total = routines.length * 7;
    final pct = total == 0 ? 0.0 : done / total;
    final streak = _calcStreak(entries, days);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('COMPLETION', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            Row(
              children: [
                _RingIndicator(value: pct, size: 80),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$done completed', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: kPrimary)),
                      Text('out of $total possible', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.local_fire_department_rounded, color: kAccent, size: 18),
                        const SizedBox(width: 4),
                        Text('$streak day streak', style: const TextStyle(fontWeight: FontWeight.w700, color: kAccent)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DayBar(entries: entries, days: days, routines: routines),
          ],
        ),
      ),
    );
  }

  int _calcStreak(List<Entry> entries, List<String> days) {
    int streak = 0;
    for (final d in days.reversed) {
      final dayDone = entries.where((e) => e.date == d && e.status == EntryStatus.done).isNotEmpty;
      if (dayDone) streak++; else break;
    }
    return streak;
  }
}

class _RingIndicator extends StatelessWidget {
  final double value;
  final double size;
  const _RingIndicator({required this.value, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value, strokeWidth: 8,
            backgroundColor: kDivider, color: kPrimary,
            strokeCap: StrokeCap.round,
          ),
          Text('${(value * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kPrimary)),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final List<Entry> entries;
  final List<String> days;
  final List<Routine> routines;
  const _DayBar({required this.entries, required this.days, required this.routines});

  @override
  Widget build(BuildContext context) {
    final dayLabels = ['M','T','W','T','F','S','S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final d = i < days.length ? days[i] : '';
        final done = entries.where((e) => e.date == d && e.status == EntryStatus.done).length;
        final total = routines.length;
        final pct = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
        return Column(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: pct > 0.7 ? kPrimary : pct > 0.3 ? kPrimaryLight.withOpacity(0.5) : kDivider,
                shape: BoxShape.circle,
              ),
              child: done > 0 ? Center(child: Text('$done', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))) : null,
            ),
            const SizedBox(height: 4),
            Text(dayLabels[i], style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
          ],
        );
      }),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final List<Outcome?> outcomes;
  final List<String> days;
  const _MoodCard({required this.outcomes, required this.days});

  @override
  Widget build(BuildContext context) {
    final dayLabels = ['M','T','W','T','F','S','S'];
    final moodEmojis = {2: '😞', 5: '😐', 7: '🙂', 10: '😄'};
    final hasData = outcomes.any((o) => o?.mood != null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MOOD THIS WEEK', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            if (!hasData)
              Center(child: Text('Log your mood daily to see trends here.',
                  style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final o = i < outcomes.length ? outcomes[i] : null;
                  final mood = o?.mood;
                  final emoji = mood != null
                      ? moodEmojis.entries.reduce((a, b) => (mood - a.key).abs() < (mood - b.key).abs() ? a : b).value
                      : '·';
                  return Column(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(dayLabels[i], style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                    ],
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final List<Entry> entries;
  final List<Routine> routines;
  const _CategoryCard({required this.entries, required this.routines});

  @override
  Widget build(BuildContext context) {
    final catCount = <RoutineCategory, int>{};
    for (final e in entries.where((e) => e.status == EntryStatus.done)) {
      final r = routines.where((r) => r.id == e.routineId).toList();
      if (r.isNotEmpty) catCount[r.first.category] = (catCount[r.first.category] ?? 0) + 1;
    }
    if (catCount.isEmpty) return const SizedBox.shrink();
    final sorted = catCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = catCount.values.fold(0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACTIVITY BY TYPE', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            for (final entry in sorted.take(5)) ...[
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: _colorFor(entry.key), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.key.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                  Text('${entry.value}x', style: const TextStyle(fontWeight: FontWeight.w700, color: kTextMid)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.value / total,
                        color: _colorFor(entry.key),
                        backgroundColor: kDivider,
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
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
}

class _InsightsCard extends StatelessWidget {
  final List<Entry> entries;
  final List<Outcome?> outcomes;
  final List<Routine> routines;
  const _InsightsCard({required this.entries, required this.outcomes, required this.routines});

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();
    if (insights.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.lightbulb_outline_rounded, color: kPrimary, size: 18),
              const SizedBox(width: 8),
              Text('INSIGHTS', style: Theme.of(context).textTheme.titleSmall),
            ]),
            const SizedBox(height: 14),
            for (final i in insights) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(i, style: const TextStyle(fontSize: 14, height: 1.5)),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _generateInsights() {
    final insights = <String>[];
    final moods = outcomes.where((o) => o?.mood != null).map((o) => o!.mood!).toList();
    if (moods.isNotEmpty) {
      final avg = moods.reduce((a, b) => a + b) / moods.length;
      final label = avg >= 7 ? 'positive 😊' : avg >= 4 ? 'neutral 😐' : 'low 😞';
      insights.add('Your mood averaged $label this week (${avg.toStringAsFixed(1)}/10).');
    }
    final movementIds = routines.where((r) => r.category == RoutineCategory.movement).map((r) => r.id).toSet();
    final movDays = entries.where((e) => movementIds.contains(e.routineId) && e.status == EntryStatus.done).map((e) => e.date).toSet().length;
    if (movDays > 0) insights.add('You moved your body on $movDays day${movDays != 1 ? 's' : ''} this week. Keep it up!');
    final doneCount = entries.where((e) => e.status == EntryStatus.done).length;
    final skippedCount = entries.where((e) => e.status == EntryStatus.skipped).length;
    if (doneCount + skippedCount > 0) {
      final pct = (doneCount / (doneCount + skippedCount) * 100).round();
      if (pct >= 80) insights.add('🔥 Excellent week — you followed through on $pct% of your logged routines!');
      else if (pct >= 50) insights.add('Good effort — you completed $pct% of your routines. A small bump next week and you\'ll be flying.');
    }
    return insights;
  }
}

class _LookbackCard extends StatelessWidget {
  final String userId;
  const _LookbackCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.history_rounded, color: kAccent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('6-Month Lookback', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text('Keep logging to unlock your full progress story.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.lock_outline_rounded, color: kTextLight, size: 20),
          ],
        ),
      ),
    );
  }
}
