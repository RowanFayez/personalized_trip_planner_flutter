import 'package:json_annotation/json_annotation.dart';

part 'routes_response_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class RoutesResponseDto {
  @JsonKey(name: 'num_journeys')
  final int numJourneys;

  final List<JourneyDto> journeys;

  @JsonKey(name: 'start_trips_found')
  final int? startTripsFound;

  @JsonKey(name: 'end_trips_found')
  final int? endTripsFound;

  @JsonKey(name: 'total_routes_found')
  final int? totalRoutesFound;

  final Object? error;

  const RoutesResponseDto({
    required this.numJourneys,
    required this.journeys,
    this.startTripsFound,
    this.endTripsFound,
    this.totalRoutesFound,
    this.error,
  });

  factory RoutesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RoutesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RoutesResponseDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JourneyDto {
  final JourneySummaryDto summary;
  final List<RouteLegDto> legs;

  @JsonKey(name: 'text_summary')
  final String? textSummary;

  final int? id;

  const JourneyDto({
    required this.summary,
    required this.legs,
    this.textSummary,
    this.id,
  });

  factory JourneyDto.fromJson(Map<String, dynamic> json) =>
      _$JourneyDtoFromJson(json);

  Map<String, dynamic> toJson() => _$JourneyDtoToJson(this);
}

@JsonSerializable()
class JourneySummaryDto {
  @JsonKey(name: 'total_time_minutes')
  final int totalTimeMinutes;

  @JsonKey(name: 'total_distance_meters')
  final int totalDistanceMeters;

  @JsonKey(name: 'walking_distance_meters')
  final int walkingDistanceMeters;

  final int transfers;
  final int cost;
  final List<String> modes;

  const JourneySummaryDto({
    required this.totalTimeMinutes,
    required this.totalDistanceMeters,
    required this.walkingDistanceMeters,
    required this.transfers,
    required this.cost,
    required this.modes,
  });

  factory JourneySummaryDto.fromJson(Map<String, dynamic> json) =>
      _$JourneySummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$JourneySummaryDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class RouteLegDto {
  final String type;

  @JsonKey(name: 'distance_meters')
  final int? distanceMeters;

  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;

  /// Path coordinates are returned as [lat, lon] pairs.
  @JsonKey(fromJson: _toDouble2D, toJson: _fromDouble2D)
  final List<List<double>>? path;

  // Trip-only fields
  @JsonKey(name: 'trip_id')
  final String? tripId;

  final String? mode;

  @JsonKey(name: 'route_short_name')
  final String? routeShortName;

  final String? headsign;
  final int? fare;

  final StopRefDto? from;
  final StopRefDto? to;

  @JsonKey(name: 'trip_ids')
  final List<String>? tripIds;

  // Transfer-only fields
  @JsonKey(name: 'from_trip_id')
  final String? fromTripId;

  @JsonKey(name: 'to_trip_id')
  final String? toTripId;

  @JsonKey(name: 'from_trip_name')
  final String? fromTripName;

  @JsonKey(name: 'to_trip_name')
  final String? toTripName;

  @JsonKey(name: 'end_stop_id')
  final int? endStopId;

  @JsonKey(name: 'walking_distance_meters')
  final int? walkingDistanceMeters;

  const RouteLegDto({
    required this.type,
    this.distanceMeters,
    this.durationMinutes,
    this.path,
    this.tripId,
    this.mode,
    this.routeShortName,
    this.headsign,
    this.fare,
    this.from,
    this.to,
    this.tripIds,
    this.fromTripId,
    this.toTripId,
    this.fromTripName,
    this.toTripName,
    this.endStopId,
    this.walkingDistanceMeters,
  });

  factory RouteLegDto.fromJson(Map<String, dynamic> json) =>
      _$RouteLegDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RouteLegDtoToJson(this);

  static List<List<double>>? _toDouble2D(dynamic value) {
    if (value is! List) return null;
    return value
        .whereType<List>()
        .map(
          (pair) => pair
              .whereType<num>()
              .take(2)
              .map((n) => n.toDouble())
              .toList(growable: false),
        )
        .where((pair) => pair.length == 2)
        .toList(growable: false);
  }

  static dynamic _fromDouble2D(List<List<double>>? value) => value;
}

@JsonSerializable()
class StopRefDto {
  @JsonKey(name: 'stop_id')
  final int stopId;

  final String name;

  /// [lat, lon]
  @JsonKey(fromJson: _toDouble1D, toJson: _fromDouble1D)
  final List<double> coord;

  const StopRefDto({
    required this.stopId,
    required this.name,
    required this.coord,
  });

  factory StopRefDto.fromJson(Map<String, dynamic> json) =>
      _$StopRefDtoFromJson(json);

  Map<String, dynamic> toJson() => _$StopRefDtoToJson(this);

  static List<double> _toDouble1D(dynamic value) {
    if (value is! List) return const [0, 0];
    final nums = value
        .whereType<num>()
        .take(2)
        .map((n) => n.toDouble())
        .toList();
    if (nums.length != 2) return const [0, 0];
    return List<double>.unmodifiable(nums);
  }

  static dynamic _fromDouble1D(List<double> value) => value;
}
