import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles all authentication — Google Sign-In + Firebase Auth.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Current Firebase user (null if signed out).
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Whether the user is currently signed in.
  bool get isSignedIn => _auth.currentUser != null;

  /// Sign in with Google.
  ///
  /// Returns the [UserCredential] on success, null if cancelled.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow.
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign-In: user cancelled');
        return null;
      }

      debugPrint('Google Sign-In: got user ${googleUser.email}');

      // Obtain the auth details.
      final googleAuth = await googleUser.authentication;
      debugPrint('Google Sign-In: got auth tokens (accessToken: ${googleAuth.accessToken != null}, idToken: ${googleAuth.idToken != null})');

      // Create a credential for Firebase.
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase.
      final result = await _auth.signInWithCredential(credential);
      debugPrint('Google Sign-In: Firebase auth success, uid=${result.user?.uid}');
      return result;
    } catch (e, stack) {
      debugPrint('Google Sign-In ERROR: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  /// Sign out of both Google and Firebase.
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Delete the Firebase Auth account.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _googleSignIn.signOut();
    await user.delete();
  }
}
