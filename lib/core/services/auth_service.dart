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

  Future<void>? _refreshInFlight;

  Timer? _proactiveRefreshTimer;
  StreamSubscription<AuthState>? _authStateSub;
  bool _didInit = false;
  DateTime? _lastProactiveRefreshAttemptAt;

  // Refresh a bit before actual expiry to avoid mid-request 401s.
  // Azure Container Apps cold-start can delay request handling for minutes.
  // Keep a generous buffer so the token is still valid when the backend wakes.
  static const Duration _refreshLeeway = Duration(minutes: 5);

  // Proactively refresh in the background before reaching the leeway window.
  static const Duration _proactiveRefreshAdvance = Duration(minutes: 10);
  static const Duration _proactiveMinDelay = Duration(seconds: 30);

  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client,
      _auth = (client ?? Supabase.instance.client).auth;

  /// Call once at app startup.
  ///
  /// Schedules proactive refresh and listens for auth state changes to keep the
  /// schedule up to date.
  void init() {
    if (_didInit) return;
    _didInit = true;

    _scheduleProactiveRefresh();

    _authStateSub = _auth.onAuthStateChange.listen((state) {
      if (state.session == null) {
        _cancelProactiveRefreshTimer();
      } else {
        _scheduleProactiveRefresh();
      }
    });
  }

  void dispose() {
    _cancelProactiveRefreshTimer();
    _authStateSub?.cancel();
    _authStateSub = null;
  }

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

      _scheduleProactiveRefresh();
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
    _cancelProactiveRefreshTimer();
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    Session? session = _auth.currentSession;

    if (forceRefresh || session == null || _isExpiredOrExpiringSoon(session)) {
      await _refreshSessionSafely();
      session = _auth.currentSession;
    }

    // Keep background refresh schedule aligned with the latest session.
    _scheduleProactiveRefresh();

    final token = session?.accessToken;
    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return token;
  }

  bool _isExpiredOrExpiringSoon(Session session) {
    // gotrue exposes `expiresAt` as epoch seconds (parsed from JWT exp claim).
    final expiresAt = session.expiresAt;
    if (expiresAt == null) {
      // Fallback to gotrue's built-in check (includes a small margin).
      return session.isExpired;
    }

    final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    return DateTime.now().add(_refreshLeeway).isAfter(expiry);
  }

  DateTime? _sessionExpiry(Session session) {
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
  }

  void _cancelProactiveRefreshTimer() {
    _proactiveRefreshTimer?.cancel();
    _proactiveRefreshTimer = null;
    _lastProactiveRefreshAttemptAt = null;
  }

  void _scheduleProactiveRefresh() {
    _proactiveRefreshTimer?.cancel();
    _proactiveRefreshTimer = null;

    final session = _auth.currentSession;
    if (session == null) return;

    final expiry = _sessionExpiry(session);
    if (expiry == null) return;

    final refreshAt = expiry.subtract(_proactiveRefreshAdvance);
    final now = DateTime.now();
    var delay = refreshAt.difference(now);
    if (delay < _proactiveMinDelay) {
      delay = _proactiveMinDelay;
    }

    _proactiveRefreshTimer = Timer(delay, () {
      unawaited(_handleProactiveRefreshTimer());
    });
  }

  Future<void> _handleProactiveRefreshTimer() async {
    final session = _auth.currentSession;
    if (session == null) {
      _cancelProactiveRefreshTimer();
      return;
    }

    final now = DateTime.now();
    final last = _lastProactiveRefreshAttemptAt;
    if (last != null && now.difference(last) < _proactiveMinDelay) {
      _scheduleProactiveRefresh();
      return;
    }
    _lastProactiveRefreshAttemptAt = now;

    await _refreshSessionSafely();
    _scheduleProactiveRefresh();
  }

  Future<void> _refreshSessionSafely() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = () async {
      try {
        await _client.auth.refreshSession();
      } catch (_) {
        // Ignore refresh errors; callers can still use the current token if any.
      }
    }();

    _refreshInFlight = future;

    return future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }

      // Refresh likely changed session expiry; keep schedule in sync.
      _scheduleProactiveRefresh();
    });
  }
}
