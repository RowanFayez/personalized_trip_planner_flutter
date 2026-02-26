import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../../core/config/map_config.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/services/map_service.dart';

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
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // From field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _fromController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'From: من',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      prefixIcon: const Icon(
                        Icons.my_location,
                        color: AppColors.primaryTeal,
                      ),
                      filled: true,
                      fillColor: AppColors.searchInputBackground, // #1B2E35
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // To field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _toController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'To: إلى أين؟',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: AppColors.accentRed,
                      ),
                      filled: true,
                      fillColor: AppColors.searchInputBackground, // #1B2E35
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Set Preferences Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Open preferences bottom sheet
                      },
                      icon: const Icon(Icons.tune),
                      label: const Text('Set preferences'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.searchInputBackground,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom action buttons
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Chat with AI button
                FloatingActionButton.extended(
                  onPressed: () {
                    // TODO: Open AI chat
                  },
                  backgroundColor: AppColors.searchInputBackground,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('الأسطى\nChat with AI'),
                  heroTag: 'chat',
                ),

                // Current location button
                FloatingActionButton(
                  onPressed: _goToCurrentLocation,
                  backgroundColor: AppColors.currentLocationButton,
                  heroTag: 'location',
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
