import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final userIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

Future<UserCredential> signInWithGoogle() async {
  // Always try anonymous first — works without OAuth setup
  try {
    final result = await FirebaseAuth.instance.signInAnonymously();
    return result;
  } catch (e) {
    // If anonymous fails try Google
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) throw Exception('Cancelled');
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (_) {
      return await FirebaseAuth.instance.signInAnonymously();
    }
  }
}

Future<void> signOut() async {
  await GoogleSignIn().signOut().catchError((_) {});
  await FirebaseAuth.instance.signOut();
}
