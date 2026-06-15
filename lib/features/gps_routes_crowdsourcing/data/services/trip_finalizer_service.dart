import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../../core/constants/crowdsourcing_constants.dart';
import '../models/gps_point_model.dart';
import '../models/trip_metadata_model.dart';
import '../models/trip_segment_model.dart';
import 'gpx_builder_service.dart';
import 'trip_local_data_source.dart';

class TripFinalizerService {
  final TripLocalDataSource localDataSource;
  final GpxBuilderService gpxBuilderService;

  const TripFinalizerService({
    required this.localDataSource,
    required this.gpxBuilderService,
  });

  Future<TripMetadataModel> finalizeStoppedTrip(
    TripMetadataModel stoppedTrip,
  ) async {
    final rawPoints = await localDataSource.getGpsPoints(stoppedTrip.tripId);
    if (rawPoints.isEmpty) {
      debugPrint(
        '[TripFinalizer] Trip ${stoppedTrip.tripId} has 0 GPS points; '
        'keeping it for review instead of discarding it.',
      );
      final emptyMeta = stoppedTrip.copyWith(status: TripStatuses.pendingReview);
      await localDataSource.saveTripMetadata(emptyMeta);
      await localDataSource.clearActiveTrip();
      return emptyMeta;
    }
    if (rawPoints.length < 3) {
      debugPrint(
        '[TripFinalizer] Trip ${stoppedTrip.tripId} has only '
        '${rawPoints.length} GPS point(s); keeping it for review and GPX '
        'generation instead of discarding a short recording.',
      );
    }

    final transfers = await localDataSource.getPotentialTransfers(
      stoppedTrip.tripId,
    );
    final countedSegments = _withPointCounts(stoppedTrip.segments, rawPoints);
    final metaForGpx = stoppedTrip.copyWith(
      status: TripStatuses.pendingReview,
      segments: countedSegments,
      potentialTransfers: transfers,
      totalDistanceM: _distanceFor(rawPoints),
    );
    final gpxPath = await gpxBuilderService.buildGpxFile(
      tripMeta: metaForGpx,
      rawPoints: rawPoints,
    );
    final completed = metaForGpx.copyWith(gpxFilePath: gpxPath);
    await localDataSource.saveTripMetadata(completed);
    await localDataSource.deleteGpsPoints(stoppedTrip.tripId);
    await localDataSource.clearActiveTrip();
    return completed;
  }

  Future<TripMetadataModel?> loadOrFinalizeForReview(String tripId) async {
    var completed = await localDataSource.getTripMetadata(tripId);
    if (completed != null) return completed;

    final active = await _waitForReviewableActiveTrip(tripId);
    completed = await localDataSource.getTripMetadata(tripId);
    if (completed != null) return completed;
    if (active == null || active.tripId != tripId) return null;
    if (active.status != TripStatuses.stopped) return active;
    return finalizeStoppedTrip(active);
  }

  Future<TripMetadataModel?> _waitForReviewableActiveTrip(String tripId) async {
    const attempts = 60;
    const delay = Duration(milliseconds: 500);
    TripMetadataModel? latest;

    for (var attempt = 0; attempt < attempts; attempt += 1) {
      final completed = await localDataSource.getTripMetadata(tripId);
      if (completed != null) return completed;
      latest = await localDataSource.getActiveTrip();
      if (latest == null || latest.tripId != tripId) return latest;
      if (latest.status == TripStatuses.stopped) return latest;
      if (!_isStoppingOrRecording(latest.status)) return latest;
      await Future<void>.delayed(delay);
    }

    return latest;
  }

  bool _isStoppingOrRecording(String status) {
    return status == TripStatuses.stopping ||
        status == TripStatuses.recording ||
        status == TripStatuses.paused ||
        status == TripStatuses.gpsLost;
  }

  List<TripSegmentModel> _withPointCounts(
    List<TripSegmentModel> segments,
    List<GpsPointModel> points,
  ) {
    return segments
        .map((segment) {
          final count = points
              .where((point) => point.segmentIndex == segment.index)
              .length;
          return segment.copyWith(pointCount: count);
        })
        .toList(growable: false);
  }

  double _distanceFor(List<GpsPointModel> points) {
    if (points.length < 2) return 0;
    var distance = 0.0;
    for (var i = 1; i < points.length; i += 1) {
      final previous = points[i - 1];
      final current = points[i];
      distance += _distanceBetween(
        previous.lat,
        previous.lon,
        current.lat,
        current.lon,
      );
    }
    return distance;
  }

  double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusM = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  double _degToRad(double degrees) => degrees * math.pi / 180;
}
