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
      priority: json['priority'] as String,
      topK: (json['top_k'] as num).toInt(),
      filters: RouteFiltersDto.fromJson(
        json['filters'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$RoutesRequestDtoToJson(RoutesRequestDto instance) =>
    <String, dynamic>{
      'start_lat': instance.startLat,
      'start_lon': instance.startLon,
      'end_lat': instance.endLat,
      'end_lon': instance.endLon,
      'max_transfers': instance.maxTransfers,
      'walking_cutoff': instance.walkingCutoff,
      'priority': instance.priority,
      'top_k': instance.topK,
      'filters': instance.filters,
    };

RouteFiltersDto _$RouteFiltersDtoFromJson(Map<String, dynamic> json) =>
    RouteFiltersDto(
      modes: ModeFilterDto.fromJson(json['modes'] as Map<String, dynamic>),
      mainStreets: ModeFilterDto.fromJson(
        json['main_streets'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$RouteFiltersDtoToJson(RouteFiltersDto instance) =>
    <String, dynamic>{
      'modes': instance.modes.toJson(),
      'main_streets': instance.mainStreets.toJson(),
    };

ModeFilterDto _$ModeFilterDtoFromJson(
  Map<String, dynamic> json,
) => ModeFilterDto(
  include: (json['include'] as List<dynamic>).map((e) => e as String).toList(),
  exclude: (json['exclude'] as List<dynamic>).map((e) => e as String).toList(),
  includeMatch: json['include_match'] as String,
);

Map<String, dynamic> _$ModeFilterDtoToJson(ModeFilterDto instance) =>
    <String, dynamic>{
      'include': instance.include,
      'exclude': instance.exclude,
      'include_match': instance.includeMatch,
    };
