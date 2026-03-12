import 'package:flutter/services.dart' show rootBundle;

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
    final seenKeys = <String>{};
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

      final exactKey = '$nameAr|${parts[2].trim()}|${parts[3].trim()}';
      if (!seenKeys.add(exactKey)) continue;

      stops.add(
        Stop(id: id, name: name, nameAr: nameAr, latitude: lat, longitude: lon),
      );
    }

    _cache = List<Stop>.unmodifiable(stops);
    return _cache!;
  }
}
