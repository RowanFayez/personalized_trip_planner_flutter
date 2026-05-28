import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class SupabaseAuthInterceptor extends Interceptor {
  static const String _retriedKey = '_retried';
  static const String _attachedKey = '_supabase_auth_attached';

  final AuthService _authService;
  final Dio _dio;

  SupabaseAuthInterceptor({required AuthService authService, required Dio dio})
    : _authService = authService,
      _dio = dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Respect any existing auth header (for example, third-party services).
    // However, if the header was attached by this interceptor, keep managing it
    // across retries (so 401 refresh + cold-start retries remain reliable).
    final hasAuthHeader = options.headers.keys.any(
      (k) => k.toLowerCase() == 'authorization',
    );
    final attachedByUs = options.extra[_attachedKey] == true;
    if (hasAuthHeader && !attachedByUs) {
      options.extra[_attachedKey] = false;
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
        options.extra[_attachedKey] = true;
        if (kDebugMode) {
          debugPrint(
            '[Auth] ${options.method} ${options.uri} attached Supabase bearer token',
          );
        }
      } else {
        options.extra[_attachedKey] = false;
        if (kDebugMode) {
          debugPrint(
            '[Auth] ${options.method} ${options.uri} has no Supabase session token',
          );
        }
      }
    } catch (_) {
      options.extra[_attachedKey] = false;
      if (kDebugMode) {
        debugPrint(
          '[Auth] ${options.method} ${options.uri} failed to retrieve Supabase token',
        );
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final requestOptions = err.requestOptions;

    if (status != 401 || requestOptions.extra[_retriedKey] == true) {
      handler.next(err);
      return;
    }

    final hasAuthHeader = requestOptions.headers.keys.any(
      (k) => k.toLowerCase() == 'authorization',
    );
    final attachedByUs = requestOptions.extra[_attachedKey] == true;
    if (hasAuthHeader && !attachedByUs) {
      // Respect third-party Authorization headers.
      handler.next(err);
      return;
    }

    if (err.type == DioExceptionType.cancel) {
      handler.next(err);
      return;
    }

    try {
      final newToken = await _authService.getIdToken(forceRefresh: true);
      if (newToken == null || newToken.trim().isEmpty) {
        handler.next(err);
        return;
      }

      final updatedHeaders = Map<String, dynamic>.from(requestOptions.headers);
      updatedHeaders['Authorization'] = 'Bearer $newToken';

      final updatedExtra = Map<String, dynamic>.from(requestOptions.extra);
      updatedExtra[_retriedKey] = true;
      updatedExtra[_attachedKey] = true;

      final retryOptions = requestOptions.copyWith(
        headers: updatedHeaders,
        extra: updatedExtra,
      );

      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Auth] ${requestOptions.method} ${requestOptions.uri} retry after 401 failed: $e',
        );
      }
      // Forward the real DioException (often a timeout during cold-start), so
      // downstream interceptors/state can handle it correctly.
      handler.next(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Auth] ${requestOptions.method} ${requestOptions.uri} retry after 401 failed: $e',
        );
      }
      handler.next(err);
    }
  }
}
