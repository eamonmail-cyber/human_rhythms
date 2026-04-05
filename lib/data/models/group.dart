import 'enums.dart';

// ── Mindset nudges ────────────────────────────────────────────────────────────
// Shown at the top of a group feed to encourage engagement.
const mindsetNudges = [
  'Small steps every day create the life you want.',
  'Progress, not perfection. Every check-in counts.',
  'You\'re not doing this alone — your group is with you.',
  'The hardest part is starting. You already did that.',
  'Consistency beats intensity. Show up again today.',
  'Rest is part of the process, not a setback.',
  'Your future self is cheering you on right now.',
  'One good choice leads to another.',
  'Habits built slowly tend to last forever.',
  'This moment matters more than you think.',
];

String nudgeForGroup(String groupId) =>
    mindsetNudges[groupId.hashCode.abs() % mindsetNudges.length];

// ── Anonymous alias wordlist ──────────────────────────────────────────────────
const _aliases = [
  'TealFox',    'CoralOwl',   'MintBear',   'SageHare',   'BlueWren',
  'PeachHawk',  'IvyLark',    'RubyDove',   'OakSwan',    'FernCrane',
  'RoseDeer',   'SlateWolf',  'CedarLynx',  'DuskFinch',  'MossEagle',
  'PineMarten', 'CocoaKite',  'TwilightRam','AmberVole',  'ReedMoose',
];

String aliasFor(String userId) =>
    _aliases[userId.hashCode.abs() % _aliases.length];

// ── WellnessGoal helpers ──────────────────────────────────────────────────────

String wellnessGoalLabel(WellnessGoal g) => switch (g) {
  WellnessGoal.sleep          => 'Better Sleep',
  WellnessGoal.weightLoss     => 'Weight Loss',
  WellnessGoal.anxiety        => 'Anxiety Relief',
  WellnessGoal.dementiaRisk   => 'Dementia Prevention',
  WellnessGoal.heartHealth    => 'Heart Health',
  WellnessGoal.chronicPain    => 'Chronic Pain',
  WellnessGoal.diabetes       => 'Diabetes Management',
  WellnessGoal.mentalWellbeing=> 'Mental Wellbeing',
  WellnessGoal.generalFitness => 'General Fitness',
  WellnessGoal.nutrition      => 'Nutrition',
};

String wellnessGoalEmoji(WellnessGoal g) => switch (g) {
  WellnessGoal.sleep          => '😴',
  WellnessGoal.weightLoss     => '⚖️',
  WellnessGoal.anxiety        => '🧘',
  WellnessGoal.dementiaRisk   => '🧠',
  WellnessGoal.heartHealth    => '❤️',
  WellnessGoal.chronicPain    => '💊',
  WellnessGoal.diabetes       => '🩸',
  WellnessGoal.mentalWellbeing=> '🌱',
  WellnessGoal.generalFitness => '🏃',
  WellnessGoal.nutrition      => '🥗',
};

// ── Group ─────────────────────────────────────────────────────────────────────

class Group {
  final String id;
  final String name;
  final String? description;
  final WellnessGoal goalCategory;
  final int memberCount;
  final String createdBy;
  final DateTime createdAt;
  final bool isAnonymousAllowed;

  const Group({
    required this.id,
    required this.name,
    this.description,
    required this.goalCategory,
    required this.memberCount,
    required this.createdBy,
    required this.createdAt,
    this.isAnonymousAllowed = true,
  });

  factory Group.fromMap(String id, Map<String, dynamic> m) => Group(
    id: id,
    name: m['name'] as String,
    description: m['description'] as String?,
    goalCategory: WellnessGoal.values[m['goalCategory'] as int],
    memberCount: (m['memberCount'] as int?) ?? 0,
    createdBy: m['createdBy'] as String,
    createdAt: DateTime.parse(m['createdAt'] as String),
    isAnonymousAllowed: (m['isAnonymousAllowed'] as bool?) ?? true,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'goalCategory': goalCategory.index,
    'memberCount': memberCount,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'isAnonymousAllowed': isAnonymousAllowed,
  };
}

// ── GroupMember ───────────────────────────────────────────────────────────────

class GroupMember {
  final String groupId;
  final String userId; // stored in doc for querying; also the doc ID
  final String alias;
  final DateTime joinedAt;

  const GroupMember({
    required this.groupId,
    required this.userId,
    required this.alias,
    required this.joinedAt,
  });

  factory GroupMember.fromMap(String userId, Map<String, dynamic> m) =>
      GroupMember(
        groupId: m['groupId'] as String,
        userId: userId,
        alias: m['alias'] as String,
        joinedAt: DateTime.parse(m['joinedAt'] as String),
      );

  Map<String, dynamic> toMap() => {
    'groupId': groupId,
    'userId': userId, // stored for collectionGroup queries
    'alias': alias,
    'joinedAt': joinedAt.toIso8601String(),
  };
}

// ── GroupActivity ─────────────────────────────────────────────────────────────
// userId is intentionally absent from activity documents.
// Only the anonymous alias is stored so anonymity is enforced at data layer.

class GroupActivity {
  final String id;
  final String groupId;
  final String alias;
  final GroupPostType postType;
  final String activityText;
  final DateTime timestamp;

  const GroupActivity({
    required this.id,
    required this.groupId,
    required this.alias,
    required this.postType,
    required this.activityText,
    required this.timestamp,
  });

  factory GroupActivity.fromMap(String id, Map<String, dynamic> m) =>
      GroupActivity(
        id: id,
        groupId: m['groupId'] as String,
        alias: m['alias'] as String,
        postType: GroupPostType.values[(m['postType'] as int?) ?? 0],
        activityText: m['activityText'] as String,
        timestamp: DateTime.parse(m['timestamp'] as String),
      );

  Map<String, dynamic> toMap() => {
    'groupId': groupId,
    'alias': alias,
    'postType': postType.index,
    'activityText': activityText,
    'timestamp': timestamp.toIso8601String(),
    // NOTE: userId is deliberately NOT included here.
    // Firestore rules enforce this absence on writes.
  };
}
