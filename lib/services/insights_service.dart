import '../data/models/entry.dart';
import '../data/models/enums.dart';
import '../data/models/outcome.dart';
import '../data/models/routine.dart';
import '../data/services/firebase_service.dart';

// ── InsightItem model ─────────────────────────────────────────────────────────

class InsightItem {
  final String type;
  final String title;
  final String body;
  final String emoji;

  const InsightItem({
    required this.type,
    required this.title,
    required this.body,
    required this.emoji,
  });
}

// ── InsightsService ───────────────────────────────────────────────────────────

class InsightsService {
  static Future<List<InsightItem>> generateInsights(String userId) async {
    final now = DateTime.now();
    final today = _ds(now);
    final since60 = _ds(now.subtract(const Duration(days: 60)));

    final routineSnap = await Fb.col('routines')
        .where('userId', isEqualTo: userId)
        .where('active', isEqualTo: true)
        .get();
    final routines =
        routineSnap.docs.map((d) => Routine.fromMap(d.id, d.data())).toList();

    final entrySnap = await Fb.col('entries')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: since60)
        .where('date', isLessThanOrEqualTo: today)
        .get();
    final entries =
        entrySnap.docs.map((d) => Entry.fromMap(d.id, d.data())).toList();

    final outcomeSnap = await Fb.col('outcomes')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: since60)
        .where('date', isLessThanOrEqualTo: today)
        .get();
    final outcomes =
        outcomeSnap.docs.map((d) => Outcome.fromMap(d.id, d.data())).toList();

    final items = <InsightItem>[];
    _add(items, _buildStreak(entries, now));
    _add(items, _buildTrend(outcomes, now));
    items.addAll(_buildCorrelations(entries, outcomes, routines).take(2));
    _add(items, _buildPattern(entries, now));
    _add(items, _buildCelebration(outcomes, now));
    _add(items, _buildNudge(outcomes, now));
    return items;
  }

  static void _add(List<InsightItem> list, InsightItem? item) {
    if (item != null) list.add(item);
  }

  static String _ds(DateTime d) =>
      '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Set<String> _dateRange(DateTime from, int startBack, int endBack) {
    return {
      for (int i = startBack; i <= endBack; i++)
        _ds(from.subtract(Duration(days: i))),
    };
  }

  static double _mean(List<double> vals) =>
      vals.reduce((a, b) => a + b) / vals.length;

  // ── STREAK ────────────────────────────────────────────────────────────────

  static InsightItem? _buildStreak(List<Entry> entries, DateTime now) {
    var streak = 0;
    var day = now;
    for (var i = 0; i < 60; i++) {
      final ds = _ds(day);
      if (entries.any((e) => e.date == ds && e.status == EntryStatus.done)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    if (streak < 1) return null;
    return InsightItem(
      type: 'STREAK',
      title: "You're on a roll",
      body: 'You have completed at least one routine for $streak '
          'day${streak == 1 ? '' : 's'} in a row.',
      emoji: '🔥',
    );
  }

  // ── TREND ─────────────────────────────────────────────────────────────────

  static InsightItem? _buildTrend(List<Outcome> outcomes, DateTime now) {
    List<double> moodVals(Set<String> dates) => outcomes
        .where((o) => dates.contains(o.date) && o.mood != null)
        .map((o) => o.mood!.toDouble())
        .toList();

    final lastVals = moodVals(_dateRange(now, 0, 6));
    final prevVals = moodVals(_dateRange(now, 7, 13));
    if (lastVals.length < 3 || prevVals.length < 3) return null;

    final lastAvg = _mean(lastVals);
    final prevAvg = _mean(prevVals);
    final diff = lastAvg - prevAvg;
    if (diff.abs() < 0.5) return null;

    return diff > 0
        ? InsightItem(
            type: 'TREND',
            title: 'Mood trending up',
            body: 'Your mood has trended upward this week — averaging '
                '${lastAvg.toStringAsFixed(1)} compared to '
                '${prevAvg.toStringAsFixed(1)} last week.',
            emoji: '↑',
          )
        : InsightItem(
            type: 'TREND',
            title: 'Mood dipped this week',
            body: 'Your mood averaged ${lastAvg.toStringAsFixed(1)} this week '
                'vs ${prevAvg.toStringAsFixed(1)} last week. '
                'Notice what may have shifted.',
            emoji: '↓',
          );
  }

  // ── CORRELATION ───────────────────────────────────────────────────────────

  static List<InsightItem> _buildCorrelations(
    List<Entry> entries,
    List<Outcome> outcomes,
    List<Routine> routines,
  ) {
    final outcomeByDate = <String, Outcome>{for (final o in outcomes) o.date: o};
    final ranked = <MapEntry<double, InsightItem>>[];

    for (final r in routines) {
      final doneDates = entries
          .where((e) => e.routineId == r.id && e.status == EntryStatus.done)
          .map((e) => e.date)
          .toSet();

      final doneVals = doneDates
          .where((d) => outcomeByDate[d]?.mood != null)
          .map((d) => outcomeByDate[d]!.mood!.toDouble())
          .toList();
      final otherVals = outcomeByDate.keys
          .where(
              (d) => !doneDates.contains(d) && outcomeByDate[d]?.mood != null)
          .map((d) => outcomeByDate[d]!.mood!.toDouble())
          .toList();

      if (doneVals.length + otherVals.length < 5) continue;
      if (doneVals.isEmpty || otherVals.isEmpty) continue;

      final doneAvg = _mean(doneVals);
      final otherAvg = _mean(otherVals);
      final diff = doneAvg - otherAvg;
      if (diff.abs() < 0.5) continue;

      ranked.add(MapEntry(
        diff.abs(),
        InsightItem(
          type: 'CORRELATION',
          title: diff > 0
              ? '"${r.title}" lifts your mood'
              : 'Mood pattern detected',
          body: diff > 0
              ? 'On days you complete "${r.title}", your mood averages '
                  '${doneAvg.toStringAsFixed(1)} vs '
                  '${otherAvg.toStringAsFixed(1)} on other days.'
              : 'On days without "${r.title}", your mood averages '
                  '${otherAvg.toStringAsFixed(1)} vs '
                  '${doneAvg.toStringAsFixed(1)} on days you do it.',
          emoji: '📊',
        ),
      ));
    }

    ranked.sort((a, b) => b.key.compareTo(a.key));
    return ranked.map((e) => e.value).toList();
  }

  // ── PATTERN ───────────────────────────────────────────────────────────────

  static InsightItem? _buildPattern(List<Entry> entries, DateTime now) {
    final done = List.filled(7, 0);
    final total = List.filled(7, 0);

    for (var i = 1; i <= 30; i++) {
      final day = now.subtract(Duration(days: i));
      final ds = _ds(day);
      final wd = day.weekday - 1;
      total[wd]++;
      if (entries.any((e) => e.date == ds && e.status == EntryStatus.done)) {
        done[wd]++;
      }
    }

    if (total.any((t) => t < 3)) return null;

    final rates = List.generate(7, (i) => done[i] / total[i]);
    var maxI = 0;
    var minI = 0;
    for (var i = 1; i < 7; i++) {
      if (rates[i] > rates[maxI]) maxI = i;
      if (rates[i] < rates[minI]) minI = i;
    }
    if (maxI == minI) return null;

    const names = [
      'Mondays', 'Tuesdays', 'Wednesdays', 'Thursdays',
      'Fridays', 'Saturdays', 'Sundays',
    ];
    final skipPct = ((1 - rates[minI]) * 100).round();

    return InsightItem(
      type: 'PATTERN',
      title: 'Your weekly rhythm',
      body: 'You are most consistent on ${names[maxI]}. '
          '${names[minI]} are your hardest day — '
          'you skip $skipPct% of the time.',
      emoji: '📅',
    );
  }

  // ── CELEBRATION ───────────────────────────────────────────────────────────

  static List<double> _fieldVals(
      List<Outcome> outcomes, Set<String> dates, String field) {
    return outcomes
        .where((o) => dates.contains(o.date))
        .map((o) => switch (field) {
              'mood' => o.mood?.toDouble(),
              'energy' => o.energy?.toDouble(),
              'focus' => o.focus?.toDouble(),
              'sleepQuality' => o.sleepQuality?.toDouble(),
              _ => null,
            })
        .whereType<double>()
        .toList();
  }

  static InsightItem? _buildCelebration(List<Outcome> outcomes, DateTime now) {
    for (final field in ['mood', 'energy', 'focus', 'sleepQuality']) {
      final recentVals = _fieldVals(outcomes, _dateRange(now, 0, 27), field);
      final olderVals = _fieldVals(outcomes, _dateRange(now, 28, 55), field);
      if (recentVals.length < 3 || olderVals.length < 3) continue;

      final diff = _mean(recentVals) - _mean(olderVals);
      if (diff <= 1.0) continue;

      final label = field == 'sleepQuality' ? 'sleep quality' : field;
      return InsightItem(
        type: 'CELEBRATION',
        title: '${label[0].toUpperCase()}${label.substring(1)} milestone',
        body: 'Your $label scores have improved by '
            '${diff.toStringAsFixed(1)} points over the past month. '
            'Something you are doing is working.',
        emoji: '🎉',
      );
    }
    return null;
  }

  // ── NUDGE ─────────────────────────────────────────────────────────────────

  static InsightItem? _buildNudge(List<Outcome> outcomes, DateTime now) {
    var missed = 0;
    for (var i = 1; i <= 7; i++) {
      final ds = _ds(now.subtract(Duration(days: i)));
      if (outcomes.any(
          (o) => o.date == ds && (o.mood != null || o.energy != null))) {
        break;
      }
      missed++;
    }
    if (missed < 3) return null;
    return InsightItem(
      type: 'NUDGE',
      title: 'Time to check in',
      body: 'You have not logged how you felt in '
          '$missed day${missed == 1 ? '' : 's'}. '
          'Results are more accurate when you log daily.',
      emoji: '📝',
    );
  }
}
