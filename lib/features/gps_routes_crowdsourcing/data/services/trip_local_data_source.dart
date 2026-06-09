import 'dart:io';

import 'package:hive/hive.dart';

import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../../../core/storage/hive/core_hive_boxes.dart';
import '../../../../core/storage/hive/hive_service.dart';
import '../models/gps_point_model.dart';
import '../models/potential_transfer_model.dart';
import '../models/trip_metadata_model.dart';
import '../models/trip_segment_model.dart';

class TripLocalDataSource {
  Future<Box<dynamic>> get _box {
    return HiveService.openBox<dynamic>(CoreHiveBoxes.crowdsourcingBox);
  }

  Future<void> saveActiveTrip(TripMetadataModel trip) async {
    final box = await _box;
    await box.put(CrowdsourcingHiveKeys.activeTrip, trip.toMap());
  }

  Future<TripMetadataModel?> getActiveTrip() async {
    final box = await _box;
    final raw = box.get(CrowdsourcingHiveKeys.activeTrip);
    if (raw is! Map) return null;
    return TripMetadataModel.fromMap(raw);
  }

  Future<void> clearActiveTrip() async {
    final box = await _box;
    await box.delete(CrowdsourcingHiveKeys.activeTrip);
  }

  Future<void> appendGpsPointsBatch(
    String tripId,
    List<GpsPointModel> points,
  ) async {
    if (points.isEmpty) return;
    try {
      final box = await _box;
      var batchCount = _readInt(box.get(_gpsBatchCountKey(tripId)));

      for (
        var start = 0;
        start < points.length;
        start += CrowdsourcingLimits.gpsBufferMax
      ) {
        final end = (start + CrowdsourcingLimits.gpsBufferMax).clamp(
          0,
          points.length,
        );
        final chunk = points
            .sublist(start, end)
            .map((point) => point.toMap())
            .toList(growable: false);
        batchCount += 1;
        await box.put(_gpsBatchKey(tripId, batchCount), chunk);
      }

      await box.put(_gpsBatchCountKey(tripId), batchCount);
    } on FileSystemException catch (error) {
      throw CrowdsourcingStorageFullException(error.toString());
    } on HiveError catch (error) {
      if (!_isStorageFailure(error.message)) rethrow;
      throw CrowdsourcingStorageFullException(error.message);
    }
  }

  Future<List<GpsPointModel>> getGpsPoints(String tripId) async {
    final box = await _box;
    final legacyRaw = box.get('${CrowdsourcingHiveKeys.gpsPrefix}$tripId');
    if (legacyRaw is Iterable) {
      return legacyRaw
          .whereType<Map>()
          .map((item) => GpsPointModel.fromMap(item))
          .toList(growable: false);
    }

    final batchCount = _readInt(box.get(_gpsBatchCountKey(tripId)));
    final points = <GpsPointModel>[];
    for (var i = 1; i <= batchCount; i += 1) {
      final raw = box.get(_gpsBatchKey(tripId, i));
      if (raw is! Iterable) continue;
      points.addAll(
        raw.whereType<Map>().map((item) => GpsPointModel.fromMap(item)),
      );
    }
    points.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
    return points;
  }

  Future<void> deleteGpsPoints(String tripId) async {
    final box = await _box;
    final batchCount = _readInt(box.get(_gpsBatchCountKey(tripId)));
    for (var i = 1; i <= batchCount; i += 1) {
      await box.delete(_gpsBatchKey(tripId, i));
    }
    await box.delete(_gpsBatchCountKey(tripId));
    await box.delete('${CrowdsourcingHiveKeys.gpsPrefix}$tripId');
  }

  Future<void> deleteTrip(String tripId) async {
    final box = await _box;
    final meta = await getTripMetadata(tripId);
    final active = await getActiveTrip();
    final gpxPath = meta?.gpxFilePath ?? active?.gpxFilePath;

    if (gpxPath != null && gpxPath.trim().isNotEmpty) {
      final file = File(gpxPath);
      if (await file.exists()) await file.delete();
    }

    await deleteGpsPoints(tripId);
    await box.delete(_transfersKey(tripId));
    await box.delete(_tripMetaKey(tripId));
    final keys = _readStringList(box.get(CrowdsourcingHiveKeys.tripMetaKeys))
      ..removeWhere((key) => key == tripId);
    await box.put(CrowdsourcingHiveKeys.tripMetaKeys, keys);
    if (active?.tripId == tripId) await clearActiveTrip();
  }

  Future<void> addPotentialTransfer(
    String tripId,
    PotentialTransferModel transfer,
  ) async {
    final box = await _box;
    final transfers = await _getTransfers(box, tripId);
    final exists = transfers.any(
      (item) => item.detectedAt == transfer.detectedAt,
    );
    if (!exists) transfers.add(transfer);
    await _saveTransfers(box, tripId, transfers);
  }

  Future<void> updateTransferResponse(
    String tripId,
    String detectedAt,
    String response,
    bool resulted,
  ) async {
    final box = await _box;
    final transfers = await _getTransfers(box, tripId);
    final updated = transfers
        .map(
          (transfer) => transfer.detectedAt == detectedAt
              ? transfer.copyWith(
                  userResponse: response,
                  resultedInSegmentSplit: resulted,
                )
              : transfer,
        )
        .toList(growable: false);
    await _saveTransfers(box, tripId, updated);
    await _syncTransfersToMetadata(tripId, updated);
  }

  Future<void> updateLatestPendingTransferBoardedAt(
    String tripId,
    String boardedAtIso8601,
  ) async {
    final box = await _box;
    final transfers = await _getTransfers(box, tripId);
    final targetIndex = transfers.lastIndexWhere(
      (transfer) => transfer.boardedAt == null,
    );
    if (targetIndex < 0) return;

    transfers[targetIndex] = transfers[targetIndex].copyWith(
      boardedAt: boardedAtIso8601,
    );
    await _saveTransfers(box, tripId, transfers);
    await _syncTransfersToMetadata(tripId, transfers);
  }

  Future<void> markExpiredPendingTransfersIgnored(
    String tripId,
    DateTime now,
  ) async {
    final box = await _box;
    final transfers = await _getTransfers(box, tripId);
    var changed = false;
    final updated = transfers
        .map((transfer) {
          if (transfer.userResponse != null) return transfer;
          final sentAt = DateTime.tryParse(transfer.notificationSentAt);
          if (sentAt == null) return transfer;
          if (now.difference(sentAt) < CrowdsourcingTiming.promptExpiresAfter) {
            return transfer;
          }
          changed = true;
          return transfer.copyWith(
            userResponse: TransferResponses.ignored,
            resultedInSegmentSplit: false,
          );
        })
        .toList(growable: false);

    if (!changed) return;
    await _saveTransfers(box, tripId, updated);
    await _syncTransfersToMetadata(tripId, updated);
  }

  Future<void> retroactiveSplitSegment(
    String tripId,
    String splitAtIso8601,
  ) async {
    final activeTrip = await getActiveTrip();
    if (activeTrip == null || activeTrip.tripId != tripId) return;

    final currentIndex = activeTrip.currentSegmentIndex;
    final nextIndex = currentIndex + 1;
    final segments = activeTrip.segments
        .map((segment) {
          if (segment.index != currentIndex) return segment;
          return segment.copyWith(endedAt: splitAtIso8601);
        })
        .toList(growable: true);

    final hasNext = segments.any((segment) => segment.index == nextIndex);
    if (!hasNext) {
      segments.add(
        TripSegmentModel(index: nextIndex, startedAt: splitAtIso8601),
      );
    }

    await saveActiveTrip(
      activeTrip.copyWith(segments: segments, currentSegmentIndex: nextIndex),
    );
  }

  Future<void> addSegmentToActiveTrip({
    required String tripId,
    required String startedAtIso8601,
    String? mode,
    double? fareEgp,
  }) async {
    final activeTrip = await getActiveTrip();
    if (activeTrip == null || activeTrip.tripId != tripId) return;

    final currentIndex = activeTrip.currentSegmentIndex;
    final nextIndex = currentIndex + 1;
    final segments = activeTrip.segments
        .map((segment) {
          if (segment.index != currentIndex) return segment;
          return segment.copyWith(endedAt: startedAtIso8601, fareEgp: fareEgp);
        })
        .toList(growable: true);

    segments.add(
      TripSegmentModel(
        index: nextIndex,
        mode: mode,
        fareEgp: fareEgp,
        startedAt: startedAtIso8601,
        confidence: mode == null
            ? SegmentConfidence.unknown
            : SegmentConfidence.userConfirmed,
      ),
    );

    await saveActiveTrip(
      activeTrip.copyWith(segments: segments, currentSegmentIndex: nextIndex),
    );
  }

  Future<void> updateCurrentSegmentMode(String tripId, String? mode) async {
    final activeTrip = await getActiveTrip();
    if (activeTrip == null || activeTrip.tripId != tripId) return;
    final updatedSegments = activeTrip.segments
        .map((segment) {
          if (segment.index != activeTrip.currentSegmentIndex) return segment;
          return segment.copyWith(
            mode: mode,
            clearMode: mode == null,
            confidence: mode == null
                ? SegmentConfidence.unknown
                : SegmentConfidence.userConfirmed,
          );
        })
        .toList(growable: false);
    await saveActiveTrip(activeTrip.copyWith(segments: updatedSegments));
  }

  Future<void> saveTripMetadata(TripMetadataModel meta) async {
    final box = await _box;
    await box.put(_tripMetaKey(meta.tripId), meta.toMap());

    final keys = _readStringList(box.get(CrowdsourcingHiveKeys.tripMetaKeys));
    if (!keys.contains(meta.tripId)) {
      keys.add(meta.tripId);
      await box.put(CrowdsourcingHiveKeys.tripMetaKeys, keys);
    }
  }

  Future<TripMetadataModel?> getTripMetadata(String tripId) async {
    final box = await _box;
    final raw = box.get(_tripMetaKey(tripId));
    if (raw is! Map) return null;
    return TripMetadataModel.fromMap(raw);
  }

  Future<List<TripMetadataModel>> getAllCompletedTripMetadata() async {
    final box = await _box;
    final keys = _readStringList(box.get(CrowdsourcingHiveKeys.tripMetaKeys));
    final trips = <TripMetadataModel>[];
    for (final tripId in keys) {
      final raw = box.get(_tripMetaKey(tripId));
      if (raw is Map) trips.add(TripMetadataModel.fromMap(raw));
    }
    return trips;
  }

  Future<void> updateTripStatus(String tripId, String status) async {
    final activeTrip = await getActiveTrip();
    if (activeTrip != null && activeTrip.tripId == tripId) {
      await saveActiveTrip(activeTrip.copyWith(status: status));
      return;
    }

    final meta = await getTripMetadata(tripId);
    if (meta == null) return;
    await saveTripMetadata(meta.copyWith(status: status));
  }

  Future<void> updateTripAfterUpload(
    String tripId,
    String contributionId,
  ) async {
    final meta = await getTripMetadata(tripId);
    if (meta == null) return;
    await saveTripMetadata(
      meta.copyWith(
        status: TripStatuses.uploaded,
        contributionId: contributionId,
        lastUploadedAt: DateTime.now().toIso8601String(),
        clearGpxFilePath: true,
      ),
    );
  }

  Future<void> replaceTripSegments(
    String tripId,
    List<TripSegmentModel> segments,
  ) async {
    final meta = await getTripMetadata(tripId);
    if (meta == null) return;
    final nextIndex = segments.isEmpty ? 0 : segments.last.index;
    await saveTripMetadata(
      meta.copyWith(segments: segments, currentSegmentIndex: nextIndex),
    );
  }

  Future<void> mergeTransfersIntoActiveTrip(String tripId) async {
    final activeTrip = await getActiveTrip();
    if (activeTrip == null || activeTrip.tripId != tripId) return;
    final box = await _box;
    final transfers = await _getTransfers(box, tripId);
    await saveActiveTrip(activeTrip.copyWith(potentialTransfers: transfers));
  }

  Future<List<PotentialTransferModel>> getPotentialTransfers(
    String tripId,
  ) async {
    final box = await _box;
    return _getTransfers(box, tripId);
  }

  Future<List<PotentialTransferModel>> _getTransfers(
    Box<dynamic> box,
    String tripId,
  ) async {
    final raw = box.get(_transfersKey(tripId));
    if (raw is! Iterable) return <PotentialTransferModel>[];
    return raw
        .whereType<Map>()
        .map((item) => PotentialTransferModel.fromMap(item))
        .toList(growable: true);
  }

  Future<void> _saveTransfers(
    Box<dynamic> box,
    String tripId,
    List<PotentialTransferModel> transfers,
  ) async {
    await box.put(
      _transfersKey(tripId),
      transfers.map((transfer) => transfer.toMap()).toList(growable: false),
    );
  }

  Future<void> _syncTransfersToMetadata(
    String tripId,
    List<PotentialTransferModel> transfers,
  ) async {
    final active = await getActiveTrip();
    if (active != null && active.tripId == tripId) {
      await saveActiveTrip(active.copyWith(potentialTransfers: transfers));
    }

    final meta = await getTripMetadata(tripId);
    if (meta != null) {
      await saveTripMetadata(meta.copyWith(potentialTransfers: transfers));
    }
  }

  String _gpsBatchCountKey(String tripId) {
    return '${CrowdsourcingHiveKeys.gpsPrefix}${tripId}_batch_count';
  }

  String _gpsBatchKey(String tripId, int batchIndex) {
    return '${CrowdsourcingHiveKeys.gpsPrefix}${tripId}_batch_$batchIndex';
  }

  String _transfersKey(String tripId) {
    return '${CrowdsourcingHiveKeys.transfersPrefix}$tripId';
  }

  String _tripMetaKey(String tripId) {
    return '${CrowdsourcingHiveKeys.tripMetaPrefix}$tripId';
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _readStringList(Object? value) {
    if (value is! Iterable) return <String>[];
    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: true);
  }

  bool _isStorageFailure(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('space') ||
        normalized.contains('quota') ||
        normalized.contains('full') ||
        normalized.contains('file system');
  }
}

class CrowdsourcingStorageFullException implements Exception {
  final String message;

  const CrowdsourcingStorageFullException(this.message);

  @override
  String toString() => message;
}
