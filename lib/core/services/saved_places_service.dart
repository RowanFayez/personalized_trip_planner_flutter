import 'package:shared_preferences/shared_preferences.dart';

enum SavedPlaceType { home, work, college }

class SavedPlace {
  final double latitude;
  final double longitude;

  const SavedPlace({required this.latitude, required this.longitude});
}

class SavedPlacesService {
  static String _latKey(SavedPlaceType type) => 'saved_${type.name}_lat';
  static String _lngKey(SavedPlaceType type) => 'saved_${type.name}_lng';

  static String _legacyFactoryLatKey() => 'saved_factory_lat';
  static String _legacyFactoryLngKey() => 'saved_factory_lng';

  Future<SavedPlace?> getPlace(SavedPlaceType type) async {
    final prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble(_latKey(type));
    double? lng = prefs.getDouble(_lngKey(type));

    // Backward-compat: older builds used "factory".
    if (type == SavedPlaceType.college && (lat == null || lng == null)) {
      lat = prefs.getDouble(_legacyFactoryLatKey());
      lng = prefs.getDouble(_legacyFactoryLngKey());
    }

    if (lat == null || lng == null) return null;
    return SavedPlace(latitude: lat, longitude: lng);
  }

  Future<void> setPlace(SavedPlaceType type, SavedPlace place) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey(type), place.latitude);
    await prefs.setDouble(_lngKey(type), place.longitude);
  }
}
