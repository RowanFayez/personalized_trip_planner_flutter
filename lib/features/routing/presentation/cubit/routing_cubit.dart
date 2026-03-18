import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/route_preferences_service.dart';
import '../../domain/entities/routing_entities.dart';
import '../../domain/usecases/get_routes_usecase.dart';
import 'routing_state.dart';

class RoutingCubit extends Cubit<RoutingState> {
  final GetRoutesUseCase _getRoutesUseCase;
  final RoutePreferencesService _routePreferencesService;

  RoutingCubit({
    required GetRoutesUseCase getRoutesUseCase,
    required RoutePreferencesService routePreferencesService,
  }) : _getRoutesUseCase = getRoutesUseCase,
       _routePreferencesService = routePreferencesService,
       super(RoutingState.initial());

  Future<void> fetchRoutes({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    emit(state.copyWith(status: RoutingStatus.loading, errorMessage: null));

    final prefs = await _routePreferencesService.load();

    final request = RoutesRequest(
      startLat: startLat,
      startLon: startLon,
      endLat: endLat,
      endLon: endLon,
      maxTransfers: prefs.maxTransfers,
      walkingCutoff: prefs.walkingCutoffMeters,
      topK: prefs.topK,
      restrictedModes: prefs.restrictedModes,
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
