import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../data/models/gps_point_model.dart';
import '../../data/models/trip_metadata_model.dart';
import '../../data/models/trip_segment_model.dart';
import '../../data/services/gpx_builder_service.dart';
import '../../data/services/trip_local_data_source.dart';
import 'recording_state.dart';

class RecordingCubit extends Cubit<RecordingState> {
  final TripLocalDataSource localDataSource;
  final GpxBuilderService gpxBuilderService;
  final FlutterBackgroundService backgroundService;
  final Uuid uuid;

  final List<StreamSubscription<Map<String, dynamic>?>> _subscriptions =
      <StreamSubscription<Map<String, dynamic>?>>[];
  final List<GpsPointModel> _recentPoints = <GpsPointModel>[];

  RecordingCubit({
    required this.localDataSource,
    required this.gpxBuilderService,
    FlutterBackgroundService? backgroundService,
    Uuid? uuid,
  }) : backgroundService = backgroundService ?? FlutterBackgroundService(),
       uuid = uuid ?? const Uuid(),
       super(const RecordingInitial());

  Future<void> init() async {
    _subscribeToServiceEvents();
    final activeTrip = await localDataSource.getActiveTrip();
    if (activeTrip == null) return;

    if (activeTrip.status == TripStatuses.stopped) {
      emit(const RecordingGeneratingGpx());
      await _finalizeStoppedTrip(activeTrip);
      return;
    }

    if (activeTrip.status == TripStatuses.recording ||
        activeTrip.status == TripStatuses.paused ||
        activeTrip.status == TripStatuses.gpsLost) {
      emit(RecordingOrphanFound(tripMeta: activeTrip));
    }
  }

  Future<void> startRecording(String? initialMode) async {
    final tripId = uuid.v4();
    final startedAt = DateTime.now().toIso8601String();
    final initialTrip = TripMetadataModel(
      tripId: tripId,
      status: TripStatuses.recording,
      startedAt: startedAt,
      segments: <TripSegmentModel>[
        TripSegmentModel(
          index: 0,
          mode: initialMode,
          startedAt: startedAt,
          confidence: initialMode == null
              ? SegmentConfidence.unknown
              : SegmentConfidence.userConfirmed,
        ),
      ],
    );
    await localDataSource.saveActiveTrip(initialTrip);
    await _startServiceIfNeeded();
    backgroundService.invoke(CrowdsourcingIpc.startTrip, <String, dynamic>{
      CrowdsourcingPayloadKeys.tripId: tripId,
      CrowdsourcingPayloadKeys.mode: initialMode,
    });
    _recentPoints.clear();
    emit(_inProgressFromTrip(initialTrip));
  }

  Future<void> resumeOrphanRecording() async {
    final activeTrip = await localDataSource.getActiveTrip();
    if (activeTrip == null) {
      emit(const RecordingInitial());
      return;
    }
    await _startServiceIfNeeded();
    emit(_inProgressFromTrip(activeTrip));
  }

  Future<void> stopRecording() async {
    final current = state;
    if (current is! RecordingInProgress) return;
    emit(const RecordingGeneratingGpx());
    backgroundService.invoke(CrowdsourcingIpc.stopTrip);
  }

  Future<void> addSegmentTransition({String? mode, double? fareEgp}) async {
    final current = state;
    if (current is! RecordingInProgress) return;
    backgroundService.invoke(CrowdsourcingIpc.addSegment, <String, dynamic>{
      CrowdsourcingPayloadKeys.mode: mode,
      CrowdsourcingPayloadKeys.fareEgp: fareEgp,
    });
    final updatedTrip = await localDataSource.getActiveTrip();
    if (updatedTrip == null) return;
    emit(
      current.copyWith(
        currentMode: mode,
        currentModeDisplay: CrowdsourcingModes.displayName(mode),
        segmentCount: updatedTrip.segments.length,
        segmentModes: _segmentModeMap(updatedTrip),
      ),
    );
  }

  void _subscribeToServiceEvents() {
    if (_subscriptions.isNotEmpty) return;
    for (final eventName in <String>[
      CrowdsourcingIpc.gpsPoint,
      CrowdsourcingIpc.potentialTransfer,
      CrowdsourcingIpc.segmentSplitConfirmed,
      CrowdsourcingIpc.transferRejected,
      CrowdsourcingIpc.tripAutoPaused,
      CrowdsourcingIpc.gpsLost,
      CrowdsourcingIpc.gpsRestored,
      CrowdsourcingIpc.tripStopped,
    ]) {
      _subscriptions.add(
        backgroundService
            .on(eventName)
            .listen((event) => _onServiceEvent(eventName, event)),
      );
    }
  }

  Future<void> _onServiceEvent(
    String eventName,
    Map<String, dynamic>? event,
  ) async {
    final current = state;
    if (eventName == CrowdsourcingIpc.gpsPoint) {
      if (current is! RecordingInProgress || event == null) return;
      final point = GpsPointModel(
        lat: _readDouble(event[CrowdsourcingPayloadKeys.lat]),
        lon: _readDouble(event[CrowdsourcingPayloadKeys.lon]),
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        segmentIndex: _readInt(event[CrowdsourcingPayloadKeys.segmentIndex]),
      );
      _appendRecentPoint(point);
      emit(
        current.copyWith(
          distanceM: _readDouble(event[CrowdsourcingPayloadKeys.distanceM]),
          elapsedSeconds: _readInt(
            event[CrowdsourcingPayloadKeys.elapsedSeconds],
          ),
          isGpsLost: event[CrowdsourcingPayloadKeys.isGpsLost] == true,
          recentPoints: List<GpsPointModel>.of(_recentPoints, growable: false),
        ),
      );
      return;
    }

    if (eventName == CrowdsourcingIpc.potentialTransfer) {
      if (current is! RecordingInProgress || event == null) return;
      emit(
        RecordingSmartPromptFired(
          detectedAt: event[CrowdsourcingPayloadKeys.detectedAt].toString(),
          previous: current,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      if (state is RecordingSmartPromptFired) emit(current);
      return;
    }

    if (eventName == CrowdsourcingIpc.segmentSplitConfirmed) {
      await _refreshAfterSegmentSplit();
      return;
    }

    if (eventName == CrowdsourcingIpc.tripAutoPaused &&
        current is RecordingInProgress) {
      emit(current.copyWith(isPaused: true));
      return;
    }

    if (eventName == CrowdsourcingIpc.gpsLost &&
        current is RecordingInProgress) {
      emit(current.copyWith(isGpsLost: true));
      return;
    }

    if (eventName == CrowdsourcingIpc.gpsRestored &&
        current is RecordingInProgress) {
      emit(current.copyWith(isGpsLost: false));
      return;
    }

    if (eventName == CrowdsourcingIpc.tripStopped) {
      emit(const RecordingGeneratingGpx());
      final stoppedTrip = event == null
          ? await localDataSource.getActiveTrip()
          : TripMetadataModel.fromMap(event);
      if (stoppedTrip != null) await _finalizeStoppedTrip(stoppedTrip);
    }
  }

  Future<void> _refreshAfterSegmentSplit() async {
    final current = state;
    if (current is! RecordingInProgress) return;
    final activeTrip = await localDataSource.getActiveTrip();
    if (activeTrip == null) return;
    emit(
      current.copyWith(
        clearCurrentMode: true,
        currentModeDisplay: CrowdsourcingStrings.unspecifiedMode,
        segmentCount: activeTrip.segments.length,
        segmentModes: _segmentModeMap(activeTrip),
      ),
    );
  }

  Future<void> _finalizeStoppedTrip(TripMetadataModel stoppedTrip) async {
    try {
      final rawPoints = await localDataSource.getGpsPoints(stoppedTrip.tripId);
      final transfers = await localDataSource.getPotentialTransfers(
        stoppedTrip.tripId,
      );
      final countedSegments = _withPointCounts(stoppedTrip.segments, rawPoints);
      final totalDistance = _distanceFor(rawPoints);
      final metaForGpx = stoppedTrip.copyWith(
        status: TripStatuses.pendingReview,
        segments: countedSegments,
        potentialTransfers: transfers,
        totalDistanceM: totalDistance,
      );
      final gpxPath = await gpxBuilderService.buildGpxFile(
        tripMeta: metaForGpx,
        rawPoints: rawPoints,
      );
      final completed = metaForGpx.copyWith(gpxFilePath: gpxPath);
      await localDataSource.saveTripMetadata(completed);
      await localDataSource.deleteGpsPoints(stoppedTrip.tripId);
      await localDataSource.clearActiveTrip();
      _recentPoints.clear();
      emit(RecordingComplete(tripMeta: completed));
    } catch (error) {
      emit(RecordingError(message: error.toString()));
    }
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

  void _appendRecentPoint(GpsPointModel point) {
    _recentPoints.add(point);
    while (_recentPoints.length > CrowdsourcingLimits.liveMapPointMax) {
      _recentPoints.removeAt(0);
    }
  }

  RecordingInProgress _inProgressFromTrip(TripMetadataModel trip) {
    final mode = trip.segments.isEmpty ? null : trip.segments.last.mode;
    return RecordingInProgress(
      tripId: trip.tripId,
      currentMode: mode,
      currentModeDisplay: CrowdsourcingModes.displayName(mode),
      elapsedSeconds: DateTime.now()
          .difference(DateTime.parse(trip.startedAt))
          .inSeconds,
      distanceM: trip.totalDistanceM ?? 0,
      segmentCount: trip.segments.length,
      isPaused: trip.status == TripStatuses.paused,
      isGpsLost: trip.status == TripStatuses.gpsLost,
      recentPoints: List<GpsPointModel>.of(_recentPoints, growable: false),
      segmentModes: _segmentModeMap(trip),
    );
  }

  Map<int, String?> _segmentModeMap(TripMetadataModel trip) {
    return <int, String?>{
      for (final segment in trip.segments) segment.index: segment.mode,
    };
  }

  Future<void> _startServiceIfNeeded() async {
    final isRunning = await backgroundService.isRunning();
    if (!isRunning) {
      await backgroundService.startService();
    }
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

  double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
