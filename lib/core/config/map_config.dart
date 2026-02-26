import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../config/env_config.dart';
import '../constants/app_strings.dart';

/// Configuration for Mapbox map initialization
class MapConfig {
  /// Get Mapbox access token from environment
  static String get accessToken => EnvConfig.mapboxAccessToken;

  /// Default map style URL (dark theme matching UI)
  static String get styleUrl => AppStrings.mapStyleUrl;

  /// Default camera position (Alexandria, Egypt)
  static CameraOptions get defaultCamera {
    return CameraOptions(
      center: Point(
        coordinates: Position(
          AppStrings.alexandriaLng,
          AppStrings.alexandriaLat,
        ),
      ),
      zoom: AppStrings.defaultZoom,
      pitch: 0,
      bearing: 0,
    );
  }

  /// Camera animation options
  static MapAnimationOptions get animationOptions {
    return MapAnimationOptions(
      duration: 1000, // 1 second
      startDelay: 0,
    );
  }

  /// Create camera options for a specific location
  static CameraOptions createCamera({
    required double latitude,
    required double longitude,
    double zoom = 15.0,
    double pitch = 0,
    double bearing = 0,
  }) {
    return CameraOptions(
      center: Point(
        coordinates: Position(longitude, latitude),
      ),
      zoom: zoom,
      pitch: pitch,
      bearing: bearing,
    );
  }

  /// Fit camera to show multiple points (for route visualization)
  static CameraOptions fitBounds({
    required List<Position> coordinates,
    EdgeInsets padding = const EdgeInsets.all(50),
  }) {
    if (coordinates.isEmpty) {
      return defaultCamera;
    }

    // Find bounds
    double minLng = coordinates.first.lng.toDouble();
    double maxLng = coordinates.first.lng.toDouble();
    double minLat = coordinates.first.lat.toDouble();
    double maxLat = coordinates.first.lat.toDouble();

    for (var coord in coordinates) {
      if (coord.lng < minLng) minLng = coord.lng.toDouble();
      if (coord.lng > maxLng) maxLng = coord.lng.toDouble();
      if (coord.lat < minLat) minLat = coord.lat.toDouble();
      if (coord.lat > maxLat) maxLat = coord.lat.toDouble();
    }

    // Calculate center
    double centerLng = (minLng + maxLng) / 2.0;
    double centerLat = (minLat + maxLat) / 2.0;

    // Calculate zoom level based on bounds
    // This is a simplified approach; you may want more sophisticated calculation
    double lngDiff = maxLng - minLng;
    double latDiff = maxLat - minLat;
    double maxDiff = lngDiff > latDiff ? lngDiff : latDiff;
    
    double zoom = 13.0;
    if (maxDiff < 0.01) {
      zoom = 15.0;
    } else if (maxDiff < 0.05) {
      zoom = 13.0;
    } else if (maxDiff < 0.1) {
      zoom = 11.0;
    } else {
      zoom = 10.0;
    }

    return CameraOptions(
      center: Point(
        coordinates: Position(centerLng, centerLat),
      ),
      zoom: zoom,
      pitch: 0,
      bearing: 0,
    );
  }
}
