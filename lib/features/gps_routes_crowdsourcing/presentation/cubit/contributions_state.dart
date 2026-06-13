import 'package:equatable/equatable.dart';

import '../../data/models/trip_metadata_model.dart';

class ContributionsState extends Equatable {
  final bool isLoading;
  final List<TripMetadataModel> trips;
  final TripMetadataModel? activeTrip;
  final bool canCreateTrip;
  final String? error;

  const ContributionsState({
    this.isLoading = false,
    this.trips = const <TripMetadataModel>[],
    this.activeTrip,
    this.canCreateTrip = true,
    this.error,
  });

  ContributionsState copyWith({
    bool? isLoading,
    List<TripMetadataModel>? trips,
    TripMetadataModel? activeTrip,
    bool clearActiveTrip = false,
    bool? canCreateTrip,
    String? error,
    bool clearError = false,
  }) {
    return ContributionsState(
      isLoading: isLoading ?? this.isLoading,
      trips: trips ?? this.trips,
      activeTrip: clearActiveTrip ? null : activeTrip ?? this.activeTrip,
      canCreateTrip: canCreateTrip ?? this.canCreateTrip,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isLoading,
    trips,
    activeTrip,
    canCreateTrip,
    error,
  ];
}
