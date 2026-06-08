import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/crowdsourcing_constants.dart';
import '../../../../core/services/map_service.dart';
import '../../data/models/gps_point_model.dart';

class RecordingMapCanvas extends StatefulWidget {
  final List<GpsPointModel> recentPoints;
  final Map<int, String?> segmentModes;
  final bool pulsePrompt;

  const RecordingMapCanvas({
    super.key,
    required this.recentPoints,
    required this.segmentModes,
    required this.pulsePrompt,
  });

  @override
  State<RecordingMapCanvas> createState() => _RecordingMapCanvasState();
}

class _RecordingMapCanvasState extends State<RecordingMapCanvas> {
  final MapService _mapService = MapService();
  final Completer<void> _ready = Completer<void>();
  MapboxMap? _mapboxMap;

  @override
  void didUpdateWidget(covariant RecordingMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recentPoints != widget.recentPoints ||
        oldWidget.pulsePrompt != widget.pulsePrompt) {
      unawaited(_draw());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey('crowdsourcing_recording_map'),
      cameraOptions: MapConfig.defaultCamera,
      styleUri: MapConfig.styleUrl,
      textureView: true,
      onMapCreated: (mapboxMap) {
        _mapboxMap = mapboxMap;
        _mapService.initialize(mapboxMap);
        _hideOrnaments(mapboxMap);
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
    await _ready.future;
    final segments = _routeSegments();
    await _mapService.removeRoute('recording_live');
    if (segments.isNotEmpty) {
      await _mapService.drawSegmentedRoute(
        id: 'recording_live',
        segments: segments,
        width: CrowdsourcingUi.routeWidth,
      );
      final allPositions = segments
          .expand((segment) => segment.coordinates)
          .toList(growable: false);
      await _mapService.fitToRoute(allPositions);
    }

    final last = widget.recentPoints.lastOrNull;
    if (last != null) {
      await _mapService.upsertMarker(
        id: 'recording_current',
        latitude: last.lat,
        longitude: last.lon,
        color: widget.pulsePrompt || _isStationary()
            ? AppColors.warning
            : AppColors.primaryTeal,
      );
    }
  }

  List<MapRouteSegment> _routeSegments() {
    final groups = <int, List<Position>>{};
    for (final point in widget.recentPoints) {
      groups.putIfAbsent(point.segmentIndex, () => <Position>[]);
      groups[point.segmentIndex]!.add(Position(point.lon, point.lat));
    }
    return groups.entries
        .where((entry) => entry.value.length >= 2)
        .map(
          (entry) => MapRouteSegment(
            mode: widget.segmentModes[entry.key] ?? 'unknown',
            coordinates: entry.value,
          ),
        )
        .toList(growable: false);
  }

  bool _isStationary() {
    if (widget.recentPoints.length < CrowdsourcingLimits.speedWindowMax) {
      return false;
    }
    final recent = widget.recentPoints
        .skip(widget.recentPoints.length - CrowdsourcingLimits.speedWindowMax)
        .toList(growable: false);
    final first = recent.first;
    return recent.every(
      (point) =>
          _distanceBetween(first.lat, first.lon, point.lat, point.lon) <=
          CrowdsourcingLimits.stationaryRadiusM,
    );
  }

  void _hideOrnaments(MapboxMap mapboxMap) {
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
  }

  double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusM = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  double _degToRad(double degrees) => degrees * math.pi / 180;
}

extension _LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
