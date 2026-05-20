import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthCancelledException implements Exception {
  final String message;

  const AuthCancelledException([this.message = 'Sign-in cancelled']);

  @override
  String toString() => 'AuthCancelledException: $message';
}

class AuthService {
  final SupabaseClient _client;
  final GoTrueClient _auth;

  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client,
      _auth = (client ?? Supabase.instance.client).auth;

  Stream<User?> authStateChanges() =>
      _auth.onAuthStateChange.map((state) => state.session?.user);

  User? get currentUser => _auth.currentUser;

  String? get userPhotoUrl {
    final meta = currentUser?.userMetadata;
    final value = meta == null ? null : meta['avatar_url'];
    return value is String ? value : null;
  }

  String? get userEmail => currentUser?.email;

  String? get displayName {
    final meta = currentUser?.userMetadata;
    final value = meta == null ? null : meta['full_name'];
    return value is String ? value : null;
  }

  String? get uid => currentUser?.id;

  Future<void> signInWithGoogle({bool forceAccountSelection = false}) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '981043656979-mocnt1v3j42jsvoa0c6keuej88brt8k0.apps.googleusercontent.com',
      );

      if (forceAccountSelection) {
        await googleSignIn.signOut();
      }

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthCancelledException();
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw Exception('Google Sign-In failed: no idToken');
      }

      await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
    } on AuthCancelledException {
      rethrow;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('sign_in_canceled') ||
          msg.contains('sign_in_cancelled') ||
          msg.contains('cancel')) {
        throw const AuthCancelledException();
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      try {
        await _client.auth.refreshSession();
      } catch (_) {
        // Ignore refresh errors; we can still return the current token if any.
      }
    }

    return _auth.currentSession?.accessToken;
  }
}
