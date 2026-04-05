import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge.dart';
import '../models/enums.dart';
import '../services/firebase_service.dart';

class ChallengesRepo {
  CollectionReference<Map<String, dynamic>> get _challenges =>
      Fb.col('challenges');

  CollectionReference<Map<String, dynamic>> _participants(
          String challengeId) =>
      _challenges.doc(challengeId).collection('participants');

  CollectionReference<Map<String, dynamic>> _checkins(
          String challengeId) =>
      _challenges.doc(challengeId).collection('checkins');

  // ── Challenges ───────────────────────────────────────────────────────────────

  Future<List<Challenge>> getActive({int limit = 20}) async {
    final snap = await _challenges
        .where('active', isEqualTo: true)
        .orderBy('participantCount', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => Challenge.fromMap(d.id, d.data()))
        .toList();
  }

  Future<List<Challenge>> getByCategory(RoutineCategory cat,
      {int limit = 20}) async {
    final snap = await _challenges
        .where('active', isEqualTo: true)
        .where('category', isEqualTo: cat.index)
        .orderBy('participantCount', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => Challenge.fromMap(d.id, d.data()))
        .toList();
  }

  Future<Challenge?> getChallenge(String id) async {
    final doc = await _challenges.doc(id).get();
    if (!doc.exists) return null;
    return Challenge.fromMap(doc.id, doc.data()!);
  }

  Future<List<Challenge>> challengesForUser(String userId) async {
    final snaps = await Fb.db
        .collectionGroup('participants')
        .where('userId', isEqualTo: userId)
        .get();
    if (snaps.docs.isEmpty) return [];
    final ids = snaps.docs
        .map((d) => d.reference.parent.parent!.id)
        .toSet()
        .toList();
    final docs = await Future.wait(ids.map((id) => _challenges.doc(id).get()));
    return docs
        .where((d) => d.exists)
        .map((d) => Challenge.fromMap(d.id, d.data()!))
        .toList();
  }

  // ── Participation ────────────────────────────────────────────────────────────

  Future<bool> isParticipant(String challengeId, String userId) async {
    final doc = await _participants(challengeId).doc(userId).get();
    return doc.exists;
  }

  Future<ChallengeParticipant?> getParticipant(
      String challengeId, String userId) async {
    final doc = await _participants(challengeId).doc(userId).get();
    if (!doc.exists) return null;
    return ChallengeParticipant.fromMap(userId, doc.data()!);
  }

  /// Joins the challenge, adds a routine to the user's diary, and increments count.
  Future<ChallengeParticipant> joinChallenge({
    required String challengeId,
    required String userId,
    required String challengeTitle,
    required RoutineCategory category,
  }) async {
    final alias = challengeAliasFor(userId);
    final now = DateTime.now();
    final participant = ChallengeParticipant(
      userId: userId,
      challengeId: challengeId,
      alias: alias,
      joinedAt: now,
    );
    final batch = Fb.db.batch();

    // Add participant record
    batch.set(_participants(challengeId).doc(userId), participant.toMap());

    // Increment participant count
    batch.update(_challenges.doc(challengeId),
        {'participantCount': FieldValue.increment(1)});

    // Auto-add a routine to the user's personal routines collection
    final routineRef = Fb.col('routines').doc();
    batch.set(routineRef, {
      'userId': userId,
      'title': challengeTitle,
      'category': category.index,
      'frequency': 'daily',
      'targetTime': null,
      'captureIntensity': false,
      'captureDuration': false,
      'captureNote': true,
      'active': true,
      'version': 1,
      'challengeId': challengeId, // link back to challenge
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });

    await batch.commit();
    return participant;
  }

  Future<void> leaveChallenge(String challengeId, String userId) async {
    final batch = Fb.db.batch();
    batch.delete(_participants(challengeId).doc(userId));
    batch.update(_challenges.doc(challengeId),
        {'participantCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  // ── Check-in ─────────────────────────────────────────────────────────────────

  /// Records a daily check-in.  Updates streak and totalCheckins on the
  /// participant document.  Returns updated participant.
  Future<ChallengeParticipant> checkIn({
    required String challengeId,
    required String userId,
    String? note,
  }) async {
    final existing = await getParticipant(challengeId, userId);
    if (existing == null) {
      throw Exception('Not a participant in this challenge');
    }
    if (existing.checkedInToday) {
      return existing; // idempotent
    }

    final now = DateTime.now();
    final alias = challengeAliasFor(userId);

    // Recalculate streak
    final daysSinceLastCheckin = existing.lastCheckin == null
        ? 999
        : now.difference(existing.lastCheckin!).inDays;
    final newStreak =
        daysSinceLastCheckin <= 1 ? existing.currentStreak + 1 : 1;
    final updated = existing.copyWith(
      currentStreak: newStreak,
      totalCheckins: existing.totalCheckins + 1,
      lastCheckin: now,
    );

    // Write checkin doc + update participant + recalculate challenge completion
    final checkinRef = _checkins(challengeId).doc();
    final batch = Fb.db.batch();
    batch.set(
      checkinRef,
      ChallengeCheckin(
        id: checkinRef.id,
        challengeId: challengeId,
        alias: alias,
        date: now,
        note: note,
      ).toMap(),
    );
    batch.set(_participants(challengeId).doc(userId), updated.toMap());
    await batch.commit();

    // Update global completionRate asynchronously (best-effort, not in main batch)
    _updateCompletionRate(challengeId);

    return updated;
  }

  Future<void> _updateCompletionRate(String challengeId) async {
    try {
      final challenge = await getChallenge(challengeId);
      if (challenge == null || challenge.durationDays == 0) return;
      final snap = await _participants(challengeId).get();
      if (snap.docs.isEmpty) return;
      double total = 0;
      for (final doc in snap.docs) {
        final p = ChallengeParticipant.fromMap(doc.id, doc.data());
        total += p.totalCheckins / challenge.durationDays;
      }
      final rate = total / snap.docs.length;
      await _challenges
          .doc(challengeId)
          .update({'completionRate': rate.clamp(0.0, 1.0)});
    } catch (_) {
      // Non-critical — don't surface to user
    }
  }

  Future<void> setLeaderboardVisibility(
      String challengeId, String userId, bool show) async {
    await _participants(challengeId)
        .doc(userId)
        .update({'showOnLeaderboard': show});
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────────

  Future<List<ChallengeParticipant>> getLeaderboard(
      String challengeId) async {
    final snap = await _participants(challengeId)
        .where('showOnLeaderboard', isEqualTo: true)
        .orderBy('totalCheckins', descending: true)
        .limit(20)
        .get();
    return snap.docs
        .map((d) => ChallengeParticipant.fromMap(d.id, d.data()))
        .toList();
  }

  // ── Community feed ────────────────────────────────────────────────────────────

  Future<List<ChallengeCheckin>> getCommunityFeed(String challengeId,
      {int limit = 30}) async {
    final snap = await _checkins(challengeId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => ChallengeCheckin.fromMap(d.id, d.data()))
        .toList();
  }
}
