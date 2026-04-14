import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthCancelledException implements Exception {
  final String message;

  const AuthCancelledException([this.message = 'Sign-in cancelled']);

  @override
  String toString() => 'AuthCancelledException: $message';
}

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleInit;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Future<void> _ensureGoogleInitialized() {
    return _googleInit ??= _googleSignIn.initialize();
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithGoogle({
    bool forceAccountSelection = false,
  }) async {
    await _ensureGoogleInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'Google sign-in is not supported on this platform.',
      );
    }

    if (forceAccountSelection) {
      // Allow selecting a different account after logout.
      // Disconnect revokes authorization; if it fails, fall back to signOut.
      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {
          // Ignore Google sign-out issues; FirebaseAuth controls app session.
        }
      }
    }

    late final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const AuthCancelledException();
      }
      rethrow;
    }

    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    // End the app session first (this is the only awaited step so UI stays snappy).
    await _auth.signOut();

    // Clear Google authorization in the background so next login can switch accounts.
    // This can be slow on some devices; we avoid blocking the logout UX.
    unawaited(_clearGoogleAuthorization());
  }

  Future<void> _clearGoogleAuthorization() async {
    try {
      await _ensureGoogleInitialized();
    } catch (_) {
      // Ignore initialization failures.
    }

    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore; user is already signed out of Firebase.
      }
    }
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }
}
