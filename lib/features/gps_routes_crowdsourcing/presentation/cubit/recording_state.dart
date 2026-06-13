import 'package:equatable/equatable.dart';

import '../../data/models/gps_point_model.dart';
import '../../data/models/trip_metadata_model.dart';

abstract class RecordingState extends Equatable {
  const RecordingState();

  @override
  List<Object?> get props => <Object?>[];
}

class RecordingInitial extends RecordingState {
  const RecordingInitial();
}

class RecordingInProgress extends RecordingState {
  final String tripId;
  final String? currentMode;
  final String currentModeDisplay;
  final int elapsedSeconds;
  final double distanceM;
  final int segmentCount;
  final bool isPaused;
  final bool isGpsLost;
  final List<GpsPointModel> recentPoints;
  final Map<int, String?> segmentModes;

  const RecordingInProgress({
    required this.tripId,
    required this.currentMode,
    required this.currentModeDisplay,
    required this.elapsedSeconds,
    required this.distanceM,
    required this.segmentCount,
    required this.isPaused,
    required this.isGpsLost,
    required this.recentPoints,
    required this.segmentModes,
  });

  RecordingInProgress copyWith({
    String? tripId,
    String? currentMode,
    bool clearCurrentMode = false,
    String? currentModeDisplay,
    int? elapsedSeconds,
    double? distanceM,
    int? segmentCount,
    bool? isPaused,
    bool? isGpsLost,
    List<GpsPointModel>? recentPoints,
    Map<int, String?>? segmentModes,
  }) {
    final nextMode = clearCurrentMode ? null : currentMode ?? this.currentMode;
    return RecordingInProgress(
      tripId: tripId ?? this.tripId,
      currentMode: nextMode,
      currentModeDisplay: currentModeDisplay ?? this.currentModeDisplay,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      distanceM: distanceM ?? this.distanceM,
      segmentCount: segmentCount ?? this.segmentCount,
      isPaused: isPaused ?? this.isPaused,
      isGpsLost: isGpsLost ?? this.isGpsLost,
      recentPoints: recentPoints ?? this.recentPoints,
      segmentModes: segmentModes ?? this.segmentModes,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    tripId,
    currentMode,
    currentModeDisplay,
    elapsedSeconds,
    distanceM,
    segmentCount,
    isPaused,
    isGpsLost,
    recentPoints,
    segmentModes,
  ];
}

class RecordingSmartPromptFired extends RecordingState {
  final String detectedAt;
  final RecordingInProgress previous;

  const RecordingSmartPromptFired({
    required this.detectedAt,
    required this.previous,
  });

  @override
  List<Object?> get props => <Object?>[detectedAt, previous];
}

class RecordingModeSelectionRequested extends RecordingState {
  final RecordingInProgress previous;

  const RecordingModeSelectionRequested({required this.previous});

  @override
  List<Object?> get props => <Object?>[previous];
}

class RecordingGeneratingGpx extends RecordingState {
  const RecordingGeneratingGpx();
}

class RecordingComplete extends RecordingState {
  final TripMetadataModel tripMeta;
  final bool shouldOpenReview;

  const RecordingComplete({
    required this.tripMeta,
    this.shouldOpenReview = true,
  });

  @override
  List<Object?> get props => <Object?>[tripMeta, shouldOpenReview];
}

class RecordingError extends RecordingState {
  final String message;

  const RecordingError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}
