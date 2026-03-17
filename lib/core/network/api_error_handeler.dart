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
				return ApiErrorModel(
					statusCode: statusCode,
					message: _messageFromStatusCode(statusCode) ?? 'Server error.',
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
}

