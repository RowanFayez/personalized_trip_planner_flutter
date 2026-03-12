import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'stops_service.dart';

class StopVisibilityService {
  List<Stop> filterStopsInBounds(
    List<Stop> stops,
    CoordinateBounds bounds, {
    double latPaddingFactor = 0.12,
    double lngPaddingFactor = 0.12,
  }) {
    final south = bounds.southwest.coordinates.lat.toDouble();
    final west = bounds.southwest.coordinates.lng.toDouble();
    final north = bounds.northeast.coordinates.lat.toDouble();
    final east = bounds.northeast.coordinates.lng.toDouble();

    final latPadding = (north - south).abs() * latPaddingFactor;
    final lngPadding = (east - west).abs() * lngPaddingFactor;

    final minLat = south - latPadding;
    final maxLat = north + latPadding;
    final minLng = west - lngPadding;
    final maxLng = east + lngPadding;
    final crossesAntimeridian = west > east;

    return stops
        .where((stop) {
          final inLatRange = stop.latitude >= minLat && stop.latitude <= maxLat;
          if (!inLatRange) return false;

          if (crossesAntimeridian) {
            return stop.longitude >= minLng || stop.longitude <= maxLng;
          }

          return stop.longitude >= minLng && stop.longitude <= maxLng;
        })
        .toList(growable: false);
  }
}
