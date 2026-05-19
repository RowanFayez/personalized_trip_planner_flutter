import 'dart:async';

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

  static const String _googleRedirectTo =
      'io.supabase.nextstation://login-callback';

  Stream<User?> authStateChanges() => _auth.onAuthStateChange.map(
    (state) => state.session?.user,
  );

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
      final didLaunch = await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _googleRedirectTo,
        queryParams: forceAccountSelection ? {'prompt': 'select_account'} : {},
      );

      // If the OAuth flow cannot be launched, treat it like a cancellation.
      if (!didLaunch) {
        throw const AuthCancelledException();
      }
    } on AuthCancelledException {
      rethrow;
    } on AuthException catch (e) {
      // Supabase uses browser-based auth. If the user closes the flow early,
      // different platforms surface different error codes/messages.
      final msg = e.message.toLowerCase();
      if (msg.contains('cancel') || msg.contains('canceled')) {
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
