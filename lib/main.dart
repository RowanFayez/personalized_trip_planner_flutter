import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await EnvConfig.init();

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
    return MaterialApp(
      title: 'NextStation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomePage(),
    );
  }
}
