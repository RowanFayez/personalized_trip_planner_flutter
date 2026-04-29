import 'package:nextstation/features/routing/domain/entities/routing_entities.dart';
import '../models/routes_request_dto.dart';

/// Builds routing requests from domain entities with preference filtering.
/// Handles conversion of domain filters to DTO format.
class RoutesRequestBuilder {
  /// Builds a RoutesRequestDto from a RoutesRequest domain entity.
  /// Applies filters and weights for the backend API.
  static RoutesRequestDto build(RoutesRequest request) {
    return RoutesRequestDto(
      startLat: request.startLat,
      startLon: request.startLon,
      endLat: request.endLat,
      endLon: request.endLon,
      maxTransfers: request.maxTransfers,
      walkingCutoff: request.walkingCutoff,
      priority: request.priority,
      topK: request.topK,
      weights: RouteWeightsDto(
        time: request.weights.time,
        cost: request.weights.cost,
        walk: request.weights.walk,
        transfer: request.weights.transfer,
      ),
      filters: RouteFiltersDto(
        modes: ModeFilterDto(
          include: List<String>.unmodifiable(request.filters.modes.include),
          exclude: List<String>.unmodifiable(request.filters.modes.exclude),
          includeMatch: request.filters.modes.includeMatch,
        ),
        mainStreets: ModeFilterDto(
          include: List<String>.unmodifiable(
            request.filters.mainStreets.include,
          ),
          exclude: List<String>.unmodifiable(
            request.filters.mainStreets.exclude,
          ),
          includeMatch: request.filters.mainStreets.includeMatch,
        ),
      ),
    );
  }
}
