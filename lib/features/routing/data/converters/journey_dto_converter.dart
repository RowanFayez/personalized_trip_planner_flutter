import '../../domain/entities/geo_point.dart';
import '../../domain/entities/routing_entities.dart';
import '../mappers/polyline_decoder.dart';
import '../models/routes_response_dto.dart';

/// Converts journey DTOs to domain entities with polyline decoding.
/// Handles Arabic field preferences and geometry decoding.
class JourneyDtoConverter {
  /// Converts a JourneyDto to a Journey domain entity.
  static Journey toDomain(JourneyDto dto) {
    return Journey(
      summary: _summarytoDomain(dto.summary),
      legs: dto.legs.map((l) => _legToDomain(l)).toList(growable: false),
      textSummary: dto.textSummary,
      textSummaryEn: dto.textSummaryEn,
      id: dto.id,
      labels: List<String>.unmodifiable(dto.labels),
      labelsAr: List<String>.unmodifiable(dto.labelsAr),
    );
  }

  static JourneySummary _summarytoDomain(JourneySummaryDto dto) {
    return JourneySummary(
      totalTimeMinutes: dto.totalTimeMinutes,
      totalDistanceMeters: dto.totalDistanceMeters,
      walkingDistanceMeters: dto.walkingDistanceMeters,
      transitDistanceMeters: dto.transitDistanceMeters,
      transfers: dto.transfers,
      cost: dto.cost,
      modesEn: List<String>.unmodifiable(dto.modesEn),
      modesAr: List<String>.unmodifiable(dto.modesAr),
      mainStreetsEn: List<String>.unmodifiable(dto.mainStreetsEn),
      mainStreetsAr: List<String>.unmodifiable(dto.mainStreetsAr),
    );
  }

  static RouteLeg _legToDomain(RouteLegDto dto) {
    // Decode polyline5 into GeoPoints
    final encodedPoints = PolylineDecoder.decode(dto.polyline);
    final points = encodedPoints
        .map((coord) => GeoPoint(lat: coord.$1, lon: coord.$2))
        .toList(growable: false);

    return RouteLeg(
      type: dto.type,
      distanceMeters: dto.distanceMeters,
      durationMinutes: dto.durationMinutes,
      path: points,
      tripId: dto.tripId,
      mode: dto.modeEn,
      modeAr: dto.modeAr,
      routeShortName: dto.routeShortName,
      routeShortNameAr: dto.routeShortNameAr,
      headsign: dto.headsign,
      headsignAr: dto.headsignAr,
      fare: dto.fare,
      from: dto.from != null ? _stopRefToDomain(dto.from!) : null,
      to: dto.to != null ? _stopRefToDomain(dto.to!) : null,
      tripIds: dto.tripIds != null ? List<String>.unmodifiable(dto.tripIds!) : null,
      fromTripId: dto.fromTripId,
      toTripId: dto.toTripId,
      fromTripName: dto.fromTripName,
      fromTripNameAr: dto.fromTripNameAr,
      toTripName: dto.toTripName,
      toTripNameAr: dto.toTripNameAr,
      endStopId: dto.endStopId,
      walkingDistanceMeters: dto.walkingDistanceMeters,
    );
  }

  static StopRef _stopRefToDomain(StopRefDto dto) {
    final lat = dto.coord.isNotEmpty ? dto.coord[0] : 0.0;
    final lon = dto.coord.length > 1 ? dto.coord[1] : 0.0;
    return StopRef(
      stopId: dto.stopId,
      name: dto.name,
      nameAr: dto.nameAr,
      coord: GeoPoint(lat: lat, lon: lon),
    );
  }
}
