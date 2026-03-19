import 'package:dio/dio.dart';

import '../config/map_config.dart';
import '../network/dio_factory.dart';
import '../network/geocoding_ruby/geocoding_ruby_api_client.dart';

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
  final Dio _mapboxDio;
  final String _accessToken;
  final GeocodingRubyApiClient _ruby;

  MapboxGeocodingService({
    Dio? mapboxDio,
    GeocodingRubyApiClient? ruby,
    String? accessToken,
  }) : _mapboxDio =
           mapboxDio ?? DioFactory.create(baseUrl: 'https://api.mapbox.com'),
       _ruby = ruby ?? GeocodingRubyApiClient(),
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

    // Search-bar autocomplete + forward-geocoding are powered by the Ruby
    // endpoint (Google Places-backed). Alexandria-only via `bias=true`.
    // We intentionally do NOT send user_lat/user_lng/language.
    final items = await _ruby.geocode(address: trimmed, biasAlexandria: true);

    final results = <MapboxPlaceSuggestion>[];
    for (final item in items) {
      final (title, subtitle) = _splitTitleSubtitle(item.formattedAddress);
      results.add(
        MapboxPlaceSuggestion(
          id: '${item.formattedAddress}|${item.latitude},${item.longitude}',
          title: title,
          subtitle: subtitle,
          latitude: item.latitude,
          longitude: item.longitude,
        ),
      );
      if (results.length >= limit) break;
    }

    return List<MapboxPlaceSuggestion>.unmodifiable(results);
  }

  /// Forward geocode to coordinates using the Ruby endpoint.
  /// Returns null when there are no results.
  Future<MapboxPlaceSuggestion?> forwardGeocode({
    required String address,
  }) async {
    final items = await _ruby.geocode(address: address, biasAlexandria: true);
    if (items.isEmpty) return null;

    final best = items.first;
    final (title, subtitle) = _splitTitleSubtitle(best.formattedAddress);
    return MapboxPlaceSuggestion(
      id: '${best.formattedAddress}|${best.latitude},${best.longitude}',
      title: title,
      subtitle: subtitle,
      latitude: best.latitude,
      longitude: best.longitude,
    );
  }

  (String title, String subtitle) _splitTitleSubtitle(String formatted) {
    final candidate = formatted.trim();
    if (candidate.isEmpty) return ('', '');

    // Prefer splitting on common separators to get a short title.
    final idxComma = candidate.indexOf(',');
    final idxArabicComma = candidate.indexOf('،');
    final idx = [idxComma, idxArabicComma]
        .where((v) => v >= 0)
        .fold<int?>(
          null,
          (best, v) => best == null ? v : (v < best ? v : best),
        );

    if (idx == null || idx <= 0) {
      return (candidate, candidate);
    }

    final title = candidate.substring(0, idx).trim();
    return (title.isEmpty ? candidate : title, candidate);
  }

  /// Reverse geocode: convert coordinates to a place name.
  /// Returns null when no result is found.
  Future<MapboxPlaceSuggestion?> reverseGeocode({
    required double latitude,
    required double longitude,
    String language = 'ar',
  }) async {
    Response<Map<String, dynamic>> res;
    try {
      res = await _mapboxDio.get<Map<String, dynamic>>(
        '/geocoding/v5/mapbox.places/$longitude,$latitude.json',
        queryParameters: <String, dynamic>{
          'access_token': _accessToken,
          'language': language,
          'limit': 1,
          'types': 'address,poi,place,neighborhood,locality',
        },
      );
    } catch (_) {
      return null;
    }

    final decoded = res.data;
    final featuresRaw = decoded?['features'];
    final features = (featuresRaw is List)
        ? featuresRaw.whereType<Map<String, dynamic>>().toList(growable: false)
        : const <Map<String, dynamic>>[];

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
