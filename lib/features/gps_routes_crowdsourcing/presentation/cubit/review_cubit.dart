import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../data/models/trip_metadata_model.dart';
import '../../data/models/trip_segment_model.dart';
import '../../data/services/trip_local_data_source.dart';
import 'review_state.dart';

class ReviewCubit extends Cubit<ReviewState> {
  final TripLocalDataSource localDataSource;

  ReviewCubit({
    required TripMetadataModel tripMeta,
    required this.localDataSource,
  }) : super(ReviewState(tripMeta: tripMeta, segments: tripMeta.segments));

  Future<void> init() async {
    if (state.segments.isNotEmpty) return;
    final fallbackSegment = TripSegmentModel(
      index: 0,
      startedAt: state.tripMeta.startedAt,
      confidence: SegmentConfidence.unknown,
    );
    final meta = state.tripMeta.copyWith(
      segments: <TripSegmentModel>[fallbackSegment],
    );
    await localDataSource.saveTripMetadata(meta);
    emit(
      state.copyWith(
        tripMeta: meta,
        segments: <TripSegmentModel>[fallbackSegment],
      ),
    );
  }

  Future<void> updateMode(int index, String? mode) async {
    final updated = state.segments
        .map((segment) {
          if (segment.index != index) return segment;
          return segment.copyWith(
            mode: mode,
            clearMode: mode == null,
            confidence: mode == null
                ? SegmentConfidence.unknown
                : SegmentConfidence.userConfirmed,
          );
        })
        .toList(growable: false);
    await _saveSegments(updated);
  }

  Future<void> updateFare(int index, double? fareEgp) async {
    final updated = state.segments
        .map((segment) {
          if (segment.index != index) return segment;
          return segment.copyWith(fareEgp: fareEgp, clearFare: fareEgp == null);
        })
        .toList(growable: false);
    await _saveSegments(updated);
  }

  Future<void> updateSegmentName(int index, String? name) async {
    final updated = state.segments
        .map((segment) {
          if (segment.index != index) return segment;
          return segment.copyWith(name: name, clearName: name == null);
        })
        .toList(growable: false);
    await _saveSegments(updated);
  }

  Future<void> updateRouteName(String value) async {
    final normalized = value.trim();
    final routeName = normalized.isEmpty ? null : normalized;
    final meta = state.tripMeta.copyWith(
      routeName: routeName,
      clearRouteName: routeName == null,
    );
    await localDataSource.saveTripMetadata(meta);
    emit(state.copyWith(tripMeta: meta, clearError: true));
  }

  Future<void> deleteSegment(int index) async {
    final updated = state.segments
        .where((segment) => segment.index != index)
        .toList(growable: false);
    if (updated.isEmpty) {
      await localDataSource.deleteTrip(state.tripMeta.tripId);
      emit(state.copyWith(segments: const [], noValidSegments: true));
      return;
    }
    await _saveSegments(updated);
  }

  Future<void> submitForFutureUpload() async {
    if (!state.hasRouteName) {
      emit(state.copyWith(error: CrowdsourcingStrings.routeNameRequired));
      return;
    }
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _saveSegments(state.segments);
      final persistedBeforeUpload =
          await localDataSource.getTripMetadata(state.tripMeta.tripId);
      final persistedSegments =
          persistedBeforeUpload?.segments ?? state.segments;
      await Future<void>.delayed(const Duration(seconds: 2));
      final gpxFilePath = state.tripMeta.gpxFilePath;
      if (gpxFilePath != null && gpxFilePath.trim().isNotEmpty) {
        localDataSource.deleteGpxFileSync(gpxFilePath);
      }
      final latestMeta =
          await localDataSource.getTripMetadata(state.tripMeta.tripId) ??
          state.tripMeta;
      final updated = latestMeta.copyWith(
        status: TripStatuses.uploaded,
        segments: persistedSegments,
        uploadAttemptCount: latestMeta.uploadAttemptCount + 1,
        contributionId: 'mock_${latestMeta.tripId}',
        lastUploadedAt: DateTime.now().toIso8601String(),
        clearGpxFilePath: true,
      );
      await localDataSource.saveTripMetadata(updated);
      await localDataSource.clearActiveTrip();
      emit(
        state.copyWith(
          tripMeta: updated,
          isSubmitting: false,
          clearError: true,
          submitSucceeded: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, error: error.toString()));
    }
  }

  Future<void> _saveSegments(List<TripSegmentModel> segments) async {
    final meta = state.tripMeta.copyWith(segments: segments);
    await localDataSource.saveTripMetadata(meta);
    emit(state.copyWith(tripMeta: meta, segments: segments));
  }

  Future<void> deleteTrip() async {
    await localDataSource.deleteTrip(state.tripMeta.tripId);
    emit(state.copyWith(tripDeleted: true));
  }
}
