import 'package:nextstation/features/routing/domain/entities/routing_entities.dart';
import '../models/routes_request_dto.dart';

/// Builds routing requests from domain entities with preference filtering.
/// Handles conversion of domain filters to DTO format.
class RoutesRequestBuilder {
  static const int _metersPerMinute = 80;

  /// Builds a RoutesRequestDto from a RoutesRequest domain entity.
  /// Applies filters for the backend API.
  static RoutesRequestDto build(RoutesRequest request) {
    final walkingCutoffMeters = request.walkingCutoffMinutes *
        _metersPerMinute;

    return RoutesRequestDto(
      startLat: request.startLat,
      startLon: request.startLon,
      endLat: request.endLat,
      endLon: request.endLon,
      maxTransfers: request.maxTransfers,
      walkingCutoff: walkingCutoffMeters,
      priority: request.priority,
      topK: request.topK,
      filters: RouteFiltersDto(
        modes: ModeFilterDto(
          include: const <String>[],
          exclude: List<String>.unmodifiable(request.filters.modes.exclude),
          includeMatch: request.filters.modes.includeMatch,
        ),
        mainStreets: ModeFilterDto(
          include: const <String>[],
          exclude: List<String>.unmodifiable(
            request.filters.mainStreets.exclude,
          ),
          includeMatch: request.filters.mainStreets.includeMatch,
        ),
      ),
    );
  }
}
