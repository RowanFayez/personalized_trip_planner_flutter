import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class SupabaseAuthInterceptor extends Interceptor {
  final AuthService _authService;

  SupabaseAuthInterceptor({required AuthService authService})
    : _authService = authService;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Respect any existing auth header (for example, third-party services).
    final hasAuthHeader = options.headers.keys.any(
      (k) => k.toLowerCase() == 'authorization',
    );
    if (hasAuthHeader) {
      if (kDebugMode) {
        debugPrint(
          '[Auth] ${options.method} ${options.uri} using pre-existing Authorization header',
        );
      }
      handler.next(options);
      return;
    }

    try {
      final token = await _authService.getIdToken();
      if (token != null && token.trim().isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        if (kDebugMode) {
          debugPrint(
            '[Auth] ${options.method} ${options.uri} attached Supabase bearer token',
          );
        }
      } else if (kDebugMode) {
        debugPrint(
          '[Auth] ${options.method} ${options.uri} has no Supabase session token',
        );
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
          '[Auth] ${options.method} ${options.uri} failed to retrieve Supabase token',
        );
      }
    }

    handler.next(options);
  }
}
