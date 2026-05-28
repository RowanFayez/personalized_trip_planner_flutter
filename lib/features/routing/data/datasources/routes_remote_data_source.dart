import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_result.dart';
import '../models/routes_request_dto.dart';
import '../models/routes_response_dto.dart';

class RoutesRemoteDataSource {
  final Dio _dio;

  RoutesRemoteDataSource({Dio? dio}) : _dio = dio ?? GetIt.I<Dio>();

  Future<ApiResult<RoutesResponseDto>> getRoutes(
    RoutesRequestDto request, {
    CancelToken? cancelToken,
  }) {
    return safeApiCall(() async {
      final response = await _dio.post<dynamic>(
        ApiConstants.routesEndpoint,
        data: request.toJson(),
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return RoutesResponseDto.fromJson(data);
      }
      if (data is Map) {
        return RoutesResponseDto.fromJson(Map<String, dynamic>.from(data));
      }

      throw StateError('Unexpected routes response type: ${data.runtimeType}');
    });
  }
}
