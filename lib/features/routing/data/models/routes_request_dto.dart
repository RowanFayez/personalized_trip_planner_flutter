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

  @JsonKey(name: 'top_k')
  final int topK;

  @JsonKey(name: 'restricted_modes')
  final List<String> restrictedModes;

  const RoutesRequestDto({
    required this.startLat,
    required this.startLon,
    required this.endLat,
    required this.endLon,
    required this.maxTransfers,
    required this.walkingCutoff,
    required this.topK,
    required this.restrictedModes,
  });

  factory RoutesRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RoutesRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RoutesRequestDtoToJson(this);
}
