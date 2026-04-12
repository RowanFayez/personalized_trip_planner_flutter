import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/config/map_config.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/services/map_service.dart';
import '../../../../../core/services/mapbox_geocoding_service.dart';
import '../../../../../core/services/saved_places_service.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../features/routing/presentation/cubit/routing_cubit.dart';
import '../../../../../features/routing/presentation/cubit/routing_state.dart';
import '../../../../features/map_picker/presentation/view/map_picker_page.dart';
import '../controllers/place_search_controller.dart';
import '../widgets/search_overlay.dart';
import '../widgets/map_action_buttons.dart';
import '../widgets/routing_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapService _mapService = MapService();
  final LocationService _locationService = LocationService();
  final MapboxGeocodingService _geocodingService = MapboxGeocodingService();
  final SavedPlacesService _savedPlacesService = SavedPlacesService();
  bool _didCenterOnUser = false;

  double? _proximityLatitude;
  double? _proximityLongitude;

  late final PlaceSearchController _fromSearch;
  late final PlaceSearchController _toSearch;

  String? _lastRoutesKey;
  String? _lastRoutingSnackKey;

  @override
  void initState() {
    super.initState();

    _fromSearch =
        PlaceSearchController(
          geocodingService: _geocodingService,
          mapService: _mapService,
          markerId: 'from_pin',
          markerColor: AppColors.primaryTeal,
        )..addListener(() {
          if (mounted) {
            setState(() {});
            _maybeFetchRoutes();
          }
        });

    _fromSearch.focusNode.addListener(() {
      if (mounted) setState(() {});
    });

    _toSearch =
        PlaceSearchController(
          geocodingService: _geocodingService,
          mapService: _mapService,
          markerId: 'to_pin',
          markerColor: AppColors.accentRed,
        )..addListener(() {
          if (mounted) {
            setState(() {});
            _maybeFetchRoutes();
          }
        });

    _toSearch.focusNode.addListener(() {
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

  Future<void> _handlePreferencesPressed() async {
    if (!mounted) return;

    final applied = await context.push<bool>('/preferences');
    if (!mounted) return;

    if (applied == true) {
      _maybeFetchRoutes(force: true);
    }
  }

  void _handleChatPressed() {
    // TODO: Open AI chat interface
  }

  void _handleProfilePressed() {
    context.push('/profile');
  }

  Future<void> _handleFromMapPick() async {
    _fromSearch.focusNode.unfocus();
    final result = await context.push<MapPickerResult>('/map-picker/from');
    if (result != null && mounted) {
      await _fromSearch.goToLocation(
        title: result.placeName,
        latitude: result.latitude,
        longitude: result.longitude,
      );
      _maybeFetchRoutes();
    }
  }

  Future<void> _handleToMapPick() async {
    _toSearch.focusNode.unfocus();
    final result = await context.push<MapPickerResult>('/map-picker/to');
    if (result != null && mounted) {
      await _toSearch.goToLocation(
        title: result.placeName,
        latitude: result.latitude,
        longitude: result.longitude,
      );
      _maybeFetchRoutes();
    }
  }

  void _maybeFetchRoutes({bool force = false}) {
    final fromLat = _fromSearch.selectedLatitude;
    final fromLon = _fromSearch.selectedLongitude;
    final toLat = _toSearch.selectedLatitude;
    final toLon = _toSearch.selectedLongitude;

    if (fromLat == null || fromLon == null || toLat == null || toLon == null) {
      return;
    }

    final key =
        '${fromLat.toStringAsFixed(6)},${fromLon.toStringAsFixed(6)}|'
        '${toLat.toStringAsFixed(6)},${toLon.toStringAsFixed(6)}';
    if (!force && _lastRoutesKey == key) return;

    _lastRoutesKey = key;
    context.read<RoutingCubit>().fetchRoutes(
      startLat: fromLat,
      startLon: fromLon,
      endLat: toLat,
      endLon: toLon,
    );
  }

  void _showRoutingSnackOnce(String message) {
    final key = message.trim();
    if (key.isEmpty) return;
    if (_lastRoutingSnackKey == key) return;
    _lastRoutingSnackKey = key;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  PlaceSearchController get _activeSearchController {
    if (_toSearch.focusNode.hasFocus) return _toSearch;
    return _fromSearch;
  }

  Future<void> _handleQuickPlaceSelected(SavedPlaceType type) async {
    final place = await _savedPlacesService.getPlace(type);
    if (!mounted) return;

    if (place == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set this location in preferences first.'),
        ),
      );
      return;
    }

    final title = switch (type) {
      SavedPlaceType.home => 'Home',
      SavedPlaceType.work => 'Work',
      SavedPlaceType.college => 'College',
    };

    await _activeSearchController.goToLocation(
      title: title,
      latitude: place.latitude,
      longitude: place.longitude,
    );
  }

  void _handleQuickPlaceMore() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('More places: coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final user = sl<AuthService>().currentUser;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: BlocListener<RoutingCubit, RoutingState>(
        listenWhen: (previous, current) {
          return previous.status != current.status ||
              previous.selectedJourneyIndex != current.selectedJourneyIndex;
        },
        listener: (context, state) async {
          if (state.status == RoutingStatus.failure) {
            await _mapService.removeRoute('active');
            _showRoutingSnackOnce(state.errorMessage ?? 'No routes found.');
            return;
          }

          if (state.status != RoutingStatus.success) {
            return;
          }

          final journey = state.selectedJourney;
          if (journey == null) {
            await _mapService.removeRoute('active');
            _showRoutingSnackOnce(
              'No routes found with your current preferences.',
            );
            return;
          }

          final allPoints = <Position>[];
          final segments = <MapRouteSegment>[];
          for (final leg in journey.legs) {
            final coords = leg.path
                .map((p) => Position(p.lon, p.lat))
                .toList(growable: false);
            if (coords.length < 2) continue;

            final mode = leg.isWalk
                ? AppStrings.modeWalking
                : (leg.mode ?? '').trim().isNotEmpty
                ? leg.mode!.trim()
                : (leg.isTransfer ? AppStrings.modeWalking : 'unknown');

            segments.add(MapRouteSegment(mode: mode, coordinates: coords));
            allPoints.addAll(coords);
          }

          if (allPoints.isEmpty) {
            await _mapService.removeRoute('active');
            _showRoutingSnackOnce('No route path returned.');
            return;
          }

          await _mapService.removeRoute('active');
          if (segments.isNotEmpty) {
            await _mapService.drawSegmentedRoute(
              id: 'active',
              segments: segments,
            );
          } else {
            await _mapService.drawRoute(id: 'active', coordinates: allPoints);
          }
          await _mapService.fitToRoute(allPoints);
        },
        child: Stack(
          children: [
            // Mapbox Map
            MapWidget(
              key: const ValueKey('mapWidget'),
              cameraOptions: MapConfig.defaultCamera,
              styleUri: MapConfig.styleUrl,
              textureView: true,
              onMapCreated: (MapboxMap mapboxMap) {
                _mapService.initialize(mapboxMap);
                // Hide Mapbox ornaments
                mapboxMap.scaleBar.updateSettings(
                  ScaleBarSettings(enabled: false),
                );
                mapboxMap.compass.updateSettings(
                  CompassSettings(enabled: false),
                );
                // Smoothly move to user's current location once at startup.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _centerOnUserOnStartup();
                });
              },
            ),

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
              onFromTapped: () {
                _fromSearch.onFieldTap();
                setState(() {});
              },
              onToTapped: () {
                _toSearch.onFieldTap();
                setState(() {});
              },
              showQuickPlaces:
                  _fromSearch.focusNode.hasFocus ||
                  _toSearch.focusNode.hasFocus,
              showQuickPlacesUnderFrom: !_toSearch.focusNode.hasFocus,
              onQuickPlaceSelected: (type) => _handleQuickPlaceSelected(type),
              onQuickPlaceMore: _handleQuickPlaceMore,
              fromSuggestions: _fromSearch.suggestions,
              toSuggestions: _toSearch.suggestions,
              onFromSuggestionSelected: _fromSearch.selectSuggestion,
              onToSuggestionSelected: _toSearch.selectSuggestion,
              showFromSuggestions: _fromSearch.showSuggestions,
              showToSuggestions: _toSearch.showSuggestions,
              onPreferencesPressed: _handlePreferencesPressed,
              onFromMapPressed: _handleFromMapPick,
              onToMapPressed: _handleToMapPick,
            ),

            // Bottom action buttons
            Align(
              alignment: Alignment.bottomLeft,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  left: 20.w,
                  bottom: keyboardInset > 0
                      ? keyboardInset + 12.h
                      : 32.h + safeBottomInset,
                ),
                child: MapActionButtons(
                  onChatPressed: _handleChatPressed,
                  onProfilePressed: _handleProfilePressed,
                  userPhotoUrl: user?.photoURL,
                  userEmail: user?.email,
                ),
              ),
            ),

            // Routing bottom sheet
            const Align(
              alignment: Alignment.bottomCenter,
              child: RoutingBottomSheet(),
            ),
          ],
        ),
      ),
    );
  }
}
