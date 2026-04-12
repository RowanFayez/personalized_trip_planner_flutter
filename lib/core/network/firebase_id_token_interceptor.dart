import 'package:dio/dio.dart';

import '../services/auth_service.dart';

class FirebaseIdTokenInterceptor extends Interceptor {
  final AuthService _authService;

  FirebaseIdTokenInterceptor({required AuthService authService})
    : _authService = authService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Respect any existing auth header (for example, third-party services).
    final hasAuthHeader =
        options.headers.keys.any((k) => k.toLowerCase() == 'authorization');
    if (hasAuthHeader) {
      handler.next(options);
      return;
    }

    try {
      final token = await _authService.getIdToken();
      if (token != null && token.trim().isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // If token retrieval fails, continue without auth.
    }

    handler.next(options);
  }
}
