import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/preferences/data/managers/preferences_manager.dart';
import '../../domain/entities/routing_entities.dart';
import '../../domain/usecases/get_routes_usecase.dart';
import 'routing_state.dart';

class RoutingCubit extends Cubit<RoutingState> {
  final GetRoutesUseCase _getRoutesUseCase;
  final PreferencesManager _preferencesManager;

  CancelToken? _cancelToken;
  int _requestId = 0;

  static const String _noRouteFoundArabicMessage =
      'عفواً، لا توجد مسارات متاحة. حاول تغيير نقطة البداية أو النهاية، أو تعديل تفضيلات البحث.';

  RoutingCubit({
    required GetRoutesUseCase getRoutesUseCase,
    required PreferencesManager preferencesManager,
  }) : _getRoutesUseCase = getRoutesUseCase,
       _preferencesManager = preferencesManager,
       super(RoutingState.initial());

  void cancelActiveRequest() {
    _requestId++;
    _cancelToken?.cancel();
    _cancelToken = null;
  }

  @override
  Future<void> close() {
    cancelActiveRequest();
    return super.close();
  }

  Future<void> fetchRoutes({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    cancelActiveRequest();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    final requestId = _requestId;

    emit(state.copyWith(status: RoutingStatus.loading, errorMessage: null));

    try {
      // Load all preference data at once for cleaner request building
      final prefData = await _preferencesManager.loadPreferenceData();
      if (requestId != _requestId || cancelToken.isCancelled) return;

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

      final result = await _getRoutesUseCase(request, cancelToken: cancelToken);
      if (requestId != _requestId || cancelToken.isCancelled) return;

      result.when(
        success: (data) {
          if (requestId != _requestId || cancelToken.isCancelled) return;
          final journeys = data.journeys;
          if (journeys.isEmpty || data.numJourneys == 0) {
            _emitNoRoutes();
            return;
          }

          final sortedJourneys = _sortJourneys(
            journeys,
            priority: request.priority,
          );
          final sortedResult = RoutingResult(
            numJourneys: sortedJourneys.length,
            journeys: sortedJourneys,
          );

          emit(
            state.copyWith(
              status: RoutingStatus.success,
              result: sortedResult,
              selectedJourneyIndex: 0,
            ),
          );
        },
        failure: (_) {
          if (requestId != _requestId || cancelToken.isCancelled) return;
          _emitNoRoutes();
        },
      );
    } catch (_) {
      // Catch-all: prevents null-iterator and any other uncaught crashes.
      if (requestId != _requestId || cancelToken.isCancelled) return;
      _emitNoRoutes();
    }
  }

  void _emitNoRoutes() {
    emit(
      state.copyWith(
        status: RoutingStatus.failure,
        result: const RoutingResult(numJourneys: 0, journeys: <Journey>[]),
        errorMessage: _noRouteFoundArabicMessage,
        selectedJourneyIndex: 0,
      ),
    );
  }

  void emitNoRoutes() {
    _emitNoRoutes();
  }

  List<Journey> _sortJourneys(
    List<Journey> journeys, {
    required String priority,
  }) {
    final p = priority.trim().toLowerCase();
    if (p == 'balanced') {
      // Preserve backend order.
      return List<Journey>.unmodifiable(journeys);
    }

    final indexed = journeys.asMap().entries.toList(growable: false);

    int compareWithIndex(
      Comparable<dynamic> a,
      Comparable<dynamic> b,
      int ia,
      int ib,
    ) {
      final c = a.compareTo(b);
      if (c != 0) return c;
      return ia.compareTo(ib);
    }

    final sorted = List<MapEntry<int, Journey>>.from(indexed);

    if (p == 'cheapest') {
      sorted.sort(
        (a, b) => compareWithIndex(
          a.value.summary.cost,
          b.value.summary.cost,
          a.key,
          b.key,
        ),
      );
    } else if (p == 'fastest') {
      sorted.sort(
        (a, b) => compareWithIndex(
          a.value.summary.totalTimeMinutes,
          b.value.summary.totalTimeMinutes,
          a.key,
          b.key,
        ),
      );
    } else {
      // Unknown priority — fall back to backend order.
      return List<Journey>.unmodifiable(journeys);
    }

    return List<Journey>.unmodifiable(sorted.map((e) => e.value));
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
    cancelActiveRequest();
    emit(RoutingState.initial());
  }
}
