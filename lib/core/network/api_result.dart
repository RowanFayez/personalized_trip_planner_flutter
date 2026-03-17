import 'package:dio/dio.dart';

import 'api_error_handeler.dart';
import 'api_error_model.dart';

class ApiResult<T> {
  final T? data;
  final ApiErrorModel? error;

  const ApiResult._({this.data, this.error});

  bool get isSuccess => error == null;

  factory ApiResult.success(T data) => ApiResult._(data: data);

  factory ApiResult.failure(ApiErrorModel error) => ApiResult._(error: error);

  R when<R>({
    required R Function(T data) success,
    required R Function(ApiErrorModel error) failure,
  }) {
    if (isSuccess) return success(data as T);
    return failure(error as ApiErrorModel);
  }
}

Future<ApiResult<T>> safeApiCall<T>(Future<T> Function() request) async {
  try {
    final result = await request();
    return ApiResult.success(result);
  } on DioException catch (e) {
    return ApiResult.failure(ApiErrorHandler.fromDioException(e));
  } catch (e) {
    return ApiResult.failure(ApiErrorModel(message: e.toString()));
  }
}
