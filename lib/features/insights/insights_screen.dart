// lib/features/insights/insights_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/date.dart';
import '../../data/models/entry.dart';
import '../../data/models/enums.dart';
import '../../data/models/outcome.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/repo_providers.dart' as repos;
import '../../features/auth/auth_controller.dart';

// ---------------------------------------------------------------------------
// Provider — loads last 7 days of data and returns a pre-computed snapshot.
// ---------------------------------------------------------------------------

class InsightsData {
  final List<String> days; // ymd strings, oldest → newest
  final List<Outcome?> outcomes;
  final List<Entry> entries;
  final List<Routine> routines;

  const InsightsData({
    required this.days,
    required this.outcomes,
    required this.entries,
    required this.routines,
  });
}

final insightsProvider = FutureProvider.autoDispose<InsightsData>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) throw Exception('Not signed in');

  final now = DateTime.now();
  final days = List.generate(7, (i) => ymd(now.subtract(Duration(days: 6 - i))));

  final entriesRepo = ref.read(repos.entriesRepoProvider);
  final outcomesRepo = ref.read(repos.outcomesRepoProvider);
  final routinesRepo = ref.read(repos.routinesRepoProvider);

  final results = await Future.wait([
    routinesRepo.byUser(userId),
    entriesRepo.byUserAndDates(userId, days),
    Future.wait(days.map((d) => outcomesRepo.getForDate(userId, d))),
  ]);

  return InsightsData(
    days: days,
    routines: results[0] as List<Routine>,
    entries: results[1] as List<Entry>,
    outcomes: (results[2] as List<Outcome?>),
  );
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(insightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'Ask AI Coach',
            onPressed: () => context.go('/assistant'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(insightsProvider),
        ),
        data: (data) => _InsightsBody(data: data),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main body
// ---------------------------------------------------------------------------

class _InsightsBody extends StatelessWidget {
  final InsightsData data;
  const _InsightsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasAnyOutcomes = data.outcomes.any((o) => o != null);
    final hasAnyEntries = data.entries.isNotEmpty;

    if (!hasAnyOutcomes && !hasAnyEntries) {
      return const _EmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(label: 'Mood — past 7 days'),
        const SizedBox(height: 8),
        _MoodRow(days: data.days, outcomes: data.outcomes),
        const SizedBox(height: 20),
        if (hasAnyOutcomes) ...[
          _SectionHeader(label: 'Weekly averages'),
          const SizedBox(height: 8),
          _AverageCards(outcomes: data.outcomes),
          const SizedBox(height: 20),
        ],
        if (hasAnyEntries) ...[
          _SectionHeader(label: 'Completion by category'),
          const SizedBox(height: 8),
          _CategoryGrid(entries: data.entries, routines: data.routines),
          const SizedBox(height: 20),
        ],
        _SectionHeader(label: 'Key insights'),
        const SizedBox(height: 8),
        _InsightsList(data: data),
        const SizedBox(height: 20),
        _AiCoachCard(),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mood sparkline row
// ---------------------------------------------------------------------------

class _MoodRow extends StatelessWidget {
  final List<String> days;
  final List<Outcome?> outcomes;
  const _MoodRow({required this.days, required this.outcomes});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(days.length, (i) {
        final outcome = outcomes[i];
        final mood = outcome?.mood;
        final label = days[i].substring(5); // MM-DD
        return Column(
          children: [
            Text(_moodEmoji(mood), style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 6,
              decoration: BoxDecoration(
                color: _moodColor(mood),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        );
      }),
    );
  }

  String _moodEmoji(int? mood) {
    if (mood == null) return '—';
    if (mood <= 3) return '🙁';
    if (mood <= 6) return '😐';
    return '🙂';
  }

  Color _moodColor(int? mood) {
    if (mood == null) return Colors.grey.shade200;
    if (mood <= 3) return const Color(0xFFFF6B6B);
    if (mood <= 6) return Colors.orange.shade300;
    return const Color(0xFF00897B);
  }
}

// ---------------------------------------------------------------------------
// Average metric cards
// ---------------------------------------------------------------------------

class _AverageCards extends StatelessWidget {
  final List<Outcome?> outcomes;
  const _AverageCards({required this.outcomes});

  @override
  Widget build(BuildContext context) {
    final mood = _avg(outcomes.map((o) => o?.mood));
    final energy = _avg(outcomes.map((o) => o?.energy));
    final sleep = _avg(outcomes.map((o) => o?.sleepQuality));

    return Row(
      children: [
        if (mood != null)
          Expanded(child: _MetricCard(label: 'Mood', value: mood, icon: Icons.mood)),
        if (energy != null)
          Expanded(child: _MetricCard(label: 'Energy', value: energy, icon: Icons.bolt)),
        if (sleep != null)
          Expanded(child: _MetricCard(label: 'Sleep', value: sleep, icon: Icons.bedtime_outlined)),
        if (mood == null && energy == null && sleep == null)
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text('No metric data yet.',
                  style: TextStyle(color: Colors.grey)),
            ),
          ),
      ],
    );
  }

  double? _avg(Iterable<int?> values) {
    final v = values.whereType<int>().toList();
    if (v.isEmpty) return null;
    return v.reduce((a, b) => a + b) / v.length;
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  const _MetricCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00897B), size: 20),
            const SizedBox(height: 4),
            Text(value.toStringAsFixed(1),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF00897B))),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Completion grid by category
// ---------------------------------------------------------------------------

class _CategoryGrid extends StatelessWidget {
  final List<Entry> entries;
  final List<Routine> routines;
  const _CategoryGrid({required this.entries, required this.routines});

  @override
  Widget build(BuildContext context) {
    // Build map: category → (done, total)
    final routineById = {for (final r in routines) r.id: r};
    final stats = <RoutineCategory, _Stat>{};

    for (final e in entries) {
      final routine = routineById[e.routineId];
      if (routine == null) continue;
      final cat = routine.category;
      stats.putIfAbsent(cat, () => _Stat());
      stats[cat]!.total++;
      if (e.status == EntryStatus.done || e.status == EntryStatus.partial) {
        stats[cat]!.done++;
      }
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.rate.compareTo(a.value.rate));

    return Column(
      children: sorted.map((e) {
        final rate = e.value.rate;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                child: Text(_catLabel(e.key),
                    style: const TextStyle(fontSize: 13)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_catColor(e.key)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(rate * 100).round()}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _catLabel(RoutineCategory c) => switch (c) {
        RoutineCategory.sleep => '😴 Sleep',
        RoutineCategory.movement => '🏃 Movement',
        RoutineCategory.food => '🍎 Food',
        RoutineCategory.mind => '🧠 Mind',
        RoutineCategory.social => '👥 Social',
        RoutineCategory.work => '💼 Work',
        RoutineCategory.health => '❤️ Health',
        RoutineCategory.reflection => '📔 Reflect',
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

class _Stat {
  int done = 0;
  int total = 0;
  double get rate => total == 0 ? 0 : done / total;
}

// ---------------------------------------------------------------------------
// Insights text list
// ---------------------------------------------------------------------------

class _InsightsList extends StatelessWidget {
  final InsightsData data;
  const _InsightsList({required this.data});

  @override
  Widget build(BuildContext context) {
    final texts = _buildInsights(data);
    if (texts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Keep logging to unlock personalised insights.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      children: texts
          .map((t) => ListTile(
                dense: true,
                leading:
                    const Icon(Icons.lightbulb_outline, color: Color(0xFF00897B)),
                title: Text(t, style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
    );
  }

  List<String> _buildInsights(InsightsData d) {
    final texts = <String>[];
    final routineById = {for (final r in d.routines) r.id: r};

    // Average mood
    final moodVals = d.outcomes.map((o) => o?.mood).whereType<int>().toList();
    if (moodVals.isNotEmpty) {
      final avg = moodVals.reduce((a, b) => a + b) / moodVals.length;
      texts.add('Average mood this week: ${avg.toStringAsFixed(1)}/10.');
    }

    // Average sleep
    final sleepVals =
        d.outcomes.map((o) => o?.sleepQuality).whereType<int>().toList();
    if (sleepVals.isNotEmpty) {
      final avg = sleepVals.reduce((a, b) => a + b) / sleepVals.length;
      texts.add('Average sleep quality: ${avg.toStringAsFixed(1)}/10.');
    }

    // Movement vs energy
    final movementIds = d.routines
        .where((r) => r.category == RoutineCategory.movement)
        .map((r) => r.id)
        .toSet();

    final movementByDate = <String, bool>{};
    for (final e in d.entries) {
      if (movementIds.contains(e.routineId) && e.status == EntryStatus.done) {
        movementByDate[e.date] = true;
      } else {
        movementByDate.putIfAbsent(e.date, () => false);
      }
    }

    final energyMoved = <int>[], energyRest = <int>[];
    for (int i = 0; i < d.days.length; i++) {
      final energy = d.outcomes[i]?.energy;
      if (energy == null) continue;
      (movementByDate[d.days[i]] == true ? energyMoved : energyRest).add(energy);
    }

    if (energyMoved.isNotEmpty && energyRest.isNotEmpty) {
      final avgM = energyMoved.reduce((a, b) => a + b) / energyMoved.length;
      final avgR = energyRest.reduce((a, b) => a + b) / energyRest.length;
      if ((avgM - avgR).abs() >= 0.5) {
        final better = avgM > avgR ? 'higher' : 'lower';
        texts.add(
            'Your energy was $better on days you exercised '
            '(${avgM.toStringAsFixed(1)} vs ${avgR.toStringAsFixed(1)}).');
      }
    }

    // Best completion category
    final stats = <RoutineCategory, _Stat>{};
    for (final e in d.entries) {
      final r = routineById[e.routineId];
      if (r == null) continue;
      stats.putIfAbsent(r.category, () => _Stat());
      stats[r.category]!.total++;
      if (e.status == EntryStatus.done || e.status == EntryStatus.partial) {
        stats[r.category]!.done++;
      }
    }
    if (stats.length >= 2) {
      final best = stats.entries
          .reduce((a, b) => a.value.rate >= b.value.rate ? a : b);
      if (best.value.rate > 0) {
        texts.add(
            'Best category: ${_catName(best.key)} at '
            '${(best.value.rate * 100).round()}% completion.');
      }
    }

    return texts;
  }

  String _catName(RoutineCategory c) => switch (c) {
        RoutineCategory.sleep => 'Sleep',
        RoutineCategory.movement => 'Movement',
        RoutineCategory.food => 'Food',
        RoutineCategory.mind => 'Mind',
        RoutineCategory.social => 'Social',
        RoutineCategory.work => 'Work',
        RoutineCategory.health => 'Health',
        RoutineCategory.reflection => 'Reflection',
      };
}

// ---------------------------------------------------------------------------
// AI Coach card
// ---------------------------------------------------------------------------

class _AiCoachCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF00897B).withOpacity(0.08),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: const Color(0xFF00897B).withOpacity(0.3))),
      child: ListTile(
        leading:
            const Icon(Icons.smart_toy_outlined, color: Color(0xFF00897B)),
        title: const Text('Ask your AI Coach',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFF00897B))),
        subtitle: const Text('Get personalised advice based on your data'),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: Color(0xFF00897B)),
        onTap: () => context.go('/assistant'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: const Color(0xFF00897B)));
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
            const Icon(Icons.bar_chart, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No data yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Log your routines and mood for a few days and your insights will appear here.',
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
            const Text('Could not load insights',
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
