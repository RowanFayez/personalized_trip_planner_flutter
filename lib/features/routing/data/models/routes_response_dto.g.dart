// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutesResponseDto _$RoutesResponseDtoFromJson(Map<String, dynamic> json) =>
    RoutesResponseDto(
      numJourneys: (json['num_journeys'] as num).toInt(),
      journeys: (json['journeys'] as List<dynamic>)
          .map((e) => JourneyDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      startTripsFound: (json['start_trips_found'] as num?)?.toInt(),
      endTripsFound: (json['end_trips_found'] as num?)?.toInt(),
      totalRoutesFound: (json['total_routes_found'] as num?)?.toInt(),
      error: json['error'],
    );

Map<String, dynamic> _$RoutesResponseDtoToJson(RoutesResponseDto instance) =>
    <String, dynamic>{
      'num_journeys': instance.numJourneys,
      'journeys': instance.journeys.map((e) => e.toJson()).toList(),
      'start_trips_found': instance.startTripsFound,
      'end_trips_found': instance.endTripsFound,
      'total_routes_found': instance.totalRoutesFound,
      'error': instance.error,
    };

JourneyDto _$JourneyDtoFromJson(Map<String, dynamic> json) => JourneyDto(
  summary: JourneySummaryDto.fromJson(json['summary'] as Map<String, dynamic>),
  legs: (json['legs'] as List<dynamic>)
      .map((e) => RouteLegDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  textSummary: json['text_summary'] as String?,
  id: (json['id'] as num?)?.toInt(),
);

Map<String, dynamic> _$JourneyDtoToJson(JourneyDto instance) =>
    <String, dynamic>{
      'summary': instance.summary.toJson(),
      'legs': instance.legs.map((e) => e.toJson()).toList(),
      'text_summary': instance.textSummary,
      'id': instance.id,
    };

JourneySummaryDto _$JourneySummaryDtoFromJson(Map<String, dynamic> json) =>
    JourneySummaryDto(
      totalTimeMinutes: (json['total_time_minutes'] as num).toInt(),
      totalDistanceMeters: (json['total_distance_meters'] as num).toInt(),
      walkingDistanceMeters: (json['walking_distance_meters'] as num).toInt(),
      transfers: (json['transfers'] as num).toInt(),
      cost: (json['cost'] as num).toInt(),
      modes: (json['modes'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$JourneySummaryDtoToJson(JourneySummaryDto instance) =>
    <String, dynamic>{
      'total_time_minutes': instance.totalTimeMinutes,
      'total_distance_meters': instance.totalDistanceMeters,
      'walking_distance_meters': instance.walkingDistanceMeters,
      'transfers': instance.transfers,
      'cost': instance.cost,
      'modes': instance.modes,
    };

RouteLegDto _$RouteLegDtoFromJson(Map<String, dynamic> json) => RouteLegDto(
  type: json['type'] as String,
  distanceMeters: (json['distance_meters'] as num?)?.toInt(),
  durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
  path: RouteLegDto._toDouble2D(json['path']),
  tripId: json['trip_id'] as String?,
  mode: json['mode'] as String?,
  routeShortName: json['route_short_name'] as String?,
  headsign: json['headsign'] as String?,
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
  toTripName: json['to_trip_name'] as String?,
  endStopId: (json['end_stop_id'] as num?)?.toInt(),
  walkingDistanceMeters: (json['walking_distance_meters'] as num?)?.toInt(),
);

Map<String, dynamic> _$RouteLegDtoToJson(RouteLegDto instance) =>
    <String, dynamic>{
      'type': instance.type,
      'distance_meters': instance.distanceMeters,
      'duration_minutes': instance.durationMinutes,
      'path': RouteLegDto._fromDouble2D(instance.path),
      'trip_id': instance.tripId,
      'mode': instance.mode,
      'route_short_name': instance.routeShortName,
      'headsign': instance.headsign,
      'fare': instance.fare,
      'from': instance.from?.toJson(),
      'to': instance.to?.toJson(),
      'trip_ids': instance.tripIds,
      'from_trip_id': instance.fromTripId,
      'to_trip_id': instance.toTripId,
      'from_trip_name': instance.fromTripName,
      'to_trip_name': instance.toTripName,
      'end_stop_id': instance.endStopId,
      'walking_distance_meters': instance.walkingDistanceMeters,
    };

StopRefDto _$StopRefDtoFromJson(Map<String, dynamic> json) => StopRefDto(
  stopId: (json['stop_id'] as num).toInt(),
  name: json['name'] as String,
  coord: StopRefDto._toDouble1D(json['coord']),
);

Map<String, dynamic> _$StopRefDtoToJson(StopRefDto instance) =>
    <String, dynamic>{
      'stop_id': instance.stopId,
      'name': instance.name,
      'coord': StopRefDto._fromDouble1D(instance.coord),
    };
