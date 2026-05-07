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

  Future<void> save(Routine r) =>
      _col.doc(r.id).set(r.toMap(), SetOptions(merge: true));

  Future<void> delete(String id) => _col.doc(id).delete();
}
