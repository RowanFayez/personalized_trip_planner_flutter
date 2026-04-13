import '../storage/hive/core_hive_boxes.dart';
import '../storage/hive/hive_service.dart';

class LastRoute {
  final String from;
  final String to;

  const LastRoute({required this.from, required this.to});
}

class UserActivityService {
  static const String _kLastSearch = 'last_search';
  static const String _kLastRouteFrom = 'last_route_from';
  static const String _kLastRouteTo = 'last_route_to';

  Future<void> setLastSearch(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) return;

    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.userActivity);
    await box.put(_kLastSearch, normalized);
  }

  Future<String?> getLastSearch() async {
    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.userActivity);
    final value = box.get(_kLastSearch);
    if (value is String) {
      final normalized = value.trim();
      return normalized.isEmpty ? null : normalized;
    }
    return null;
  }

  Future<void> setLastRoute({required String from, required String to}) async {
    final normalizedFrom = from.trim();
    final normalizedTo = to.trim();
    if (normalizedFrom.isEmpty || normalizedTo.isEmpty) return;

    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.userActivity);
    await box.put(_kLastRouteFrom, normalizedFrom);
    await box.put(_kLastRouteTo, normalizedTo);
  }

  Future<LastRoute?> getLastRoute() async {
    final box = await HiveService.openBox<dynamic>(CoreHiveBoxes.userActivity);
    final from = box.get(_kLastRouteFrom);
    final to = box.get(_kLastRouteTo);

    if (from is String && to is String) {
      final normalizedFrom = from.trim();
      final normalizedTo = to.trim();
      if (normalizedFrom.isEmpty || normalizedTo.isEmpty) return null;
      return LastRoute(from: normalizedFrom, to: normalizedTo);
    }

    return null;
  }
}
