import 'package:equatable/equatable.dart';

import 'geo_point.dart';

class RoutingResult extends Equatable {
  final int numJourneys;
  final List<Journey> journeys;

  const RoutingResult({required this.numJourneys, required this.journeys});

  @override
  List<Object?> get props => [numJourneys, journeys];
}

class Journey extends Equatable {
  final JourneySummary summary;
  final List<RouteLeg> legs;
  final String? textSummary;
  final String? textSummaryEn;
  final int? id;

  final List<String> labels;
  final List<String> labelsAr;

  const Journey({
    required this.summary,
    required this.legs,
    this.textSummary,
    this.textSummaryEn,
    this.id,
    this.labels = const <String>[],
    this.labelsAr = const <String>[],
  });

  @override
  List<Object?> get props => [
    summary,
    legs,
    textSummary,
    textSummaryEn,
    id,
    labels,
    labelsAr,
  ];
}

class JourneySummary extends Equatable {
  final int totalTimeMinutes;
  final int totalDistanceMeters;
  final int walkingDistanceMeters;
  final int? transitDistanceMeters;
  final int transfers;
  final int cost;

  final List<String> modesEn;
  final List<String> modesAr;
  final List<String> mainStreetsEn;
  final List<String> mainStreetsAr;

  const JourneySummary({
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

  @override
  List<Object?> get props => [
    totalTimeMinutes,
    totalDistanceMeters,
    walkingDistanceMeters,
    transitDistanceMeters,
    transfers,
    cost,
    modesEn,
    modesAr,
    mainStreetsEn,
    mainStreetsAr,
  ];
}

class StopRef extends Equatable {
  final int stopId;
  final String name;
  final String? nameAr;
  final GeoPoint coord;

  const StopRef({
    required this.stopId,
    required this.name,
    this.nameAr,
    required this.coord,
  });

  @override
  List<Object?> get props => [stopId, name, nameAr, coord];
}

class RouteLeg extends Equatable {
  final String type;

  final int? distanceMeters;
  final int? durationMinutes;
  final List<GeoPoint> path;

  // Trip fields
  final String? tripId;
  final String? mode;
  final String? modeAr;
  final String? routeShortName;
  final String? routeShortNameAr;
  final String? headsign;
  final String? headsignAr;
  final int? fare;
  final StopRef? from;
  final StopRef? to;

  final List<String>? tripIds;

  // Transfer fields
  final String? fromTripId;
  final String? toTripId;
  final String? fromTripName;
  final String? fromTripNameAr;
  final String? toTripName;
  final String? toTripNameAr;
  final int? endStopId;
  final int? walkingDistanceMeters;

  const RouteLeg({
    required this.type,
    required this.path,
    this.distanceMeters,
    this.durationMinutes,
    this.tripId,
    this.mode,
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

  bool get isWalk => type == 'walk';
  bool get isTrip => type == 'trip';
  bool get isTransfer => type == 'transfer';

  @override
  List<Object?> get props => [
    type,
    distanceMeters,
    durationMinutes,
    path,
    tripId,
    mode,
    modeAr,
    routeShortName,
    routeShortNameAr,
    headsign,
    headsignAr,
    fare,
    from,
    to,
    tripIds,
    fromTripId,
    toTripId,
    fromTripName,
    fromTripNameAr,
    toTripName,
    toTripNameAr,
    endStopId,
    walkingDistanceMeters,
  ];
}

class ModeFilter extends Equatable {
  final List<String> include;
  final List<String> exclude;
  final String includeMatch;

  const ModeFilter({
    this.include = const <String>[],
    this.exclude = const <String>[],
    this.includeMatch = 'any',
  });

  @override
  List<Object?> get props => [include, exclude, includeMatch];
}

class RouteFilters extends Equatable {
  final ModeFilter modes;
  final ModeFilter mainStreets;

  const RouteFilters({
    this.modes = const ModeFilter(),
    this.mainStreets = const ModeFilter(),
  });

  @override
  List<Object?> get props => [modes, mainStreets];
}

class RoutesRequest extends Equatable {
  final double startLat;
  final double startLon;
  final double endLat;
  final double endLon;

  final int maxTransfers;
  final int walkingCutoffMinutes;
  final String priority;
  final int topK;

  final RouteFilters filters;

  const RoutesRequest({
    required this.startLat,
    required this.startLon,
    required this.endLat,
    required this.endLon,
    required this.maxTransfers,
    required this.walkingCutoffMinutes,
    required this.priority,
    required this.topK,
    required this.filters,
  });

  @override
  List<Object?> get props => [
    startLat,
    startLon,
    endLat,
    endLon,
    maxTransfers,
    walkingCutoffMinutes,
    priority,
    topK,
    filters,
  ];
}
