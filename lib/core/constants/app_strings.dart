/// App-wide string constants
class AppStrings {
  AppStrings._();

  // App Info
  static const String appName = 'NextStation';
  static const String appNameAr = 'المحطة التالية';

  // Map Configuration
  static const String mapStyleUrl = 'mapbox://styles/mapbox/streets-v12';

  // Default Location (Alexandria, Egypt - City Center)
  static const double alexandriaLat = 31.2001;
  static const double alexandriaLng = 29.9187;
  static const double defaultZoom = 13.0;

  // Transport Modes
  static const String modeMicrobus = 'microbus';
  static const String modeTram = 'tram';
  static const String modeMinibus = 'minibus';
  static const String modeBus = 'bus';
  static const String modeWalking = 'walking';
  static const String modeTonaya = 'tonaya';

  // Route Preferences
  static const String prefFastest = 'fastest';
  static const String prefCheapest = 'cheapest';
  static const String prefSimplest = 'simplest';

  // Storage Keys
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyUserPreferences = 'user_preferences';
  static const String keyRecentSearches = 'recent_searches';
  static const String keyFavoriteRoutes = 'favorite_routes';
  static const String keyMaxWalkingTime = 'max_walking_time';

  // API Endpoints (will be configured from backend)
  static const String endpointRoute = '/route';
  static const String endpointSearch = '/search';
  static const String endpointStops = '/stops';
  static const String endpointChat = '/chat';
}
