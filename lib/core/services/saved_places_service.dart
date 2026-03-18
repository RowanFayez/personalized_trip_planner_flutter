import 'package:shared_preferences/shared_preferences.dart';

import '../storage/hive/core_hive_boxes.dart';
import '../storage/hive/hive_service.dart';

enum SavedPlaceType { home, work, college }

class SavedPlace {
  final double latitude;
  final double longitude;

  const SavedPlace({required this.latitude, required this.longitude});
}

class SavedPlacesService {
  static String _placeKey(SavedPlaceType type) => 'saved_place_${type.name}';

  static String _latKey(SavedPlaceType type) => 'saved_${type.name}_lat';
  static String _lngKey(SavedPlaceType type) => 'saved_${type.name}_lng';

  static String _legacyFactoryLatKey() => 'saved_factory_lat';
  static String _legacyFactoryLngKey() => 'saved_factory_lng';

  Future<void> _migrateIfNeeded(SavedPlaceType type) async {
    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.savedPlaces);
    if (box.containsKey(_placeKey(type))) return;

    final prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble(_latKey(type));
    double? lng = prefs.getDouble(_lngKey(type));

    if (type == SavedPlaceType.college && (lat == null || lng == null)) {
      lat = prefs.getDouble(_legacyFactoryLatKey());
      lng = prefs.getDouble(_legacyFactoryLngKey());
    }

    if (lat == null || lng == null) return;

    await box.put(_placeKey(type), <String, double>{'lat': lat, 'lng': lng});

    // Optional cleanup of legacy keys.
    await prefs.remove(_latKey(type));
    await prefs.remove(_lngKey(type));
    if (type == SavedPlaceType.college) {
      await prefs.remove(_legacyFactoryLatKey());
      await prefs.remove(_legacyFactoryLngKey());
    }
  }

  Future<SavedPlace?> getPlace(SavedPlaceType type) async {
    await _migrateIfNeeded(type);
    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.savedPlaces);
    final value = box.get(_placeKey(type));

    if (value is Map) {
      final lat = value['lat'];
      final lng = value['lng'];
      if (lat is num && lng is num) {
        return SavedPlace(latitude: lat.toDouble(), longitude: lng.toDouble());
      }
    }

    return null;
  }

  Future<void> setPlace(SavedPlaceType type, SavedPlace place) async {
    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.savedPlaces);
    await box.put(_placeKey(type), <String, double>{
      'lat': place.latitude,
      'lng': place.longitude,
    });
  }
}
