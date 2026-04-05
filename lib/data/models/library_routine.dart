class LibraryRoutine {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool isVerifiedExpert;
  final String? expertCredential;
  final String? expertSpecialty; // e.g. "physiotherapist", "nutritionist"
  final String? evidenceNote;    // brief evidence/research backing
  final String title;
  final String description;
  final String category;
  final String frequency;
  final String? targetTime;
  final int ageGroupMin;
  final int ageGroupMax;
  final List<String> tags;
  final List<String> goals;
  final int adoptedCount;
  final double avgRating;
  final int ratingCount;
  final List<String> resultHighlights;
  final DateTime createdAt;
  final bool active;

  LibraryRoutine({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.isVerifiedExpert = false,
    this.expertCredential,
    this.expertSpecialty,
    this.evidenceNote,
    required this.title,
    required this.description,
    required this.category,
    required this.frequency,
    this.targetTime,
    this.ageGroupMin = 0,
    this.ageGroupMax = 99,
    this.tags = const [],
    this.goals = const [],
    this.adoptedCount = 0,
    this.avgRating = 0,
    this.ratingCount = 0,
    this.resultHighlights = const [],
    required this.createdAt,
    this.active = true,
  });

  factory LibraryRoutine.fromMap(String id, Map<String, dynamic> m) =>
      LibraryRoutine(
        id: id,
        authorId: m['authorId'] ?? '',
        authorName: m['authorName'] ?? 'Anonymous',
        authorAvatarUrl: m['authorAvatarUrl'],
        isVerifiedExpert: m['isVerifiedExpert'] ?? false,
        expertCredential: m['expertCredential'],
        expertSpecialty: m['expertSpecialty'],
        evidenceNote: m['evidenceNote'],
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        category: m['category'] ?? 'movement',
        frequency: m['frequency'] ?? 'daily',
        targetTime: m['targetTime'],
        ageGroupMin: m['ageGroupMin'] ?? 0,
        ageGroupMax: m['ageGroupMax'] ?? 99,
        tags: List<String>.from(m['tags'] ?? []),
        goals: List<String>.from(m['goals'] ?? []),
        adoptedCount: m['adoptedCount'] ?? 0,
        avgRating: (m['avgRating'] ?? 0).toDouble(),
        ratingCount: m['ratingCount'] ?? 0,
        resultHighlights:
            List<String>.from(m['resultHighlights'] ?? []),
        createdAt: DateTime.parse(m['createdAt']),
        active: m['active'] ?? true,
      );

  Map<String, dynamic> toMap() => {
    'authorId': authorId,
    'authorName': authorName,
    'authorAvatarUrl': authorAvatarUrl,
    'isVerifiedExpert': isVerifiedExpert,
    'expertCredential': expertCredential,
    'expertSpecialty': expertSpecialty,
    'evidenceNote': evidenceNote,
    'title': title,
    'description': description,
    'category': category,
    'frequency': frequency,
    'targetTime': targetTime,
    'ageGroupMin': ageGroupMin,
    'ageGroupMax': ageGroupMax,
    'tags': tags,
    'goals': goals,
    'adoptedCount': adoptedCount,
    'avgRating': avgRating,
    'ratingCount': ratingCount,
    'resultHighlights': resultHighlights,
    'createdAt': createdAt.toIso8601String(),
    'active': active,
  };
}
