import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../api_constants.dart';
import '../api_result.dart';

class RubyGeocodeItem {
  final String formattedAddress;
  final double latitude;
  final double longitude;

  const RubyGeocodeItem({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  static RubyGeocodeItem? tryParse(dynamic value) {
    if (value is! Map<String, dynamic>) return null;
    final formatted = (value['formatted_address'] as String?)?.trim();
    final latRaw = value['latitude'];
    final lngRaw = value['longitude'];
    if (formatted == null || formatted.isEmpty) return null;
    if (latRaw is! num || lngRaw is! num) return null;
    return RubyGeocodeItem(
      formattedAddress: formatted,
      latitude: latRaw.toDouble(),
      longitude: lngRaw.toDouble(),
    );
  }
}

class GeocodingRubyApiClient {
  final Dio _dio;

  GeocodingRubyApiClient({Dio? dio})
    : _dio = dio ?? GetIt.I<Dio>();

  /// Calls the authenticated Azure geocoding gateway.
  ///
  /// Returns an empty list on any error to keep UI behavior simple.
  Future<List<RubyGeocodeItem>> geocode({
    required String address,
    bool biasAlexandria = true,
    String language = 'ar',
    double? userLatitude,
    double? userLongitude,
  }) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return const [];

    final result = await safeApiCall(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiConstants.geocodingEndpoint,
        data: <String, dynamic>{
          'address': trimmed,
          'bias': biasAlexandria,
          'language': language,
          if (userLatitude != null) 'user_lat': userLatitude,
          if (userLongitude != null) 'user_lng': userLongitude,
        },
      );
      return res.data;
    });

    return result.when(
      success: (data) {
        if (data == null) return const <RubyGeocodeItem>[];
        final ok = data['success'];
        if (ok is! bool || ok != true) return const <RubyGeocodeItem>[];

        final list = data['results'];
        if (list is! List) return const <RubyGeocodeItem>[];

        return list
            .map(RubyGeocodeItem.tryParse)
            .whereType<RubyGeocodeItem>()
            .toList(growable: false);
      },
      failure: (_) => const <RubyGeocodeItem>[],
    );
  }
}
