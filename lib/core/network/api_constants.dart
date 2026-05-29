class ApiConstants {
  ApiConstants._();

  /// Unified Azure API Gateway base URL.
  static const String baseUrl =
      'https://final-project-backend.calmplant-705f106c.germanywestcentral.azurecontainerapps.io/api/v1/';

  /// Routing endpoint.
  static const String routesEndpoint = 'route';

  /// Nearby trips endpoint.
  static const String nearbyTripsEndpoint = 'nearby-trips';

  /// Geocoding endpoint.
  static const String geocodingEndpoint = 'geocode';

  /// AI transit agent endpoint.
  static const String agentQueryEndpoint = 'agent/query';
}
