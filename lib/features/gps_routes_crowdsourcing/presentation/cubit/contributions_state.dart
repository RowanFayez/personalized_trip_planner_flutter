import 'package:equatable/equatable.dart';

import '../../data/models/trip_metadata_model.dart';

class ContributionsState extends Equatable {
  final bool isLoading;
  final List<TripMetadataModel> trips;
  final String? error;

  const ContributionsState({
    this.isLoading = false,
    this.trips = const <TripMetadataModel>[],
    this.error,
  });

  ContributionsState copyWith({
    bool? isLoading,
    List<TripMetadataModel>? trips,
    String? error,
    bool clearError = false,
  }) {
    return ContributionsState(
      isLoading: isLoading ?? this.isLoading,
      trips: trips ?? this.trips,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[isLoading, trips, error];
}
