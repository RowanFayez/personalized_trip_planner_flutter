import 'package:dio/dio.dart';

import 'api_constants.dart';

/// Retries requests that time out during Azure Container Apps cold starts.
///
/// Important characteristics:
/// - Only retries *specific* backend endpoints (routing + nearby trips).
/// - Only retries when a [CancelToken] is present so callers can stop polling
///   immediately (prevents zombie network calls).
/// - Retries forever (every [retryDelay]) until success or cancellation.
class ColdStartRetryInterceptor extends Interceptor {
  static const String _skipKey = '_cold_start_retry_skip';

  final Dio _dio;
  final Duration retryDelay;

  ColdStartRetryInterceptor({
    required Dio dio,
    this.retryDelay = const Duration(seconds: 10),
  }) : _dio = dio;

  bool _isTimeout(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  bool _isCancelled(RequestOptions options) {
    final token = options.cancelToken;
    return token != null && token.isCancelled;
  }

  bool _isColdStartEndpoint(RequestOptions options) {
    final path = options.path.toLowerCase();
    return path.contains(ApiConstants.routesEndpoint) ||
        path.contains(ApiConstants.nearbyTripsEndpoint);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_isTimeout(err)) {
      handler.next(err);
      return;
    }

    final options = err.requestOptions;

    // Prevent recursion when this interceptor triggers its own retry fetch.
    if (options.extra[_skipKey] == true) {
      handler.next(err);
      return;
    }

    // Only apply to the map actions affected by ACA cold start.
    if (!_isColdStartEndpoint(options)) {
      handler.next(err);
      return;
    }

    // Require a cancel token so UI actions can stop polling instantly.
    final cancelToken = options.cancelToken;
    if (cancelToken == null || cancelToken.isCancelled || _isCancelled(options)) {
      handler.next(err);
      return;
    }

    final updatedExtra = Map<String, dynamic>.from(options.extra);
    updatedExtra[_skipKey] = true;

    while (true) {
      // Keep the original request pending and the UI in loading state.
      await Future<void>.delayed(retryDelay);

      if (cancelToken.isCancelled || _isCancelled(options)) {
        handler.next(err);
        return;
      }

      final retryOptions = options.copyWith(extra: updatedExtra);

      try {
        final response = await _dio.fetch<dynamic>(retryOptions);
        handler.resolve(response);
        return;
      } on DioException catch (e) {
        if (CancelToken.isCancel(e) || e.type == DioExceptionType.cancel) {
          handler.next(e);
          return;
        }

        if (_isTimeout(e)) {
          // Continue polling.
          continue;
        }

        handler.next(e);
        return;
      }
    }
  }
}
