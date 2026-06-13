import 'dart:async';

import 'package:flutter/material.dart';
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
    final path = widget.gpxFilePath;
    if (path == null || _mapboxMap == null || !_ready.isCompleted) return;
    final tracks = await _reader.readSegments(path);
    final segments = tracks
        .map(
          (track) => MapRouteSegment(
            mode: track.mode ?? 'unknown',
            coordinates: track.coordinates,
          ),
        )
        .toList(growable: false);
    if (segments.isEmpty) return;
    await _mapService.removeRoute('gpx_preview');
    await _mapService.drawSegmentedRoute(
      id: 'gpx_preview',
      segments: segments,
      width: CrowdsourcingUi.routeWidth,
    );
    final allPositions = segments
        .expand((segment) => segment.coordinates)
        .toList(growable: false);
    await _mapService.fitToRoute(allPositions);
  }
}
