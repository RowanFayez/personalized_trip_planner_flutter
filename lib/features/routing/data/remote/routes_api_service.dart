import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_constants.dart';
import '../models/routes_request_dto.dart';
import '../models/routes_response_dto.dart';

part 'routes_api_service.g.dart';

@RestApi(baseUrl: ApiConstants.baseUrl)
abstract class RoutesApiService {
  factory RoutesApiService(Dio dio, {String? baseUrl}) = _RoutesApiService;

  @POST(ApiConstants.routesEndpoint)
  Future<RoutesResponseDto> getRoutes(@Body() RoutesRequestDto body);
}
