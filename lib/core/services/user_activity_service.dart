import '../storage/hive/core_hive_boxes.dart';
import '../storage/hive/hive_service.dart';
import 'auth_service.dart';

class LastRoute {
  final String from;
  final String to;

  final double? fromLat;
  final double? fromLon;
  final double? toLat;
  final double? toLon;

  const LastRoute({
    required this.from,
    required this.to,
    this.fromLat,
    this.fromLon,
    this.toLat,
    this.toLon,
  });
}

class UserActivityService {
  final AuthService _authService;

  UserActivityService({required AuthService authService})
    : _authService = authService;

  static const String _kLastSearch = 'last_search';
  static const String _kLastRouteFrom = 'last_route_from';
  static const String _kLastRouteTo = 'last_route_to';
  static const String _kLastRouteFromLat = 'last_route_from_lat';
  static const String _kLastRouteFromLon = 'last_route_from_lon';
  static const String _kLastRouteToLat = 'last_route_to_lat';
  static const String _kLastRouteToLon = 'last_route_to_lon';

  String? get _currentUserId => _authService.currentUser?.uid;

  static String _scopedKey({required String userId, required String key}) =>
      '${userId}_$key';

  Future<void> _migrateLegacyIfNeeded(String userId) async {
    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.userActivity);

    for (final key in [
      _kLastSearch,
      _kLastRouteFrom,
      _kLastRouteTo,
      _kLastRouteFromLat,
      _kLastRouteFromLon,
      _kLastRouteToLat,
      _kLastRouteToLon,
    ]) {
      final scoped = _scopedKey(userId: userId, key: key);
      if (box.containsKey(scoped)) continue;
      if (!box.containsKey(key)) continue;

      final legacyValue = box.get(key);
      if (legacyValue != null) {
        await box.put(scoped, legacyValue);
      }
      await box.delete(key);
    }
  }

  Future<void> setLastSearch(String value) async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _migrateLegacyIfNeeded(userId);

    final normalized = value.trim();
    if (normalized.isEmpty) return;

    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.userActivity);
    await box.put(_scopedKey(userId: userId, key: _kLastSearch), normalized);
  }

  Future<String?> getLastSearch() async {
    final userId = _currentUserId;
    if (userId == null) return null;

    await _migrateLegacyIfNeeded(userId);

    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.userActivity);
    final value = box.get(_scopedKey(userId: userId, key: _kLastSearch));
    if (value is String) {
      final normalized = value.trim();
      return normalized.isEmpty ? null : normalized;
    }
    return null;
  }

  Future<void> setLastRoute({
    required String from,
    required String to,
    double? fromLat,
    double? fromLon,
    double? toLat,
    double? toLon,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _migrateLegacyIfNeeded(userId);

    final normalizedFrom = from.trim();
    final normalizedTo = to.trim();
    if (normalizedFrom.isEmpty || normalizedTo.isEmpty) return;

    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.userActivity);
    await box.put(
      _scopedKey(userId: userId, key: _kLastRouteFrom),
      normalizedFrom,
    );
    await box.put(_scopedKey(userId: userId, key: _kLastRouteTo), normalizedTo);

    final hasCoords =
        fromLat != null && fromLon != null && toLat != null && toLon != null;

    final fromLatKey = _scopedKey(userId: userId, key: _kLastRouteFromLat);
    final fromLonKey = _scopedKey(userId: userId, key: _kLastRouteFromLon);
    final toLatKey = _scopedKey(userId: userId, key: _kLastRouteToLat);
    final toLonKey = _scopedKey(userId: userId, key: _kLastRouteToLon);

    if (hasCoords) {
      await box.put(fromLatKey, fromLat);
      await box.put(fromLonKey, fromLon);
      await box.put(toLatKey, toLat);
      await box.put(toLonKey, toLon);
    } else {
      // Avoid stale coordinates if caller doesn't provide them.
      try {
        await box.delete(fromLatKey);
        await box.delete(fromLonKey);
        await box.delete(toLatKey);
        await box.delete(toLonKey);
      } catch (_) {
        // Ignore.
      }
    }
  }

  Future<LastRoute?> getLastRoute() async {
    final userId = _currentUserId;
    if (userId == null) return null;

    await _migrateLegacyIfNeeded(userId);

    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.userActivity);
    final from = box.get(_scopedKey(userId: userId, key: _kLastRouteFrom));
    final to = box.get(_scopedKey(userId: userId, key: _kLastRouteTo));

    double? asDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final fromLat = asDouble(
      box.get(_scopedKey(userId: userId, key: _kLastRouteFromLat)),
    );
    final fromLon = asDouble(
      box.get(_scopedKey(userId: userId, key: _kLastRouteFromLon)),
    );
    final toLat = asDouble(
      box.get(_scopedKey(userId: userId, key: _kLastRouteToLat)),
    );
    final toLon = asDouble(
      box.get(_scopedKey(userId: userId, key: _kLastRouteToLon)),
    );

    if (from is String && to is String) {
      final normalizedFrom = from.trim();
      final normalizedTo = to.trim();
      if (normalizedFrom.isEmpty || normalizedTo.isEmpty) return null;
      return LastRoute(
        from: normalizedFrom,
        to: normalizedTo,
        fromLat: fromLat,
        fromLon: fromLon,
        toLat: toLat,
        toLon: toLon,
      );
    }

    return null;
  }
}
