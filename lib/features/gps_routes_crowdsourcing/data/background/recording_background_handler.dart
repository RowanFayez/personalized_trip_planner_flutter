import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;

import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../../../core/storage/hive/hive_service.dart';
import '../models/gps_point_model.dart';
import '../models/potential_transfer_model.dart';
import '../models/trip_metadata_model.dart';
import '../models/trip_segment_model.dart';
import '../services/trip_local_data_source.dart';

@pragma('vm:entry-point')
Future<void> initializeCrowdsourcingBackgroundService() async {
  if (!Platform.isAndroid) return;

  final notifications = FlutterLocalNotificationsPlugin();
  await _initializeNotifications(notifications);

  await notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          CrowdsourcingNotifications.recordingChannelId,
          CrowdsourcingStrings.recordingNotificationTitle,
          importance: Importance.low,
        ),
      );

  await notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          CrowdsourcingNotifications.promptChannelId,
          CrowdsourcingStrings.smartPromptTitle,
          importance: Importance.defaultImportance,
        ),
      );

  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: crowdsourcingServiceOnStart,
      autoStart: false,
      autoStartOnBoot: true,
      isForegroundMode: true,
      notificationChannelId: CrowdsourcingNotifications.recordingChannelId,
      initialNotificationTitle: CrowdsourcingStrings.recordingNotificationTitle,
      initialNotificationContent: CrowdsourcingStrings.unspecifiedMode,
      foregroundServiceNotificationId: CrowdsourcingNotifications.recordingId,
      foregroundServiceTypes: <AndroidForegroundType>[
        AndroidForegroundType.location,
      ],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: crowdsourcingServiceOnStart,
    ),
  );
}

@pragma('vm:entry-point')
void crowdsourcingServiceOnStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();
  final controller = _RecordingBackgroundController(service);
  unawaited(controller.start());
}

@pragma('vm:entry-point')
void crowdsourcingNotificationTapBackground(NotificationResponse response) {
  DartPluginRegistrant.ensureInitialized();
  _forwardNotificationAction(response);
}

void _onNotificationResponse(NotificationResponse response) {
  _forwardNotificationAction(response);
}

void _forwardNotificationAction(NotificationResponse response) {
  final actionId = response.actionId;
  final service = FlutterBackgroundService();

  if ((actionId == null || actionId.isEmpty) &&
      response.payload == CrowdsourcingNotifications.reviewReadyPayload) {
    service.invoke(CrowdsourcingIpc.bringToForeground);
    return;
  }

  if (actionId == null || actionId.isEmpty) return;
  final payload = _decodePayload(response.payload);

  if (actionId == CrowdsourcingNotifications.actionArrived ||
      actionId == CrowdsourcingNotifications.actionStop) {
    service.invoke(CrowdsourcingIpc.bringToForeground);
    service.invoke(CrowdsourcingIpc.stopTrip);
    return;
  }

  if (actionId == CrowdsourcingNotifications.actionTransfer) {
    service.invoke(CrowdsourcingIpc.bringToForeground);
    service.invoke(CrowdsourcingIpc.notificationTransferRequested);
    return;
  }

  if (actionId == CrowdsourcingNotifications.actionConfirmTransfer) {
    service.invoke(CrowdsourcingIpc.bringToForeground);
    service.invoke(CrowdsourcingIpc.confirmTransfer, payload);
    return;
  }

  if (actionId == CrowdsourcingNotifications.actionRejectTransfer) {
    service.invoke(CrowdsourcingIpc.rejectTransfer, payload);
  }
}

Map<String, dynamic> _decodePayload(String? payload) {
  if (payload == null || payload.trim().isEmpty) return <String, dynamic>{};
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return <String, dynamic>{};
  }
  if (decoded is Map<String, dynamic>) return decoded;
  return <String, dynamic>{};
}

Future<void> _initializeNotifications(
  FlutterLocalNotificationsPlugin notifications,
) {
  return notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveNotificationResponse: _onNotificationResponse,
    onDidReceiveBackgroundNotificationResponse:
        crowdsourcingNotificationTapBackground,
  );
}

class _RecordingBackgroundController {
  final ServiceInstance service;
  final TripLocalDataSource localDataSource = TripLocalDataSource();
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<Activity>? _activitySubscription;
  Timer? _flushTimer;
  Timer? _gpsWatchTimer;
  Timer? _notificationTimer;
  Timer? _debounceTimer;
  Timer? _promptExpiryTimer;

  TripMetadataModel? _activeTrip;
  final List<GpsPointModel> _buffer = <GpsPointModel>[];
  final List<double> _speedWindow = <double>[];

  DateTime? _lastAcceptedAt;
  DateTime? _lastReceivedAt;
  GpsPointModel? _lastAcceptedPoint;
  ActivityType? _lastStableActivity;
  DateTime? _potentialTransferStartTime;
  DateTime? _lastPromptAt;
  String? _latestPendingTransferDetectedAt;
  double _distanceM = 0;
  bool _isGpsLost = false;
  bool _isAutoPaused = false;
  bool _isFlushing = false;
  bool _isStopping = false;
  bool _storageFullHandled = false;
  DateTime? _stationarySince;

  _RecordingBackgroundController(this.service);

  Future<void> start() async {
    await HiveService.init();
    await _initializeNotifications(notifications);
    _bindIpc();

    if (service is AndroidServiceInstance) {
      await (service as AndroidServiceInstance).setAsForegroundService();
    }

    final orphan = await localDataSource.getActiveTrip();
    if (orphan != null && orphan.status == TripStatuses.recording) {
      _activeTrip = orphan;
      _distanceM = orphan.totalDistanceM ?? 0;
      await _startStreams();
      await _showRecordingNotification();
    }
  }

  void _bindIpc() {
    service.on(CrowdsourcingIpc.startTrip).listen(_handleStartTrip);
    service.on(CrowdsourcingIpc.stopTrip).listen((_) => _handleStopTrip());
    service.on(CrowdsourcingIpc.addSegment).listen(_handleAddSegment);
    service
        .on(CrowdsourcingIpc.notificationTransferRequested)
        .listen(_handleNotificationTransferRequested);
    service
        .on(CrowdsourcingIpc.setCurrentSegmentMode)
        .listen(_handleSetCurrentSegmentMode);
    service.on(CrowdsourcingIpc.confirmTransfer).listen(_handleConfirmTransfer);
    service.on(CrowdsourcingIpc.rejectTransfer).listen(_handleRejectTransfer);
    service.on(CrowdsourcingIpc.pauseTrip).listen((_) => _setPaused(true));
    service.on(CrowdsourcingIpc.resumeTrip).listen((_) => _setPaused(false));
    service.on(CrowdsourcingIpc.bringToForeground).listen((_) {
      final androidService = service;
      if (androidService is AndroidServiceInstance) {
        unawaited(androidService.openApp());
      }
    });
  }

  Future<void> _handleStartTrip(Map<String, dynamic>? event) async {
    final now = DateTime.now().toIso8601String();
    final tripId = event?[CrowdsourcingPayloadKeys.tripId]?.toString();
    if (tripId == null || tripId.trim().isEmpty) return;
    final mode = event?[CrowdsourcingPayloadKeys.mode]?.toString();

    final existing = await localDataSource.getActiveTrip();
    if (existing != null &&
        existing.tripId == tripId &&
        _isResumableStatus(existing.status)) {
      final resumed = existing.copyWith(status: TripStatuses.recording);
      _activeTrip = resumed;
      _distanceM = resumed.totalDistanceM ?? 0;
      _resetRuntimeTracking();
      await localDataSource.saveActiveTrip(resumed);
      await _startStreams();
      await _showRecordingNotification();
      return;
    }

    final trip = TripMetadataModel(
      tripId: tripId,
      status: TripStatuses.recording,
      startedAt: now,
      segments: <TripSegmentModel>[
        TripSegmentModel(
          index: 0,
          mode: mode?.trim().isEmpty == true ? null : mode,
          startedAt: now,
          confidence: mode == null
              ? SegmentConfidence.unknown
              : SegmentConfidence.userConfirmed,
        ),
      ],
    );

    _activeTrip = trip;
    _distanceM = 0;
    _resetRuntimeTracking();
    await localDataSource.saveActiveTrip(trip);
    await _startStreams();
    await _showRecordingNotification();
  }

  bool _isResumableStatus(String status) {
    return status == TripStatuses.recording ||
        status == TripStatuses.paused ||
        status == TripStatuses.gpsLost;
  }

  void _resetRuntimeTracking() {
    _lastAcceptedAt = null;
    _lastReceivedAt = null;
    _lastAcceptedPoint = null;
    _potentialTransferStartTime = null;
    _latestPendingTransferDetectedAt = null;
    _isGpsLost = false;
    _isAutoPaused = false;
    _stationarySince = null;
    _buffer.clear();
    _speedWindow.clear();
  }

  Future<void> _startStreams() async {
    await _gpsSubscription?.cancel();
    await _activitySubscription?.cancel();
    _flushTimer?.cancel();
    _gpsWatchTimer?.cancel();
    _notificationTimer?.cancel();

    _flushTimer = Timer.periodic(
      CrowdsourcingTiming.flushInterval,
      (_) => _flushBuffer(),
    );
    _gpsWatchTimer = Timer.periodic(
      CrowdsourcingTiming.minPointInterval,
      (_) => _checkGpsHealth(),
    );
    _notificationTimer = Timer.periodic(
      CrowdsourcingTiming.flushInterval,
      (_) => _showRecordingNotification(),
    );

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_onPosition, onError: (_) => _markGpsLost());

    await _startActivityStream();
  }

  Future<void> _startActivityStream() async {
    try {
      final permission = await FlutterActivityRecognition.instance
          .checkPermission();
      if (permission != ActivityPermission.GRANTED) return;
      _activitySubscription = FlutterActivityRecognition.instance.activityStream
          .handleError((Object error) => debugPrint(error.toString()))
          .listen(_onActivity);
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<void> _onPosition(Position position) async {
    _lastReceivedAt = DateTime.now();
    if (_isGpsLost) {
      _isGpsLost = false;
      service.invoke(CrowdsourcingIpc.gpsRestored);
    }

    if ((position.accuracy) > CrowdsourcingLimits.gpsRecordingAccuracyMaxM) {
      return;
    }

    final now = position.timestamp;
    if (_lastAcceptedAt != null &&
        now.difference(_lastAcceptedAt!) <
            CrowdsourcingTiming.minPointInterval) {
      return;
    }

    _trackSpeed(position.speed);
    _updateStationaryState(position.speed);
    if (_isAutoPaused &&
        position.speed <= CrowdsourcingLimits.stationaryResumeVelocityMs) {
      return;
    }

    final activeTrip = _activeTrip ?? await localDataSource.getActiveTrip();
    if (activeTrip == null) return;
    _activeTrip = activeTrip;

    final nextPoint = GpsPointModel(
      lat: position.latitude,
      lon: position.longitude,
      altitude: position.altitude,
      timestampMs: now.millisecondsSinceEpoch,
      segmentIndex: activeTrip.currentSegmentIndex,
      accuracyM: position.accuracy,
      speedMs: position.speed,
    );

    if (_isImpossibleOutlier(nextPoint, now)) return;
    if (!_passesStaticDriftFilter(nextPoint, now)) return;
    _appendPoint(nextPoint, now);
  }

  bool _isImpossibleOutlier(GpsPointModel point, DateTime now) {
    final previous = _lastAcceptedPoint;
    final previousAt = _lastAcceptedAt;
    if (previous == null || previousAt == null) return false;

    final distance = _distanceBetween(
      previous.lat,
      previous.lon,
      point.lat,
      point.lon,
    );
    final elapsedSeconds = math.max(
      1.0,
      now.difference(previousAt).inMilliseconds / 1000,
    );
    final impliedSpeedMs = distance / elapsedSeconds;
    return impliedSpeedMs > CrowdsourcingLimits.impossibleTransitSpeedMs;
  }

  bool _passesStaticDriftFilter(GpsPointModel point, DateTime now) {
    final previous = _lastAcceptedPoint;
    final previousAt = _lastAcceptedAt;
    if (previous == null || previousAt == null) return true;

    final distance = _distanceBetween(
      previous.lat,
      previous.lon,
      point.lat,
      point.lon,
    );
    if (distance > CrowdsourcingLimits.staticDriftMinDistanceM) return true;

    final enoughTime =
        now.difference(previousAt) > CrowdsourcingTiming.flushInterval;
    final activeVelocity =
        (point.speedMs ?? 0) > CrowdsourcingLimits.activeVelocityMs;
    return enoughTime && activeVelocity;
  }

  void _appendPoint(GpsPointModel point, DateTime now) {
    final previous = _lastAcceptedPoint;
    if (previous != null) {
      _distanceM += _distanceBetween(
        previous.lat,
        previous.lon,
        point.lat,
        point.lon,
      );
    }

    _lastAcceptedPoint = point;
    _lastAcceptedAt = now;
    _buffer.add(point);
    if (_buffer.length >= CrowdsourcingLimits.gpsBufferMax) {
      unawaited(_flushBuffer());
    }

    final activeTrip = _activeTrip;
    service.invoke(CrowdsourcingIpc.gpsPoint, <String, dynamic>{
      CrowdsourcingPayloadKeys.lat: point.lat,
      CrowdsourcingPayloadKeys.lon: point.lon,
      CrowdsourcingPayloadKeys.segmentIndex: point.segmentIndex,
      CrowdsourcingPayloadKeys.distanceM: _distanceM,
      CrowdsourcingPayloadKeys.elapsedSeconds: activeTrip == null
          ? 0
          : DateTime.now()
                .difference(DateTime.parse(activeTrip.startedAt))
                .inSeconds,
      CrowdsourcingPayloadKeys.isGpsLost: _isGpsLost,
    });
  }

  Future<void> _flushBuffer() async {
    if (_isFlushing) return;
    final activeTrip = _activeTrip;
    if (activeTrip == null || _buffer.isEmpty) return;
    _isFlushing = true;
    try {
      final points = List<GpsPointModel>.of(_buffer, growable: false);
      _buffer.clear();
      await localDataSource.appendGpsPointsBatch(activeTrip.tripId, points);
      final updated = activeTrip.copyWith(totalDistanceM: _distanceM);
      await localDataSource.saveActiveTrip(updated);
      _activeTrip = updated;
    } on Object catch (error) {
      if (!_isStorageError(error)) rethrow;
      await _handleStorageFull();
    } finally {
      _isFlushing = false;
    }
  }

  bool _isStorageError(Object error) {
    if (error is CrowdsourcingStorageFullException ||
        error is FileSystemException) {
      return true;
    }
    final message = error.toString().toLowerCase();
    return message.contains('space') ||
        message.contains('quota') ||
        message.contains('full') ||
        message.contains('file system');
  }

  Future<void> _handleStorageFull() async {
    if (_storageFullHandled) return;
    _storageFullHandled = true;
    await _showStorageFullNotification();
    if (!_isStopping) {
      await _handleStopTrip(flushPendingBuffer: false);
    }
  }

  void _trackSpeed(double speed) {
    _speedWindow.add(speed);
    if (_speedWindow.length > CrowdsourcingLimits.speedWindowMax) {
      _speedWindow.removeAt(0);
    }
  }

  void _updateStationaryState(double speed) {
    if (_speedWindow.length < CrowdsourcingLimits.speedWindowMax) return;
    final medianSpeed = _median(_speedWindow);
    final now = DateTime.now();

    if (medianSpeed < CrowdsourcingLimits.activeVelocityMs) {
      _stationarySince ??= now;
      if (!_isAutoPaused &&
          now.difference(_stationarySince!) >=
              CrowdsourcingTiming.stationaryAfter) {
        _isAutoPaused = true;
        service.invoke(CrowdsourcingIpc.tripAutoPaused);
        unawaited(_setPaused(true));
        unawaited(_showStationaryNotification());
      }
      return;
    }

    if (speed > CrowdsourcingLimits.stationaryResumeVelocityMs) {
      _stationarySince = null;
      if (_isAutoPaused) {
        _isAutoPaused = false;
        unawaited(_setPaused(false));
      }
    }
  }

  Future<void> _setPaused(bool paused) async {
    final activeTrip = _activeTrip;
    if (activeTrip == null) return;
    final status = paused ? TripStatuses.paused : TripStatuses.recording;
    final updated = activeTrip.copyWith(status: status);
    _activeTrip = updated;
    await localDataSource.saveActiveTrip(updated);
  }

  void _checkGpsHealth() {
    final last = _lastReceivedAt;
    if (last == null) return;
    if (DateTime.now().difference(last) > CrowdsourcingTiming.gpsLostAfter) {
      _markGpsLost();
    }
  }

  void _markGpsLost() {
    if (_isGpsLost) return;
    _isGpsLost = true;
    service.invoke(CrowdsourcingIpc.gpsLost);
    final activeTrip = _activeTrip;
    if (activeTrip != null) {
      final updated = activeTrip.copyWith(status: TripStatuses.gpsLost);
      _activeTrip = updated;
      unawaited(localDataSource.saveActiveTrip(updated));
    }
    unawaited(_showRecordingNotification());
  }

  void _onActivity(Activity activity) {
    if (!_isTrustedActivity(activity)) return;

    if (activity.type == ActivityType.IN_VEHICLE) {
      _lastStableActivity = ActivityType.IN_VEHICLE;
      if (_debounceTimer?.isActive == true) {
        _debounceTimer?.cancel();
        _debounceTimer = null;
        _potentialTransferStartTime = null;
        return;
      }
      if (_potentialTransferStartTime != null) {
        unawaited(_recordBoardingDetected());
      }
      return;
    }

    if (activity.type == ActivityType.WALKING &&
        _lastStableActivity == ActivityType.IN_VEHICLE &&
        (_debounceTimer == null || !_debounceTimer!.isActive) &&
        _isPromptCooldownOver()) {
      _potentialTransferStartTime = DateTime.now();
      _debounceTimer = Timer(
        CrowdsourcingTiming.transferDebounce,
        () => unawaited(_onTransferConfirmed()),
      );
    }
  }

  bool _isTrustedActivity(Activity activity) {
    return activity.confidence == ActivityConfidence.HIGH;
  }

  bool _isPromptCooldownOver() {
    final lastPromptAt = _lastPromptAt;
    if (lastPromptAt == null) return true;
    return DateTime.now().difference(lastPromptAt) >=
        CrowdsourcingTiming.promptCooldown;
  }

  Future<void> _onTransferConfirmed() async {
    final activeTrip = _activeTrip;
    final transferStart = _potentialTransferStartTime;
    if (activeTrip == null || transferStart == null) return;

    final detectedAt = transferStart.toIso8601String();
    final notificationSentAt = DateTime.now().toIso8601String();
    _latestPendingTransferDetectedAt = detectedAt;
    _lastPromptAt = DateTime.now();

    await localDataSource.addPotentialTransfer(
      activeTrip.tripId,
      PotentialTransferModel(
        detectedAt: detectedAt,
        notificationSentAt: notificationSentAt,
      ),
    );

    await _showSmartPromptNotification(activeTrip.tripId, detectedAt);
    service.invoke(CrowdsourcingIpc.potentialTransfer, <String, dynamic>{
      CrowdsourcingPayloadKeys.detectedAt: detectedAt,
    });

    _promptExpiryTimer?.cancel();
    _promptExpiryTimer = Timer(
      CrowdsourcingTiming.promptExpiresAfter,
      () => unawaited(
        localDataSource.updateTransferResponse(
          activeTrip.tripId,
          detectedAt,
          TransferResponses.ignored,
          false,
        ),
      ),
    );
  }

  Future<void> _recordBoardingDetected() async {
    final activeTrip = _activeTrip;
    if (activeTrip == null) return;
    await localDataSource.updateLatestPendingTransferBoardedAt(
      activeTrip.tripId,
      DateTime.now().toIso8601String(),
    );
    _potentialTransferStartTime = null;
  }

  Future<void> _handleAddSegment(Map<String, dynamic>? event) async {
    final activeTrip = _activeTrip ?? await localDataSource.getActiveTrip();
    if (activeTrip == null) return;
    _activeTrip = activeTrip;

    final modeValue = event?[CrowdsourcingPayloadKeys.mode];
    final mode = modeValue?.toString();
    final fare = _readNullableDouble(event?[CrowdsourcingPayloadKeys.fareEgp]);
    final startedAt = DateTime.now().toIso8601String();

    await localDataSource.addSegmentToActiveTrip(
      tripId: activeTrip.tripId,
      startedAtIso8601: startedAt,
      mode: mode?.trim().isEmpty == true ? null : mode,
      fareEgp: fare,
    );
    _activeTrip = await localDataSource.getActiveTrip();
    await _showRecordingNotification();
  }

  Future<void> _handleNotificationTransferRequested(
    Map<String, dynamic>? event,
  ) async {
    final androidService = service;
    if (androidService is AndroidServiceInstance) {
      await androidService.openApp();
    }
    await _handleAddSegment(<String, dynamic>{
      CrowdsourcingPayloadKeys.mode: null,
    });
    service.invoke(CrowdsourcingIpc.showModeSelector);
  }

  Future<void> _handleSetCurrentSegmentMode(Map<String, dynamic>? event) async {
    final activeTrip = _activeTrip ?? await localDataSource.getActiveTrip();
    if (activeTrip == null) return;
    final modeValue = event?[CrowdsourcingPayloadKeys.mode];
    final mode = modeValue?.toString().trim();
    final normalizedMode = mode == null || mode.isEmpty ? null : mode;

    await localDataSource.updateCurrentSegmentMode(
      activeTrip.tripId,
      normalizedMode,
    );
    _activeTrip = await localDataSource.getActiveTrip();
    await _showRecordingNotification();
  }

  Future<void> _handleConfirmTransfer(Map<String, dynamic>? event) async {
    final activeTrip = _activeTrip ?? await localDataSource.getActiveTrip();
    if (activeTrip == null) return;
    final detectedAt =
        event?[CrowdsourcingPayloadKeys.detectedAt]?.toString() ??
        _latestPendingTransferDetectedAt;
    if (detectedAt == null) return;

    await localDataSource.retroactiveSplitSegment(
      activeTrip.tripId,
      detectedAt,
    );
    await localDataSource.updateTransferResponse(
      activeTrip.tripId,
      detectedAt,
      TransferResponses.confirmed,
      true,
    );
    _activeTrip = await localDataSource.getActiveTrip();
    service.invoke(CrowdsourcingIpc.segmentSplitConfirmed);
    await _showRecordingNotification();
  }

  Future<void> _handleRejectTransfer(Map<String, dynamic>? event) async {
    final activeTrip = _activeTrip ?? await localDataSource.getActiveTrip();
    if (activeTrip == null) return;
    final detectedAt =
        event?[CrowdsourcingPayloadKeys.detectedAt]?.toString() ??
        _latestPendingTransferDetectedAt;
    if (detectedAt == null) return;

    await localDataSource.updateTransferResponse(
      activeTrip.tripId,
      detectedAt,
      TransferResponses.rejected,
      false,
    );
    service.invoke(CrowdsourcingIpc.transferRejected);
  }

  Future<void> _handleStopTrip({bool flushPendingBuffer = true}) async {
    if (_isStopping) return;
    _isStopping = true;
    final activeTrip = _activeTrip ?? await localDataSource.getActiveTrip();
    if (activeTrip == null) {
      _isStopping = false;
      return;
    }
    await _showPreparingTripNotification();
    if (flushPendingBuffer) {
      await _flushBuffer();
    }
    await _cancelRecordingResources();

    final endedAt = DateTime.now().toIso8601String();
    final segments = activeTrip.segments
        .map((segment) {
          if (segment.index != activeTrip.currentSegmentIndex) return segment;
          return segment.copyWith(endedAt: endedAt);
        })
        .toList(growable: false);
    final transfers = await localDataSource.getPotentialTransfers(
      activeTrip.tripId,
    );
    final stopped = activeTrip.copyWith(
      status: TripStatuses.stopped,
      endedAt: endedAt,
      segments: segments,
      potentialTransfers: transfers,
      totalDistanceM: _distanceM,
    );

    try {
      await localDataSource.saveActiveTrip(stopped);
    } on Object catch (error) {
      if (!_isStorageError(error)) rethrow;
    }
    await notifications.cancel(CrowdsourcingNotifications.recordingId);
    service.invoke(CrowdsourcingIpc.tripStopped, stopped.toMap());
    await _showReviewReadyNotification();
    service.stopSelf();
  }

  Future<void> _cancelRecordingResources() async {
    await _gpsSubscription?.cancel();
    await _activitySubscription?.cancel();
    _flushTimer?.cancel();
    _gpsWatchTimer?.cancel();
    _notificationTimer?.cancel();
    _debounceTimer?.cancel();
    _promptExpiryTimer?.cancel();
  }

  Future<void> _showRecordingNotification() async {
    final activeTrip = _activeTrip;
    if (activeTrip == null) return;
    final mode = activeTrip.segments.isEmpty
        ? null
        : activeTrip.segments.last.mode;
    final elapsed = DateTime.now()
        .difference(DateTime.parse(activeTrip.startedAt))
        .inSeconds;
    final body = _isGpsLost
        ? CrowdsourcingStrings.gpsLost
        : '${CrowdsourcingModes.displayName(mode)} · '
              '${(_distanceM / 1000).toStringAsFixed(1)} km · '
              '${_formatElapsed(elapsed)}';

    await notifications.show(
      CrowdsourcingNotifications.recordingId,
      CrowdsourcingStrings.recordingNotificationTitle,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          CrowdsourcingNotifications.recordingChannelId,
          CrowdsourcingStrings.recordingNotificationTitle,
          icon: '@mipmap/ic_launcher',
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          priority: Priority.low,
          importance: Importance.low,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              CrowdsourcingNotifications.actionTransfer,
              CrowdsourcingStrings.changedTransport,
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              CrowdsourcingNotifications.actionArrived,
              CrowdsourcingStrings.arrived,
              showsUserInterface: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPreparingTripNotification() async {
    final androidService = service;
    if (androidService is AndroidServiceInstance) {
      await androidService.setForegroundNotificationInfo(
        title: CrowdsourcingStrings.recordingNotificationTitle,
        content: CrowdsourcingStrings.preparingTripData,
      );
    }
  }

  Future<void> _showReviewReadyNotification() async {
    await notifications.show(
      CrowdsourcingNotifications.reviewReadyId,
      CrowdsourcingStrings.reviewReadyTitle,
      CrowdsourcingStrings.reviewReadyBody,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          CrowdsourcingNotifications.promptChannelId,
          CrowdsourcingStrings.reviewReadyTitle,
          icon: '@mipmap/ic_launcher',
          autoCancel: true,
          priority: Priority.high,
          importance: Importance.defaultImportance,
        ),
      ),
      payload: CrowdsourcingNotifications.reviewReadyPayload,
    );
  }

  Future<void> _showStorageFullNotification() async {
    await notifications.show(
      CrowdsourcingNotifications.storageFullId,
      CrowdsourcingStrings.storageFullTitle,
      CrowdsourcingStrings.storageFullBody,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          CrowdsourcingNotifications.promptChannelId,
          CrowdsourcingStrings.storageFullTitle,
          icon: '@mipmap/ic_launcher',
          autoCancel: true,
          priority: Priority.high,
          importance: Importance.defaultImportance,
        ),
      ),
    );
  }

  Future<void> _showSmartPromptNotification(
    String tripId,
    String detectedAt,
  ) async {
    await notifications.show(
      CrowdsourcingNotifications.smartPromptId,
      CrowdsourcingStrings.smartPromptTitle,
      CrowdsourcingStrings.smartPromptBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          CrowdsourcingNotifications.promptChannelId,
          CrowdsourcingStrings.smartPromptTitle,
          icon: '@mipmap/ic_launcher',
          autoCancel: true,
          ongoing: false,
          priority: Priority.high,
          importance: Importance.defaultImportance,
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              CrowdsourcingNotifications.actionConfirmTransfer,
              CrowdsourcingStrings.smartPromptYes,
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              CrowdsourcingNotifications.actionRejectTransfer,
              CrowdsourcingStrings.smartPromptNo,
              showsUserInterface: false,
            ),
          ],
        ),
      ),
      payload: jsonEncode(<String, dynamic>{
        CrowdsourcingPayloadKeys.tripId: tripId,
        CrowdsourcingPayloadKeys.detectedAt: detectedAt,
      }),
    );
  }

  Future<void> _showStationaryNotification() async {
    await notifications.show(
      CrowdsourcingNotifications.stationaryId,
      CrowdsourcingStrings.stillRecording,
      CrowdsourcingStrings.arrived,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          CrowdsourcingNotifications.promptChannelId,
          CrowdsourcingStrings.stillRecording,
          icon: '@mipmap/ic_launcher',
          priority: Priority.defaultPriority,
          importance: Importance.defaultImportance,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              CrowdsourcingNotifications.actionStop,
              CrowdsourcingStrings.arrived,
              showsUserInterface: true,
            ),
          ],
        ),
      ),
    );
  }

  String _formatElapsed(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    final parts = <String>[
      hours.toString().padLeft(2, '0'),
      minutes.toString().padLeft(2, '0'),
      secs.toString().padLeft(2, '0'),
    ];
    return parts.join(':');
  }

  double _median(List<double> values) {
    final sorted = List<double>.of(values, growable: false)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return (sorted[middle - 1] + sorted[middle]) / 2;
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

  double? _readNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
