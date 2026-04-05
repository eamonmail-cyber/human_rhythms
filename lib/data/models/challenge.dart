import 'enums.dart';

// ── Mindset nudges for challenges ─────────────────────────────────────────────
const challengeNudges = [
  'Day by day, you\'re becoming the person you want to be.',
  'Every check-in is a vote for the life you\'re building.',
  'You don\'t have to be perfect — you just have to show up.',
  'The secret is: it gets easier after day 3, day 7, day 14.',
  'Your streak is proof that you can do hard things.',
  'Rest when you need to. Show up when you can.',
  'Progress is invisible until it\'s undeniable.',
  'You are one decision away from changing everything.',
  'The person who finishes is not the same person who started.',
  'Momentum is a superpower. Protect yours today.',
  'Your future self will thank you for this check-in.',
  'Small wins today equal big change in 30 days.',
];

String challengeNudgeForDay(int day) =>
    challengeNudges[day.abs() % challengeNudges.length];

// ── Anonymous alias reuse ─────────────────────────────────────────────────────
const _challengeAliases = [
  'SwiftOak',    'BoldFern',   'CalmRiver',  'SteadyPine', 'BrightMoss',
  'QuietSage',   'StrongReed', 'ClearSkye',  'DeepRoots',  'FlowState',
  'RisingTide',  'WarmLight',  'FreePath',   'TrueNorth',  'OpenField',
  'CrispAir',    'SilverLeaf', 'GoldenHour', 'PureWave',   'TallGrass',
];

String challengeAliasFor(String userId) =>
    _challengeAliases[userId.hashCode.abs() % _challengeAliases.length];

// ── Milestone days ────────────────────────────────────────────────────────────
const milestoneDays = {7, 14, 21, 30};

// ── Challenge ─────────────────────────────────────────────────────────────────

class Challenge {
  final String id;
  final String title;
  final String goal;
  final int durationDays;
  final int participantCount;
  final DateTime startDate;
  final double completionRate; // 0.0–1.0 across all participants
  final RoutineCategory category;
  final String? description;
  final bool active;

  const Challenge({
    required this.id,
    required this.title,
    required this.goal,
    this.durationDays = 30,
    this.participantCount = 0,
    required this.startDate,
    this.completionRate = 0.0,
    required this.category,
    this.description,
    this.active = true,
  });

  factory Challenge.fromMap(String id, Map<String, dynamic> m) => Challenge(
    id: id,
    title: m['title'] as String,
    goal: m['goal'] as String,
    durationDays: (m['durationDays'] as int?) ?? 30,
    participantCount: (m['participantCount'] as int?) ?? 0,
    startDate: DateTime.parse(m['startDate'] as String),
    completionRate: ((m['completionRate'] ?? 0) as num).toDouble(),
    category: RoutineCategory.values[(m['category'] as int?) ?? 0],
    description: m['description'] as String?,
    active: (m['active'] as bool?) ?? true,
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'goal': goal,
    'durationDays': durationDays,
    'participantCount': participantCount,
    'startDate': startDate.toIso8601String(),
    'completionRate': completionRate,
    'category': category.index,
    'description': description,
    'active': active,
  };

  /// How many days since the challenge started.
  int get daysSinceStart =>
      DateTime.now().difference(startDate).inDays.clamp(0, durationDays);

  bool get isComplete => daysSinceStart >= durationDays;
}

// ── ChallengeParticipant ──────────────────────────────────────────────────────
// Sub-collection: challenges/{id}/participants/{userId}

class ChallengeParticipant {
  final String userId; // also the document ID; stored for collectionGroup
  final String challengeId;
  final String alias;
  final DateTime joinedAt;
  final int currentStreak;
  final int totalCheckins;
  final bool showOnLeaderboard;
  final DateTime? lastCheckin;

  const ChallengeParticipant({
    required this.userId,
    required this.challengeId,
    required this.alias,
    required this.joinedAt,
    this.currentStreak = 0,
    this.totalCheckins = 0,
    this.showOnLeaderboard = true,
    this.lastCheckin,
  });

  factory ChallengeParticipant.fromMap(
      String userId, Map<String, dynamic> m) =>
      ChallengeParticipant(
        userId: userId,
        challengeId: m['challengeId'] as String,
        alias: m['alias'] as String,
        joinedAt: DateTime.parse(m['joinedAt'] as String),
        currentStreak: (m['currentStreak'] as int?) ?? 0,
        totalCheckins: (m['totalCheckins'] as int?) ?? 0,
        showOnLeaderboard: (m['showOnLeaderboard'] as bool?) ?? true,
        lastCheckin: m['lastCheckin'] != null
            ? DateTime.parse(m['lastCheckin'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'challengeId': challengeId,
    'alias': alias,
    'joinedAt': joinedAt.toIso8601String(),
    'currentStreak': currentStreak,
    'totalCheckins': totalCheckins,
    'showOnLeaderboard': showOnLeaderboard,
    'lastCheckin': lastCheckin?.toIso8601String(),
  };

  ChallengeParticipant copyWith({
    int? currentStreak,
    int? totalCheckins,
    bool? showOnLeaderboard,
    DateTime? lastCheckin,
  }) =>
      ChallengeParticipant(
        userId: userId,
        challengeId: challengeId,
        alias: alias,
        joinedAt: joinedAt,
        currentStreak: currentStreak ?? this.currentStreak,
        totalCheckins: totalCheckins ?? this.totalCheckins,
        showOnLeaderboard:
            showOnLeaderboard ?? this.showOnLeaderboard,
        lastCheckin: lastCheckin ?? this.lastCheckin,
      );

  /// Percentage of challenge days completed (0–1).
  double completionFraction(int durationDays) =>
      durationDays == 0 ? 0 : totalCheckins / durationDays;

  /// True if the user has already checked in today.
  bool get checkedInToday {
    if (lastCheckin == null) return false;
    final now = DateTime.now();
    final lc = lastCheckin!;
    return lc.year == now.year &&
        lc.month == now.month &&
        lc.day == now.day;
  }
}

// ── ChallengeCheckin ──────────────────────────────────────────────────────────
// Sub-collection: challenges/{id}/checkins/{docId}
// NO userId stored — only alias for anonymity.

class ChallengeCheckin {
  final String id;
  final String challengeId;
  final String alias;
  final DateTime date;
  final String? note;

  const ChallengeCheckin({
    required this.id,
    required this.challengeId,
    required this.alias,
    required this.date,
    this.note,
  });

  factory ChallengeCheckin.fromMap(String id, Map<String, dynamic> m) =>
      ChallengeCheckin(
        id: id,
        challengeId: m['challengeId'] as String,
        alias: m['alias'] as String,
        date: DateTime.parse(m['date'] as String),
        note: m['note'] as String?,
      );

  Map<String, dynamic> toMap() => {
    'challengeId': challengeId,
    'alias': alias,
    'date': date.toIso8601String(),
    'note': note,
    // userId deliberately NOT stored — same anonymity pattern as group activity.
  };
}
