import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

      // Initialize Firebase (handle already initialized case)
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on FirebaseException catch (e) {
        if (e.code != 'duplicate-app') {
          rethrow;
        }
        // Firebase already initialized by native layer, continue
        debugPrint('Firebase already initialized');
      }

      // Firebase Emulator 연결 (개발 환경에서 실제 Firebase 없이 테스트 가능)
      await _connectToFirebaseEmulatorIfNeeded();

      // Crashlytics 초기화 (Emulator 모드가 아닐 때만)
      final useEmulator = dotenv.env['USE_FIREBASE_EMULATOR'] == 'true';
      if (!useEmulator) {
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
      final useEmulator = dotenv.env['USE_FIREBASE_EMULATOR'] == 'true';
      if (!useEmulator) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } else {
        debugPrint('Error: $error\n$stack');
      }
    },
  );
}

/// Firebase Emulator Suite에 연결합니다.
/// .env.dev에서 USE_FIREBASE_EMULATOR=true로 설정하면 활성화됩니다.
/// 이를 통해 실제 Firebase 프로젝트 없이도 앱을 테스트할 수 있습니다.
Future<void> _connectToFirebaseEmulatorIfNeeded() async {
  final useEmulator = dotenv.env['USE_FIREBASE_EMULATOR'] == 'true';

  if (!useEmulator) {
    debugPrint('📱 Using production Firebase');
    return;
  }

  debugPrint('🔧 Connecting to Firebase Emulator Suite...');

  // Emulator 호스트 설정
  // Android Emulator: 10.0.2.2 (localhost 매핑)
  // iOS Simulator / 실제 기기: localhost 또는 컴퓨터 IP
  final host = dotenv.env['EMULATOR_HOST'] ??
      (Platform.isAndroid ? '10.0.2.2' : 'localhost');

  // Auth Emulator
  final authPort = int.tryParse(dotenv.env['AUTH_EMULATOR_PORT'] ?? '9099') ?? 9099;
  await FirebaseAuth.instance.useAuthEmulator(host, authPort);
  debugPrint('  ✓ Auth Emulator: $host:$authPort');

  // Firestore Emulator
  final firestorePort = int.tryParse(dotenv.env['FIRESTORE_EMULATOR_PORT'] ?? '8080') ?? 8080;
  FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
  debugPrint('  ✓ Firestore Emulator: $host:$firestorePort');

  // Storage Emulator
  final storagePort = int.tryParse(dotenv.env['STORAGE_EMULATOR_PORT'] ?? '9199') ?? 9199;
  await FirebaseStorage.instance.useStorageEmulator(host, storagePort);
  debugPrint('  ✓ Storage Emulator: $host:$storagePort');

  debugPrint('🔧 Firebase Emulator Suite connected!');
}
