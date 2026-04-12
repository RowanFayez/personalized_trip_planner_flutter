import 'package:dio/dio.dart';

import 'api_error_model.dart';

class ApiErrorHandler {
  ApiErrorHandler._();

  static ApiErrorModel fromDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiErrorModel(
          statusCode: statusCode,
          message: 'Connection timeout. Please try again.',
          data: data,
        );
      case DioExceptionType.badCertificate:
        return ApiErrorModel(
          statusCode: statusCode,
          message: 'Bad SSL certificate.',
          data: data,
        );
      case DioExceptionType.cancel:
        return ApiErrorModel(
          statusCode: statusCode,
          message: 'Request cancelled.',
          data: data,
        );
      case DioExceptionType.connectionError:
        return ApiErrorModel(
          statusCode: statusCode,
          message: 'No internet connection.',
          data: data,
        );
      case DioExceptionType.badResponse:
        final serverDetails = _extractServerDetails(data);
        final base = _messageFromStatusCode(statusCode) ?? 'Server error.';
        final message = serverDetails == null || serverDetails.isEmpty
            ? base
            : (statusCode == 422
                  ? '$base ${_truncate(serverDetails)}'
                  : '${_truncate(serverDetails)}');
        return ApiErrorModel(
          statusCode: statusCode,
          message: message,
          data: data,
        );
      case DioExceptionType.unknown:
        return ApiErrorModel(
          statusCode: statusCode,
          message: 'Unexpected error occurred.',
          data: data,
        );
    }
  }

  static String? _messageFromStatusCode(int? statusCode) {
    if (statusCode == null) return null;
    switch (statusCode) {
      case 400:
        return 'Bad request.';
      case 401:
        return 'Unauthorized.';
      case 403:
        return 'Forbidden.';
      case 404:
        return 'Not found.';
      case 409:
        return 'Conflict.';
      case 422:
        return 'Validation error.';
      case 500:
        return 'Internal server error.';
      case 503:
        return 'Service unavailable.';
      default:
        return null;
    }
  }

  static String? _extractServerDetails(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      final trimmed = data.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      dynamic candidate =
          map['detail'] ??
          map['message'] ??
          map['error'] ??
          map['errors'] ??
          map['msg'] ??
          map['reason'];

      if (candidate == null) {
        // Common FastAPI/pydantic style: {"detail": [{"loc":...,"msg":...}]}
        candidate = map['detail'];
      }

      if (candidate is List) {
        final parts = candidate
            .map((e) {
              if (e is Map) {
                final msg = e['msg'] ?? e['message'] ?? e['detail'];
                final loc = e['loc'];
                if (msg is String && loc != null) {
                  return '$loc: $msg';
                }
                if (msg is String) return msg;
              }
              return e?.toString();
            })
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(growable: false);
        if (parts.isEmpty) return null;
        return parts.join(' | ');
      }

      if (candidate is Map) {
        // Field errors map: { field: ["msg1", "msg2"], ... }
        final entries = candidate.entries
            .map((e) => '${e.key}: ${e.value}')
            .toList(growable: false);
        return entries.isEmpty ? null : entries.join(' | ');
      }

      if (candidate != null) {
        final asString = candidate.toString().trim();
        return asString.isEmpty ? null : asString;
      }
    }

    return data.toString().trim().isEmpty ? null : data.toString().trim();
  }

  static String _truncate(String value, {int max = 180}) {
    final trimmed = value.trim();
    if (trimmed.length <= max) return trimmed;
    return '${trimmed.substring(0, max)}…';
  }
}
