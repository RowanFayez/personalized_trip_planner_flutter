import '../../domain/entities/geo_point.dart';
import '../../domain/entities/routing_entities.dart';
import '../models/routes_request_dto.dart';
import '../models/routes_response_dto.dart';

extension RoutesRequestDtoMapper on RoutesRequest {
  RoutesRequestDto toDto() {
    return RoutesRequestDto(
      startLat: startLat,
      startLon: startLon,
      endLat: endLat,
      endLon: endLon,
      maxWalkingTimeMinutes: maxWalkingTimeMinutes,
      priority: priority,
      modes: modes,
      avoidTransfers: avoidTransfers,
    );
  }
}

extension RoutesResponseMapper on RoutesResponseDto {
  RoutingResult toEntity() {
    return RoutingResult(
      numJourneys: numJourneys,
      journeys: journeys.map((j) => j.toEntity()).toList(growable: false),
    );
  }
}

extension JourneyMapper on JourneyDto {
  Journey toEntity() {
    return Journey(
      summary: summary.toEntity(),
      legs: legs.map((l) => l.toEntity()).toList(growable: false),
    );
  }
}

extension JourneySummaryMapper on JourneySummaryDto {
  JourneySummary toEntity() {
    return JourneySummary(
      totalTimeMinutes: totalTimeMinutes,
      totalDistanceMeters: totalDistanceMeters,
      walkingDistanceMeters: walkingDistanceMeters,
      transfers: transfers,
      cost: cost,
      modes: List<String>.unmodifiable(modes),
    );
  }
}

extension RouteLegMapper on RouteLegDto {
  RouteLeg toEntity() {
    final points = (path ?? const <List<double>>[])
        .where((p) => p.length == 2)
        .map((p) => GeoPoint(lat: p[0], lon: p[1]))
        .toList(growable: false);

    return RouteLeg(
      type: type,
      distanceMeters: distanceMeters,
      durationMinutes: durationMinutes,
      path: points,
      tripId: tripId,
      mode: mode,
      routeShortName: routeShortName,
      headsign: headsign,
      fare: fare,
      from: from?.toEntity(),
      to: to?.toEntity(),
    );
  }
}

extension StopRefMapper on StopRefDto {
  StopRef toEntity() {
    final lat = coord.isNotEmpty ? coord[0] : 0.0;
    final lon = coord.length > 1 ? coord[1] : 0.0;
    return StopRef(
      stopId: stopId,
      name: name,
      coord: GeoPoint(lat: lat, lon: lon),
    );
  }
}
