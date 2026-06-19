import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../data/models/gps_point_model.dart';
import '../../data/models/trip_metadata_model.dart';
import '../../data/models/trip_segment_model.dart';
import '../../data/services/trip_finalizer_service.dart';
import '../../data/services/trip_local_data_source.dart';
import 'recording_state.dart';

class RecordingCubit extends Cubit<RecordingState> {
  final TripLocalDataSource localDataSource;
  final TripFinalizerService tripFinalizerService;
  final FlutterBackgroundService backgroundService;
  final Uuid uuid;

  final List<StreamSubscription<Map<String, dynamic>?>> _subscriptions =
      <StreamSubscription<Map<String, dynamic>?>>[];
  final List<GpsPointModel> _recentPoints = <GpsPointModel>[];

  RecordingCubit({
    required this.localDataSource,
    required this.tripFinalizerService,
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

    if (activeTrip.status == TripStatuses.stopping) {
      await _handleStoppingTripOnInit(activeTrip);
      return;
    }

    if (!_isActiveRecordingStatus(activeTrip.status)) return;
    if (!await localDataSource.isRecordingServiceArmed()) return;

    final startedAt = DateTime.tryParse(activeTrip.startedAt);
    final tripAge = startedAt == null
        ? const Duration(days: 1)
        : DateTime.now().difference(startedAt);

    if (tripAge >= CrowdsourcingTiming.maxRecordingDuration) {
      final stopped = activeTrip.copyWith(
        status: TripStatuses.stopped,
        endedAt: DateTime.now().toIso8601String(),
      );
      await localDataSource.saveActiveTrip(stopped);
      emit(const RecordingGeneratingGpx());
      await _finalizeStoppedTrip(stopped);
      return;
    }

    await _startServiceIfNeeded();
    backgroundService.invoke(CrowdsourcingIpc.startTrip, <String, dynamic>{
      CrowdsourcingPayloadKeys.tripId: activeTrip.tripId,
      CrowdsourcingPayloadKeys.mode: activeTrip.segments.isEmpty
          ? null
          : activeTrip.segments.last.mode,
    });
    _recentPoints.clear();
    emit(_inProgressFromTrip(activeTrip));
  }

  Future<void> startRecording(String? initialMode) async {
    if (!await localDataSource.canCreateTrip()) {
      emit(
        const RecordingError(message: CrowdsourcingStrings.maxDraftsReached),
      );
      return;
    }
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
    await localDataSource.setRecordingServiceArmed(true);
    await _startServiceIfNeeded();
    backgroundService.invoke(CrowdsourcingIpc.startTrip, <String, dynamic>{
      CrowdsourcingPayloadKeys.tripId: tripId,
      CrowdsourcingPayloadKeys.mode: initialMode,
    });
    _recentPoints.clear();
    emit(_inProgressFromTrip(initialTrip));
  }

  Future<void> stopRecording() async {
    final current = state;
    if (current is! RecordingInProgress) return;
    emit(const RecordingGeneratingGpx());
    backgroundService.invoke(CrowdsourcingIpc.stopTrip, <String, dynamic>{
      CrowdsourcingPayloadKeys.stopSource:
          CrowdsourcingPayloadKeys.stopSourceApp,
    });
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
      CrowdsourcingIpc.tripStopAcknowledged,
      CrowdsourcingIpc.tripStopped,
      CrowdsourcingIpc.showModeSelector,
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
    if (eventName == CrowdsourcingIpc.tripStopAcknowledged) {
      await _handleStopAcknowledged(event);
      return;
    }

    if (eventName == CrowdsourcingIpc.gpsPoint) {
      final progress = current is RecordingInProgress
          ? current
          : current is RecordingSmartPromptFired
          ? current.previous
          : current is RecordingModeSelectionRequested
          ? current.previous
          : null;
      if (progress == null || event == null) return;
      final point = GpsPointModel(
        lat: _readDouble(event[CrowdsourcingPayloadKeys.lat]),
        lon: _readDouble(event[CrowdsourcingPayloadKeys.lon]),
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        segmentIndex: _readInt(event[CrowdsourcingPayloadKeys.segmentIndex]),
      );
      _appendRecentPoint(point);
      emit(
        progress.copyWith(
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
      const shouldOpenReview = true;
      emit(const RecordingGeneratingGpx());
      final stoppedTrip = event == null
          ? await localDataSource.getActiveTrip()
          : TripMetadataModel.fromMap(event);
      if (stoppedTrip != null) {
        await _finalizeStoppedTrip(
          stoppedTrip,
          shouldOpenReview: shouldOpenReview,
        );
      }
      return;
    }

    if (eventName == CrowdsourcingIpc.showModeSelector &&
        current is RecordingInProgress) {
      final activeTrip = await localDataSource.getActiveTrip();
      final refreshed = activeTrip == null
          ? current
          : current.copyWith(
              clearCurrentMode: true,
              currentModeDisplay: CrowdsourcingStrings.unspecifiedMode,
              segmentCount: activeTrip.segments.length,
              segmentModes: _segmentModeMap(activeTrip),
            );
      emit(RecordingModeSelectionRequested(previous: refreshed));
    }
  }

  Future<void> restoreProgress(RecordingInProgress progress) async {
    emit(progress);
  }

  Future<void> setCurrentSegmentMode(String? mode) async {
    final current = state;
    final progress = current is RecordingModeSelectionRequested
        ? current.previous
        : current is RecordingInProgress
        ? current
        : null;
    if (progress == null) return;
    await localDataSource.updateCurrentSegmentMode(progress.tripId, mode);
    backgroundService.invoke(CrowdsourcingIpc.setCurrentSegmentMode, {
      CrowdsourcingPayloadKeys.mode: mode,
    });
    final activeTrip = await localDataSource.getActiveTrip();
    emit(
      progress.copyWith(
        currentMode: mode,
        currentModeDisplay: CrowdsourcingModes.displayName(mode),
        segmentModes: activeTrip == null
            ? progress.segmentModes
            : _segmentModeMap(activeTrip),
      ),
    );
  }

  Future<void> _refreshAfterSegmentSplit() async {
    final current = state;
    // Extract the inner RecordingInProgress regardless of whether it is the
    // top-level state or wrapped inside a smart-prompt / mode-selection state.
    final RecordingInProgress progress;
    if (current is RecordingInProgress) {
      progress = current;
    } else if (current is RecordingSmartPromptFired) {
      progress = current.previous;
    } else if (current is RecordingModeSelectionRequested) {
      progress = current.previous;
    } else {
      return;
    }

    final activeTrip = await localDataSource.getActiveTrip();
    if (activeTrip == null) return;
    final lastMode = activeTrip.segments.isEmpty
        ? null
        : activeTrip.segments.last.mode;
    final updated = progress.copyWith(
      currentMode: lastMode,
      clearCurrentMode: lastMode == null,
      currentModeDisplay: CrowdsourcingModes.displayName(lastMode),
      segmentCount: activeTrip.segments.length,
      segmentModes: _segmentModeMap(activeTrip),
    );

    // Re-wrap in the same outer state type so the UI layer is not disrupted.
    if (current is RecordingSmartPromptFired) {
      emit(RecordingSmartPromptFired(
        detectedAt: current.detectedAt,
        previous: updated,
      ));
    } else if (current is RecordingModeSelectionRequested) {
      emit(RecordingModeSelectionRequested(previous: updated));
    } else {
      emit(updated);
    }
  }

  Future<void> _handleStopAcknowledged(Map<String, dynamic>? event) async {
    final source = event?[CrowdsourcingPayloadKeys.stopSource]?.toString();
    if (source != CrowdsourcingPayloadKeys.stopSourceNotification) return;

    _recentPoints.clear();
    final activeTrip = await localDataSource.getActiveTrip();
    if (activeTrip != null && _isActiveRecordingStatus(activeTrip.status)) {
      await localDataSource.saveActiveTrip(
        _closedTrip(activeTrip, TripStatuses.stopping),
      );
    }
    emit(const RecordingInitial());
  }

  Future<void> _handleStoppingTripOnInit(TripMetadataModel activeTrip) async {
    _recentPoints.clear();
    emit(const RecordingInitial());
    if (await backgroundService.isRunning()) return;

    final stopped = _closedTrip(activeTrip, TripStatuses.stopped);
    await localDataSource.saveActiveTrip(stopped);
    await _finalizeStoppedTrip(stopped, shouldOpenReview: true);
  }

  TripMetadataModel _closedTrip(TripMetadataModel trip, String status) {
    final endedAt = trip.endedAt ?? DateTime.now().toIso8601String();
    final segments = trip.segments
        .map((segment) {
          if (segment.index != trip.currentSegmentIndex) return segment;
          return segment.copyWith(endedAt: endedAt);
        })
        .toList(growable: false);
    return trip.copyWith(status: status, endedAt: endedAt, segments: segments);
  }

  bool _isActiveRecordingStatus(String status) {
    return status == TripStatuses.recording ||
        status == TripStatuses.paused ||
        status == TripStatuses.gpsLost;
  }

  Future<void> _finalizeStoppedTrip(
    TripMetadataModel stoppedTrip, {
    bool shouldOpenReview = true,
  }) async {
    try {
      final completed = await tripFinalizerService.finalizeStoppedTrip(
        stoppedTrip,
      );
      _recentPoints.clear();
      emit(
        RecordingComplete(
          tripMeta: completed,
          shouldOpenReview: shouldOpenReview,
        ),
      );
    } catch (error) {
      emit(RecordingError(message: error.toString()));
    }
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
