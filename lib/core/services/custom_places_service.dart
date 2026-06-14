import 'package:uuid/uuid.dart';

import '../storage/hive/core_hive_boxes.dart';
import '../storage/hive/hive_service.dart';
import 'auth_service.dart';

class CustomPlace {
  final String id;
  final String label;
  final double latitude;
  final double longitude;

  const CustomPlace({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'lat': latitude,
    'lng': longitude,
  };

  static CustomPlace? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final label = raw['label'];
    final lat = raw['lat'];
    final lng = raw['lng'];
    if (id is! String || label is! String || lat is! num || lng is! num) {
      return null;
    }
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) return null;
    return CustomPlace(
      id: id,
      label: normalizedLabel,
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
    );
  }
}

class CustomPlacesService {
  final AuthService _authService;

  CustomPlacesService({required AuthService authService})
    : _authService = authService;

  String? get _currentUserId => _authService.uid;

  /// Public key helper for Hive [ValueListenableBuilder].
  static String storageKeyFor(String userId) => 'custom_places_$userId';

  Future<List<CustomPlace>> getCustomPlaces() async {
    final userId = _currentUserId;
    if (userId == null) return const [];

    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.savedPlaces);
    final key = storageKeyFor(userId);
    final raw = box.get(key);

    if (raw is! List) return const [];

    final places = <CustomPlace>[];
    for (final item in raw) {
      final place = CustomPlace.fromMap(item);
      if (place != null) {
        places.add(place);
      }
    }
    return places;
  }

  Future<void> addCustomPlace(CustomPlace place) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.savedPlaces);
    final key = storageKeyFor(userId);
    final existing = await getCustomPlaces();

    if (existing.length >= 10) return; // soft cap

    final updated = [...existing.map((p) => p.toMap()), place.toMap()];
    await box.put(key, updated);
  }

  Future<void> updateCustomPlace(CustomPlace place) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.savedPlaces);
    final key = storageKeyFor(userId);
    final existing = await getCustomPlaces();

    final updated =
        existing.map((p) => p.id == place.id ? place : p).toList();
    await box.put(key, updated.map((p) => p.toMap()).toList());
  }

  Future<void> deleteCustomPlace(String id) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.savedPlaces);
    final key = storageKeyFor(userId);
    final existing = await getCustomPlaces();

    final updated = existing.where((p) => p.id != id).toList();
    await box.put(key, updated.map((p) => p.toMap()).toList());
  }

  /// Convenience: generate a new UUID for a custom place ID.
  static String newId() => const Uuid().v4();
}
