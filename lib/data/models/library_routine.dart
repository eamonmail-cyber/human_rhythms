import 'enums.dart';

class LibraryRoutine {
  final String id;
  final String authorId;
  final String title;
  final String? description;
  final RoutineCategory category;
  final String frequency;
  final bool captureIntensity;
  final bool captureDuration;
  final bool captureNote;
  final int saves;
  final DateTime createdAt;

  LibraryRoutine({
    required this.id,
    required this.authorId,
    required this.title,
    this.description,
    required this.category,
    required this.frequency,
    this.captureIntensity = true,
    this.captureDuration = true,
    this.captureNote = true,
    this.saves = 0,
    required this.createdAt,
  });

  factory LibraryRoutine.fromMap(String id, Map<String, dynamic> m) => LibraryRoutine(
    id: id,
    authorId: m['authorId'] ?? '',
    title: m['title'] ?? '',
    description: m['description'],
    category: RoutineCategory.values[m['category'] ?? 0],
    frequency: m['frequency'] ?? 'daily',
    captureIntensity: m['captureIntensity'] ?? true,
    captureDuration: m['captureDuration'] ?? true,
    captureNote: m['captureNote'] ?? true,
    saves: m['saves'] ?? 0,
    createdAt: DateTime.parse(m['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'authorId': authorId,
    'title': title,
    'description': description,
    'category': category.index,
    'frequency': frequency,
    'captureIntensity': captureIntensity,
    'captureDuration': captureDuration,
    'captureNote': captureNote,
    'saves': saves,
    'createdAt': createdAt.toIso8601String(),
  };
}
