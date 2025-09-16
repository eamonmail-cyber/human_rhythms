import '../models/entry.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EntriesRepo {
  final _col = Fb.col('entries');

  Future<List<Entry>> byUserAndDate(String userId, String date) async {
    final q = await _col
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: date)
        .get();
    return q.docs.map((d) => Entry.fromMap(d.id, d.data())).toList();
  }

  Future<List<Entry>> byUserAndDates(String userId, List<String> dates) async {
    if (dates.isEmpty) return [];
    final q = await _col
        .where('userId', isEqualTo: userId)
        .where('date', whereIn: dates)
        .get();
    return q.docs.map((d) => Entry.fromMap(d.id, d.data())).toList();
  }

  Future<void> upsert(Entry e) =>
      _col.doc(e.id).set(e.toMap(), SetOptions(merge: true));
}
