import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import '../config/map_config.dart';
import '../constants/app_colors.dart';
import 'stop_icon_service.dart';
import 'stop_visibility_service.dart';
import 'stops_service.dart';

/// Service for managing Mapbox map operations
class MapService {
  MapboxMap? _mapboxMap;
  final StopIconService _stopIconService = StopIconService();
  final StopVisibilityService _stopVisibilityService = StopVisibilityService();
  PointAnnotationManager? _stopsAnnotationManager;
  Uint8List? _stopsIconBytes;
  List<Stop> _lastStops = const [];
  List<Stop> _renderedStops = const [];
  bool _showStopLabels = false;
  double? _lastStopsCenterLat;
  double? _lastStopsCenterLng;
  double? _lastStopsZoom;
  bool _didHideBasemapLayers = false;
  List<int> _renderedStopIds = const [];

  static const double stopLabelZoomThreshold = 15.3;

  static const List<String> _conflictingBasemapTokens = <String>[
    'transit',
    'station',
    'rail',
    'metro',
  ];

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

  Future<Uint8List> _getStopIconBytes() async {
    if (_stopsIconBytes != null) return _stopsIconBytes!;

    _stopsIconBytes = await _stopIconService.loadOptimizedStopIconBytes();
    return _stopsIconBytes!;
  }

  Future<void> removeStopsLayer() async {
    if (_mapboxMap == null) return;

    if (_stopsAnnotationManager != null) {
      try {
        await _stopsAnnotationManager!.deleteAll();
      } catch (_) {}

      try {
        await _mapboxMap!.annotations.removeAnnotationManager(
          _stopsAnnotationManager!,
        );
      } catch (_) {}

      _stopsAnnotationManager = null;
    }

    _renderedStopIds = const [];
    _didHideBasemapLayers = false;
  }

  Future<void> _hideConflictingBasemapLayers() async {
    if (_mapboxMap == null) return;

    final styleLayers = await _mapboxMap!.style.getStyleLayers();
    for (final layer in styleLayers.whereType<StyleObjectInfo>()) {
      final id = layer.id.toLowerCase();
      final shouldHide =
          _conflictingBasemapTokens.any(id.contains) &&
          (id.contains('label') || id.contains('icon'));
      if (!shouldHide) continue;

      try {
        await _mapboxMap!.style.setStyleLayerProperty(
          layer.id,
          'visibility',
          'none',
        );
      } catch (_) {}
    }
  }

  Future<void> _renderStopsAnnotations() async {
    if (_mapboxMap == null) return;

    if (!_didHideBasemapLayers) {
      await _hideConflictingBasemapLayers();
      _didHideBasemapLayers = true;
    }

    final iconBytes = await _getStopIconBytes();

    // Create manager only once; reuse on subsequent renders.
    if (_stopsAnnotationManager == null) {
      _stopsAnnotationManager = await _mapboxMap!.annotations
          .createPointAnnotationManager();

      await _stopsAnnotationManager!.setIconAllowOverlap(true);
      await _stopsAnnotationManager!.setIconIgnorePlacement(true);
      await _stopsAnnotationManager!.setTextAllowOverlap(false);
      await _stopsAnnotationManager!.setTextIgnorePlacement(false);
      await _stopsAnnotationManager!.setTextOptional(true);
    } else {
      try {
        await _stopsAnnotationManager!.deleteAll();
      } catch (_) {}
    }

    if (_renderedStops.isEmpty) return;

    await _stopsAnnotationManager!.setTextIgnorePlacement(false);
    await _stopsAnnotationManager!.setTextOptional(true);

    final options = _renderedStops
        .map(
          (stop) => PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(stop.longitude, stop.latitude),
            ),
            image: iconBytes,
            iconSize: 0.30,
            iconAnchor: IconAnchor.BOTTOM,
            textField: _showStopLabels ? stop.labelAr : '',
            textSize: 10.5,
            textMaxWidth: 8.0,
            textColor: Colors.white.toARGB32(),
            textHaloColor: const Color(0xFF0B171D).toARGB32(),
            textHaloWidth: 1.5,
            textOffset: [0.0, 0.72],
            textAnchor: TextAnchor.TOP,
            symbolSortKey: 10.0,
          ),
        )
        .toList(growable: false);

    await _stopsAnnotationManager!.createMulti(options);

    debugPrint(
      'Stops layer: added ${options.length} point annotations, labels=${_showStopLabels ? 'on' : 'off'}',
    );
  }

  /// Add stops with icons always visible; labels appear only at high zoom.
  Future<void> addStopsLayer(List<Stop> stops, {double? currentZoom}) async {
    if (_mapboxMap == null || stops.isEmpty) return;

    _lastStops = stops;
    _showStopLabels = (currentZoom ?? 0) >= stopLabelZoomThreshold;

    final state = await _mapboxMap!.getCameraState();
    await updateStopsForCameraState(state, force: true);
  }

  Future<void> updateStopsForZoom(double zoom) async {
    if (_lastStops.isEmpty) return;

    final shouldShowLabels = zoom >= stopLabelZoomThreshold;
    if (shouldShowLabels == _showStopLabels) return;

    _showStopLabels = shouldShowLabels;
    await _renderStopsAnnotations();
  }

  Future<void> updateStopsForCameraState(
    CameraState state, {
    bool force = false,
  }) async {
    if (_lastStops.isEmpty) return;

    final zoom = state.zoom;
    final shouldShowLabels = zoom >= stopLabelZoomThreshold;

    final movedEnough =
        _lastStopsCenterLat == null ||
        _lastStopsCenterLng == null ||
        _distanceMeters(
              _lastStopsCenterLat!,
              _lastStopsCenterLng!,
              state.center.coordinates.lat.toDouble(),
              state.center.coordinates.lng.toDouble(),
            ) >=
            350;

    final zoomChangedEnough =
        _lastStopsZoom == null || (zoom - _lastStopsZoom!).abs() >= 0.5;
    final labelsChanged = shouldShowLabels != _showStopLabels;

    if (!force && !movedEnough && !zoomChangedEnough && !labelsChanged) {
      return;
    }

    _showStopLabels = shouldShowLabels;
    _lastStopsCenterLat = state.center.coordinates.lat.toDouble();
    _lastStopsCenterLng = state.center.coordinates.lng.toDouble();
    _lastStopsZoom = zoom;

    final bounds = await _mapboxMap!.coordinateBoundsForCamera(
      CameraOptions(
        center: state.center,
        padding: state.padding,
        zoom: state.zoom,
        bearing: state.bearing,
        pitch: state.pitch,
      ),
    );

    final newRendered = _stopVisibilityService.filterStopsInBounds(
      _lastStops,
      bounds,
    );

    // Skip re-render if exact same stops and same label state.
    final newIds = newRendered.map((s) => s.id).toList(growable: false);
    if (!force && _listsEqual(newIds, _renderedStopIds) && !labelsChanged) {
      return;
    }

    _renderedStops = newRendered;
    _renderedStopIds = newIds;

    debugPrint(
      'Stops layer: rendering ${_renderedStops.length}/${_lastStops.length} stops at zoom ${zoom.toStringAsFixed(2)}, labels=${_showStopLabels ? 'on' : 'off'}',
    );

    await _renderStopsAnnotations();
  }

  bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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

  double _degToRad(double degrees) => degrees * 3.1415926535897932 / 180.0;
}
