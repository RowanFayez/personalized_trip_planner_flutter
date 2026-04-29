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
      maxTransfers: maxTransfers,
      walkingCutoff: walkingCutoff,
      priority: priority,
      topK: topK,
      weights: RouteWeightsDto(
        time: weights.time,
        cost: weights.cost,
        walk: weights.walk,
        transfer: weights.transfer,
      ),
      filters: RouteFiltersDto(
        modes: ModeFilterDto(
          include: List<String>.unmodifiable(filters.modes.include),
          exclude: List<String>.unmodifiable(filters.modes.exclude),
          includeMatch: filters.modes.includeMatch,
        ),
        mainStreets: ModeFilterDto(
          include: List<String>.unmodifiable(filters.mainStreets.include),
          exclude: List<String>.unmodifiable(filters.mainStreets.exclude),
          includeMatch: filters.mainStreets.includeMatch,
        ),
      ),
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
      textSummary: textSummary,
      textSummaryEn: textSummaryEn,
      id: id,
      labels: List<String>.unmodifiable(labels),
      labelsAr: List<String>.unmodifiable(labelsAr),
    );
  }
}

extension JourneySummaryMapper on JourneySummaryDto {
  JourneySummary toEntity() {
    return JourneySummary(
      totalTimeMinutes: totalTimeMinutes,
      totalDistanceMeters: totalDistanceMeters,
      walkingDistanceMeters: walkingDistanceMeters,
      transitDistanceMeters: transitDistanceMeters,
      transfers: transfers,
      cost: cost,
      modesEn: List<String>.unmodifiable(modesEn),
      modesAr: List<String>.unmodifiable(modesAr),
      mainStreetsEn: List<String>.unmodifiable(mainStreetsEn),
      mainStreetsAr: List<String>.unmodifiable(mainStreetsAr),
    );
  }
}

extension RouteLegMapper on RouteLegDto {
  RouteLeg toEntity() {
    final points = _decodePolyline5(polyline);

    return RouteLeg(
      type: type,
      distanceMeters: distanceMeters,
      durationMinutes: durationMinutes,
      path: points,
      tripId: tripId,
      mode: modeEn,
      modeAr: modeAr,
      routeShortName: routeShortName,
      routeShortNameAr: routeShortNameAr,
      headsign: headsign,
      headsignAr: headsignAr,
      fare: fare,
      from: from?.toEntity(),
      to: to?.toEntity(),
      tripIds: tripIds == null ? null : List<String>.unmodifiable(tripIds!),
      fromTripId: fromTripId,
      toTripId: toTripId,
      fromTripName: fromTripName,
      fromTripNameAr: fromTripNameAr,
      toTripName: toTripName,
      toTripNameAr: toTripNameAr,
      endStopId: endStopId,
      walkingDistanceMeters: walkingDistanceMeters,
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
      nameAr: nameAr,
      coord: GeoPoint(lat: lat, lon: lon),
    );
  }
}

List<GeoPoint> _decodePolyline5(String? encoded) {
  final value = (encoded ?? '').trim();
  if (value.isEmpty) return const <GeoPoint>[];

  final points = <GeoPoint>[];
  var index = 0;
  var lat = 0;
  var lon = 0;

  try {
    while (index < value.length) {
      final latResult = _decodePolylineComponent(value, startIndex: index);
      index = latResult.nextIndex;
      lat += latResult.delta;

      if (index >= value.length) break;

      final lonResult = _decodePolylineComponent(value, startIndex: index);
      index = lonResult.nextIndex;
      lon += lonResult.delta;

      points.add(GeoPoint(lat: lat / 1e5, lon: lon / 1e5));
    }
  } catch (_) {
    // If decoding fails, return best-effort points collected so far.
  }

  return List<GeoPoint>.unmodifiable(points);
}

({int delta, int nextIndex}) _decodePolylineComponent(
  String encoded, {
  required int startIndex,
}) {
  var result = 0;
  var shift = 0;
  var index = startIndex;

  while (index < encoded.length) {
    final b = encoded.codeUnitAt(index) - 63;
    index++;
    result |= (b & 0x1f) << shift;
    shift += 5;
    if (b < 0x20) break;
  }

  final delta = (result & 1) == 1 ? ~(result >> 1) : (result >> 1);
  return (delta: delta, nextIndex: index);
}
