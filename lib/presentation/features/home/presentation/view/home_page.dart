import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/config/map_config.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/services/map_service.dart';
import '../widgets/search_overlay.dart';
import '../widgets/map_action_buttons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MapboxMap? _mapboxMap;
  final MapService _mapService = MapService();
  final LocationService _locationService = LocationService();
  bool _didCenterOnUser = false;

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      await _mapService.animateCamera(
        latitude: position.latitude,
        longitude: position.longitude,
        zoom: 15.0,
      );
    }
  }

  Future<void> _centerOnUserOnStartup() async {
    if (_didCenterOnUser) return;
    _didCenterOnUser = true;
    await _goToCurrentLocation();
  }

  void _handlePreferencesPressed() {
    // TODO: Open preferences bottom sheet
  }

  void _handleChatPressed() {
    // TODO: Open AI chat interface
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapbox Map
          MapWidget(
            key: const ValueKey('mapWidget'),
            cameraOptions: MapConfig.defaultCamera,
            styleUri: MapConfig.styleUrl,
            textureView: true,
            onMapCreated: (MapboxMap mapboxMap) {
              _mapboxMap = mapboxMap;
              _mapService.initialize(mapboxMap);
              // Smoothly move to user's current location once at startup.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _centerOnUserOnStartup();
              });
            },
          ),

          // Top search UI overlay
          SearchOverlay(
            fromController: _fromController,
            toController: _toController,
            onPreferencesPressed: _handlePreferencesPressed,
          ),

          // Bottom action buttons
          Positioned(
            bottom: 32.h,
            left: 20.w,
            right: 20.w,
            child: MapActionButtons(
              onChatPressed: _handleChatPressed,
              onLocationPressed: _goToCurrentLocation,
            ),
          ),
        ],
      ),
    );
  }
}
