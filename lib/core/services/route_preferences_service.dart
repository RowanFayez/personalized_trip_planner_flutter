import '../storage/hive/core_hive_boxes.dart';
import '../storage/hive/hive_service.dart';

class RoutePreferences {
  final int maxTransfers;
  final int walkingCutoffMeters;
  final int topK;
  final List<String> restrictedModes;
  final String priority;
  final List<String> excludedMainStreets;

  const RoutePreferences({
    required this.maxTransfers,
    required this.walkingCutoffMeters,
    required this.topK,
    required this.restrictedModes,
    required this.priority,
    required this.excludedMainStreets,
  });

  RoutePreferences copyWith({
    int? maxTransfers,
    int? walkingCutoffMeters,
    int? topK,
    List<String>? restrictedModes,
    String? priority,
    List<String>? excludedMainStreets,
  }) {
    return RoutePreferences(
      maxTransfers: maxTransfers ?? this.maxTransfers,
      walkingCutoffMeters: walkingCutoffMeters ?? this.walkingCutoffMeters,
      topK: topK ?? this.topK,
      restrictedModes: restrictedModes ?? this.restrictedModes,
      priority: priority ?? this.priority,
      excludedMainStreets: excludedMainStreets ?? this.excludedMainStreets,
    );
  }
}

class RoutePreferencesService {
  static const _kMaxTransfers = 'route_pref_max_transfers';
  static const _kWalkingCutoff = 'route_pref_walking_cutoff_m';
  static const _kTopK = 'route_pref_top_k';
  static const _kRestrictedModes = 'route_pref_restricted_modes';
  static const _kPriority = 'route_pref_priority';
  static const _kExcludedMainStreets = 'route_pref_main_streets_exclude';

  static const int defaultMaxTransfers = 2;
  static const int defaultWalkingCutoffMeters = 1500;
  static const int defaultTopK = 5;

  static const String defaultPriority = 'balanced';

  /// Default is "no restrictions".
  static const List<String> defaultRestrictedModes = <String>[];

  /// Default is no street exclusions.
  static const List<String> defaultExcludedMainStreets = <String>[];

  static const int minTransfers = 1;
  static const int maxTransfersLimit = 5;

  static const Set<String> allowedPriorities = <String>{
    'balanced',
    'fastest',
    'cheapest',
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
    final walkingCutoff =
        (box.get(_kWalkingCutoff) as int?) ?? defaultWalkingCutoffMeters;
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
              .toList(growable: false)
        : null;

    final rawStreets = box.get(_kExcludedMainStreets);
    final List<String>? streets = rawStreets is List
        ? rawStreets
              .whereType<String>()
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList(growable: false)
        : null;

    return RoutePreferences(
      maxTransfers: maxTransfers,
      walkingCutoffMeters: walkingCutoff,
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
    await box.put(_kWalkingCutoff, preferences.walkingCutoffMeters);
    await box.put(_kTopK, preferences.topK);
    await box.put(_kRestrictedModes, preferences.restrictedModes);
    await box.put(_kPriority, preferences.priority);
    await box.put(_kExcludedMainStreets, preferences.excludedMainStreets);
  }
}
