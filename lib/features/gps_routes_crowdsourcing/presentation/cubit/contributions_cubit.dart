import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../data/models/trip_metadata_model.dart';
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
      final rawActiveTrip = await localDataSource.getActiveTrip();
      final isServiceArmed = await localDataSource.isRecordingServiceArmed();
      final activeTrip = isServiceArmed && _visibleActiveTrip(rawActiveTrip)
          ? rawActiveTrip
          : null;
      emit(
        state.copyWith(
          isLoading: false,
          trips: trips,
          activeTrip: activeTrip,
          clearActiveTrip: activeTrip == null,
          canCreateTrip: await localDataSource.canCreateTrip(),
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  Future<void> deleteTrip(String tripId) async {
    await localDataSource.deleteTrip(tripId);
    await load();
  }

  bool _visibleActiveTrip(TripMetadataModel? trip) {
    final status = trip?.status;
    return status == TripStatuses.recording ||
        status == TripStatuses.paused ||
        status == TripStatuses.gpsLost;
  }
}
