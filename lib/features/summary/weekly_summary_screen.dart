import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils/date.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/entry.dart';
import '../../data/models/enums.dart';
import '../../data/models/outcome.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/repo_providers.dart' as repos;
import '../../features/auth/auth_controller.dart';
import '../../services/insights_service.dart';
import 'correlations_screen.dart';
import 'lookback_screen.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class WeeklySummaryScreen extends ConsumerStatefulWidget {
  const WeeklySummaryScreen({super.key});
  @override
  ConsumerState<WeeklySummaryScreen> createState() =>
      _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends ConsumerState<WeeklySummaryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Tab 1 — Insights
  int _weeksBack = 0;
  Future<List<InsightItem>>? _insightsFuture;
  String? _insightsUserId;
  final _dismissedTitles = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> _weekDays(DateTime now) {
    final weekStart =
        now.subtract(Duration(days: now.weekday - 1 + (_weeksBack * 7)));
    return List.generate(7, (i) => ymd(weekStart.add(Duration(days: i))));
  }

  String _weekLabel() {
    if (_weeksBack == 0) return 'This Week';
    if (_weeksBack == 1) return 'Last Week';
    return '$_weeksBack weeks ago';
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    if (userId == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: kPrimary)));
    }

    if (_insightsFuture == null || _insightsUserId != userId) {
      _insightsUserId = userId;
      _insightsFuture = InsightsService.generateInsights(userId);
    }

    return AppScaffold(
      title: 'Insights',
      body: Column(
        children: [
          Container(
            color: kSurface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: kPrimary,
              labelColor: kPrimary,
              unselectedLabelColor: kTextMid,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(text: 'Insights'),
                Tab(text: 'Journey'),
                Tab(text: 'Patterns'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInsightsTab(userId),
                LookbackView(userId: userId),
                CorrelationsView(userId: userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1 — Insights ───────────────────────────────────────────────────────

  Widget _buildInsightsTab(String userId) {
    final now = DateTime.now();
    final days = _weekDays(now);

    return FutureBuilder(
      future: Future.wait<dynamic>([
        ref.read(repos.entriesRepoProvider).byUserAndDates(userId, days),
        Future.wait(days.map(
            (d) => ref.read(repos.outcomesRepoProvider).getForDate(userId, d))),
        ref.read(repos.routinesRepoProvider).byUser(userId),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: kPrimary));
        }
        final data = snap.data as List;
        final entries = data[0] as List<Entry>;
        final outcomes = data[1] as List<Outcome?>;
        final routines = data[2] as List<Routine>;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            _WeekSelector(
              weekLabel: _weekLabel(),
              onPrev: () => setState(() => _weeksBack++),
              onNext:
                  _weeksBack > 0 ? () => setState(() => _weeksBack--) : null,
            ),
            const SizedBox(height: 16),
            _CompletionCard(
                entries: entries, routines: routines, days: days),
            const SizedBox(height: 12),
            _MoodCard(outcomes: outcomes, days: days),
            const SizedBox(height: 12),
            _CategoryCard(entries: entries, routines: routines),
            const SizedBox(height: 16),
            FutureBuilder<List<InsightItem>>(
              future: _insightsFuture,
              builder: (context, insightSnap) {
                if (!insightSnap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: CircularProgressIndicator(color: kPrimary)),
                  );
                }
                return _buildInsightsSection(insightSnap.data!);
              },
            ),
          ],
        );
      },
    );
  }

  // ── AI Insights section ───────────────────────────────────────────────────

  static const _nudges = [
    'This is what consistency looks like in numbers',
    'Your data does not lie — but it takes time to speak',
    'Small changes. Logged daily. Add up to everything.',
  ];

  Widget _buildInsightsSection(List<InsightItem> all) {
    final visible = all
        .where((item) => !_dismissedTitles.contains(item.title))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: kPrimary, size: 18),
              const SizedBox(width: 8),
              Text('AI INSIGHTS',
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
        if (visible.isEmpty)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kDivider),
            ),
            child: Column(
              children: [
                const Icon(Icons.bar_chart_rounded,
                    color: kTextLight, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Keep logging — insights appear after 5 days of data',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          )
        else
          for (var i = 0; i < visible.length; i++) ...[
            _InsightCard(
              item: visible[i],
              onDismiss: () =>
                  setState(() => _dismissedTitles.add(visible[i].title)),
            ),
            const SizedBox(height: 10),
            if ((i + 1) % 3 == 0 && i < visible.length - 1) ...[
              _MindsetNudgeCard(
                  text: _nudges[(i ~/ 3) % _nudges.length]),
              const SizedBox(height: 10),
            ],
          ],
      ],
    );
  }
}

// ── Week Selector ─────────────────────────────────────────────────────────────

class _WeekSelector extends StatelessWidget {
  final String weekLabel;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  const _WeekSelector({
    required this.weekLabel,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: kTextMid,
            onPressed: onPrev),
        Text(weekLabel, style: Theme.of(context).textTheme.titleLarge),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, size: 28),
          color: onNext != null ? kTextMid : kDivider,
          onPressed: onNext,
        ),
      ],
    );
  }
}

// ── Completion Card ───────────────────────────────────────────────────────────

class _CompletionCard extends StatelessWidget {
  final List<Entry> entries;
  final List<Routine> routines;
  final List<String> days;
  const _CompletionCard(
      {required this.entries, required this.routines, required this.days});

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
            Text('COMPLETION',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            Row(
              children: [
                _RingIndicator(value: pct, size: 80),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$done completed',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: kPrimary)),
                      Text('out of $total possible',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: kAccent, size: 18),
                        const SizedBox(width: 4),
                        Text('$streak day streak',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: kAccent)),
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
    var streak = 0;
    for (final d in days.reversed) {
      if (entries
          .where((e) => e.date == d && e.status == EntryStatus.done)
          .isNotEmpty) {
        streak++;
      } else {
        break;
      }
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
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 8,
            backgroundColor: kDivider,
            color: kPrimary,
            strokeCap: StrokeCap.round,
          ),
          Text('${(value * 100).round()}%',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: kPrimary)),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final List<Entry> entries;
  final List<String> days;
  final List<Routine> routines;
  const _DayBar(
      {required this.entries, required this.days, required this.routines});

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final d = i < days.length ? days[i] : '';
        final done = entries
            .where((e) => e.date == d && e.status == EntryStatus.done)
            .length;
        final total = routines.length;
        final pct = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: pct > 0.7
                    ? kPrimary
                    : pct > 0.3
                        ? kPrimaryLight.withOpacity(0.5)
                        : kDivider,
                shape: BoxShape.circle,
              ),
              child: done > 0
                  ? Center(
                      child: Text('$done',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)))
                  : null,
            ),
            const SizedBox(height: 4),
            Text(dayLabels[i],
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 11)),
          ],
        );
      }),
    );
  }
}

// ── Mood Card ─────────────────────────────────────────────────────────────────

class _MoodCard extends StatelessWidget {
  final List<Outcome?> outcomes;
  final List<String> days;
  const _MoodCard({required this.outcomes, required this.days});

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const moodEmojis = {2: '😞', 5: '😐', 7: '🙂', 10: '😄'};
    final hasData = outcomes.any((o) => o?.mood != null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MOOD THIS WEEK',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            if (!hasData)
              Center(
                  child: Text('Log your mood daily to see trends here.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final o = i < outcomes.length ? outcomes[i] : null;
                  final mood = o?.mood;
                  final emoji = mood != null
                      ? moodEmojis.entries
                          .reduce((a, b) =>
                              (mood - a.key).abs() < (mood - b.key).abs()
                                  ? a
                                  : b)
                          .value
                      : '·';
                  return Column(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(dayLabels[i],
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 11)),
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

// ── Category Card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final List<Entry> entries;
  final List<Routine> routines;
  const _CategoryCard({required this.entries, required this.routines});

  @override
  Widget build(BuildContext context) {
    final catCount = <RoutineCategory, int>{};
    for (final e in entries.where((e) => e.status == EntryStatus.done)) {
      final match = routines.where((r) => r.id == e.routineId).toList();
      if (match.isNotEmpty) {
        catCount[match.first.category] =
            (catCount[match.first.category] ?? 0) + 1;
      }
    }
    if (catCount.isEmpty) return const SizedBox.shrink();

    final sorted = catCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = catCount.values.fold(0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACTIVITY BY TYPE',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            for (final entry in sorted.take(5)) ...[
              Row(
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: _colorFor(entry.key),
                          shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(entry.key.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500))),
                  Text('${entry.value}x',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kTextMid)),
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

  Color _colorFor(RoutineCategory c) => switch (c) {
        RoutineCategory.sleep => kCatSleep,
        RoutineCategory.movement => kCatMovement,
        RoutineCategory.food => kCatFood,
        RoutineCategory.mind => kCatMind,
        RoutineCategory.social => kCatSocial,
        RoutineCategory.work => kCatWork,
        RoutineCategory.health => kCatHealth,
        RoutineCategory.reflection => kCatReflection,
      };
}

// ── Insight Card (expandable + dismissable) ───────────────────────────────────

class _InsightCard extends StatefulWidget {
  final InsightItem item;
  final VoidCallback onDismiss;
  const _InsightCard({required this.item, required this.onDismiss});

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Card(
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.emoji,
                      style: const TextStyle(fontSize: 28, height: 1.1)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(item.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: kTextLight,
                    onPressed: widget.onDismiss,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    item.body,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(item.body,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, right: 8),
                  child: Text(
                    _expanded ? 'Tap to collapse' : 'Tap for more',
                    style: const TextStyle(
                        fontSize: 11, color: kTextLight),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mindset Nudge Card ────────────────────────────────────────────────────────

class _MindsetNudgeCard extends StatelessWidget {
  final String text;
  const _MindsetNudgeCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.format_quote_rounded,
              color: kPrimary.withOpacity(0.6), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: kTextMid,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
