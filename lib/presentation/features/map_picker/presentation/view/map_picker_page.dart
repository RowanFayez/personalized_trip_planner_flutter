import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../../core/config/map_config.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/services/mapbox_geocoding_service.dart';
import '../widgets/picker_pin.dart';
import '../widgets/picker_location_card.dart';
import '../widgets/picker_back_button.dart';
import '../widgets/picker_my_location_button.dart';

/// Result returned when the user confirms a location from the map picker.
class MapPickerResult {
  final String placeName;
  final double latitude;
  final double longitude;

  const MapPickerResult({
    required this.placeName,
    required this.latitude,
    required this.longitude,
  });
}

/// Full-screen interactive map picker.
/// The user moves the map; a pin stays at the centre.
/// On camera idle → reverse-geocode → show place name card.
/// User taps confirm → pop with [MapPickerResult].
class MapPickerPage extends StatefulWidget {
  /// Which field triggered the picker ("from" or "to").
  final String fieldLabel;

  const MapPickerPage({super.key, required this.fieldLabel});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final LocationService _locationService = LocationService();
  final MapboxGeocodingService _geocodingService = MapboxGeocodingService();

  MapboxMap? _mapboxMap;

  String? _placeName;
  String? _placeSubtitle;
  double? _pinLat;
  double? _pinLng;
  bool _isMoving = false;
  bool _isGeocoding = false;

  Timer? _idleTimer;

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  // ── Map lifecycle ──────────────────────────────────────────────

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    // Hide ornaments
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));

    // Start at user location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToUserLocation(initial: true);
    });
  }

  void _onCameraChangeListener(CameraChangedEventData _) {
    if (!_isMoving) {
      setState(() {
        _isMoving = true;
        _placeName = null;
        _placeSubtitle = null;
      });
    }
    // Reset the idle timer every time camera moves
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(milliseconds: 800), _onCameraIdle);
  }

  Future<void> _onCameraIdle() async {
    if (_mapboxMap == null) return;

    final cameraState = await _mapboxMap!.getCameraState();
    final center = cameraState.center.coordinates;
    final lat = center.lat.toDouble();
    final lng = center.lng.toDouble();

    setState(() {
      _isMoving = false;
      _isGeocoding = true;
      _pinLat = lat;
      _pinLng = lng;
    });

    // Try Mapbox queryRenderedFeatures first for road name
    String? streetName;
    try {
      final screenCenter = await _mapboxMap!.pixelForCoordinate(
        Point(coordinates: Position(lng, lat)),
      );
      final features = await _mapboxMap!.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(
          ScreenCoordinate(x: screenCenter.x, y: screenCenter.y),
        ),
        RenderedQueryOptions(layerIds: ['road-label', 'road-street-label']),
      );
      if (features.isNotEmpty) {
        final props = features.first?.queriedFeature.feature['properties'];
        if (props is Map) {
          streetName =
              (props['name'] as String?) ??
              (props['name_en'] as String?) ??
              (props['name_ar'] as String?);
        }
      }
    } catch (_) {
      // queryRenderedFeatures may fail, fall through to geocoding
    }

    if (streetName != null && streetName.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _placeName = streetName;
        _placeSubtitle = null;
        _isGeocoding = false;
      });
      return;
    }

    // Fallback: reverse geocoding (network call)
    final result = await _geocodingService.reverseGeocode(
      latitude: lat,
      longitude: lng,
    );

    if (!mounted) return;
    setState(() {
      _placeName = result?.title;
      _placeSubtitle = result?.subtitle;
      _isGeocoding = false;
    });
  }

  // ── Actions ────────────────────────────────────────────────────

  Future<void> _goToUserLocation({bool initial = false}) async {
    final position = await _locationService.getCurrentLocation();
    if (position == null || !mounted || _mapboxMap == null) return;

    final cameraOptions = MapConfig.createCamera(
      latitude: position.latitude,
      longitude: position.longitude,
      zoom: 16.0,
    );

    await _mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 800));

    if (initial) {
      // trigger geocode for the initial position
      _idleTimer?.cancel();
      _idleTimer = Timer(const Duration(milliseconds: 900), _onCameraIdle);
    }
  }

  void _onConfirm() {
    if (_pinLat == null || _pinLng == null || _placeName == null) return;

    context.pop(
      MapPickerResult(
        placeName: _placeName!,
        latitude: _pinLat!,
        longitude: _pinLng!,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapbox map
          MapWidget(
            key: const ValueKey('pickerMapWidget'),
            cameraOptions: MapConfig.defaultCamera,
            styleUri: MapConfig.styleUrl,
            textureView: true,
            onMapCreated: _onMapCreated,
            onCameraChangeListener: _onCameraChangeListener,
          ),

          // Centre pin – always fixed in the middle of the screen
          const PickerPin(),

          // Back button
          PickerBackButton(onPressed: () => context.pop()),

          // "My Location" FAB
          Positioned(
            right: 20.w,
            bottom: 180.h,
            child: PickerMyLocationButton(onPressed: () => _goToUserLocation()),
          ),

          // Bottom location card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PickerLocationCard(
              fieldLabel: widget.fieldLabel,
              placeName: _placeName,
              placeSubtitle: _placeSubtitle,
              isMoving: _isMoving,
              isGeocoding: _isGeocoding,
              onConfirm: _onConfirm,
            ),
          ),
        ],
      ),
    );
  }
}
