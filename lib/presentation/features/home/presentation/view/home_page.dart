import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/config/map_config.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/services/map_service.dart';
import '../../../../../core/services/mapbox_geocoding_service.dart';
import '../controllers/place_search_controller.dart';
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
  final MapboxGeocodingService _geocodingService = MapboxGeocodingService();
  bool _didCenterOnUser = false;

  double? _proximityLatitude;
  double? _proximityLongitude;

  late final PlaceSearchController _fromSearch;
  late final PlaceSearchController _toSearch;

  @override
  void initState() {
    super.initState();

    _fromSearch = PlaceSearchController(
      geocodingService: _geocodingService,
      mapService: _mapService,
      markerId: 'from_pin',
      markerColor: AppColors.primaryTeal,
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _toSearch = PlaceSearchController(
      geocodingService: _geocodingService,
      mapService: _mapService,
      markerId: 'to_pin',
      markerColor: AppColors.accentRed,
    )..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _fromSearch.dispose();
    _toSearch.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      _proximityLatitude = position.latitude;
      _proximityLongitude = position.longitude;

      _fromSearch.setProximity(
        latitude: _proximityLatitude,
        longitude: _proximityLongitude,
      );
      _toSearch.setProximity(
        latitude: _proximityLatitude,
        longitude: _proximityLongitude,
      );

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
              // Hide Mapbox ornaments
              mapboxMap.scaleBar.updateSettings(
                ScaleBarSettings(enabled: false),
              );
              mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
              // Smoothly move to user's current location once at startup.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _centerOnUserOnStartup();
              });
            },
          ),

          // Gradient overlay matching HTML mockup:
          // from-background-dark/80 via-background-dark/20 to-background-dark/50
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x800F2123), // top: 50% dark
                      Color(0x330F2123), // via: 20% dark
                      Color(0x330F2123), // middle: transparent-ish
                      Color(0xCC0F2123), // bottom: 80% dark
                    ],
                    stops: [0.0, 0.25, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Top search UI overlay
          SearchOverlay(
            fromController: _fromSearch.textController,
            toController: _toSearch.textController,
            fromFocusNode: _fromSearch.focusNode,
            toFocusNode: _toSearch.focusNode,
            onFromChanged: _fromSearch.onChanged,
            onToChanged: _toSearch.onChanged,
            onFromSubmitted: (_) => _fromSearch.submit(),
            onToSubmitted: (_) => _toSearch.submit(),
            onFromTapped: _fromSearch.onFieldTap,
            onToTapped: _toSearch.onFieldTap,
            fromSuggestions: _fromSearch.suggestions,
            toSuggestions: _toSearch.suggestions,
            onFromSuggestionSelected: _fromSearch.selectSuggestion,
            onToSuggestionSelected: _toSearch.selectSuggestion,
            showFromSuggestions: _fromSearch.showSuggestions,
            showToSuggestions: _toSearch.showSuggestions,
            onPreferencesPressed: _handlePreferencesPressed,
          ),

          // Bottom action buttons
          Positioned(
            bottom: 32.h,
            left: 20.w,
            child: MapActionButtons(onChatPressed: _handleChatPressed),
          ),
        ],
      ),
    );
  }
}
