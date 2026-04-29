import 'package:json_annotation/json_annotation.dart';

part 'routes_response_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class RoutesResponseDto {
  @JsonKey(name: 'geometry_encoding')
  final String? geometryEncoding;

  @JsonKey(name: 'selected_priority')
  final String? selectedPriority;

  @JsonKey(name: 'weights_used')
  final Map<String, double>? weightsUsed;

  @JsonKey(name: 'num_journeys')
  final int numJourneys;

  final List<JourneyDto> journeys;

  @JsonKey(name: 'start_trips_found')
  final int? startTripsFound;

  @JsonKey(name: 'end_trips_found')
  final int? endTripsFound;

  @JsonKey(name: 'total_routes_found')
  final int? totalRoutesFound;

  @JsonKey(name: 'total_after_dedup')
  final int? totalAfterDedup;

  final Object? error;

  const RoutesResponseDto({
    this.geometryEncoding,
    this.selectedPriority,
    this.weightsUsed,
    required this.numJourneys,
    required this.journeys,
    this.startTripsFound,
    this.endTripsFound,
    this.totalRoutesFound,
    this.totalAfterDedup,
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

  @JsonKey(name: 'text_summary_en')
  final String? textSummaryEn;

  final int? id;

  @JsonKey(defaultValue: <String>[], name: 'labels')
  final List<String> labels;

  @JsonKey(defaultValue: <String>[], name: 'labels_ar')
  final List<String> labelsAr;

  const JourneyDto({
    required this.summary,
    required this.legs,
    this.textSummary,
    this.textSummaryEn,
    this.id,
    this.labels = const <String>[],
    this.labelsAr = const <String>[],
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

  @JsonKey(name: 'transit_distance_meters')
  final int? transitDistanceMeters;

  final int transfers;
  final int cost;

  @JsonKey(name: 'modes_en', defaultValue: <String>[])
  final List<String> modesEn;

  @JsonKey(name: 'modes_ar', defaultValue: <String>[])
  final List<String> modesAr;

  @JsonKey(name: 'main_streets_en', defaultValue: <String>[])
  final List<String> mainStreetsEn;

  @JsonKey(name: 'main_streets_ar', defaultValue: <String>[])
  final List<String> mainStreetsAr;

  const JourneySummaryDto({
    required this.totalTimeMinutes,
    required this.totalDistanceMeters,
    required this.walkingDistanceMeters,
    this.transitDistanceMeters,
    required this.transfers,
    required this.cost,
    this.modesEn = const <String>[],
    this.modesAr = const <String>[],
    this.mainStreetsEn = const <String>[],
    this.mainStreetsAr = const <String>[],
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

  /// Encoded path (polyline5) returned per leg.
  final String? polyline;

  // Trip-only fields
  @JsonKey(name: 'trip_id')
  final String? tripId;

  @JsonKey(name: 'mode_en')
  final String? modeEn;

  @JsonKey(name: 'mode_ar')
  final String? modeAr;

  @JsonKey(name: 'route_short_name')
  final String? routeShortName;

  @JsonKey(name: 'route_short_name_ar')
  final String? routeShortNameAr;

  final String? headsign;

  @JsonKey(name: 'headsign_ar')
  final String? headsignAr;
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

  @JsonKey(name: 'from_trip_name_ar')
  final String? fromTripNameAr;

  @JsonKey(name: 'to_trip_name')
  final String? toTripName;

  @JsonKey(name: 'to_trip_name_ar')
  final String? toTripNameAr;

  @JsonKey(name: 'end_stop_id')
  final int? endStopId;

  @JsonKey(name: 'walking_distance_meters')
  final int? walkingDistanceMeters;

  const RouteLegDto({
    required this.type,
    this.distanceMeters,
    this.durationMinutes,
    this.polyline,
    this.tripId,
    this.modeEn,
    this.modeAr,
    this.routeShortName,
    this.routeShortNameAr,
    this.headsign,
    this.headsignAr,
    this.fare,
    this.from,
    this.to,
    this.tripIds,
    this.fromTripId,
    this.toTripId,
    this.fromTripName,
    this.fromTripNameAr,
    this.toTripName,
    this.toTripNameAr,
    this.endStopId,
    this.walkingDistanceMeters,
  });

  factory RouteLegDto.fromJson(Map<String, dynamic> json) =>
      _$RouteLegDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RouteLegDtoToJson(this);

  // No custom converters needed; polyline is decoded in the mapper.
}

@JsonSerializable()
class StopRefDto {
  @JsonKey(name: 'stop_id')
  final int stopId;

  final String name;

  @JsonKey(name: 'name_ar')
  final String? nameAr;

  /// [lat, lon]
  @JsonKey(fromJson: _toDouble1D, toJson: _fromDouble1D)
  final List<double> coord;

  const StopRefDto({
    required this.stopId,
    required this.name,
    this.nameAr,
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
