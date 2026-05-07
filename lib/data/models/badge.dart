import 'enums.dart';

class Badge {
  final String id;
  final String userId;
  final String periodDate;
  final BadgeType type;
  final String? label;
  final String source;
  final DateTime createdAt;

  Badge({
    required this.id, required this.userId, required this.periodDate,
    required this.type, this.label, required this.source, required this.createdAt,
  });

  factory Badge.fromMap(String id, Map<String,dynamic> m) => Badge(
    id: id, userId: m['userId'], periodDate: m['periodDate'],
    type: BadgeType.values[m['type']], label: m['label'],
    source: m['source'], createdAt: DateTime.parse(m['createdAt']),
  );

  Map<String,dynamic> toMap() => {
    'userId': userId, 'periodDate': periodDate, 'type': type.index,
    'label': label, 'source': source, 'createdAt': createdAt.toIso8601String(),
  };
}
