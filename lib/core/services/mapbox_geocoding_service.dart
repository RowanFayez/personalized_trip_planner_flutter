import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/map_config.dart';

class MapboxPlaceSuggestion {
  final String id;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;

  const MapboxPlaceSuggestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });

  String get displayName => subtitle.isNotEmpty ? subtitle : title;
}

/// Minimal Mapbox Geocoding API client for autocomplete.
class MapboxGeocodingService {
  final http.Client _client;
  final String _accessToken;

  MapboxGeocodingService({http.Client? client, String? accessToken})
    : _client = client ?? http.Client(),
      _accessToken = accessToken ?? MapConfig.accessToken;

  Future<List<MapboxPlaceSuggestion>> autocomplete({
    required String query,
    int limit = 6,
    String language = 'ar',
    String? country,
    double? proximityLatitude,
    double? proximityLongitude,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final params = <String, String>{
      'access_token': _accessToken,
      'autocomplete': 'true',
      'limit': limit.toString(),
      'language': language,
    };

    final countryValue = (country ?? 'EG').trim();
    if (countryValue.isNotEmpty) {
      params['country'] = countryValue;
    }

    if (proximityLatitude != null && proximityLongitude != null) {
      params['proximity'] = '$proximityLongitude,$proximityLatitude';
    }

    final uri = Uri.https(
      'api.mapbox.com',
      '/geocoding/v5/mapbox.places/$trimmed.json',
      params,
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return const [];
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final features = (decoded['features'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    return features
        .map((feature) {
          final id = (feature['id'] as String?) ?? '';
          final title = (feature['text'] as String?) ?? '';
          final placeName = (feature['place_name'] as String?) ?? '';
          final center = (feature['center'] as List<dynamic>? ?? const []);
          if (center.length < 2) return null;

          final longitude = (center[0] as num).toDouble();
          final latitude = (center[1] as num).toDouble();

          return MapboxPlaceSuggestion(
            id: id,
            title: title,
            subtitle: placeName,
            latitude: latitude,
            longitude: longitude,
          );
        })
        .whereType<MapboxPlaceSuggestion>()
        .toList(growable: false);
  }

  /// Reverse geocode: convert coordinates to a place name.
  /// Returns null when no result is found.
  Future<MapboxPlaceSuggestion?> reverseGeocode({
    required double latitude,
    required double longitude,
    String language = 'ar',
  }) async {
    final params = <String, String>{
      'access_token': _accessToken,
      'language': language,
      'limit': '1',
      'types': 'address,poi,place,neighborhood,locality',
    };

    final uri = Uri.https(
      'api.mapbox.com',
      '/geocoding/v5/mapbox.places/$longitude,$latitude.json',
      params,
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final features = (decoded['features'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    if (features.isEmpty) return null;

    final feature = features.first;
    final id = (feature['id'] as String?) ?? '';
    final title = (feature['text'] as String?) ?? '';
    final placeName = (feature['place_name'] as String?) ?? '';
    final center = (feature['center'] as List<dynamic>? ?? const []);
    final lng = center.length >= 2 ? (center[0] as num).toDouble() : longitude;
    final lat = center.length >= 2 ? (center[1] as num).toDouble() : latitude;

    return MapboxPlaceSuggestion(
      id: id,
      title: title,
      subtitle: placeName,
      latitude: lat,
      longitude: lng,
    );
  }
}
