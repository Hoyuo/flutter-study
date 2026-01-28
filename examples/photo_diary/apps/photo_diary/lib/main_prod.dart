import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/config/app_config.dart';
import 'firebase_options_prod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set environment to production
  AppConfig.setEnvironment(Environment.prod);

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load production environment variables
  await dotenv.load(fileName: '.env.prod');

  // Initialize Firebase with prod config
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Dependency Injection
  await configureDependencies();

  // Initialize Localization
  await EasyLocalization.ensureInitialized();

  // Disable debug banner in production
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: const PhotoDiaryApp(debugShowCheckedModeBanner: false),
    ),
  );
}
