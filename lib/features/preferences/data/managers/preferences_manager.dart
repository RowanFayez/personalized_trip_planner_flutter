import 'package:nextstation/core/services/route_preferences_service.dart';
import 'package:nextstation/features/routing/domain/entities/routing_entities.dart';

import '../builders/mode_filter_builder.dart';

/// Coordinates preference loading and request building for routing.
/// Bridges preferences storage and routing request creation.
class PreferencesManager {
  final RoutePreferencesService _preferencesService;

  PreferencesManager({required RoutePreferencesService preferencesService})
    : _preferencesService = preferencesService;

  /// Loads saved preferences and builds filters for routing.
  Future<RouteFilters> buildFilters() async {
    final prefs = await _preferencesService.load();

    final modeFilter = ModeFilterBuilder.build(prefs.restrictedModes);

    return RouteFilters(
      modes: modeFilter,
      mainStreets: ModeFilter(
        include: const <String>[],
        exclude: prefs.excludedMainStreets,
        includeMatch: 'any',
      ),
    );
  }

  /// Loads all preference data for request building.
  Future<PreferenceData> loadPreferenceData() async {
    final prefs = await _preferencesService.load();
    final filters = await buildFilters();

    return PreferenceData(
      maxTransfers: prefs.maxTransfers,
      walkingCutoffMinutes: prefs.walkingCutoffMinutes,
      priority: prefs.priority,
      topK: prefs.topK,
      filters: filters,
    );
  }
}

/// Container for preference data used in routing requests.
class PreferenceData {
  final int maxTransfers;
  final int walkingCutoffMinutes;
  final String priority;
  final int topK;
  final RouteFilters filters;

  const PreferenceData({
    required this.maxTransfers,
    required this.walkingCutoffMinutes,
    required this.priority,
    required this.topK,
    required this.filters,
  });
}
