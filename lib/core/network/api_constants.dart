class ApiConstants {
  ApiConstants._();

  /// Backend base URL (Railway).
  static const String baseUrl = 'https://routing-api-production-54ce.up.railway.app';

  /// DB-tools base URL (Railway).
  static const String dbToolsBaseUrl =
      'https://db-tools-production-6513.up.railway.app';

  static const String routesEndpoint = '/api/v1/journeys';

  static const String nearbyTripsEndpoint = '/api/v1/nearby-trips';
}
