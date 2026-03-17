// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutesRequestDto _$RoutesRequestDtoFromJson(
  Map<String, dynamic> json,
) => RoutesRequestDto(
  startLat: (json['start_lat'] as num).toDouble(),
  startLon: (json['start_lon'] as num).toDouble(),
  endLat: (json['end_lat'] as num).toDouble(),
  endLon: (json['end_lon'] as num).toDouble(),
  maxWalkingTimeMinutes: (json['max_walking_time_minutes'] as num?)?.toInt(),
  priority: json['priority'] as String?,
  modes: (json['modes'] as List<dynamic>?)?.map((e) => e as String).toList(),
  avoidTransfers: json['avoid_transfers'] as bool?,
);

Map<String, dynamic> _$RoutesRequestDtoToJson(RoutesRequestDto instance) =>
    <String, dynamic>{
      'start_lat': instance.startLat,
      'start_lon': instance.startLon,
      'end_lat': instance.endLat,
      'end_lon': instance.endLon,
      'max_walking_time_minutes': instance.maxWalkingTimeMinutes,
      'priority': instance.priority,
      'modes': instance.modes,
      'avoid_transfers': instance.avoidTransfers,
    };
