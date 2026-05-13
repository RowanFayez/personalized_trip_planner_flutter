import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/preferences/data/managers/preferences_manager.dart';
import '../../domain/entities/routing_entities.dart';
import '../../domain/usecases/get_routes_usecase.dart';
import 'routing_state.dart';

class RoutingCubit extends Cubit<RoutingState> {
  final GetRoutesUseCase _getRoutesUseCase;
  final PreferencesManager _preferencesManager;

  RoutingCubit({
    required GetRoutesUseCase getRoutesUseCase,
    required PreferencesManager preferencesManager,
  }) : _getRoutesUseCase = getRoutesUseCase,
       _preferencesManager = preferencesManager,
       super(RoutingState.initial());

  Future<void> fetchRoutes({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    emit(state.copyWith(status: RoutingStatus.loading, errorMessage: null));

    // Load all preference data at once for cleaner request building
    final prefData = await _preferencesManager.loadPreferenceData();

    // Build request with all preferences applied
    final request = RoutesRequest(
      startLat: startLat,
      startLon: startLon,
      endLat: endLat,
      endLon: endLon,
      maxTransfers: prefData.maxTransfers,
      walkingCutoffMinutes: prefData.walkingCutoffMinutes,
      priority: prefData.priority,
      topK: prefData.topK,
      filters: prefData.filters,
    );

    final result = await _getRoutesUseCase(request);

    result.when(
      success: (data) {
        emit(
          state.copyWith(
            status: RoutingStatus.success,
            result: data,
            selectedJourneyIndex: 0,
          ),
        );
      },
      failure: (err) {
        emit(
          state.copyWith(
            status: RoutingStatus.failure,
            errorMessage: err.message,
          ),
        );
      },
    );
  }

  void selectJourney(int index) {
    final journeys = state.result?.journeys ?? const [];
    if (journeys.isEmpty) return;
    final clamped = index.clamp(0, journeys.length - 1);
    emit(state.copyWith(selectedJourneyIndex: clamped));
  }

  void nextJourney() {
    final journeys = state.result?.journeys ?? const [];
    if (journeys.isEmpty) return;
    selectJourney((state.selectedJourneyIndex + 1) % journeys.length);
  }

  void previousJourney() {
    final journeys = state.result?.journeys ?? const [];
    if (journeys.isEmpty) return;
    final nextIndex = (state.selectedJourneyIndex - 1) < 0
        ? journeys.length - 1
        : (state.selectedJourneyIndex - 1);
    selectJourney(nextIndex);
  }

  void clear() {
    emit(RoutingState.initial());
  }
}
