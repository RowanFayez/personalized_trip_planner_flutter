import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_factory.dart';
import '../models/routes_request_dto.dart';
import '../models/routes_response_dto.dart';
import '../remote/routes_api_service.dart';

class RoutesRemoteDataSource {
  final RoutesApiService _api;

  RoutesRemoteDataSource({RoutesApiService? api, Dio? dio})
      : _api = api ??
            RoutesApiService(
              dio ?? DioFactory.create(baseUrl: ApiConstants.baseUrl),
              baseUrl: ApiConstants.baseUrl,
            );

  Future<ApiResult<RoutesResponseDto>> getRoutes(RoutesRequestDto request) {
    return safeApiCall(() => _api.getRoutes(request));
  }
}
