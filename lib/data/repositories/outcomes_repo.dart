import '../models/outcome.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OutcomesRepo {
  final _col = Fb.col('outcomes');

  Future<Outcome?> getForDate(String userId, String date) async {
    final q = await _col.where('userId', isEqualTo: userId).where('date', isEqualTo: date).limit(1).get();
    if (q.docs.isEmpty) return null;
    final d = q.docs.first; return Outcome.fromMap(d.id, d.data());
  }

  Future<void> upsert(Outcome o) => _col.doc(o.id).set(o.toMap(), SetOptions(merge: true));
}
