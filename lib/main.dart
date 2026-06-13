import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/config/env_config.dart';
import 'core/di/service_locator.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/gps_routes_crowdsourcing/data/background/recording_background_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await EnvConfig.init();

  await Supabase.initialize(
    url: 'https://uhsvskfingvwqfpbxldf.supabase.co',
    anonKey: 'sb_publishable_VXEpxVo2QxsPD7qBCM4DUQ_iTxhXsbS',
  );

  // Dependency injection + local storage
  await ServiceLocator.init();
  await initializeCrowdsourcingBackgroundService();
  await AppRouter.checkPendingReview();

  // Provide Mapbox token at runtime (keeps native config files token-free for GitHub).
  MapboxOptions.setAccessToken(EnvConfig.mapboxAccessToken);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const YastaaApp());
}

class YastaaApp extends StatelessWidget {
  const YastaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Yastaa',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            return _PendingReviewLifecycleGate(
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}

class _PendingReviewLifecycleGate extends StatefulWidget {
  final Widget child;

  const _PendingReviewLifecycleGate({required this.child});

  @override
  State<_PendingReviewLifecycleGate> createState() =>
      _PendingReviewLifecycleGateState();
}

class _PendingReviewLifecycleGateState
    extends State<_PendingReviewLifecycleGate>
    with WidgetsBindingObserver {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingReview();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _openPendingReview();
    }
  }

  Future<void> _openPendingReview() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      await AppRouter.openPendingReviewIfAny();
    } finally {
      _isChecking = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
