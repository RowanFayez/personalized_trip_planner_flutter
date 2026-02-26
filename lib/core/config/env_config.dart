import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration helper to securely access API keys and tokens
class EnvConfig {
  EnvConfig._();

  /// Initialize environment variables from .env file
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  /// Mapbox Access Token
  static String get mapboxAccessToken {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (token == null || token.isEmpty) {
      throw Exception('MAPBOX_ACCESS_TOKEN not found in .env file');
    }
    return token;
  }

  /// Google Maps/Places API Key
  static String get googleMapsApiKey {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GOOGLE_MAPS_API_KEY not found in .env file');
    }
    return key;
  }

  /// Backend API Base URL
  static String get apiBaseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api';
  }

  /// Check if running in development mode
  static bool get isDevelopment {
    return dotenv.env['ENVIRONMENT'] != 'production';
  }
}
