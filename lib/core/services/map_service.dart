import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:convert';
import '../config/map_config.dart';
import '../constants/app_colors.dart';

/// Service for managing Mapbox map operations
class MapService {
  MapboxMap? _mapboxMap;

  /// Initialize map controller
  void initialize(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  /// Animate camera to a specific location
  Future<void> animateCamera({
    required double latitude,
    required double longitude,
    double zoom = 15.0,
  }) async {
    if (_mapboxMap == null) return;

    final cameraOptions = MapConfig.createCamera(
      latitude: latitude,
      longitude: longitude,
      zoom: zoom,
    );

    await _mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1000));
  }

  /// Add a marker/pin to the map
  Future<void> addMarker({
    required String id,
    required double latitude,
    required double longitude,
    Color color = AppColors.mapPin,
  }) async {
    if (_mapboxMap == null) return;

    final geoJsonFeature = {
      'type': 'Feature',
      'properties': <String, dynamic>{},
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
    };

    // Add source with GeoJSON point
    try {
      await _mapboxMap!.style.addSource(
        GeoJsonSource(id: '${id}_source', data: jsonEncode(geoJsonFeature)),
      );
    } catch (e) {
      // Source might already exist
    }

    // Add symbol layer for the marker
    try {
      await _mapboxMap!.style.addLayer(
        CircleLayer(
          id: '${id}_layer',
          sourceId: '${id}_source',
          circleRadius: 10.0,
          circleColor: color.toARGB32(),
          circleStrokeWidth: 2.0,
          circleStrokeColor: Colors.white.toARGB32(),
        ),
      );
    } catch (e) {
      // Layer might already exist
    }
  }

  /// Add or replace a marker at a new location.
  Future<void> upsertMarker({
    required String id,
    required double latitude,
    required double longitude,
    Color color = AppColors.mapPin,
  }) async {
    await removeMarker(id);
    await addMarker(
      id: id,
      latitude: latitude,
      longitude: longitude,
      color: color,
    );
  }

  /// Remove a marker from the map
  Future<void> removeMarker(String id) async {
    if (_mapboxMap == null) return;

    try {
      await _mapboxMap!.style.removeStyleLayer('${id}_layer');
      await _mapboxMap!.style.removeStyleSource('${id}_source');
    } catch (e) {
      // Marker might not exist
    }
  }

  /// Draw route polyline on map
  Future<void> drawRoute({
    required String id,
    required List<Position> coordinates,
    Color color = AppColors.routeLine,
    double width = 5.0,
  }) async {
    if (_mapboxMap == null || coordinates.isEmpty) return;

    // Create GeoJSON LineString
    final lineString = {
      'type': 'Feature',
      'geometry': {
        'type': 'LineString',
        'coordinates': coordinates.map((pos) => [pos.lng, pos.lat]).toList(),
      },
    };

    // Add source
    try {
      await _mapboxMap!.style.addSource(
        GeoJsonSource(id: '${id}_route_source', data: jsonEncode(lineString)),
      );
    } catch (e) {
      // Source already exists
    }

    // Add line layer
    try {
      await _mapboxMap!.style.addLayer(
        LineLayer(
          id: '${id}_route_layer',
          sourceId: '${id}_route_source',
          lineColor: color.toARGB32(),
          lineWidth: width,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
    } catch (e) {
      // Layer might already exist
    }
  }

  /// Remove route from map
  Future<void> removeRoute(String id) async {
    if (_mapboxMap == null) return;

    try {
      await _mapboxMap!.style.removeStyleLayer('${id}_route_layer');
      await _mapboxMap!.style.removeStyleSource('${id}_route_source');
    } catch (e) {
      // Route might not exist
    }
  }

  /// Clear all markers and routes
  Future<void> clearMap() async {
    if (_mapboxMap == null) return;
    // Implement specific clearing logic based on your needs
  }

  /// Fit camera to show all route points
  Future<void> fitToRoute(List<Position> coordinates) async {
    if (_mapboxMap == null || coordinates.isEmpty) return;

    final cameraOptions = MapConfig.fitBounds(coordinates: coordinates);
    await _mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1500));
  }

  /// Get current camera position
  Future<CameraState?> getCameraState() async {
    if (_mapboxMap == null) return null;
    return await _mapboxMap!.getCameraState();
  }
}
