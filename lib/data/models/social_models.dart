class Story {
  final String id;
  final String userId;
  final String content;
  final int likes;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.userId,
    required this.content,
    this.likes = 0,
    required this.createdAt,
  });

  factory Story.fromMap(String id, Map<String, dynamic> m) => Story(
    id: id,
    userId: m['userId'] ?? '',
    content: m['content'] ?? '',
    likes: m['likes'] ?? 0,
    createdAt: DateTime.parse(m['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'content': content,
    'likes': likes,
    'createdAt': createdAt.toIso8601String(),
  };
}

class CommunityPost {
  final String id;
  final String userId;
  final String title;
  final String body;
  final int likes;
  final int comments;
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.likes = 0,
    this.comments = 0,
    required this.createdAt,
  });

  factory CommunityPost.fromMap(String id, Map<String, dynamic> m) => CommunityPost(
    id: id,
    userId: m['userId'] ?? '',
    title: m['title'] ?? '',
    body: m['body'] ?? '',
    likes: m['likes'] ?? 0,
    comments: m['comments'] ?? 0,
    createdAt: DateTime.parse(m['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'body': body,
    'likes': likes,
    'comments': comments,
    'createdAt': createdAt.toIso8601String(),
  };
}
