import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/library_routine.dart';
import '../services/firebase_service.dart';

class LibraryRepo {
  final _col = Fb.col('library');

  Future<List<LibraryRoutine>> fetchAll() async {
    final q = await _col
        .orderBy('saves', descending: true)
        .limit(50)
        .get();
    return q.docs.map((d) => LibraryRoutine.fromMap(d.id, d.data())).toList();
  }

  Future<void> save(LibraryRoutine r) =>
      _col.doc(r.id).set(r.toMap(), SetOptions(merge: true));

  Future<void> incrementSaves(String id) =>
      _col.doc(id).update({'saves': FieldValue.increment(1)});
}
