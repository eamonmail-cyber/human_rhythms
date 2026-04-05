import '../data/models/entry.dart';
import '../data/models/enums.dart';
import '../data/models/outcome.dart';
import '../data/models/routine.dart';
import '../data/services/firebase_service.dart';

// ── CorrelationItem model ─────────────────────────────────────────────────────

class CorrelationItem {
  final String routineTitle;
  final String routineCategory;
  final String outcomeName;
  final double avgWith;
  final double avgWithout;
  final double difference;
  final int dataPoints;
  final int confidenceLevel;
  final bool isPositive;

  const CorrelationItem({
    required this.routineTitle,
    required this.routineCategory,
    required this.outcomeName,
    required this.avgWith,
    required this.avgWithout,
    required this.difference,
    required this.dataPoints,
    required this.confidenceLevel,
    required this.isPositive,
  });
}

// ── CorrelationService ────────────────────────────────────────────────────────

class CorrelationService {
  static Future<List<CorrelationItem>> generate(String userId) async {
    final now = DateTime.now();
    final since90 = _ds(now.subtract(const Duration(days: 90)));
    final today = _ds(now);

    final routineSnap = await Fb.col('routines')
        .where('userId', isEqualTo: userId)
        .where('active', isEqualTo: true)
        .get();
    final routines =
        routineSnap.docs.map((d) => Routine.fromMap(d.id, d.data())).toList();

    final entrySnap = await Fb.col('entries')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: since90)
        .where('date', isLessThanOrEqualTo: today)
        .get();
    final entries =
        entrySnap.docs.map((d) => Entry.fromMap(d.id, d.data())).toList();

    final outcomeSnap = await Fb.col('outcomes')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: since90)
        .where('date', isLessThanOrEqualTo: today)
        .get();
    final outcomes =
        outcomeSnap.docs.map((d) => Outcome.fromMap(d.id, d.data())).toList();

    final outcomeByDate = <String, Outcome>{for (final o in outcomes) o.date: o};
    const fields = ['mood', 'energy', 'sleepQuality', 'focus', 'pain'];
    final results = <CorrelationItem>[];

    for (final routine in routines) {
      final doneDates = entries
          .where((e) => e.routineId == routine.id && e.status == EntryStatus.done)
          .map((e) => e.date)
          .toSet();
      final allDates = outcomeByDate.keys.toSet();

      for (final field in fields) {
        double? getVal(String date) {
          final o = outcomeByDate[date];
          if (o == null) return null;
          return switch (field) {
            'mood' => o.mood?.toDouble(),
            'energy' => o.energy?.toDouble(),
            'sleepQuality' => o.sleepQuality?.toDouble(),
            'focus' => o.focus?.toDouble(),
            'pain' => o.pain?.toDouble(),
            _ => null,
          };
        }

        final withVals = doneDates
            .where((d) => allDates.contains(d))
            .map(getVal)
            .whereType<double>()
            .toList();
        final withoutVals = allDates
            .difference(doneDates)
            .map(getVal)
            .whereType<double>()
            .toList();

        final dataPoints = withVals.length + withoutVals.length;
        if (dataPoints < 5) continue;
        if (withVals.isEmpty || withoutVals.isEmpty) continue;

        final avgWith = withVals.reduce((a, b) => a + b) / withVals.length;
        final avgWithout =
            withoutVals.reduce((a, b) => a + b) / withoutVals.length;
        final diff = avgWith - avgWithout;
        if (diff.abs() < 0.3) continue;

        final confidence = dataPoints < 10 ? 1 : dataPoints <= 30 ? 2 : 3;
        final label = field == 'sleepQuality' ? 'sleep quality' : field;

        results.add(CorrelationItem(
          routineTitle: routine.title,
          routineCategory: routine.category.name,
          outcomeName: label,
          avgWith: avgWith,
          avgWithout: avgWithout,
          difference: diff,
          dataPoints: dataPoints,
          confidenceLevel: confidence,
          isPositive: diff > 0,
        ));
      }
    }

    results.sort((a, b) => b.difference.abs().compareTo(a.difference.abs()));
    return results;
  }

  static String _ds(DateTime d) =>
      '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
