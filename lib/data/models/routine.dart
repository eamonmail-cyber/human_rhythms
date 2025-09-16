import 'enums.dart';

class Routine {
  final String id;
  final String userId;
  final String title;
  final RoutineCategory category;
  final String? targetTime; // "07:00"
  final String frequency;   // "daily|weekly|monthly|custom"
  final List<int>? daysOfWeek; // 0-6 if weekly
  final bool captureIntensity;
  final bool captureDuration;
  final bool captureNote;
  final bool active;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  Routine({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    this.targetTime,
    required this.frequency,
    this.daysOfWeek,
    this.captureIntensity = true,
    this.captureDuration = true,
    this.captureNote = true,
    this.active = true,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Routine.fromMap(String id, Map<String, dynamic> m) => Routine(
    id: id,
    userId: m['userId'],
    title: m['title'],
    category: RoutineCategory.values[m['category']],
    targetTime: m['targetTime'],
    frequency: m['frequency'],
    daysOfWeek: (m['daysOfWeek'] as List?)?.cast<int>(),
    captureIntensity: m['captureIntensity'] ?? true,
    captureDuration: m['captureDuration'] ?? true,
    captureNote: m['captureNote'] ?? true,
    active: m['active'] ?? true,
    version: m['version'] ?? 1,
    createdAt: DateTime.parse(m['createdAt']),
    updatedAt: DateTime.parse(m['updatedAt']),
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'category': category.index,
    'targetTime': targetTime,
    'frequency': frequency,
    'daysOfWeek': daysOfWeek,
    'captureIntensity': captureIntensity,
    'captureDuration': captureDuration,
    'captureNote': captureNote,
    'active': active,
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
