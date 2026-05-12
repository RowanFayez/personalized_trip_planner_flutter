import 'dart:async';

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
import '../../../../../core/services/user_activity_service.dart';
import '../../../../../features/nearby_trips/data/services/nearby_trips_service.dart';
import '../../../../../features/nearby_trips/domain/entities/nearby_route.dart';
import '../../../../../features/routing/presentation/cubit/routing_cubit.dart';
import '../../../../../features/routing/presentation/cubit/routing_state.dart';
import '../../../../features/map_picker/presentation/view/map_picker_page.dart';
import '../../../auth/presentation/widgets/google_sign_in_dialog.dart';
import '../controllers/place_search_controller.dart';
import '../widgets/nearby_bus_location_pin.dart';
import '../widgets/nearby_routes_bottom_sheet.dart';
import '../widgets/nearby_routes_floating_card.dart';
import '../widgets/search_overlay.dart';
import '../widgets/map_action_buttons.dart';
import '../widgets/routing_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  final bool viewLastRouteOnStart;

  const HomePage({super.key, this.viewLastRouteOnStart = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapService _mapService = MapService();
  final LocationService _locationService = LocationService();
  final MapboxGeocodingService _geocodingService = MapboxGeocodingService();
  final NearbyTripsService _nearbyTripsService = NearbyTripsService();
  final AuthService _authService = sl<AuthService>();
  late final SavedPlacesService _savedPlacesService = SavedPlacesService(
    authService: _authService,
  );
  final UserActivityService _userActivityService = sl<UserActivityService>();
  bool _didCenterOnUser = false;

  MapboxMap? _mapboxMap;

  // ── Nearby Transit Routes (manual FAB trigger) ─────────────────
  bool _isNearbyModeActive = false;
  String? _nearbyStreetName;
  bool _isNearbyLoading = false;
  List<NearbyRoute> _nearbyRoutes = const <NearbyRoute>[];

  double? _proximityLatitude;
  double? _proximityLongitude;

  late final PlaceSearchController _fromSearch;
  late final PlaceSearchController _toSearch;

  SavedPlaceType? _selectedQuickPlaceFrom;
  SavedPlaceType? _selectedQuickPlaceTo;

  String? _lastRoutesKey;
  String? _lastRoutingSnackKey;
  String? _lastFromSelectionKey;
  String? _lastToSelectionKey;

  @override
  void initState() {
    super.initState();

    if (widget.viewLastRouteOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _viewLastRouteOnMap();
      });
    }

    _fromSearch =
        PlaceSearchController(
          geocodingService: _geocodingService,
          mapService: _mapService,
          markerId: 'from_pin',
          markerColor: AppColors.primaryTeal,
        )..addListener(() {
          if (mounted) {
            setState(() {});
            _maybeStoreLastSearch(isFrom: true);
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
            _maybeStoreLastSearch(isFrom: false);
            _maybeFetchRoutes();
          }
        });

    _toSearch.focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _viewLastRouteOnMap() async {
    final last = await _userActivityService.getLastRoute();
    if (!mounted) return;
    if (last == null || last.from.trim().isEmpty || last.to.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No recent route found.')));
      return;
    }

    setState(() {
      _selectedQuickPlaceFrom = null;
      _selectedQuickPlaceTo = null;
    });

    final fromResolved = await _geocodingService.forwardGeocode(
      address: last.from,
    );
    final toResolved = await _geocodingService.forwardGeocode(address: last.to);

    if (!mounted) return;
    if (fromResolved == null || toResolved == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load that route on the map.')),
      );
      return;
    }

    await _fromSearch.goToLocation(
      title: last.from,
      latitude: fromResolved.latitude,
      longitude: fromResolved.longitude,
    );
    await _toSearch.goToLocation(
      title: last.to,
      latitude: toResolved.latitude,
      longitude: toResolved.longitude,
    );

    _maybeFetchRoutes(force: true);
  }

  @override
  void dispose() {
    _fromSearch.dispose();
    _toSearch.dispose();
    super.dispose();
  }

  // ── Nearby Transit Routes (manual FAB) ─────────────────────────

  Future<void> _triggerNearbySearch() async {
    if (_mapboxMap == null) return;

    setState(() {
      _isNearbyModeActive = true;
      _isNearbyLoading = true;
      _nearbyStreetName = null;
      _nearbyRoutes = const <NearbyRoute>[];
    });

    final cameraState = await _mapboxMap!.getCameraState();
    final center = cameraState.center.coordinates;
    final lat = center.lat.toDouble();
    final lng = center.lng.toDouble();

    final streetFuture = _resolveStreetNameAt(
      latitude: lat,
      longitude: lng,
    ).catchError((_) => null);
    final routesFuture = _nearbyTripsService
        .getNearbyRoutes(latitude: lat, longitude: lng, radiusM: 500)
        .catchError((_) => const <NearbyRoute>[]);

    final results = await Future.wait<Object?>([streetFuture, routesFuture]);
    if (!mounted) return;

    setState(() {
      _nearbyStreetName = results[0] as String?;
      _nearbyRoutes =
          (results[1] as List<NearbyRoute>?) ?? const <NearbyRoute>[];
      _isNearbyLoading = false;
    });
  }

  void _clearNearbyMode() {
    setState(() {
      _isNearbyModeActive = false;
      _nearbyStreetName = null;
      _nearbyRoutes = const <NearbyRoute>[];
      _isNearbyLoading = false;
    });
  }

  Future<String?> _resolveStreetNameAt({
    required double latitude,
    required double longitude,
  }) async {
    if (_mapboxMap == null) return null;

    // Try Mapbox vector tiles for an actual road label first.
    try {
      final screenCenter = await _mapboxMap!.pixelForCoordinate(
        Point(coordinates: Position(longitude, latitude)),
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
          final streetName =
              (props['name_ar'] as String?) ??
              (props['name'] as String?) ??
              (props['name_en'] as String?);
          if (streetName != null && streetName.trim().isNotEmpty) {
            return streetName.trim();
          }
        }
      }
    } catch (_) {
      // Best-effort; fall back to reverse geocoding.
    }

    final result = await _geocodingService.reverseGeocode(
      latitude: latitude,
      longitude: longitude,
    );
    return result?.title;
  }

  Future<void> _onHomeMapTap(MapContentGestureContext ctx) async {
    if (ctx.gestureState != GestureState.ended) return;
    if (_mapboxMap == null) return;

    final coords = ctx.point.coordinates;
    final lat = coords.lat.toDouble();
    final lng = coords.lng.toDouble();

    final cameraState = await _mapboxMap!.getCameraState();
    final zoom = cameraState.zoom.toDouble();

    final cameraOptions = MapConfig.createCamera(
      latitude: lat,
      longitude: lng,
      zoom: zoom,
    );

    await _mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 650));
  }

  void _openNearbyRoutesSheet() {
    if (_nearbyRoutes.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.62,
          child: NearbyRoutesBottomSheet(
            streetName: _nearbyStreetName,
            isLoading: _isNearbyLoading,
            routes: _nearbyRoutes,
          ),
        );
      },
    );
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
    final signedIn = _authService.currentUser != null;
    if (signedIn) {
      context.push('/profile');
      return;
    }

    showGoogleSignInDialog(context);
  }

  void _maybeStoreLastSearch({required bool isFrom}) {
    final controller = isFrom ? _fromSearch : _toSearch;
    final lat = controller.selectedLatitude;
    final lon = controller.selectedLongitude;
    if (lat == null || lon == null) return;

    final key = '${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}';
    if (isFrom) {
      if (_lastFromSelectionKey == key) return;
      _lastFromSelectionKey = key;
    } else {
      if (_lastToSelectionKey == key) return;
      _lastToSelectionKey = key;
    }

    final title = controller.textController.text.trim();
    if (title.isEmpty) return;
    _userActivityService.setLastSearch(title);
  }

  Future<void> _handleFromMapPick() async {
    setState(() {
      _selectedQuickPlaceFrom = null;
    });
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
    setState(() {
      _selectedQuickPlaceTo = null;
    });
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

    final fromTitle = _fromSearch.textController.text.trim();
    final toTitle = _toSearch.textController.text.trim();
    if (fromTitle.isNotEmpty && toTitle.isNotEmpty) {
      _userActivityService.setLastRoute(from: fromTitle, to: toTitle);
    }

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
    final isTo = _toSearch.focusNode.hasFocus;
    setState(() {
      if (isTo) {
        _selectedQuickPlaceTo = type;
      } else {
        _selectedQuickPlaceFrom = type;
      }
    });

    final place = await _savedPlacesService.getPlace(type);
    if (!mounted) return;

    final label = switch (type) {
      SavedPlaceType.home => 'Home',
      SavedPlaceType.work => 'Work',
      SavedPlaceType.college => 'College',
    };

    if (place == null) {
      // Prefer saving from the currently selected search location.
      final selectedLat = _activeSearchController.selectedLatitude;
      final selectedLon = _activeSearchController.selectedLongitude;
      final selectedTitle = _activeSearchController.textController.text.trim();

      if (selectedLat != null && selectedLon != null) {
        await _savedPlacesService.setPlace(
          type,
          SavedPlace(
            latitude: selectedLat,
            longitude: selectedLon,
            name: selectedTitle,
          ),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label saved.')));
        return;
      }

      // Otherwise, let the user pick it on the map.
      final result = await context.push<MapPickerResult>(
        '/map-picker/${type.name}',
      );
      if (!mounted) return;
      if (result == null) return;

      await _savedPlacesService.setPlace(
        type,
        SavedPlace(
          latitude: result.latitude,
          longitude: result.longitude,
          name: result.placeName,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label saved.')));
      return;
    }

    await _activeSearchController.goToLocation(
      title: place.name?.trim().isNotEmpty == true ? place.name!.trim() : label,
      latitude: place.latitude,
      longitude: place.longitude,
    );
  }

  /// Callback for the RoutingBottomSheet close button — removes drawn route.
  Future<void> _onRoutingSheetClosed() async {
    await _mapService.removeRoute('active');
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: BlocConsumer<RoutingCubit, RoutingState>(
        listenWhen: (previous, current) {
          return previous.status != current.status ||
              previous.selectedJourneyIndex != current.selectedJourneyIndex;
        },
        listener: (context, state) async {
          // ── Auto-clear nearby mode when routing becomes active ──
          if (state.status != RoutingStatus.initial && _isNearbyModeActive) {
            _isNearbyModeActive = false;
            _nearbyRoutes = const <NearbyRoute>[];
            _nearbyStreetName = null;
            _isNearbyLoading = false;
          }

          // ── Clear drawn route when cubit resets to initial ──
          if (state.status == RoutingStatus.initial) {
            await _mapService.removeRoute('active');
            return;
          }

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
        builder: (context, routingState) {
          final isRouting = routingState.status != RoutingStatus.initial;

          return Stack(
            children: [
              // ── Mapbox Map ──────────────────────────────────────
              MapWidget(
                key: const ValueKey('mapWidget'),
                cameraOptions: MapConfig.defaultCamera,
                styleUri: MapConfig.styleUrl,
                textureView: true,
                onTapListener: _onHomeMapTap,
                onMapCreated: (MapboxMap mapboxMap) {
                  _mapboxMap = mapboxMap;
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

              // ── Gradient overlay ────────────────────────────────
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

              // ── Nearby mode UI (pin + card) — only in Nearby Mode ──
              if (_isNearbyModeActive && !isRouting) ...[
                const IgnorePointer(child: NearbyBusLocationPin()),
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 150.h),
                    child: SizedBox(
                      width: 1.sw - 46.w,
                      child: NearbyRoutesFloatingCard(
                        streetName: _nearbyStreetName,
                        isLoading: _isNearbyLoading,
                        routes: _nearbyRoutes,
                        onTap: _openNearbyRoutesSheet,
                        onClose: _clearNearbyMode,
                      ),
                    ),
                  ),
                ),
              ],

              // ── Nearby Search FAB — only in Default Mode ───────
              if (!_isNearbyModeActive && !isRouting)
                Positioned(
                  right: 20.w,
                  bottom: 110.h + safeBottomInset,
                  child: _NearbySearchFab(onPressed: _triggerNearbySearch),
                ),

              // ── Top search UI overlay ───────────────────────────
              StreamBuilder<Object?>(
                stream: _authService.authStateChanges(),
                builder: (context, _) {
                  final user = _authService.currentUser;
                  final signedIn = user != null;

                  return SearchOverlay(
                    fromController: _fromSearch.textController,
                    toController: _toSearch.textController,
                    fromFocusNode: _fromSearch.focusNode,
                    toFocusNode: _toSearch.focusNode,
                    onFromChanged: (value) {
                      if (_selectedQuickPlaceFrom != null) {
                        setState(() => _selectedQuickPlaceFrom = null);
                      }
                      _fromSearch.onChanged(value);
                    },
                    onToChanged: (value) {
                      if (_selectedQuickPlaceTo != null) {
                        setState(() => _selectedQuickPlaceTo = null);
                      }
                      _toSearch.onChanged(value);
                    },
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
                        signedIn &&
                        (_fromSearch.focusNode.hasFocus ||
                            _toSearch.focusNode.hasFocus),
                    showQuickPlacesUnderFrom: !_toSearch.focusNode.hasFocus,
                    signedInUserId: user?.uid,
                    savedPlacesService: _savedPlacesService,
                    onQuickPlaceSelected: (type) =>
                        _handleQuickPlaceSelected(type),
                    selectedQuickPlaceFrom: _selectedQuickPlaceFrom,
                    selectedQuickPlaceTo: _selectedQuickPlaceTo,
                    fromSuggestions: _fromSearch.suggestions,
                    toSuggestions: _toSearch.suggestions,
                    onFromSuggestionSelected: (s) async {
                      if (_selectedQuickPlaceFrom != null) {
                        setState(() => _selectedQuickPlaceFrom = null);
                      }
                      await _fromSearch.selectSuggestion(s);
                    },
                    onToSuggestionSelected: (s) async {
                      if (_selectedQuickPlaceTo != null) {
                        setState(() => _selectedQuickPlaceTo = null);
                      }
                      await _toSearch.selectSuggestion(s);
                    },
                    showFromSuggestions: _fromSearch.showSuggestions,
                    showToSuggestions: _toSearch.showSuggestions,
                    onPreferencesPressed: _handlePreferencesPressed,
                    onFromMapPressed: _handleFromMapPick,
                    onToMapPressed: _handleToMapPick,
                  );
                },
              ),

              // ── Bottom action buttons ───────────────────────────
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
                  child: SizedBox(
                    width: 1.sw - 40.w,
                    child: StreamBuilder<Object?>(
                      stream: _authService.authStateChanges(),
                      builder: (context, _) {
                        final user = _authService.currentUser;
                        return MapActionButtons(
                          onChatPressed: _handleChatPressed,
                          onProfilePressed: _handleProfilePressed,
                          userPhotoUrl: user?.photoURL,
                          userEmail: user?.email,
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Routing bottom sheet ────────────────────────────
              Align(
                alignment: Alignment.bottomCenter,
                child: RoutingBottomSheet(onClose: _onRoutingSheetClosed),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Nearby Search FAB ──────────────────────────────────────────────
class _NearbySearchFab extends StatelessWidget {
  final VoidCallback onPressed;

  const _NearbySearchFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: AppColors.shadow,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 54.r,
          height: 54.r,
          child: Center(
            child: Icon(
              Icons.departure_board_rounded,
              color: AppColors.primaryTeal,
              size: 26.r,
            ),
          ),
        ),
      ),
    );
  }
}
