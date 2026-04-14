import 'package:shared_preferences/shared_preferences.dart';

import '../storage/hive/core_hive_boxes.dart';
import '../storage/hive/hive_service.dart';
import 'auth_service.dart';

enum SavedPlaceType { home, work, college }

class SavedPlace {
  final double latitude;
  final double longitude;
  final String? name;

  const SavedPlace({
    required this.latitude,
    required this.longitude,
    this.name,
  });
}

class SavedPlacesService {
  final AuthService _authService;

  SavedPlacesService({required AuthService authService})
    : _authService = authService;

  String? get _currentUserId => _authService.currentUser?.uid;

  /// Public helper for UI widgets that need to listen to Hive changes.
  static String storageKeyFor({
    required String userId,
    required SavedPlaceType type,
  }) =>
      '${userId}_${type.name}_location';

  static String _legacyHiveKey(SavedPlaceType type) =>
      'saved_place_${type.name}';

  static String _latKey(SavedPlaceType type) => 'saved_${type.name}_lat';
  static String _lngKey(SavedPlaceType type) => 'saved_${type.name}_lng';

  static String _legacyFactoryLatKey() => 'saved_factory_lat';
  static String _legacyFactoryLngKey() => 'saved_factory_lng';

  Future<void> _migrateIfNeeded({
    required String userId,
    required SavedPlaceType type,
  }) async {
    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.savedPlaces);
    final key = storageKeyFor(userId: userId, type: type);
    if (box.containsKey(key)) return;

    // One-time migration from older app versions that stored places without
    // scoping by user. We migrate to the *current* signed-in user and remove
    // the legacy key to avoid leaking data across accounts.
    final legacyKey = _legacyHiveKey(type);
    if (box.containsKey(legacyKey)) {
      final legacyValue = box.get(legacyKey);
      if (legacyValue != null) {
        await box.put(key, legacyValue);
      }
      await box.delete(legacyKey);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble(_latKey(type));
    double? lng = prefs.getDouble(_lngKey(type));

    if (type == SavedPlaceType.college && (lat == null || lng == null)) {
      lat = prefs.getDouble(_legacyFactoryLatKey());
      lng = prefs.getDouble(_legacyFactoryLngKey());
    }

    if (lat == null || lng == null) return;

    await box.put(key, <String, double>{'lat': lat, 'lng': lng});

    // Optional cleanup of legacy keys.
    await prefs.remove(_latKey(type));
    await prefs.remove(_lngKey(type));
    if (type == SavedPlaceType.college) {
      await prefs.remove(_legacyFactoryLatKey());
      await prefs.remove(_legacyFactoryLngKey());
    }
  }

  Future<SavedPlace?> getPlace(SavedPlaceType type) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    await _migrateIfNeeded(userId: userId, type: type);
    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.savedPlaces);
    final value = box.get(storageKeyFor(userId: userId, type: type));

    if (value is Map) {
      final lat = value['lat'];
      final lng = value['lng'];
      final name = value['name'];
      if (lat is num && lng is num) {
        return SavedPlace(
          latitude: lat.toDouble(),
          longitude: lng.toDouble(),
          name: name is String && name.trim().isNotEmpty ? name.trim() : null,
        );
      }
    }

    return null;
  }

  Future<void> setPlace(SavedPlaceType type, SavedPlace place) async {
    final userId = _currentUserId;
    if (userId == null) return;
    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.savedPlaces);

    final payload = <String, dynamic>{
      'lat': place.latitude,
      'lng': place.longitude,
    };
    final normalizedName = place.name?.trim();
    if (normalizedName != null && normalizedName.isNotEmpty) {
      payload['name'] = normalizedName;
    }

    await box.put(storageKeyFor(userId: userId, type: type), payload);
  }
}
