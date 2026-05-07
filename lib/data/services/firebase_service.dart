import 'package:cloud_firestore/cloud_firestore.dart';

class Fb {
  static final db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> col(String path) =>
      db.collection(path);
}
