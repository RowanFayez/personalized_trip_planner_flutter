import 'package:flutter/services.dart' show rootBundle;
import 'dart:math' as math;

/// A single transit stop parsed from stops.txt.
class Stop {
  final int id;
  final String name;
  final String nameAr;
  final double latitude;
  final double longitude;

  const Stop({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.latitude,
    required this.longitude,
  });

  String get labelAr => 'موقف $nameAr';
}

/// Reads and parses stops from the bundled stops.txt asset.
class StopsService {
  List<Stop>? _cache;

  Future<List<Stop>> loadStops() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString('assets/files/stops.txt');
    final lines = raw.split('\n');

    final stops = <Stop>[];
    // Skip header line
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(',');
      if (parts.length < 5) continue;

      final id = int.tryParse(parts[0].trim());
      final name = parts[1].trim();
      final lat = double.tryParse(parts[2].trim());
      final lon = double.tryParse(parts[3].trim());
      final nameAr = parts
          .sublist(4)
          .join(',')
          .trim(); // handle commas in Arabic name

      if (id == null || lat == null || lon == null) continue;

      stops.add(
        Stop(id: id, name: name, nameAr: nameAr, latitude: lat, longitude: lon),
      );
    }

    _cache = _deduplicateNearbyStops(stops);
    return _cache!;
  }

  List<Stop> _deduplicateNearbyStops(List<Stop> stops) {
    final unique = <Stop>[];

    for (final stop in stops) {
      final isDuplicate = unique.any(
        (existing) =>
            existing.nameAr == stop.nameAr &&
            _distanceMeters(
                  existing.latitude,
                  existing.longitude,
                  stop.latitude,
                  stop.longitude,
                ) <=
                35,
      );

      if (!isDuplicate) {
        unique.add(stop);
      }
    }

    return unique;
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double degrees) => degrees * math.pi / 180.0;
}
