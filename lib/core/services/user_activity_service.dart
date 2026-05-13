import '../storage/hive/core_hive_boxes.dart';
import '../storage/hive/hive_service.dart';
import 'auth_service.dart';

class LastRoute {
  final String from;
  final String to;

  const LastRoute({required this.from, required this.to});
}

class UserActivityService {
  final AuthService _authService;

  UserActivityService({required AuthService authService})
    : _authService = authService;

  static const String _kLastSearch = 'last_search';
  static const String _kLastRouteFrom = 'last_route_from';
  static const String _kLastRouteTo = 'last_route_to';

  String? get _currentUserId => _authService.currentUser?.uid;

  static String _scopedKey({required String userId, required String key}) =>
      '${userId}_$key';

  Future<void> _migrateLegacyIfNeeded(String userId) async {
    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.userActivity);

    for (final key in [_kLastSearch, _kLastRouteFrom, _kLastRouteTo]) {
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

  Future<void> setLastRoute({required String from, required String to}) async {
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
  }

  Future<LastRoute?> getLastRoute() async {
    final userId = _currentUserId;
    if (userId == null) return null;

    await _migrateLegacyIfNeeded(userId);

    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.userActivity);
    final from = box.get(_scopedKey(userId: userId, key: _kLastRouteFrom));
    final to = box.get(_scopedKey(userId: userId, key: _kLastRouteTo));

    if (from is String && to is String) {
      final normalizedFrom = from.trim();
      final normalizedTo = to.trim();
      if (normalizedFrom.isEmpty || normalizedTo.isEmpty) return null;
      return LastRoute(from: normalizedFrom, to: normalizedTo);
    }

    return null;
  }
}
