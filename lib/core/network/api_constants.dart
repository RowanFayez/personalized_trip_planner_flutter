import '../config/env_config.dart';

class ApiConstants {
  ApiConstants._();

  static const String defaultBaseUrl =
      'https://routing-demo-eval.azurewebsites.net';

  /// Backend base URL.
  ///
  /// Default points to the provided Azure demo, but can be overridden via `.env`.
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

  static const String routesEndpoint = '/api/routes';
}
