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
  final int? id;

  const Journey({
    required this.summary,
    required this.legs,
    this.textSummary,
    this.id,
  });

  @override
  List<Object?> get props => [summary, legs];
}

class JourneySummary extends Equatable {
  final int totalTimeMinutes;
  final int totalDistanceMeters;
  final int walkingDistanceMeters;
  final int transfers;
  final int cost;
  final List<String> modes;

  const JourneySummary({
    required this.totalTimeMinutes,
    required this.totalDistanceMeters,
    required this.walkingDistanceMeters,
    required this.transfers,
    required this.cost,
    required this.modes,
  });

  @override
  List<Object?> get props => [
    totalTimeMinutes,
    totalDistanceMeters,
    walkingDistanceMeters,
    transfers,
    cost,
    modes,
  ];
}

class StopRef extends Equatable {
  final int stopId;
  final String name;
  final GeoPoint coord;

  const StopRef({
    required this.stopId,
    required this.name,
    required this.coord,
  });

  @override
  List<Object?> get props => [stopId, name, coord];
}

class RouteLeg extends Equatable {
  final String type;

  final int? distanceMeters;
  final int? durationMinutes;
  final List<GeoPoint> path;

  // Trip fields
  final String? tripId;
  final String? mode;
  final String? routeShortName;
  final String? headsign;
  final int? fare;
  final StopRef? from;
  final StopRef? to;

  final List<String>? tripIds;

  // Transfer fields
  final String? fromTripId;
  final String? toTripId;
  final String? fromTripName;
  final String? toTripName;
  final int? endStopId;
  final int? walkingDistanceMeters;

  const RouteLeg({
    required this.type,
    required this.path,
    this.distanceMeters,
    this.durationMinutes,
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
    routeShortName,
    headsign,
    fare,
    from,
    to,
    tripIds,
    fromTripId,
    toTripId,
    fromTripName,
    toTripName,
    endStopId,
    walkingDistanceMeters,
  ];
}

class RoutesRequest extends Equatable {
  final double startLat;
  final double startLon;
  final double endLat;
  final double endLon;

  final int maxTransfers;
  final int walkingCutoff;
  final int topK;
  final List<String> restrictedModes;

  const RoutesRequest({
    required this.startLat,
    required this.startLon,
    required this.endLat,
    required this.endLon,
    required this.maxTransfers,
    required this.walkingCutoff,
    required this.topK,
    required this.restrictedModes,
  });

  @override
  List<Object?> get props => [
    startLat,
    startLon,
    endLat,
    endLon,
    maxTransfers,
    walkingCutoff,
    topK,
    restrictedModes,
  ];
}
