// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutesResponseDto _$RoutesResponseDtoFromJson(Map<String, dynamic> json) =>
    RoutesResponseDto(
      geometryEncoding: json['geometry_encoding'] as String?,
      selectedPriority: json['selected_priority'] as String?,
      weightsUsed: (json['weights_used'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      numJourneys: (json['num_journeys'] as num).toInt(),
      journeys: (json['journeys'] as List<dynamic>)
          .map((e) => JourneyDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      startTripsFound: (json['start_trips_found'] as num?)?.toInt(),
      endTripsFound: (json['end_trips_found'] as num?)?.toInt(),
      totalRoutesFound: (json['total_routes_found'] as num?)?.toInt(),
      totalAfterDedup: (json['total_after_dedup'] as num?)?.toInt(),
      error: json['error'],
    );

Map<String, dynamic> _$RoutesResponseDtoToJson(RoutesResponseDto instance) =>
    <String, dynamic>{
      'geometry_encoding': instance.geometryEncoding,
      'selected_priority': instance.selectedPriority,
      'weights_used': instance.weightsUsed,
      'num_journeys': instance.numJourneys,
      'journeys': instance.journeys.map((e) => e.toJson()).toList(),
      'start_trips_found': instance.startTripsFound,
      'end_trips_found': instance.endTripsFound,
      'total_routes_found': instance.totalRoutesFound,
      'total_after_dedup': instance.totalAfterDedup,
      'error': instance.error,
    };

JourneyDto _$JourneyDtoFromJson(Map<String, dynamic> json) => JourneyDto(
  summary: JourneySummaryDto.fromJson(json['summary'] as Map<String, dynamic>),
  legs: (json['legs'] as List<dynamic>)
      .map((e) => RouteLegDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  textSummary: json['text_summary'] as String?,
  textSummaryEn: json['text_summary_en'] as String?,
  id: (json['id'] as num?)?.toInt(),
  labels:
      (json['labels'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  labelsAr:
      (json['labels_ar'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
);

Map<String, dynamic> _$JourneyDtoToJson(JourneyDto instance) =>
    <String, dynamic>{
      'summary': instance.summary.toJson(),
      'legs': instance.legs.map((e) => e.toJson()).toList(),
      'text_summary': instance.textSummary,
      'text_summary_en': instance.textSummaryEn,
      'id': instance.id,
      'labels': instance.labels,
      'labels_ar': instance.labelsAr,
    };

JourneySummaryDto _$JourneySummaryDtoFromJson(
  Map<String, dynamic> json,
) => JourneySummaryDto(
  totalTimeMinutes: (json['total_time_minutes'] as num).toInt(),
  totalDistanceMeters: (json['total_distance_meters'] as num).toInt(),
  walkingDistanceMeters: (json['walking_distance_meters'] as num).toInt(),
  transitDistanceMeters: (json['transit_distance_meters'] as num?)?.toInt(),
  transfers: (json['transfers'] as num).toInt(),
  cost: (json['cost'] as num).toInt(),
  modesEn:
      (json['modes_en'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  modesAr:
      (json['modes_ar'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  mainStreetsEn:
      (json['main_streets_en'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  mainStreetsAr:
      (json['main_streets_ar'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
);

Map<String, dynamic> _$JourneySummaryDtoToJson(JourneySummaryDto instance) =>
    <String, dynamic>{
      'total_time_minutes': instance.totalTimeMinutes,
      'total_distance_meters': instance.totalDistanceMeters,
      'walking_distance_meters': instance.walkingDistanceMeters,
      'transit_distance_meters': instance.transitDistanceMeters,
      'transfers': instance.transfers,
      'cost': instance.cost,
      'modes_en': instance.modesEn,
      'modes_ar': instance.modesAr,
      'main_streets_en': instance.mainStreetsEn,
      'main_streets_ar': instance.mainStreetsAr,
    };

RouteLegDto _$RouteLegDtoFromJson(Map<String, dynamic> json) => RouteLegDto(
  type: json['type'] as String,
  distanceMeters: (json['distance_meters'] as num?)?.toInt(),
  durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
  polyline: json['polyline'] as String?,
  tripId: json['trip_id'] as String?,
  modeEn: json['mode_en'] as String?,
  modeAr: json['mode_ar'] as String?,
  routeShortName: json['route_short_name'] as String?,
  routeShortNameAr: json['route_short_name_ar'] as String?,
  headsign: json['headsign'] as String?,
  headsignAr: json['headsign_ar'] as String?,
  fare: (json['fare'] as num?)?.toInt(),
  from: json['from'] == null
      ? null
      : StopRefDto.fromJson(json['from'] as Map<String, dynamic>),
  to: json['to'] == null
      ? null
      : StopRefDto.fromJson(json['to'] as Map<String, dynamic>),
  tripIds: (json['trip_ids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  fromTripId: json['from_trip_id'] as String?,
  toTripId: json['to_trip_id'] as String?,
  fromTripName: json['from_trip_name'] as String?,
  fromTripNameAr: json['from_trip_name_ar'] as String?,
  toTripName: json['to_trip_name'] as String?,
  toTripNameAr: json['to_trip_name_ar'] as String?,
  endStopId: (json['end_stop_id'] as num?)?.toInt(),
  walkingDistanceMeters: (json['walking_distance_meters'] as num?)?.toInt(),
);

Map<String, dynamic> _$RouteLegDtoToJson(RouteLegDto instance) =>
    <String, dynamic>{
      'type': instance.type,
      'distance_meters': instance.distanceMeters,
      'duration_minutes': instance.durationMinutes,
      'polyline': instance.polyline,
      'trip_id': instance.tripId,
      'mode_en': instance.modeEn,
      'mode_ar': instance.modeAr,
      'route_short_name': instance.routeShortName,
      'route_short_name_ar': instance.routeShortNameAr,
      'headsign': instance.headsign,
      'headsign_ar': instance.headsignAr,
      'fare': instance.fare,
      'from': instance.from?.toJson(),
      'to': instance.to?.toJson(),
      'trip_ids': instance.tripIds,
      'from_trip_id': instance.fromTripId,
      'to_trip_id': instance.toTripId,
      'from_trip_name': instance.fromTripName,
      'from_trip_name_ar': instance.fromTripNameAr,
      'to_trip_name': instance.toTripName,
      'to_trip_name_ar': instance.toTripNameAr,
      'end_stop_id': instance.endStopId,
      'walking_distance_meters': instance.walkingDistanceMeters,
    };

StopRefDto _$StopRefDtoFromJson(Map<String, dynamic> json) => StopRefDto(
  stopId: (json['stop_id'] as num).toInt(),
  name: json['name'] as String,
  nameAr: json['name_ar'] as String?,
  coord: StopRefDto._toDouble1D(json['coord']),
);

Map<String, dynamic> _$StopRefDtoToJson(StopRefDto instance) =>
    <String, dynamic>{
      'stop_id': instance.stopId,
      'name': instance.name,
      'name_ar': instance.nameAr,
      'coord': StopRefDto._fromDouble1D(instance.coord),
    };
