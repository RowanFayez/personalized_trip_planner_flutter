// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutesRequestDto _$RoutesRequestDtoFromJson(Map<String, dynamic> json) =>
    RoutesRequestDto(
      startLat: (json['start_lat'] as num).toDouble(),
      startLon: (json['start_lon'] as num).toDouble(),
      endLat: (json['end_lat'] as num).toDouble(),
      endLon: (json['end_lon'] as num).toDouble(),
      maxTransfers: (json['max_transfers'] as num).toInt(),
      walkingCutoff: (json['walking_cutoff'] as num).toInt(),
      topK: (json['top_k'] as num).toInt(),
      restrictedModes: (json['restricted_modes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$RoutesRequestDtoToJson(RoutesRequestDto instance) =>
    <String, dynamic>{
      'start_lat': instance.startLat,
      'start_lon': instance.startLon,
      'end_lat': instance.endLat,
      'end_lon': instance.endLon,
      'max_transfers': instance.maxTransfers,
      'walking_cutoff': instance.walkingCutoff,
      'top_k': instance.topK,
      'restricted_modes': instance.restrictedModes,
    };
