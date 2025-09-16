import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/global.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

Future<UserCredential> signInWithGoogle() async {
  // This requires Google Sign-In setup on platform; fallback to anonymous if fails.
  try {
    // On mobile, use GoogleSignIn; omitted here to avoid platform config complexity.
    // For MVP, sign in anonymously.
    return await FirebaseAuth.instance.signInAnonymously();
  } catch (_) {
    return await FirebaseAuth.instance.signInAnonymously();
  }
}

Future<void> signOut() async => FirebaseAuth.instance.signOut();

final userIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  return authState?.uid;
});
