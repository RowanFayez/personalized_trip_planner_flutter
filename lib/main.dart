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
        );
      },
    );
  }
}
