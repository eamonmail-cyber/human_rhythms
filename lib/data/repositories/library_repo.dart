import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/library_routine.dart';
import '../models/social_models.dart';

class LibraryRepo {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _routines => _db.collection('library_routines');
  CollectionReference get _profiles => _db.collection('public_profiles');
  CollectionReference get _follows  => _db.collection('follows');
  CollectionReference get _stories  => _db.collection('routine_stories');

  Future<List<LibraryRoutine>> getRoutines({
    String? category,
    String? goal,
    bool expertsOnly = false,
    int limit = 20,
  }) async {
    Query q = _routines.where('active', isEqualTo: true);
    if (category != null) q = q.where('category', isEqualTo: category);
    if (expertsOnly) q = q.where('isVerifiedExpert', isEqualTo: true);
    q = q.orderBy('adoptedCount', descending: true).limit(limit);
    final snap = await q.get();
    return snap.docs.map((d) =>
        LibraryRoutine.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();
  }

  Future<void> adoptRoutine({
    required String libraryRoutineId,
    required String userId,
    required LibraryRoutine routine,
  }) async {
    final batch = _db.batch();
    final personalRef = _db.collection('routines').doc();
    batch.set(personalRef, {
      'userId': userId,
      'title': routine.title,
      'category': routine.category,
      'frequency': routine.frequency,
      'targetTime': routine.targetTime,
      'captureIntensity': true,
      'captureDuration': true,
      'captureNote': true,
      'active': true,
      'version': 1,
      'adoptedFromLibraryId': libraryRoutineId,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    batch.update(_routines.doc(libraryRoutineId),
        {'adoptedCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> publishRoutine(LibraryRoutine routine) async {
    await _routines.doc(routine.id).set(routine.toMap());
  }

  Future<void> followUser(String followerId, String followingId) async {
    final batch = _db.batch();
    batch.set(_follows.doc('${followerId}_$followingId'), Follow(
      followerId: followerId,
      followingId: followingId,
      createdAt: DateTime.now(),
    ).toMap());
    batch.update(_profiles.doc(followerId),
        {'followingCount': FieldValue.increment(1)});
    batch.update(_profiles.doc(followingId),
        {'followersCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> unfollowUser(String followerId, String followingId) async {
    final batch = _db.batch();
    batch.delete(_follows.doc('${followerId}_$followingId'));
    batch.update(_profiles.doc(followerId),
        {'followingCount': FieldValue.increment(-1)});
    batch.update(_profiles.doc(followingId),
        {'followersCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    final doc = await _follows.doc('${followerId}_$followingId').get();
    return doc.exists;
  }

  Future<List<PublicProfile>> getFollowing(String userId) async {
    final snap = await _follows
        .where('followerId', isEqualTo: userId).get();
    final ids = snap.docs
        .map((d) => (d.data() as Map)['followingId'] as String).toList();
    if (ids.isEmpty) return [];
    final profiles = await Future.wait(
        ids.map((id) => _profiles.doc(id).get()));
    return profiles
        .where((d) => d.exists)
        .map((d) => PublicProfile.fromMap(
            d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<LibraryRoutine>> getRoutinesByUser(String userId) async {
    final snap = await _routines
        .where('authorId', isEqualTo: userId)
        .where('active', isEqualTo: true).get();
    return snap.docs.map((d) =>
        LibraryRoutine.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<PublicProfile?> getProfile(String userId) async {
    final doc = await _profiles.doc(userId).get();
    if (!doc.exists) return null;
    return PublicProfile.fromMap(
        doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<void> upsertProfile(PublicProfile profile) async {
    await _profiles.doc(profile.userId)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<List<PublicProfile>> searchProfiles({
    int? ageMin, int? ageMax,
  }) async {
    Query q = _profiles;
    if (ageMin != null) q = q.where('age', isGreaterThanOrEqualTo: ageMin);
    if (ageMax != null) q = q.where('age', isLessThanOrEqualTo: ageMax);
    q = q.orderBy('followersCount', descending: true).limit(20);
    final snap = await q.get();
    return snap.docs.map((d) =>
        PublicProfile.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<RoutineStory>> getStories({int limit = 20}) async {
    final snap = await _stories
        .orderBy('likesCount', descending: true)
        .limit(limit).get();
    return snap.docs.map((d) =>
        RoutineStory.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> publishStory(RoutineStory story) async {
    await _stories.doc(story.id).set(story.toMap());
  }

  Future<void> likeStory(String storyId) async {
    await _stories.doc(storyId)
        .update({'likesCount': FieldValue.increment(1)});
  }
}
