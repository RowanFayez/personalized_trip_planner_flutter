import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration helper to securely access API keys and tokens
class EnvConfig {
  EnvConfig._();

  /// Initialize environment variables from .env file
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // If the file is missing/empty, don't crash the whole app.
      // Tokens can still be provided via --dart-define.
    }
  }

  static String? _fromDartDefine(String key) {
    // `String.fromEnvironment` is compile-time; it works with --dart-define.
    const mapbox = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
    const google = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    const apiBase = String.fromEnvironment('API_BASE_URL');
    const env = String.fromEnvironment('ENVIRONMENT');

    switch (key) {
      case 'MAPBOX_ACCESS_TOKEN':
        return mapbox.isEmpty ? null : mapbox;
      case 'GOOGLE_MAPS_API_KEY':
        return google.isEmpty ? null : google;
      case 'API_BASE_URL':
        return apiBase.isEmpty ? null : apiBase;
      case 'ENVIRONMENT':
        return env.isEmpty ? null : env;
      default:
        return null;
    }
  }

  static String? _get(String key) {
    final fromEnvFile = dotenv.env[key];
    if (fromEnvFile != null && fromEnvFile.isNotEmpty) return fromEnvFile;
    return _fromDartDefine(key);
  }

  /// Mapbox Access Token
  static String get mapboxAccessToken {
    final token = _get('MAPBOX_ACCESS_TOKEN');
    if (token == null || token.isEmpty) {
      throw Exception('MAPBOX_ACCESS_TOKEN not found in .env file');
    }
    return token;
  }

  /// Google Maps/Places API Key
  static String get googleMapsApiKey {
    final key = _get('GOOGLE_MAPS_API_KEY');
    if (key == null || key.isEmpty) {
      throw Exception('GOOGLE_MAPS_API_KEY not found in .env file');
    }
    return key;
  }

  /// Backend API Base URL
  static String get apiBaseUrl {
    return _get('API_BASE_URL') ?? 'http://localhost:8000/api';
  }

  /// Check if running in development mode
  static bool get isDevelopment {
    return (_get('ENVIRONMENT') ?? '') != 'production';
  }
}
