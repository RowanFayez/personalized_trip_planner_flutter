import '../storage/hive/core_hive_boxes.dart';
import '../storage/hive/hive_service.dart';

class RoutePreferences {
  final int maxTransfers;
  final int walkingCutoffMinutes;
  final int topK;
  final List<String> restrictedModes;
  final String priority;
  final List<String> excludedMainStreets;

  const RoutePreferences({
    required this.maxTransfers,
    required this.walkingCutoffMinutes,
    required this.topK,
    required this.restrictedModes,
    required this.priority,
    required this.excludedMainStreets,
  });

  RoutePreferences copyWith({
    int? maxTransfers,
    int? walkingCutoffMinutes,
    int? topK,
    List<String>? restrictedModes,
    String? priority,
    List<String>? excludedMainStreets,
  }) {
    return RoutePreferences(
      maxTransfers: maxTransfers ?? this.maxTransfers,
      walkingCutoffMinutes: walkingCutoffMinutes ?? this.walkingCutoffMinutes,
      topK: topK ?? this.topK,
      restrictedModes: restrictedModes ?? this.restrictedModes,
      priority: priority ?? this.priority,
      excludedMainStreets: excludedMainStreets ?? this.excludedMainStreets,
    );
  }
}

class RoutePreferencesService {
  static const _kMaxTransfers = 'route_pref_max_transfers';
  static const _kWalkingCutoffMinutes = 'route_pref_walking_cutoff_min';

  // Legacy key (meters). Kept for migration.
  static const _kWalkingCutoffMetersLegacy = 'route_pref_walking_cutoff_m';
  static const _kTopK = 'route_pref_top_k';
  static const _kRestrictedModes = 'route_pref_restricted_modes';
  static const _kPriority = 'route_pref_priority';
  static const _kExcludedMainStreets = 'route_pref_main_streets_exclude';

  static const int defaultMaxTransfers = 2;
  static const int defaultWalkingCutoffMinutes = 19;
  static const int defaultTopK = 5;

  static const String defaultPriority = 'balanced';

  /// Default is "no restrictions".
  static const List<String> defaultRestrictedModes = <String>[];

  /// Default is no street exclusions.
  static const List<String> defaultExcludedMainStreets = <String>[];

  static const int minTransfers = 1;
  static const int maxTransfersLimit = 5;

  static const int minWalkingMinutes = 0;
  static const int maxWalkingMinutes = 60;

  /// Conversion used by the backend request builder: minutes -> meters.
  static const int metersPerMinute = 80;

  static const Set<String> allowedPriorities = <String>{
    'balanced',
    'fastest',
    'cheapest',
  };

  static const Map<String, String> arabicMainStreetToId = <String, String>{
    'كورنيش الإسكندرية': 'Coastal',
    'شارع أبو قير': 'Abou Qir',
    'ترعة المحمودية': 'Mahmoudia',
  };

  static const Set<String> allowedMainStreetIds = <String>{
    'Coastal',
    'Abou Qir',
    'Mahmoudia',
  };

  Future<RoutePreferences> load() async {
    final box = await HiveService.openBox<dynamic>(
      CoreHiveBoxes.routePreferences,
    );

    final rawMaxTransfers =
        (box.get(_kMaxTransfers) as int?) ?? defaultMaxTransfers;
    final maxTransfers = rawMaxTransfers
        .clamp(minTransfers, maxTransfersLimit)
        .toInt();

    int walkingMinutes;
    final storedMinutes = box.get(_kWalkingCutoffMinutes) as int?;
    if (storedMinutes != null) {
      walkingMinutes = storedMinutes;
    } else {
      final legacyMeters = box.get(_kWalkingCutoffMetersLegacy) as int?;
      walkingMinutes = legacyMeters != null
        ? (legacyMeters / metersPerMinute).round()
        : defaultWalkingCutoffMinutes;
    }
    walkingMinutes = walkingMinutes
      .clamp(minWalkingMinutes, maxWalkingMinutes)
      .toInt();

    final topK = (box.get(_kTopK) as int?) ?? defaultTopK;

    final rawPriority = (box.get(_kPriority) as String?)?.trim().toLowerCase();
    final priority = allowedPriorities.contains(rawPriority)
        ? rawPriority!
        : defaultPriority;

    final rawModes = box.get(_kRestrictedModes);
    final List<String>? modes = rawModes is List
        ? rawModes
              .whereType<String>()
              // Legacy value (old UI) — no longer supported.
              .where((m) => m.toLowerCase() != 'walking')
          // No longer supported.
          .where((m) => m.toLowerCase() != 'tram')
              .toList(growable: false)
        : null;

    final rawStreets = box.get(_kExcludedMainStreets);
    final List<String>? streets = rawStreets is List
        ? rawStreets
              .whereType<String>()
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .map((value) {
                final mapped = arabicMainStreetToId[value];
                if (mapped != null) return mapped;

                final normalized = value.toLowerCase();
                for (final allowed in allowedMainStreetIds) {
                  if (allowed.toLowerCase() == normalized) return allowed;
                }
                return null;
              })
              .whereType<String>()
              .toSet()
              .toList(growable: false)
        : null;

    return RoutePreferences(
      maxTransfers: maxTransfers,
      walkingCutoffMinutes: walkingMinutes,
      topK: topK,
      restrictedModes: modes == null
          ? defaultRestrictedModes
          : List<String>.unmodifiable(modes),
      priority: priority,
      excludedMainStreets: streets == null
          ? defaultExcludedMainStreets
          : List<String>.unmodifiable(streets),
    );
  }

  Future<void> save(RoutePreferences preferences) async {
    final box = await HiveService.openBox<dynamic>(
      CoreHiveBoxes.routePreferences,
    );
    await box.put(_kMaxTransfers, preferences.maxTransfers);
    await box.put(_kWalkingCutoffMinutes, preferences.walkingCutoffMinutes);
    await box.put(_kTopK, preferences.topK);
    await box.put(_kRestrictedModes, preferences.restrictedModes);
    await box.put(_kPriority, preferences.priority);
    await box.put(_kExcludedMainStreets, preferences.excludedMainStreets);
  }
}
