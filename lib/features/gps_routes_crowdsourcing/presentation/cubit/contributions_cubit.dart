import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/trip_local_data_source.dart';
import 'contributions_state.dart';

class ContributionsCubit extends Cubit<ContributionsState> {
  final TripLocalDataSource localDataSource;

  ContributionsCubit({required this.localDataSource})
    : super(const ContributionsState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final trips = await localDataSource.getAllCompletedTripMetadata();
      trips.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      emit(state.copyWith(isLoading: false, trips: trips));
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  Future<void> deleteTrip(String tripId) async {
    await localDataSource.deleteTrip(tripId);
    await load();
  }
}
