import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final userIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

// ── Input sanitisation ────────────────────────────────────────────────────────

/// Strip HTML tags, trim whitespace, cap at 200 characters.
String sanitise(String input) {
  final stripped = input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  return stripped.length > 200 ? stripped.substring(0, 200) : stripped;
}

// ── Lockout tracking ──────────────────────────────────────────────────────────

class _LockoutInfo {
  int count = 0;
  DateTime? lockedUntil;
}

final _lockouts = <String, _LockoutInfo>{};
const _maxAttempts = 5;
const _lockoutDuration = Duration(minutes: 15);

/// Returns a lockout message if the email is currently locked, null if allowed.
String? checkLockout(String email) {
  final info = _lockouts[email.toLowerCase()];
  if (info?.lockedUntil == null) return null;
  if (DateTime.now().isBefore(info!.lockedUntil!)) {
    final mins = info.lockedUntil!.difference(DateTime.now()).inMinutes + 1;
    return 'Too many failed attempts. Try again in $mins minute${mins == 1 ? '' : 's'}.';
  }
  return null;
}

void _recordFailure(String email) {
  final info = _lockouts.putIfAbsent(email.toLowerCase(), _LockoutInfo.new);
  info.count++;
  if (info.count >= _maxAttempts) {
    info.lockedUntil = DateTime.now().add(_lockoutDuration);
    info.count = 0;
  }
}

void _clearFailures(String email) => _lockouts.remove(email.toLowerCase());

// ── Firebase error → friendly message ────────────────────────────────────────

String friendlyAuthError(String code) {
  switch (code) {
    case 'user-not-found':         return 'No account found with this email.';
    case 'wrong-password':         return 'Incorrect password. Please try again.';
    case 'invalid-credential':     return 'Incorrect email or password.';
    case 'email-already-in-use':   return 'An account already exists with this email.';
    case 'weak-password':          return 'Password must be at least 6 characters.';
    case 'invalid-email':          return 'Please enter a valid email address.';
    case 'too-many-requests':      return 'Too many attempts. Please try again later.';
    case 'network-request-failed': return 'Network error. Check your connection.';
    case 'user-disabled':          return 'This account has been disabled.';
    case 'operation-not-allowed':  return 'This sign-in method is not enabled.';
    default:                       return 'Something went wrong. Please try again.';
  }
}

// ── Auth methods ──────────────────────────────────────────────────────────────

/// Register a new user with display name, email and password.
/// Throws a human-readable [Exception] on failure.
Future<void> registerWithEmail(String name, String email, String password) async {
  try {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: sanitise(email),
      password: password,
    );
    await cred.user?.updateDisplayName(sanitise(name));
  } on FirebaseAuthException catch (e) {
    throw Exception(friendlyAuthError(e.code));
  }
}

/// Sign in with email + password. Enforces lockout after [_maxAttempts] failures.
/// Throws a human-readable [Exception] on failure.
Future<UserCredential> signInWithEmail(String email, String password) async {
  final clean = sanitise(email);
  final locked = checkLockout(clean);
  if (locked != null) throw Exception(locked);
  try {
    final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: clean,
      password: password,
    );
    _clearFailures(clean);
    return result;
  } on FirebaseAuthException catch (e) {
    _recordFailure(clean);
    throw Exception(friendlyAuthError(e.code));
  }
}

/// Send a password-reset email.
/// Throws a human-readable [Exception] on failure.
Future<void> resetPassword(String email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: sanitise(email));
  } on FirebaseAuthException catch (e) {
    throw Exception(friendlyAuthError(e.code));
  }
}

/// Sign in with Google. Falls back to anonymous for testing.
Future<UserCredential> signInWithGoogle() async {
  try {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Sign-in cancelled');
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

Future<void> signOut() async {
  await GoogleSignIn().signOut();
  await FirebaseAuth.instance.signOut();
}
