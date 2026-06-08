import 'package:equatable/equatable.dart';

import '../../data/models/trip_metadata_model.dart';
import '../../data/models/trip_segment_model.dart';

class ReviewState extends Equatable {
  final TripMetadataModel tripMeta;
  final List<TripSegmentModel> segments;
  final bool isSubmitting;
  final String? error;
  final bool removedShortSegments;

  const ReviewState({
    required this.tripMeta,
    required this.segments,
    this.isSubmitting = false,
    this.error,
    this.removedShortSegments = false,
  });

  ReviewState copyWith({
    TripMetadataModel? tripMeta,
    List<TripSegmentModel>? segments,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    bool? removedShortSegments,
  }) {
    return ReviewState(
      tripMeta: tripMeta ?? this.tripMeta,
      segments: segments ?? this.segments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      removedShortSegments: removedShortSegments ?? this.removedShortSegments,
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
  ];
}
