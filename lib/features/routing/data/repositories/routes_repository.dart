import 'package:nextstation/features/routing/domain/entities/routing_entities.dart';

import '../builders/routes_request_builder.dart';
import '../converters/journey_dto_converter.dart';
import '../remote/routes_api_service.dart';

/// Repository for route queries using the Railway journeys API.
/// Handles request building, API calls, and response conversion.
class RoutesRepository {
  final RoutesApiService _apiService;

  RoutesRepository({required RoutesApiService apiService}) : _apiService = apiService;

  /// Fetches routes from the backend API.
  /// Returns a list of Journey domain entities with decoded polylines.
  Future<List<Journey>> getRoutes(RoutesRequest request) async {
    final dto = RoutesRequestBuilder.build(request);
    final response = await _apiService.getRoutes(dto);
    
    return response.journeys
        .map((journeyDto) => JourneyDtoConverter.toDomain(journeyDto))
        .toList(growable: false);
  }
}
