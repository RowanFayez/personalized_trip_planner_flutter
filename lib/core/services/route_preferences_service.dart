import '../storage/hive/core_hive_boxes.dart';
import '../storage/hive/hive_service.dart';

class RoutePreferences {
  final int maxTransfers;
  final int walkingCutoffMeters;
  final int topK;
  final List<String> restrictedModes;

  const RoutePreferences({
    required this.maxTransfers,
    required this.walkingCutoffMeters,
    required this.topK,
    required this.restrictedModes,
  });

  RoutePreferences copyWith({
    int? maxTransfers,
    int? walkingCutoffMeters,
    int? topK,
    List<String>? restrictedModes,
  }) {
    return RoutePreferences(
      maxTransfers: maxTransfers ?? this.maxTransfers,
      walkingCutoffMeters: walkingCutoffMeters ?? this.walkingCutoffMeters,
      topK: topK ?? this.topK,
      restrictedModes: restrictedModes ?? this.restrictedModes,
    );
  }
}

class RoutePreferencesService {
  static const _kMaxTransfers = 'route_pref_max_transfers';
  static const _kWalkingCutoff = 'route_pref_walking_cutoff_m';
  static const _kTopK = 'route_pref_top_k';
  static const _kRestrictedModes = 'route_pref_restricted_modes';

  static const int defaultMaxTransfers = 3;
  static const int defaultWalkingCutoffMeters = 2400;
  static const int defaultTopK = 5;

  static const List<String> defaultRestrictedModes = <String>[
    'microbus',
    'tram',
    'walking',
  ];

  Future<RoutePreferences> load() async {
    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.routePreferences);

    final maxTransfers = (box.get(_kMaxTransfers) as int?) ?? defaultMaxTransfers;
    final walkingCutoff =
        (box.get(_kWalkingCutoff) as int?) ?? defaultWalkingCutoffMeters;
    final topK = (box.get(_kTopK) as int?) ?? defaultTopK;

    final rawModes = box.get(_kRestrictedModes);
    final List<String>? modes = rawModes is List
        ? rawModes.whereType<String>().toList(growable: false)
        : null;

    return RoutePreferences(
      maxTransfers: maxTransfers,
      walkingCutoffMeters: walkingCutoff,
      topK: topK,
      restrictedModes: (modes == null || modes.isEmpty)
          ? defaultRestrictedModes
          : List<String>.unmodifiable(modes),
    );
  }

  Future<void> save(RoutePreferences preferences) async {
    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.routePreferences);
    await box.put(_kMaxTransfers, preferences.maxTransfers);
    await box.put(_kWalkingCutoff, preferences.walkingCutoffMeters);
    await box.put(_kTopK, preferences.topK);
    await box.put(_kRestrictedModes, preferences.restrictedModes);
  }
}
