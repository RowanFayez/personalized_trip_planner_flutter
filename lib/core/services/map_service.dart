import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import '../config/map_config.dart';
import '../constants/app_colors.dart';
import 'stops_service.dart';

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

  /// Register a PNG asset as a Mapbox style image.
  Future<void> _registerStopIcon() async {
    if (_mapboxMap == null) return;

    // Paint a bus-stop pin icon programmatically (no asset file needed).
    const int size = 96;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 96, 96));

    // Pin body (teardrop)
    final pinPaint = Paint()..color = const Color(0xFF2196F3); // blue
    final path = Path()
      ..moveTo(48, 96) // bottom tip
      ..cubicTo(48, 96, 8, 58, 8, 38)
      ..arcToPoint(const Offset(88, 38),
          radius: const Radius.circular(40), clockwise: true)
      ..cubicTo(88, 58, 48, 96, 48, 96)
      ..close();
    canvas.drawPath(path, pinPaint);

    // White circle
    final circlePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(48, 38), 22, circlePaint);

    // Simple bus shape inside
    final busPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.fill;
    // Bus body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(33, 28, 30, 18),
        const Radius.circular(3),
      ),
      busPaint,
    );
    // Windows
    final windowPaint = Paint()..color = Colors.white;
    for (var x = 36.0; x <= 55; x += 8) {
      canvas.drawRect(Rect.fromLTWH(x, 31, 5, 7), windowPaint);
    }
    // Wheels
    canvas.drawCircle(const Offset(40, 47), 2.5, busPaint);
    canvas.drawCircle(const Offset(56, 47), 2.5, busPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    if (byteData == null) return;

    final mbImage = MbxImage(
      width: image.width,
      height: image.height,
      data: byteData.buffer.asUint8List(),
    );

    await _mapboxMap!.style.addStyleImage(
      'stop-icon',
      1.0,
      mbImage,
      false,
      [],
      [],
      null,
    );
  }

  /// Add a stops layer with bus-stop icons and Arabic labels.
  Future<void> addStopsLayer(List<Stop> stops) async {
    if (_mapboxMap == null || stops.isEmpty) return;

    // 1. Register the stop icon image
    await _registerStopIcon();

    // 2. Build GeoJSON FeatureCollection
    final features = stops.map((s) => {
          'type': 'Feature',
          'properties': {
            'name_ar': s.nameAr,
            'stop_id': s.id,
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [s.longitude, s.latitude],
          },
        }).toList();

    final geoJson = jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
    });

    // 3. Add GeoJSON source
    try {
      await _mapboxMap!.style.addSource(
        GeoJsonSource(id: 'stops_source', data: geoJson),
      );
    } catch (_) {}

    // 4. Add symbol layer (icon + text)
    try {
      await _mapboxMap!.style.addLayer(
        SymbolLayer(
          id: 'stops_layer',
          sourceId: 'stops_source',
          iconImage: 'stop-icon',
          iconSize: 0.45,
          iconAllowOverlap: false,
          iconAnchor: IconAnchor.BOTTOM,
          textField: '{name_ar}',
          textSize: 12.0,
          textColor: Colors.white.toARGB32(),
          textHaloColor: const Color(0xFF0E1D25).toARGB32(),
          textHaloWidth: 1.5,
          textOffset: [0.0, 0.8],
          textAnchor: TextAnchor.TOP,
          textAllowOverlap: false,
          textOptional: true,
          symbolSortKey: 1.0,
          minZoom: 13.0,
        ),
      );
    } catch (_) {}
  }
}
