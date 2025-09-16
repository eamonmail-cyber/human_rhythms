import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

// Run in a Flutter environment (e.g., via a debug button). For illustration.

Future<void> seedDummy() async {
  await Firebase.initializeApp();
  final auth = FirebaseAuth.instance;
  final user = await auth.signInAnonymously();
  final uid = user.user!.uid;
  final db = FirebaseFirestore.instance;

  final routines = [
    {"title":"Morning Swim","cat":0,"time":"06:30"},
    {"title":"Walk","cat":1,"time":"18:00"},
    {"title":"Meditation","cat":3,"time":"07:00"}
  ];
  for (final r in routines) {
    final id = db.collection('routines').doc().id;
    await db.collection('routines').doc(id).set({
      "userId": uid,
      "title": r["title"],
      "category": r["cat"],
      "targetTime": r["time"],
      "frequency": "daily",
      "daysOfWeek": null,
      "captureIntensity": true,
      "captureDuration": true,
      "captureNote": true,
      "active": true,
      "version": 1,
      "createdAt": DateTime.now().toIso8601String(),
      "updatedAt": DateTime.now().toIso8601String(),
    });
  }
}
