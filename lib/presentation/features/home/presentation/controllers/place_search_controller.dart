import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/services/map_service.dart';
import '../../../../../core/services/mapbox_geocoding_service.dart';

class PlaceSearchController extends ChangeNotifier {
  final MapboxGeocodingService _geocodingService;
  final MapService _mapService;
  final String _markerId;
  final Color _markerColor;

  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  Timer? _debounce;
  List<MapboxPlaceSuggestion> _suggestions = const [];
  bool _showSuggestions = false;

  double? _proximityLatitude;
  double? _proximityLongitude;

  double? _selectedLatitude;
  double? _selectedLongitude;

  double? get selectedLatitude => _selectedLatitude;
  double? get selectedLongitude => _selectedLongitude;

  PlaceSearchController({
    required MapboxGeocodingService geocodingService,
    required MapService mapService,
    required String markerId,
    required Color markerColor,
  }) : _geocodingService = geocodingService,
       _mapService = mapService,
       _markerId = markerId,
       _markerColor = markerColor;

  List<MapboxPlaceSuggestion> get suggestions => _suggestions;

  bool get showSuggestions =>
      _showSuggestions &&
      _suggestions.isNotEmpty &&
      textController.text.trim().isNotEmpty;

  void setProximity({double? latitude, double? longitude}) {
    _proximityLatitude = latitude;
    _proximityLongitude = longitude;
  }

  void onFieldTap() {
    _showSuggestions = true;
    notifyListeners();
  }

  void onChanged(String value) {
    _debounce?.cancel();
    _showSuggestions = true;

    final query = value.trim();
    if (query.isEmpty) {
      _suggestions = const [];
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final results = await _geocodingService.autocomplete(
        query: query,
        country: 'EG',
        proximityLatitude: _proximityLatitude,
        proximityLongitude: _proximityLongitude,
      );
      _suggestions = results;
      notifyListeners();
    });
  }

  Future<void> submit() async {
    final query = textController.text.trim();
    if (query.isEmpty) return;

    // If we already have suggestions, pick top.
    if (_suggestions.isNotEmpty) {
      await selectSuggestion(_suggestions.first);
      return;
    }

    // Otherwise do a 1-shot lookup and pick first.
    final results = await _geocodingService.autocomplete(
      query: query,
      limit: 1,
      country: 'EG',
      proximityLatitude: _proximityLatitude,
      proximityLongitude: _proximityLongitude,
    );

    if (results.isEmpty) return;
    await selectSuggestion(results.first);
  }

  Future<void> selectSuggestion(MapboxPlaceSuggestion suggestion) async {
    textController.text = suggestion.title;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );

    _suggestions = const [];
    _showSuggestions = false;

    _selectedLatitude = suggestion.latitude;
    _selectedLongitude = suggestion.longitude;
    notifyListeners();

    await _mapService.animateCamera(
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
      zoom: 15.0,
    );

    await _mapService.upsertMarker(
      id: _markerId,
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
      color: _markerColor,
    );
  }

  Future<void> goToLocation({
    required String title,
    required double latitude,
    required double longitude,
  }) async {
    textController.text = title;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );

    _suggestions = const [];
    _showSuggestions = false;

    _selectedLatitude = latitude;
    _selectedLongitude = longitude;
    notifyListeners();

    await _mapService.animateCamera(
      latitude: latitude,
      longitude: longitude,
      zoom: 15.0,
    );

    await _mapService.upsertMarker(
      id: _markerId,
      latitude: latitude,
      longitude: longitude,
      color: _markerColor,
    );
  }

  void clearSuggestions() {
    _suggestions = const [];
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
