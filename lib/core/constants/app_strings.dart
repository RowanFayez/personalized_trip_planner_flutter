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
  static const String prefBalanced = 'balanced';
  static const String prefSimplest = prefBalanced;

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

  // AI Agent
  static const String agentTitle = 'الاسطا';
  static const String agentSubtitle = 'El_osta transit agent';
  static const String agentGreeting = 'ازيك عايز تعرف اي من الاسطا ؟';
  static const String agentPromptTitle = 'اسألني عن أي مشوار';
  static const String agentTyping = 'الاسطا بيفكر';
  static const String agentInputHint = 'اسأل الاسطا عن الطريق...';
  static const String agentClearChatTooltip = 'Clear chat';
  static const String agentOnline = 'Online';
  static const String agentLocationError =
      'برجاء تفعيل الـ GPS وصلاحية الموقع لمساعدة الأسطى في معرفة مكانك.';
  static const String agentFallbackAnswer =
      'مش قادر اوصل لاجابة دلوقتي، جرب تسألني بطريقة تانية.';
  static const String agentSignInRequired =
      'عذراً، يجب تسجيل الدخول أولاً لاستخدام الدردشة.';
  static const String agentSignInGateMessage =
      'سجّل الدخول لاستخدام دردشة المساعد وحفظ محادثاتك.';
  static const String agentSignInButton = 'تسجيل الدخول';
  static const List<String> agentSuggestedQueries = <String>[
    'اروح ازاي رنين السيوف من سابا باشا',
    'عايز أروح سيدي جابر بس من غير ما أعدي على البحر؟',
    'إيه أسرع طريق يوديني عزبة سعد ؟',
    'أجرة المشروع من فيكتوريا لمحطة الرمل كام؟',
    'هل طريق الكورنيش زحمة دلوقتي عند جليم؟',
  ];
}
