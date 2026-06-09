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
    final kept = state.segments
        .where((segment) => segment.pointCount >= 2)
        .toList(growable: false);
    if (kept.isEmpty) {
      await localDataSource.deleteTrip(state.tripMeta.tripId);
      emit(state.copyWith(noValidSegments: true, segments: const []));
      return;
    }
    if (kept.length == state.segments.length) return;
    final meta = state.tripMeta.copyWith(segments: kept);
    await localDataSource.saveTripMetadata(meta);
    emit(
      state.copyWith(
        tripMeta: meta,
        segments: kept,
        removedShortSegments: true,
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
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final updated = state.tripMeta.copyWith(
        status: TripStatuses.pendingUpload,
        segments: state.segments,
        uploadAttemptCount: state.tripMeta.uploadAttemptCount + 1,
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
