import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/features/home/presentation/view/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await EnvConfig.init();

  // Provide Mapbox token at runtime (keeps native config files token-free for GitHub).
  MapboxOptions.setAccessToken(EnvConfig.mapboxAccessToken);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const NextStationApp());
}

class NextStationApp extends StatelessWidget {
  const NextStationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      child: const HomePage(),
      builder: (context, child) {
        return MaterialApp(
          title: 'NextStation',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: child,
        );
      },
    );
  }
}
