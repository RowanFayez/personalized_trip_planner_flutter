import 'package:json_annotation/json_annotation.dart';

part 'routes_request_dto.g.dart';

@JsonSerializable()
class RoutesRequestDto {
  @JsonKey(name: 'start_lat')
  final double startLat;

  @JsonKey(name: 'start_lon')
  final double startLon;

  @JsonKey(name: 'end_lat')
  final double endLat;

  @JsonKey(name: 'end_lon')
  final double endLon;

  /// Optional: max walking time constraint (minutes).
  @JsonKey(name: 'max_walking_time_minutes')
  final int? maxWalkingTimeMinutes;

  /// Optional: preference such as "fastest", "cheapest", "simplest", "less_walking".
  final String? priority;

  /// Optional: allowed modes (e.g. ["microbus","tram","walking"]).
  final List<String>? modes;

  /// Optional: backend may support avoiding transfers.
  @JsonKey(name: 'avoid_transfers')
  final bool? avoidTransfers;

  const RoutesRequestDto({
    required this.startLat,
    required this.startLon,
    required this.endLat,
    required this.endLon,
    this.maxWalkingTimeMinutes,
    this.priority,
    this.modes,
    this.avoidTransfers,
  });

  factory RoutesRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RoutesRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RoutesRequestDtoToJson(this);
}
