class ApiConstants {
  ApiConstants._();

  /// Backend base URL (Railway).
  static const String baseUrl =
      'https://alexandria-multimodal-routing-engine-production.up.railway.app';

  /// DB-tools base URL (Railway).
  static const String dbToolsBaseUrl =
      'https://dbtools-production.up.railway.app';

  static const String routesEndpoint = '/api/v1/journeys';

  static const String nearbyTripsEndpoint = '/api/v1/nearby-trips';
}
