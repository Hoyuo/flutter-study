import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:photo_diary/app.dart';
import 'package:photo_diary/core/di/injection.dart';
import 'package:photo_diary/core/lifecycle/app_lifecycle_handler.dart';
import 'package:photo_diary/firebase_options_dev.dart';

void main() {
  // Zone을 사용하여 Dart 에러 캐치
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Lock orientation to portrait
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Load environment variables
      await dotenv.load(fileName: '.env.dev');

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Crashlytics 초기화
      // Flutter 프레임워크 에러 캐치
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Flutter 외부 에러 캐치 (release 모드에서만)
      if (kReleaseMode) {
        // Isolate 에러 캐치
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      // Initialize Dependency Injection
      await configureDependencies();

      // Initialize App Lifecycle Handler
      // DI 컨테이너에서 AppLifecycleHandler를 가져와 초기화
      // 이렇게 하면 앱 생명주기 이벤트를 감지하고 처리할 수 있습니다
      GetIt.instance<AppLifecycleHandler>();

      // Initialize Localization
      await EasyLocalization.ensureInitialized();

      runApp(
        EasyLocalization(
          supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en', 'US'),
          child: const PhotoDiaryApp(),
        ),
      );
    },
    (error, stack) {
      // Zone에서 캐치되지 않은 비동기 에러 처리
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}
