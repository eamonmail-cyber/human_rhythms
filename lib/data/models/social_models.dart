class PublicProfile {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final int age;
  final List<String> goals;
  final int followersCount;
  final int followingCount;
  final int publicRoutinesCount;
  final bool isVerifiedExpert;
  final String? expertCredential;
  final String? expertSpecialty; // "physiotherapist", "medical doctor", etc.
  final DateTime joinedAt;

  PublicProfile({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.age,
    this.goals = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.publicRoutinesCount = 0,
    this.isVerifiedExpert = false,
    this.expertCredential,
    this.expertSpecialty,
    required this.joinedAt,
  });

  factory PublicProfile.fromMap(String id, Map<String, dynamic> m) =>
      PublicProfile(
        userId: id,
        displayName: m['displayName'] ?? 'Human Rhythms User',
        avatarUrl: m['avatarUrl'],
        bio: m['bio'],
        age: m['age'] ?? 0,
        goals: List<String>.from(m['goals'] ?? []),
        followersCount: m['followersCount'] ?? 0,
        followingCount: m['followingCount'] ?? 0,
        publicRoutinesCount: m['publicRoutinesCount'] ?? 0,
        isVerifiedExpert: m['isVerifiedExpert'] ?? false,
        expertCredential: m['expertCredential'],
        expertSpecialty: m['expertSpecialty'],
        joinedAt: DateTime.parse(m['joinedAt']),
      );

  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'bio': bio,
    'age': age,
    'goals': goals,
    'followersCount': followersCount,
    'followingCount': followingCount,
    'publicRoutinesCount': publicRoutinesCount,
    'isVerifiedExpert': isVerifiedExpert,
    'expertCredential': expertCredential,
    'expertSpecialty': expertSpecialty,
    'joinedAt': joinedAt.toIso8601String(),
  };
}

class Follow {
  final String followerId;
  final String followingId;
  final DateTime createdAt;

  Follow({
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  factory Follow.fromMap(Map<String, dynamic> m) => Follow(
    followerId: m['followerId'],
    followingId: m['followingId'],
    createdAt: DateTime.parse(m['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'followerId': followerId,
    'followingId': followingId,
    'createdAt': createdAt.toIso8601String(),
  };
}

class RoutineStory {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final int authorAge;
  final String title;
  final String beforeDescription;
  final String afterDescription;
  final String routineId;
  final String routineTitle;
  final int durationWeeks;
  final List<String> improvements;
  final List<String> tags;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final bool isAnonymous;

  RoutineStory({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.authorAge,
    required this.title,
    required this.beforeDescription,
    required this.afterDescription,
    required this.routineId,
    required this.routineTitle,
    required this.durationWeeks,
    this.improvements = const [],
    this.tags = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.isAnonymous = false,
  });

  factory RoutineStory.fromMap(String id, Map<String, dynamic> m) =>
      RoutineStory(
        id: id,
        authorId: m['authorId'],
        authorName: m['authorName'] ?? 'Anonymous',
        authorAvatarUrl: m['authorAvatarUrl'],
        authorAge: m['authorAge'] ?? 0,
        title: m['title'],
        beforeDescription: m['beforeDescription'],
        afterDescription: m['afterDescription'],
        routineId: m['routineId'],
        routineTitle: m['routineTitle'],
        durationWeeks: m['durationWeeks'] ?? 4,
        improvements: List<String>.from(m['improvements'] ?? []),
        tags: List<String>.from(m['tags'] ?? []),
        likesCount: m['likesCount'] ?? 0,
        commentsCount: m['commentsCount'] ?? 0,
        createdAt: DateTime.parse(m['createdAt']),
        isAnonymous: m['isAnonymous'] ?? false,
      );

  Map<String, dynamic> toMap() => {
    'authorId': authorId,
    'authorName': isAnonymous ? 'Anonymous' : authorName,
    'authorAvatarUrl': isAnonymous ? null : authorAvatarUrl,
    'authorAge': authorAge,
    'title': title,
    'beforeDescription': beforeDescription,
    'afterDescription': afterDescription,
    'routineId': routineId,
    'routineTitle': routineTitle,
    'durationWeeks': durationWeeks,
    'improvements': improvements,
    'tags': tags,
    'likesCount': likesCount,
    'commentsCount': commentsCount,
    'createdAt': createdAt.toIso8601String(),
    'isAnonymous': isAnonymous,
  };

  /// Returns a copy of this story with updated anonymous flag.
  RoutineStory withAnonymous(bool anon) => RoutineStory(
    id: id,
    authorId: authorId,
    authorName: authorName,
    authorAvatarUrl: authorAvatarUrl,
    authorAge: authorAge,
    title: title,
    beforeDescription: beforeDescription,
    afterDescription: afterDescription,
    routineId: routineId,
    routineTitle: routineTitle,
    durationWeeks: durationWeeks,
    improvements: improvements,
    tags: tags,
    likesCount: likesCount,
    commentsCount: commentsCount,
    createdAt: createdAt,
    isAnonymous: anon,
  );
}
