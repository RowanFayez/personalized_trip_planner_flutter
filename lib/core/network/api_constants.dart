import '../config/env_config.dart';

class ApiConstants {
  ApiConstants._();

  static const String defaultBaseUrl =
  'https://routing-api-production-54ce.up.railway.app';

  /// Backend base URL.
  ///
  static String get baseUrl {
    final fromEnv = EnvConfig.apiBaseUrl.trim();
    if (fromEnv.isNotEmpty && fromEnv != 'http://localhost:8000/api') {
      return _normalizeBaseUrl(fromEnv);
    }
    return defaultBaseUrl;
  }

  static String _normalizeBaseUrl(String url) {
    var normalized = url.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (normalized.endsWith('/api')) {
      normalized = normalized.substring(0, normalized.length - 4);
    }
    return normalized;
  }

  static const String routesEndpoint = '/api/v1/journeys';
}
