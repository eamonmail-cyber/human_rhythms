import 'enums.dart';

class Entry {
  final String id;
  final String userId;
  final String? routineId;
  final String date;
  final TimeBucket timeBucket;
  final EntryStatus status;
  final int? durationMin;
  final int? intensity;
  final String? note;
  final List<String> tags;
  final int? routineVersionAtLog;
  final DateTime createdAt;

  Entry({
    required this.id,
    required this.userId,
    required this.routineId,
    required this.date,
    required this.timeBucket,
    required this.status,
    this.durationMin,
    this.intensity,
    this.note,
    this.tags = const [],
    this.routineVersionAtLog,
    required this.createdAt,
  });

  factory Entry.fromMap(String id, Map<String, dynamic> m) => Entry(
    id: id,
    userId: m['userId'],
    routineId: m['routineId'],
    date: m['date'],
    timeBucket: TimeBucket.values[m['timeBucket']],
    status: EntryStatus.values[m['status']],
    durationMin: m['durationMin'],
    intensity: m['intensity'],
    note: m['note'],
    tags: (m['tags'] as List?)?.cast<String>() ?? const [],
    routineVersionAtLog: m['routineVersionAtLog'],
    createdAt: DateTime.parse(m['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'routineId': routineId,
    'date': date,
    'timeBucket': timeBucket.index,
    'status': status.index,
    'durationMin': durationMin,
    'intensity': intensity,
    'note': note,
    'tags': tags,
    'routineVersionAtLog': routineVersionAtLog,
    'createdAt': createdAt.toIso8601String(),
  };
}
