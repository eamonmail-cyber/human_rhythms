import '../data/models/entry.dart';
import '../data/models/enums.dart';
import '../data/models/outcome.dart';
import '../data/models/routine.dart';
import '../data/services/firebase_service.dart';

// ── MonthSummary model ────────────────────────────────────────────────────────

class MonthSummary {
  final String monthLabel;
  final DateTime month;
  final double completionRate;
  final double? avgMood;
  final double? avgEnergy;
  final int routinesAdded;
  final int routinesRemoved;
  final String? bestDay;

  const MonthSummary({
    required this.monthLabel,
    required this.month,
    required this.completionRate,
    this.avgMood,
    this.avgEnergy,
    required this.routinesAdded,
    required this.routinesRemoved,
    this.bestDay,
  });
}

// ── MilestoneItem model ───────────────────────────────────────────────────────

class MilestoneItem {
  final String id;
  final String userId;
  final String date;
  final String note;
  final DateTime createdAt;

  const MilestoneItem({
    required this.id,
    required this.userId,
    required this.date,
    required this.note,
    required this.createdAt,
  });

  factory MilestoneItem.fromMap(String id, Map<String, dynamic> m) =>
      MilestoneItem(
        id: id,
        userId: m['userId'] as String,
        date: m['date'] as String,
        note: m['note'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'date': date,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };
}

// ── LookbackService ───────────────────────────────────────────────────────────

class LookbackService {
  static Future<List<MonthSummary>> generate(String userId) async {
    final now = DateTime.now();
    final monthStart6 = DateTime(now.year, now.month - 5, 1);
    final sinceStr = _ds(monthStart6);
    final todayStr = _ds(now);

    // Fetch entries for last 6 months
    final entrySnap = await Fb.col('entries')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: sinceStr)
        .where('date', isLessThanOrEqualTo: todayStr)
        .get();
    final entries =
        entrySnap.docs.map((d) => Entry.fromMap(d.id, d.data())).toList();

    // Fetch outcomes for last 6 months
    final outcomeSnap = await Fb.col('outcomes')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: sinceStr)
        .where('date', isLessThanOrEqualTo: todayStr)
        .get();
    final outcomes =
        outcomeSnap.docs.map((d) => Outcome.fromMap(d.id, d.data())).toList();

    // Fetch all routines (active + inactive)
    final routineSnap =
        await Fb.col('routines').where('userId', isEqualTo: userId).get();
    final routines =
        routineSnap.docs.map((d) => Routine.fromMap(d.id, d.data())).toList();
    final activeCount = routines.where((r) => r.active).length;

    final summaries = <MonthSummary>[];
    for (var i = 0; i < 6; i++) {
      final ms = DateTime(now.year, now.month - i, 1);
      final me = DateTime(now.year, now.month - i + 1, 0);

      final me2 = entries.where((e) {
        final d = DateTime.parse(e.date);
        return d.year == ms.year && d.month == ms.month;
      }).toList();

      final mo = outcomes.where((o) {
        final d = DateTime.parse(o.date);
        return d.year == ms.year && d.month == ms.month;
      }).toList();

      final daysInMonth = me.day;
      final doneCount = me2.where((e) => e.status == EntryStatus.done).length;
      final totalPossible = activeCount * daysInMonth;
      final completionRate =
          totalPossible == 0 ? 0.0 : (doneCount / totalPossible).clamp(0.0, 1.0);

      final moodVals = mo
          .where((o) => o.mood != null)
          .map((o) => o.mood!.toDouble())
          .toList();
      final energyVals = mo
          .where((o) => o.energy != null)
          .map((o) => o.energy!.toDouble())
          .toList();

      final avgMood = moodVals.isEmpty
          ? null
          : moodVals.reduce((a, b) => a + b) / moodVals.length;
      final avgEnergy = energyVals.isEmpty
          ? null
          : energyVals.reduce((a, b) => a + b) / energyVals.length;

      final routinesAdded = routines
          .where((r) =>
              r.createdAt.year == ms.year && r.createdAt.month == ms.month)
          .length;
      final routinesRemoved = routines
          .where((r) =>
              !r.active &&
              r.updatedAt.year == ms.year &&
              r.updatedAt.month == ms.month)
          .length;

      // Best day = day with most done entries
      String? bestDay;
      var bestCount = 0;
      final daysSet = me2.map((e) => e.date).toSet();
      for (final d in daysSet) {
        final count =
            me2.where((e) => e.date == d && e.status == EntryStatus.done).length;
        if (count > bestCount) {
          bestCount = count;
          bestDay = d;
        }
      }

      summaries.add(MonthSummary(
        monthLabel: _monthLabel(ms),
        month: ms,
        completionRate: completionRate,
        avgMood: avgMood,
        avgEnergy: avgEnergy,
        routinesAdded: routinesAdded,
        routinesRemoved: routinesRemoved,
        bestDay: bestDay,
      ));
    }

    return summaries;
  }

  static String _ds(DateTime d) =>
      '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _monthLabel(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}
