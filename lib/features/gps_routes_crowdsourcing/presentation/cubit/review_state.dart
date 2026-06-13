import 'package:equatable/equatable.dart';

import '../../data/models/trip_metadata_model.dart';
import '../../data/models/trip_segment_model.dart';

class ReviewState extends Equatable {
  final TripMetadataModel tripMeta;
  final List<TripSegmentModel> segments;
  final bool isSubmitting;
  final String? error;
  final bool removedShortSegments;
  final bool noValidSegments;
  final bool submitSucceeded;
  final bool tripDeleted;

  const ReviewState({
    required this.tripMeta,
    required this.segments,
    this.isSubmitting = false,
    this.error,
    this.removedShortSegments = false,
    this.noValidSegments = false,
    this.submitSucceeded = false,
    this.tripDeleted = false,
  });

  ReviewState copyWith({
    TripMetadataModel? tripMeta,
    List<TripSegmentModel>? segments,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    bool? removedShortSegments,
    bool? noValidSegments,
    bool? submitSucceeded,
    bool? tripDeleted,
  }) {
    return ReviewState(
      tripMeta: tripMeta ?? this.tripMeta,
      segments: segments ?? this.segments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      removedShortSegments: removedShortSegments ?? this.removedShortSegments,
      noValidSegments: noValidSegments ?? this.noValidSegments,
      submitSucceeded: submitSucceeded ?? this.submitSucceeded,
      tripDeleted: tripDeleted ?? this.tripDeleted,
    );
  }

  bool get hasMissingModes {
    return segments.any((segment) => segment.mode == null);
  }

  @override
  List<Object?> get props => <Object?>[
    tripMeta,
    segments,
    isSubmitting,
    error,
    removedShortSegments,
    noValidSegments,
    submitSucceeded,
    tripDeleted,
  ];
}
