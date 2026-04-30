import 'package:json_annotation/json_annotation.dart';

part 'routes_request_dto.g.dart';

@JsonSerializable(includeIfNull: false)
class RoutesRequestDto {
  @JsonKey(name: 'start_lat')
  final double startLat;

  @JsonKey(name: 'start_lon')
  final double startLon;

  @JsonKey(name: 'end_lat')
  final double endLat;

  @JsonKey(name: 'end_lon')
  final double endLon;

  @JsonKey(name: 'max_transfers')
  final int maxTransfers;

  @JsonKey(name: 'walking_cutoff')
  final int walkingCutoff;

  /// Backend priority: fastest | cheapest | balanced
  final String priority;

  @JsonKey(name: 'top_k')
  final int topK;

  final RouteFiltersDto filters;

  const RoutesRequestDto({
    required this.startLat,
    required this.startLon,
    required this.endLat,
    required this.endLon,
    required this.maxTransfers,
    required this.walkingCutoff,
    required this.priority,
    required this.topK,
    required this.filters,
  });

  factory RoutesRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RoutesRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RoutesRequestDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class RouteFiltersDto {
  final ModeFilterDto modes;

  @JsonKey(name: 'main_streets')
  final ModeFilterDto mainStreets;

  const RouteFiltersDto({required this.modes, required this.mainStreets});

  factory RouteFiltersDto.fromJson(Map<String, dynamic> json) =>
      _$RouteFiltersDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RouteFiltersDtoToJson(this);
}

@JsonSerializable()
class ModeFilterDto {
  final List<String> include;
  final List<String> exclude;

  @JsonKey(name: 'include_match')
  final String includeMatch;

  const ModeFilterDto({
    required this.include,
    required this.exclude,
    required this.includeMatch,
  });

  factory ModeFilterDto.fromJson(Map<String, dynamic> json) =>
      _$ModeFilterDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ModeFilterDtoToJson(this);
}
