import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../config/map_config.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class MapRouteSegment {
  final String mode;
  final List<Position> coordinates;

  const MapRouteSegment({required this.mode, required this.coordinates});
}

/// Service for managing Mapbox map operations
class MapService {
  MapboxMap? _mapboxMap;
  final Map<String, PointAnnotationManager> _segmentIconManagers =
      <String, PointAnnotationManager>{};
  final Map<String, Uint8List> _modeIconPngCache = <String, Uint8List>{};

  /// Initialize map controller
  void initialize(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _segmentIconManagers.clear();
    _modeIconPngCache.clear();
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

  /// Draw a segmented route, where each segment is colored by transport mode,
  /// and a mode icon is placed at the start of each segment.
  Future<void> drawSegmentedRoute({
    required String id,
    required List<MapRouteSegment> segments,
    double width = 6.0,
  }) async {
    if (_mapboxMap == null) return;

    final usableSegments = segments
        .where((s) => s.coordinates.length >= 2)
        .toList(growable: false);
    if (usableSegments.isEmpty) return;

    final lineFeatures = <Map<String, dynamic>>[];
    final pointFeatures = <Map<String, dynamic>>[];

    for (final segment in usableSegments) {
      final mode = _normalizeMode(segment.mode);
      final coords = segment.coordinates
          .map((p) => <double>[p.lng.toDouble(), p.lat.toDouble()])
          .toList(growable: false);

      lineFeatures.add({
        'type': 'Feature',
        'properties': <String, dynamic>{'mode': mode},
        'geometry': <String, dynamic>{
          'type': 'LineString',
          'coordinates': coords,
        },
      });

      if (_svgAssetForMode(mode) != null) {
        pointFeatures.add({
          'type': 'Feature',
          'properties': <String, dynamic>{'mode': mode},
          'geometry': <String, dynamic>{
            'type': 'Point',
            'coordinates': coords.first,
          },
        });
      }
    }

    final lineCollection = {
      'type': 'FeatureCollection',
      'features': lineFeatures,
    };
    final pointCollection = {
      'type': 'FeatureCollection',
      'features': pointFeatures,
    };

    await removeRoute(id);

    final routeSourceId = '${id}_route_source';
    final routeLayerId = '${id}_route_layer';
    final pointSourceId = '${id}_route_points_source';
    final pointCircleLayerId = '${id}_route_points_circle_layer';

    try {
      await _mapboxMap!.style.addSource(
        GeoJsonSource(id: routeSourceId, data: jsonEncode(lineCollection)),
      );
    } catch (e) {
      // Source might already exist
    }

    try {
      await _mapboxMap!.style.addLayer(
        LineLayer(
          id: routeLayerId,
          sourceId: routeSourceId,
          lineWidth: width,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
          lineColorExpression: _modeToColorExpression(),
        ),
      );
    } catch (e) {
      // Layer might already exist
    }

    if (pointFeatures.isNotEmpty) {
      try {
        await _mapboxMap!.style.addSource(
          GeoJsonSource(id: pointSourceId, data: jsonEncode(pointCollection)),
        );
      } catch (e) {
        // Source might already exist
      }

      try {
        await _mapboxMap!.style.addLayer(
          CircleLayer(
            id: pointCircleLayerId,
            sourceId: pointSourceId,
            circleRadius: 10.0,
            circleStrokeWidth: 2.0,
            circleStrokeColor: Colors.white.toARGB32(),
            circleColorExpression: _modeToColorExpression(),
          ),
        );
      } catch (e) {
        // Layer might already exist
      }

      // Use PointAnnotations for icons (more reliable than SymbolLayer icons).
      await _drawSegmentStartIconsWithAnnotations(
        routeId: id,
        pointFeatures: pointFeatures,
      );
    }
  }

  /// Remove route from map
  Future<void> removeRoute(String id) async {
    if (_mapboxMap == null) return;

    await _removeSegmentIconManager(id);

    try {
      await _mapboxMap!.style.removeStyleLayer('${id}_route_layer');
      await _mapboxMap!.style.removeStyleSource('${id}_route_source');
    } catch (e) {
      // Route might not exist
    }

    try {
      await _mapboxMap!.style.removeStyleLayer(
        '${id}_route_points_circle_layer',
      );
    } catch (e) {
      // Layer might not exist
    }

    try {
      await _mapboxMap!.style.removeStyleSource('${id}_route_points_source');
    } catch (e) {
      // Source might not exist
    }
  }

  Future<void> _drawSegmentStartIconsWithAnnotations({
    required String routeId,
    required List<Map<String, dynamic>> pointFeatures,
  }) async {
    if (_mapboxMap == null) return;

    await _removeSegmentIconManager(routeId);

    PointAnnotationManager manager;
    try {
      manager = await _mapboxMap!.annotations.createPointAnnotationManager(
        id: '${routeId}_segment_icons',
      );
      _segmentIconManagers[routeId] = manager;
    } catch (_) {
      return;
    }

    try {
      await manager.setIconAllowOverlap(true);
      await manager.setIconIgnorePlacement(true);
      await manager.setIconAnchor(IconAnchor.CENTER);
      await manager.setIconSize(1.0);
    } catch (_) {
      // Best-effort; continue.
    }

    final options = <PointAnnotationOptions>[];
    for (final f in pointFeatures) {
      final props = f['properties'] as Map<String, dynamic>;
      final geometry = f['geometry'] as Map<String, dynamic>;
      final coords = (geometry['coordinates'] as List).cast<num>();
      if (coords.length < 2) continue;

      final mode = (props['mode'] as String?) ?? 'unknown';
      final imageBytes = await _modeIconPngBytesForMode(mode);
      if (imageBytes == null || imageBytes.isEmpty) continue;

      options.add(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(coords[0].toDouble(), coords[1].toDouble()),
          ),
          image: imageBytes,
        ),
      );
    }

    if (options.isEmpty) return;
    try {
      await manager.createMulti(options);
    } catch (_) {
      // If creation fails, keep map usable.
    }
  }

  Future<void> _removeSegmentIconManager(String routeId) async {
    if (_mapboxMap == null) return;

    final existing = _segmentIconManagers.remove(routeId);
    if (existing != null) {
      try {
        await _mapboxMap!.annotations.removeAnnotationManager(existing);
      } catch (_) {
        // Ignore.
      }
      return;
    }

    // Best-effort cleanup in case the manager existed but wasn't tracked.
    try {
      await _mapboxMap!.annotations.removeAnnotationManagerById(
        '${routeId}_segment_icons',
      );
    } catch (_) {
      // Ignore.
    }
  }

  String _normalizeMode(String mode) {
    final m = mode.trim().toLowerCase();
    if (m.isEmpty) return 'unknown';

    // Walk-like
    if (m == 'walk' || m == 'transfer' || m.contains('walk')) {
      return AppStrings.modeWalking;
    }

    // Metro / subway / rail / lines
    if (m.contains('metro') ||
        m.contains('subway') ||
        m.contains('rail') ||
        m.contains('line')) {
      return AppStrings.modeTram;
    }

    // Vehicle modes
    if (m.contains('micro')) return AppStrings.modeMicrobus;
    if (m.contains('mini')) return AppStrings.modeMinibus;
    if (m.contains('bus')) return AppStrings.modeBus;
    if (m.contains('tram')) return AppStrings.modeTram;
    if (m.contains('tonaya') || m.contains('taxi'))
      return AppStrings.modeTonaya;

    return m;
  }

  String? _svgAssetForMode(String mode) {
    return switch (mode) {
      AppStrings.modeWalking => 'assets/icons/walking.svg',
      AppStrings.modeBus => 'assets/icons/bus.svg',
      AppStrings.modeTram => 'assets/icons/tram.svg',
      AppStrings.modeMicrobus => 'assets/icons/microbus.svg',
      AppStrings.modeMinibus => 'assets/icons/minibus.svg',
      // No dedicated tonaya/taxi SVG in assets; use bus as fallback.
      AppStrings.modeTonaya => 'assets/icons/bus.svg',
      _ => null,
    };
  }

  Future<Uint8List?> _modeIconPngBytesForMode(String mode) async {
    final normalized = _normalizeMode(mode);
    final cached = _modeIconPngCache[normalized];
    if (cached != null) return cached;

    final assetPath = _svgAssetForMode(normalized);
    if (assetPath == null) return null;

    final pictureInfo = await vg.loadPicture(
      SvgAssetLoader(
        assetPath,
        theme: const SvgTheme(currentColor: Colors.white),
      ),
      null,
    );

    try {
      final devicePixelRatio = ui.PlatformDispatcher.instance.views.isEmpty
          ? 1.0
          : ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
      const logicalSize = 18.0;
      final sizePx = (logicalSize * devicePixelRatio).round().clamp(16, 96);

      final image = await _rasterizePicture(
        picture: pictureInfo.picture,
        pictureSize: pictureInfo.size,
        widthPx: sizePx,
        heightPx: sizePx,
      );
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return null;

        final bytes = byteData.buffer.asUint8List();
        _modeIconPngCache[normalized] = bytes;
        return bytes;
      } finally {
        image.dispose();
      }
    } finally {
      pictureInfo.picture.dispose();
    }
  }

  Future<ui.Image> _rasterizePicture({
    required ui.Picture picture,
    required ui.Size pictureSize,
    required int widthPx,
    required int heightPx,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, widthPx.toDouble(), heightPx.toDouble()),
    );

    // Clear transparent.
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, widthPx.toDouble(), heightPx.toDouble()),
      ui.Paint()..color = const ui.Color(0x00000000),
    );

    final safeW = pictureSize.width <= 0 ? 24.0 : pictureSize.width;
    final safeH = pictureSize.height <= 0 ? 24.0 : pictureSize.height;

    final scale = ((widthPx / safeW).clamp(0.01, 1000.0)).toDouble();
    final scaleY = ((heightPx / safeH).clamp(0.01, 1000.0)).toDouble();
    final uniformScale = scale < scaleY ? scale : scaleY;

    final dx = (widthPx - safeW * uniformScale) / 2.0;
    final dy = (heightPx - safeH * uniformScale) / 2.0;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(uniformScale, uniformScale);
    canvas.drawPicture(picture);
    canvas.restore();

    final recorded = recorder.endRecording();
    final image = await recorded.toImage(widthPx, heightPx);
    recorded.dispose();
    return image;
  }

  List<Object> _modeToColorExpression() {
    // Keep colors deterministic per mode.
    // Requested: walking always yellow; microbus always blue.
    final walk = AppColors.walkColor.toARGB32().toRGBA();
    final microbus = AppColors.tramColor.toARGB32().toRGBA();
    final tram = AppColors.routeLine.toARGB32().toRGBA();
    final bus = AppColors.busColor.toARGB32().toRGBA();
    final minibus = AppColors.minibusColor.toARGB32().toRGBA();
    final tonaya = AppColors.tonayaColor.toARGB32().toRGBA();
    final fallback = AppColors.routeLine.toARGB32().toRGBA();

    return <Object>[
      'match',
      <Object>['get', 'mode'],
      AppStrings.modeWalking,
      walk,
      AppStrings.modeMicrobus,
      microbus,
      AppStrings.modeBus,
      bus,
      AppStrings.modeTram,
      tram,
      AppStrings.modeMinibus,
      minibus,
      AppStrings.modeTonaya,
      tonaya,
      fallback,
    ];
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
