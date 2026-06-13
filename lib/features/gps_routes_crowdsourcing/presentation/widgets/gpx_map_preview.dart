import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../../../core/services/map_service.dart';
import '../../data/services/gpx_track_reader.dart';

class GpxMapPreview extends StatefulWidget {
  final String? gpxFilePath;
  final bool interactive;

  const GpxMapPreview({
    super.key,
    required this.gpxFilePath,
    this.interactive = false,
  });

  @override
  State<GpxMapPreview> createState() => _GpxMapPreviewState();
}

class _GpxMapPreviewState extends State<GpxMapPreview> {
  final MapService _mapService = MapService();
  final GpxTrackReader _reader = GpxTrackReader();
  final Completer<void> _ready = Completer<void>();
  MapboxMap? _mapboxMap;

  @override
  void didUpdateWidget(covariant GpxMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gpxFilePath != widget.gpxFilePath) {
      unawaited(_draw());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: ValueKey('gpx_preview_${widget.gpxFilePath ?? 'empty'}'),
      cameraOptions: MapConfig.defaultCamera,
      styleUri: MapConfig.styleUrl,
      textureView: true,
      onMapCreated: (mapboxMap) {
        _mapboxMap = mapboxMap;
        _mapService.initialize(mapboxMap);
        mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
        mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
        if (!_ready.isCompleted) {
          Future<void>.delayed(const Duration(milliseconds: 220), () {
            if (!_ready.isCompleted) _ready.complete();
            unawaited(_draw());
          });
        }
      },
    );
  }

  Future<void> _draw() async {
    if (_mapboxMap == null || !_ready.isCompleted) return;
    await _mapService.removeRoute('gpx_preview');
    await _mapService.removeMarker('gpx_preview_single_point');
    await _mapService.removeMarker('gpx_preview_current_location');

    final path = widget.gpxFilePath;
    if (path == null || path.trim().isEmpty) {
      await _showCurrentLocationFallback();
      return;
    }

    final tracks = await _reader.readSegments(path);
    final segments = tracks
        .map(
          (track) => MapRouteSegment(
            mode: track.mode ?? 'unknown',
            coordinates: track.coordinates,
          ),
        )
        .toList(growable: false);
    final allPositions = segments
        .expand((segment) => segment.coordinates)
        .toList(growable: false);
    if (allPositions.isEmpty) {
      await _showCurrentLocationFallback();
      return;
    }

    final drawableSegments = segments
        .where((segment) => segment.coordinates.length >= 2)
        .toList(growable: false);
    if (drawableSegments.isNotEmpty) {
      await _mapService.drawSegmentedRoute(
        id: 'gpx_preview',
        segments: drawableSegments,
        width: CrowdsourcingUi.routeWidth,
      );
      await _mapService.fitToRoute(allPositions);
      return;
    }

    final onlyPoint = allPositions.first;
    await _mapService.upsertMarker(
      id: 'gpx_preview_single_point',
      latitude: onlyPoint.lat.toDouble(),
      longitude: onlyPoint.lng.toDouble(),
    );
    await _mapService.animateCamera(
      latitude: onlyPoint.lat.toDouble(),
      longitude: onlyPoint.lng.toDouble(),
      zoom: 16,
    );
  }

  Future<void> _showCurrentLocationFallback() async {
    try {
      if (!await geo.Geolocator.isLocationServiceEnabled()) return;
      final permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        return;
      }
      final current = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      await _mapService.upsertMarker(
        id: 'gpx_preview_current_location',
        latitude: current.latitude,
        longitude: current.longitude,
      );
      await _mapService.animateCamera(
        latitude: current.latitude,
        longitude: current.longitude,
        zoom: 16,
      );
    } on Object {
      // Keep the Alexandria default camera visible if live location is unavailable.
    }
  }
}
