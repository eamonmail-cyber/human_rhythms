import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/routine.dart';
import '../services/firebase_service.dart';

class RoutinesRepo {
  final _col = Fb.col('routines');

  Future<List<Routine>> byUser(String userId) async {
    final q = await _col
        .where('userId', isEqualTo: userId)
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    return q.docs.map((d) => Routine.fromMap(d.id, d.data())).toList();
  }

  /// Re-assigns every routine owned by [oldUserId] to [newUserId] in a
  /// single batch write. Call this when the same user signs back in and
  /// their UID has changed (e.g. anonymous → authenticated account).
  Future<void> transferRoutines(String oldUserId, String newUserId) async {
    if (oldUserId == newUserId) return;
    final snap = await _col.where('userId', isEqualTo: oldUserId).get();
    if (snap.docs.isEmpty) return;
    final batch = Fb.db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'userId': newUserId,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit();
  }

  /// Returns routines for [userId]. If none are found and [previousUserId]
  /// is provided, migrates routines from [previousUserId] to [userId] first,
  /// then returns the result. This restores routines when a user signs back
  /// in under a new UID.
  Future<List<Routine>> byUserWithFallback(
      String userId, String? previousUserId) async {
    final routines = await byUser(userId);
    if (routines.isNotEmpty || previousUserId == null) return routines;
    await transferRoutines(previousUserId, userId);
    return byUser(userId);
  }

  Future<void> save(Routine r) =>
      _col.doc(r.id).set(r.toMap(), SetOptions(merge: true));

  Future<void> delete(String id) => _col.doc(id).delete();
}
