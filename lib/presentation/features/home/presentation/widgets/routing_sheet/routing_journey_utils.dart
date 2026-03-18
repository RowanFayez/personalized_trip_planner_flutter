import '../../../../../../features/routing/domain/entities/routing_entities.dart';

class RoutingJourneyUtils {
  RoutingJourneyUtils._();

  static int findFastestIndex(List<Journey> journeys) {
    if (journeys.isEmpty) return 0;
    var best = 0;
    var bestValue = journeys.first.summary.totalTimeMinutes;
    for (var i = 1; i < journeys.length; i++) {
      final v = journeys[i].summary.totalTimeMinutes;
      if (v < bestValue) {
        best = i;
        bestValue = v;
      }
    }
    return best;
  }

  static int findCheapestIndex(List<Journey> journeys) {
    if (journeys.isEmpty) return 0;
    var best = 0;
    var bestValue = journeys.first.summary.cost;
    for (var i = 1; i < journeys.length; i++) {
      final v = journeys[i].summary.cost;
      if (v < bestValue) {
        best = i;
        bestValue = v;
      }
    }
    return best;
  }

  static int findLessWalkingIndex(List<Journey> journeys) {
    if (journeys.isEmpty) return 0;
    var best = 0;
    var bestValue = journeys.first.summary.walkingDistanceMeters;
    for (var i = 1; i < journeys.length; i++) {
      final v = journeys[i].summary.walkingDistanceMeters;
      if (v < bestValue) {
        best = i;
        bestValue = v;
      }
    }
    return best;
  }

  static String formatTime(DateTime dt) {
    var hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $ampm';
  }
}
