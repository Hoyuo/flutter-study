# Flutter Observability 가이드 (통합)

> **난이도**: 시니어 | **카테고리**: system
> **선행 학습**: [ProductionOperations](./ProductionOperations.md) | **예상 학습 시간**: 2h

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Firebase Analytics로 사용자 행동 이벤트를 추적할 수 있다
> - 구조화된 로깅 시스템을 구축할 수 있다
> - Firebase Crashlytics로 크래시를 모니터링할 수 있다
> - Performance Monitoring으로 앱 성능을 추적할 수 있다
> - 알림 규칙을 설정하여 장애를 조기에 감지할 수 있다

## 1. 개요

Observability(가시성)는 시스템의 내부 상태를 외부에서 이해할 수 있는 능력입니다. 프로덕션 환경에서 앱의 안정성, 성능, 사용자 경험을 지속적으로 추적하고 개선하기 위해 필수적입니다.

### Observability의 3가지 기둥

| 기둥 | 설명 | 도구 |
|------|------|------|
| **Logging** | 개별 이벤트 기록 및 추적 | logger, Firebase Crashlytics |
| **Metrics** | 시스템 성능 수치화 | Firebase Performance, 커스텀 메트릭 |
| **Tracing** | 요청 흐름 추적 | Sentry, Correlation ID |

### 핵심 모니터링 메트릭

| 메트릭 | 설명 | 목표값 |
|--------|------|--------|
| **Crash-free users** | 크래시 없이 앱을 사용한 사용자 비율 | > 99.5% |
| **Crash-free sessions** | 크래시 없이 완료된 세션 비율 | > 99.9% |
| **ANR rate** | Application Not Responding 발생률 | < 0.1% |
| **Cold start time** | 앱 콜드 스타트 시간 | < 2초 |
| **API latency p95** | API 응답 시간 95퍼센타일 | < 500ms |
| **Error rate** | 전체 요청 대비 에러 비율 | < 1% |

---

## 2. 설치 및 Firebase 공통 설정

### 2.1 의존성 추가

```yaml
# pubspec.yaml (2026년 1월 기준)
dependencies:
  # Firebase 모니터링
  firebase_core: ^4.4.0
  firebase_analytics: ^12.1.1
  firebase_crashlytics: ^5.0.7
  firebase_performance: ^0.11.0

  # 로깅
  logger: ^2.5.0

  # Sentry (선택사항)
  sentry_flutter: ^8.12.0
  sentry_dio: ^8.12.0

  # 네트워크 & 유틸
  dio: ^5.9.0
  sqflite: ^2.3.0
  path_provider: ^2.1.0
  intl: ^0.19.0
  uuid: ^4.0.0
  injectable: ^2.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
```

**Firebase BoM (Bill of Materials) 호환성:**

Android에서 Firebase 라이브러리 버전 충돌을 방지하려면:

```gradle
// android/app/build.gradle
dependencies {
  // Firebase BoM (2026년 1월 기준)
  implementation platform('com.google.firebase:firebase-bom:33.7.0')
  implementation 'com.google.firebase:firebase-analytics-ktx'
  implementation 'com.google.firebase:firebase-crashlytics-ktx'
}
```

### 2.2 Android 설정

```kotlin
// android/app/build.gradle
android {
    buildTypes {
        release {
            // Crashlytics 매핑 파일 업로드
            firebaseCrashlytics {
                mappingFileUploadEnabled true
                nativeSymbolUploadEnabled true
            }
        }
    }
}
```

### 2.3 iOS 설정

Xcode에서:
1. Build Phases > New Run Script Phase
2. 스크립트 추가:

```bash
"${PODS_ROOT}/FirebaseCrashlytics/run"
```

### 2.4 Firebase 초기화 (main.dart)

```dart
// lib/main.dart
import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/monitoring/monitoring_initializer.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 1. Firebase 초기화
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Crashlytics 설정
      if (!kDebugMode) {
        // Flutter 프레임워크 에러 핸들링
        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        };

        // 비동기 에러 핸들링 (Zone 외부)
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(
            error,
            stack,
            fatal: true,
            reason: 'PlatformDispatcher.onError',
          );
          return true;
        };
      }

      // 3. 통합 모니터링 초기화
      await MonitoringInitializer.initialize(
        environment: const String.fromEnvironment('ENV', defaultValue: 'dev'),
        slackWebhookUrl: const String.fromEnvironment('SLACK_WEBHOOK'),
        metricsEndpoint: const String.fromEnvironment('METRICS_ENDPOINT'),
        metricsApiKey: const String.fromEnvironment('METRICS_API_KEY'),
      );

      runApp(const MyApp());
    },
    (error, stack) {
      // Zone 에러 캐치
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}
```

---

## 3. 구조화된 로깅

### 3.1 로그 레벨 정의

| 레벨 | 심각도 | 용도 | 릴리즈 모드 |
|------|--------|------|-----------|
| **Verbose** | 낮음 | 상세 추적 정보 | 비활성화 |
| **Debug** | 낮음 | 개발 정보 | 비활성화 |
| **Info** | 중간 | 중요한 정보 | 활성화 |
| **Warning** | 높음 | 경고 메시지 | 활성화 |
| **Error** | 매우 높음 | 에러 발생 | 활성화 |

### 3.2 커스텀 로거 클래스

```dart
// lib/core/logging/app_logger.dart
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 3,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceMillis,
    ),
    level: kDebugMode ? Level.trace : Level.warning,
  );

  AppLogger._();

  /// Verbose 레벨 로깅
  static void verbose(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      _logger.t(message, time: time, error: error, stackTrace: stackTrace);
    }
  }

  /// Debug 레벨 로깅
  static void debug(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      _logger.d(message, time: time, error: error, stackTrace: stackTrace);
    }
  }

  /// Info 레벨 로깅
  static void info(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.i(message, time: time, error: error, stackTrace: stackTrace);
  }

  /// Warning 레벨 로깅
  static void warning(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.w(message, time: time, error: error, stackTrace: stackTrace);
  }

  /// Error 레벨 로깅
  static void error(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(message, time: time, error: error, stackTrace: stackTrace);
  }

  /// 구조화된 로깅
  static void logStructured(
    String tag,
    String action,
    Map<String, dynamic> data, {
    Level level = Level.info,
  }) {
    final log = {
      'timestamp': DateTime.now().toIso8601String(),
      'tag': tag,
      'action': action,
      ...data,
    };
    _logger.log(level, log);
  }
}
```

### 3.3 BlocObserver 로깅

```dart
// lib/core/logging/app_bloc_observer.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_logger.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    AppLogger.debug('[Bloc Created] ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    AppLogger.logStructured(
      'Bloc.Event',
      bloc.runtimeType.toString(),
      {
        'event': event.runtimeType.toString(),
        'details': event.toString(),
      },
    );
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    AppLogger.logStructured(
      'Bloc.Change',
      bloc.runtimeType.toString(),
      {
        'previousState': change.currentState.runtimeType.toString(),
        'newState': change.nextState.runtimeType.toString(),
      },
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    AppLogger.error(
      '[Bloc Error] ${bloc.runtimeType}: $error',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    AppLogger.debug('[Bloc Closed] ${bloc.runtimeType}');
  }
}
```

### 3.4 네트워크 로깅 인터셉터

```dart
// lib/core/network/logging_interceptor.dart
import 'package:dio/dio.dart';
import '../logging/app_logger.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final url = options.uri.toString();

    options.extra['requestStartTime'] = DateTime.now().millisecondsSinceEpoch;

    final headers = Map<String, dynamic>.from(options.headers)
      ..removeWhere((key, value) => _isSensitiveHeader(key));

    AppLogger.logStructured(
      'Network.Request',
      method,
      {
        'url': url,
        'headers': headers,
        'body': _maskBody(options.data),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final method = response.requestOptions.method.toUpperCase();
    final url = response.requestOptions.uri.toString();
    final statusCode = response.statusCode ?? 0;

    final startTime = response.requestOptions.extra['requestStartTime'] as int?;
    final duration = startTime != null
        ? Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - startTime)
        : null;

    AppLogger.logStructured(
      'Network.Response',
      '$method $statusCode',
      {
        'url': url,
        'statusCode': statusCode,
        'duration_ms': duration?.inMilliseconds ?? 'N/A',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final method = err.requestOptions.method.toUpperCase();
    final url = err.requestOptions.uri.toString();

    AppLogger.error(
      '[Network Error] $method $url',
      error: err,
      stackTrace: err.stackTrace,
    );

    handler.next(err);
  }

  bool _isSensitiveHeader(String key) {
    final sensitiveHeaders = [
      'authorization',
      'token',
      'cookie',
      'x-api-key',
    ];
    return sensitiveHeaders.contains(key.toLowerCase());
  }

  String _maskBody(dynamic body) {
    if (body == null) return 'null';
    // 민감한 정보 마스킹 로직
    return body.toString();
  }
}
```

### 3.5 로그 레벨 관리

```dart
// lib/core/logging/log_config.dart
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class LogConfig {
  static Level getLogLevel() {
    if (kDebugMode) {
      return Level.trace;
    } else {
      return Level.info;
    }
  }

  /// 환경별 로깅 구성
  static Level getEnvironmentLogLevel(String environment) {
    return switch (environment) {
      'development' => Level.trace,
      'staging' => Level.debug,
      'production' => Level.warning,
      _ => Level.info,
    };
  }
}
```

---

## 4. Analytics 이벤트 추적

### 4.1 AnalyticsService 인터페이스

```dart
// lib/core/analytics/analytics_service.dart
abstract class AnalyticsService {
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  });

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });

  Future<void> setUserProperty({
    required String name,
    required String? value,
  });

  Future<void> setUserId(String? userId);

  Future<void> setDefaultEventParameters(Map<String, Object>? parameters);
}
```

### 4.2 Firebase Analytics 구현

```dart
// lib/core/analytics/firebase_analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';

import 'analytics_service.dart';

@LazySingleton(as: AnalyticsService)
class FirebaseAnalyticsService implements AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(
      name: name,
      value: value,
    );
  }

  @override
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  @override
  Future<void> setDefaultEventParameters(
    Map<String, Object>? parameters,
  ) async {
    await _analytics.setDefaultEventParameters(parameters);
  }
}
```

### 4.3 이벤트 상수 정의

```dart
// lib/core/analytics/analytics_events.dart
abstract class AnalyticsEvents {
  // 인증
  static const login = 'login';
  static const logout = 'logout';
  static const signUp = 'sign_up';

  // 상품
  static const viewProduct = 'view_product';
  static const addToCart = 'add_to_cart';
  static const purchase = 'purchase';

  // 검색
  static const search = 'search';

  // 커스텀
  static const buttonClick = 'button_click';
  static const errorOccurred = 'error_occurred';
}

abstract class AnalyticsParams {
  static const screenName = 'screen_name';
  static const buttonName = 'button_name';
  static const itemId = 'item_id';
  static const itemName = 'item_name';
  static const price = 'price';
  static const currency = 'currency';
  static const errorMessage = 'error_message';
}
```

### 4.4 Analytics Logger 래퍼

```dart
// lib/core/analytics/analytics_logger.dart
import 'package:injectable/injectable.dart';

import 'analytics_events.dart';
import 'analytics_service.dart';

@lazySingleton
class AnalyticsLogger {
  final AnalyticsService _analyticsService;

  AnalyticsLogger(this._analyticsService);

  Future<void> logLogin(String method) async {
    await _analyticsService.logEvent(
      name: AnalyticsEvents.login,
      parameters: {'method': method},
    );
  }

  Future<void> logSignUp(String method) async {
    await _analyticsService.logEvent(
      name: AnalyticsEvents.signUp,
      parameters: {'method': method},
    );
  }

  Future<void> logViewProduct({
    required String productId,
    required String productName,
    required double price,
    required String currency,
  }) async {
    await _analyticsService.logEvent(
      name: AnalyticsEvents.viewProduct,
      parameters: {
        AnalyticsParams.itemId: productId,
        AnalyticsParams.itemName: productName,
        AnalyticsParams.price: price,
        AnalyticsParams.currency: currency,
      },
    );
  }

  Future<void> logButtonClick({
    required String buttonName,
    required String screenName,
  }) async {
    await _analyticsService.logEvent(
      name: AnalyticsEvents.buttonClick,
      parameters: {
        AnalyticsParams.buttonName: buttonName,
        AnalyticsParams.screenName: screenName,
      },
    );
  }
}
```

### 4.5 GoRouter 통합

```dart
// lib/core/router/app_router.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  observers: [
    FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
  ],
  routes: [...],
);
```

### 4.6 GDPR 동의 관리

```dart
// lib/core/consent/consent_service.dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class ConsentService {
  static const _keyAnalyticsConsent = 'analytics_consent';
  static const _keyCrashlyticsConsent = 'crashlytics_consent';

  final SharedPreferences _prefs;

  ConsentService(this._prefs);

  bool get hasAnalyticsConsent {
    return _prefs.getBool(_keyAnalyticsConsent) ?? false;
  }

  bool get hasCrashlyticsConsent {
    return _prefs.getBool(_keyCrashlyticsConsent) ?? false;
  }

  Future<void> setAnalyticsConsent(bool consent) async {
    await _prefs.setBool(_keyAnalyticsConsent, consent);
  }

  Future<void> setCrashlyticsConsent(bool consent) async {
    await _prefs.setBool(_keyCrashlyticsConsent, consent);
  }

  bool get isFirstLaunch {
    return !_prefs.containsKey(_keyAnalyticsConsent);
  }
}
```

```dart
// lib/core/consent/consent_manager.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:injectable/injectable.dart';

import '../analytics/analytics_service.dart';
import 'consent_service.dart';

@lazySingleton
class ConsentManager {
  final ConsentService _consentService;
  final AnalyticsService _analyticsService;

  ConsentManager(this._consentService, this._analyticsService);

  Future<void> applyConsent() async {
    final hasAnalyticsConsent = _consentService.hasAnalyticsConsent;
    final hasCrashlyticsConsent = _consentService.hasCrashlyticsConsent;

    await FirebaseAnalytics.instance
        .setAnalyticsCollectionEnabled(hasAnalyticsConsent);

    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(hasCrashlyticsConsent);
  }

  Future<void> grantConsent({
    required bool analytics,
    required bool crashlytics,
  }) async {
    await _consentService.setAnalyticsConsent(analytics);
    await _consentService.setCrashlyticsConsent(crashlytics);
    await applyConsent();
  }
}
```

### 4.7 Firebase Analytics 제한사항

| 제한 항목 | 값 | 초과 시 |
|----------|---|--------|
| 이벤트 파라미터 개수 | 25개 | 초과 파라미터 무시 |
| 이벤트 이름 길이 | 40자 | 이벤트 기록 안됨 |
| 파라미터 값 (문자열) | 100자 | 잘림 처리 |
| 사용자 속성 개수 | 25개 | 초과 속성 무시 |

---

## 5. 앱 모니터링

### 5.1 Crashlytics 서비스

```dart
// lib/core/monitoring/crashlytics_service.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  Future<void> setUserIdentifier(String userId) async {
    if (kDebugMode) return;
    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> setCustomKey(String key, Object value) async {
    if (kDebugMode) return;
    await _crashlytics.setCustomKey(key, value);
  }

  Future<void> setUserContext({
    required String userId,
    String? email,
    String? subscriptionType,
    String? appVersion,
  }) async {
    if (kDebugMode) return;

    await setUserIdentifier(userId);
    await _crashlytics.setCustomKey('subscription', subscriptionType ?? 'free');
    await _crashlytics.setCustomKey('app_version', appVersion ?? 'unknown');
  }

  void log(String message) {
    if (kDebugMode) {
      debugPrint('[Crashlytics] $message');
      return;
    }
    _crashlytics.log(message);
  }

  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? information,
  }) async {
    if (kDebugMode) {
      debugPrint('[Crashlytics Error] $error');
      return;
    }

    if (information != null) {
      for (final entry in information.entries) {
        await _crashlytics.setCustomKey(
          'error_${entry.key}',
          entry.value.toString(),
        );
      }
    }

    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }
}
```

### 5.2 Sentry 통합

```dart
// lib/main.dart (Sentry 초기화)
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.environment = const String.fromEnvironment('ENV', defaultValue: 'dev');
      options.tracesSampleRate = 0.2;
      options.profilesSampleRate = 0.1;

      options.beforeSend = (event, {hint}) {
        // 민감 정보 필터링
        if (event.user != null) {
          event = event.copyWith(
            user: event.user?.copyWith(
              ipAddress: null,
            ),
          );
        }
        return event;
      };
    },
    appRunner: () => runApp(const MyApp()),
  );
}
```

### 5.3 Firebase Performance Monitoring

```dart
// lib/core/monitoring/performance_service.dart
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final FirebasePerformance _performance = FirebasePerformance.instance;

  Trace newTrace(String name) {
    return _performance.newTrace(name);
  }

  HttpMetric newHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }
}
```

```dart
// lib/core/monitoring/trace_manager.dart
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class TraceManager {
  final PerformanceService _performanceService;
  final Map<String, Trace> _activeTraces = {};

  TraceManager({PerformanceService? performanceService})
      : _performanceService = performanceService ?? PerformanceService();

  Future<void> startTrace(String name) async {
    if (kDebugMode) return;

    if (_activeTraces.containsKey(name)) return;

    final trace = _performanceService.newTrace(name);
    await trace.start();
    _activeTraces[name] = trace;
  }

  Future<void> stopTrace(String name, {Map<String, int>? metrics}) async {
    if (kDebugMode) return;

    final trace = _activeTraces.remove(name);
    if (trace == null) return;

    if (metrics != null) {
      for (final entry in metrics.entries) {
        trace.setMetric(entry.key, entry.value);
      }
    }

    await trace.stop();
  }

  Future<T> measureAsync<T>(
    String name,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    if (kDebugMode) {
      return operation();
    }

    final trace = _performanceService.newTrace(name);

    if (attributes != null) {
      for (final entry in attributes.entries) {
        trace.putAttribute(entry.key, entry.value);
      }
    }

    await trace.start();
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      trace.setMetric('success', 1);
      return result;
    } catch (e) {
      trace.setMetric('success', 0);
      trace.putAttribute('error', e.runtimeType.toString());
      rethrow;
    } finally {
      stopwatch.stop();
      trace.setMetric('duration_ms', stopwatch.elapsedMilliseconds);
      await trace.stop();
    }
  }
}
```

### 5.4 HTTP 성능 자동 수집

```dart
// lib/core/network/performance_interceptor.dart
import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class PerformanceInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      handler.next(options);
      return;
    }

    final httpMethod = _getHttpMethod(options.method);
    final metric = FirebasePerformance.instance.newHttpMetric(
      options.uri.toString(),
      httpMethod,
    );

    metric.start();
    options.extra['firebase_metric'] = metric;

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final metric = response.requestOptions.extra['firebase_metric'] as HttpMetric?;
    if (metric != null) {
      metric.httpResponseCode = response.statusCode;
      metric.responsePayloadSize = response.data?.toString().length ?? 0;
      metric.stop();
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final metric = err.requestOptions.extra['firebase_metric'] as HttpMetric?;
    if (metric != null) {
      metric.httpResponseCode = err.response?.statusCode;
      metric.stop();
    }

    handler.next(err);
  }

  HttpMethod _getHttpMethod(String method) {
    return switch (method.toUpperCase()) {
      'GET' => HttpMethod.Get,
      'POST' => HttpMethod.Post,
      'PUT' => HttpMethod.Put,
      'DELETE' => HttpMethod.Delete,
      'PATCH' => HttpMethod.Patch,
      _ => HttpMethod.Get,
    };
  }
}
```

### 5.5 메트릭 수집

```dart
// lib/core/monitoring/metrics_collector.dart
import 'dart:async';

class MetricsCollector {
  static final MetricsCollector _instance = MetricsCollector._internal();
  factory MetricsCollector() => _instance;
  MetricsCollector._internal();

  final Map<String, List<double>> _metrics = {};
  final Map<String, int> _counters = {};

  void recordValue(String name, double value) {
    _metrics.putIfAbsent(name, () => []);
    _metrics[name]!.add(value);

    if (_metrics[name]!.length > 1000) {
      _metrics[name]!.removeAt(0);
    }
  }

  void incrementCounter(String name, [int delta = 1]) {
    _counters[name] = (_counters[name] ?? 0) + delta;
  }

  Map<String, dynamic> getSnapshot() {
    final snapshot = <String, dynamic>{};

    for (final entry in _metrics.entries) {
      if (entry.value.isEmpty) continue;

      final sorted = List<double>.from(entry.value)..sort();
      final sum = sorted.reduce((a, b) => a + b);

      snapshot['${entry.key}_avg'] = sum / sorted.length;
      snapshot['${entry.key}_min'] = sorted.first;
      snapshot['${entry.key}_max'] = sorted.last;
      snapshot['${entry.key}_p95'] = _percentile(sorted, 95);
    }

    for (final entry in _counters.entries) {
      snapshot['${entry.key}_total'] = entry.value;
    }

    return snapshot;
  }

  double _percentile(List<double> sorted, int percentile) {
    if (sorted.isEmpty) return 0;
    final index = ((percentile / 100) * sorted.length).floor();
    return sorted[index.clamp(0, sorted.length - 1)];
  }
}
```

### 5.6 알림 설정

```dart
// lib/core/monitoring/alert_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum AlertSeverity {
  info,
  warning,
  error,
  critical,
}

class AlertService {
  final Dio _dio;
  final String? _slackWebhookUrl;

  AlertService({
    Dio? dio,
    String? slackWebhookUrl,
  })  : _dio = dio ?? Dio(),
        _slackWebhookUrl = slackWebhookUrl;

  Future<void> sendAlert({
    required String title,
    required String message,
    required AlertSeverity severity,
    Map<String, dynamic>? metadata,
  }) async {
    if (kDebugMode) {
      debugPrint('[Alert] [$severity] $title: $message');
      return;
    }

    switch (severity) {
      case AlertSeverity.critical:
      case AlertSeverity.error:
        await _sendToSlack(title, message, severity, metadata);
      case AlertSeverity.warning:
      case AlertSeverity.info:
        await _sendToSlack(title, message, severity, metadata);
    }
  }

  Future<void> _sendToSlack(
    String title,
    String message,
    AlertSeverity severity,
    Map<String, dynamic>? metadata,
  ) async {
    if (_slackWebhookUrl == null) return;

    final color = switch (severity) {
      AlertSeverity.info => '#36a64f',
      AlertSeverity.warning => '#ffcc00',
      AlertSeverity.error => '#ff6600',
      AlertSeverity.critical => '#ff0000',
    };

    try {
      await _dio.post(
        _slackWebhookUrl!,
        data: {
          'attachments': [
            {
              'color': color,
              'title': '[$severity] $title',
              'text': message,
              'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            }
          ],
        },
      );
    } catch (e) {
      debugPrint('[AlertService] Failed: $e');
    }
  }
}
```

### 5.7 임계값 모니터링

```dart
// lib/core/monitoring/threshold_monitor.dart
import 'dart:async';
import 'alert_service.dart';
import 'metrics_collector.dart';

class ThresholdConfig {
  final String metricName;
  final double warningThreshold;
  final double criticalThreshold;
  final bool isUpperBound;

  const ThresholdConfig({
    required this.metricName,
    required this.warningThreshold,
    required this.criticalThreshold,
    this.isUpperBound = true,
  });
}

class ThresholdMonitor {
  final MetricsCollector _metricsCollector;
  final AlertService _alertService;
  final List<ThresholdConfig> _thresholds;

  Timer? _checkTimer;
  final Set<String> _activeAlerts = {};

  ThresholdMonitor({
    required MetricsCollector metricsCollector,
    required AlertService alertService,
    required List<ThresholdConfig> thresholds,
  })  : _metricsCollector = metricsCollector,
        _alertService = alertService,
        _thresholds = thresholds;

  static List<ThresholdConfig> get defaultThresholds => [
    const ThresholdConfig(
      metricName: 'api_error_rate',
      warningThreshold: 1.0,
      criticalThreshold: 5.0,
    ),
    const ThresholdConfig(
      metricName: 'api_latency_p95',
      warningThreshold: 500,
      criticalThreshold: 1000,
    ),
  ];

  void start({Duration interval = const Duration(minutes: 1)}) {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(interval, (_) => _checkThresholds());
  }

  void stop() {
    _checkTimer?.cancel();
  }

  void _checkThresholds() {
    final snapshot = _metricsCollector.getSnapshot();

    for (final config in _thresholds) {
      final value = snapshot[config.metricName];
      if (value == null || value is! num) continue;

      final severity = _checkSeverity(value.toDouble(), config);
      final alertKey = config.metricName;

      if (severity != null && !_activeAlerts.contains(alertKey)) {
        _activeAlerts.add(alertKey);
        _alertService.sendAlert(
          title: '${config.metricName} 임계값 초과',
          message: '현재 값: $value (임계값: ${config.criticalThreshold})',
          severity: severity,
          metadata: {'metric': config.metricName, 'value': value},
        );
      } else if (severity == null && _activeAlerts.contains(alertKey)) {
        _activeAlerts.remove(alertKey);
      }
    }
  }

  AlertSeverity? _checkSeverity(double value, ThresholdConfig config) {
    if (config.isUpperBound) {
      if (value >= config.criticalThreshold) return AlertSeverity.critical;
      if (value >= config.warningThreshold) return AlertSeverity.warning;
    }
    return null;
  }
}
```

---

## 6. Crashlytics 에러 리포팅

### 6.1 Bloc 에러 통합

```dart
// lib/core/monitoring/monitored_bloc_observer.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'crashlytics_service.dart';

class MonitoredBlocObserver extends BlocObserver {
  final CrashlyticsService _crashlytics;

  MonitoredBlocObserver({CrashlyticsService? crashlytics})
      : _crashlytics = crashlytics ?? CrashlyticsService();

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _crashlytics.log('Event: ${bloc.runtimeType} <- ${event.runtimeType}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);

    _crashlytics.recordError(
      error,
      stackTrace,
      reason: 'Bloc error in ${bloc.runtimeType}',
      information: {
        'bloc_type': bloc.runtimeType.toString(),
        'state_type': bloc.state.runtimeType.toString(),
      },
    );
  }
}
```

### 6.2 사용자 이벤트 추적

```dart
// lib/core/monitoring/user_event_tracker.dart
import 'crashlytics_service.dart';

enum UserAction {
  login,
  logout,
  purchase,
  search,
}

class UserEventTracker {
  final CrashlyticsService _crashlytics;

  UserEventTracker({CrashlyticsService? crashlytics})
      : _crashlytics = crashlytics ?? CrashlyticsService();

  void trackAction(UserAction action, {Map<String, dynamic>? params}) {
    final message = 'Action: ${action.name.toUpperCase()}';
    _crashlytics.log(message);
  }

  void trackScreenView(String screenName) {
    _crashlytics.log('Screen: $screenName');
  }

  void trackApiCall(String endpoint, {int? statusCode}) {
    final status = statusCode != null ? ' [$statusCode]' : '';
    _crashlytics.log('API: $endpoint$status');
  }
}
```

---

## 7. 실전 통합 패턴

### 7.1 통합 모니터링 초기화

```dart
// lib/core/monitoring/monitoring_initializer.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'alert_service.dart';
import 'crashlytics_service.dart';
import 'metrics_collector.dart';
import 'monitored_bloc_observer.dart';
import 'threshold_monitor.dart';

class MonitoringInitializer {
  static Future<void> initialize({
    required String environment,
    String? slackWebhookUrl,
    String? metricsEndpoint,
    String? metricsApiKey,
  }) async {
    // Bloc Observer 설정
    Bloc.observer = MonitoredBlocObserver();

    // 메트릭 수집기 초기화
    final metricsCollector = MetricsCollector();

    // 알림 서비스
    final alertService = AlertService(
      slackWebhookUrl: slackWebhookUrl,
    );

    // 임계값 모니터
    if (!kDebugMode) {
      final thresholdMonitor = ThresholdMonitor(
        metricsCollector: metricsCollector,
        alertService: alertService,
        thresholds: ThresholdMonitor.defaultThresholds,
      );
      thresholdMonitor.start();
    }

    // 환경 태그 설정
    await CrashlyticsService().setCustomKey('environment', environment);
  }
}
```

### 7.2 Repository 패턴 통합

```dart
// lib/features/product/data/datasources/product_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/trace_manager.dart';

class ProductRemoteDataSource {
  final Dio _dio;
  final TraceManager _traceManager = TraceManager();

  ProductRemoteDataSource(this._dio);

  Future<List<ProductDto>> getProducts() async {
    return await _traceManager.measureAsync(
      'getProducts',
      () async {
        try {
          AppLogger.info('[ProductRemoteDataSource] Fetching products...');

          final response = await _dio.get('/api/products');

          if (response.statusCode == 200) {
            final products = (response.data as List)
                .map((item) => ProductDto.fromJson(item))
                .toList();

            AppLogger.logStructured(
              'Product.Fetch',
              'success',
              {'count': products.length},
            );

            return products;
          } else {
            throw Exception('Failed to load products');
          }
        } catch (e, stackTrace) {
          AppLogger.error(
            '[ProductRemoteDataSource] Failed',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      },
    );
  }
}
```

### 7.3 Distributed Tracing

```dart
// lib/core/network/correlation_interceptor.dart
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../logging/app_logger.dart';

class CorrelationInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final correlationId = const Uuid().v4();
    options.headers['X-Correlation-ID'] = correlationId;

    AppLogger.logStructured(
      'API',
      'Request',
      {
        'correlationId': correlationId,
        'method': options.method,
        'path': options.path,
      },
    );

    handler.next(options);
  }
}
```

---

## 8. 체크리스트

### 로깅

- [ ] AppLogger 구현 및 로그 레벨 설정
- [ ] BlocObserver 등록
- [ ] LoggingInterceptor 등록
- [ ] 민감 정보 마스킹 확인
- [ ] 프로덕션 로그 레벨 설정

### Analytics

- [ ] Firebase Analytics 초기화
- [ ] AnalyticsService 인터페이스 구현
- [ ] 이벤트 상수 정의
- [ ] GoRouter에 FirebaseAnalyticsObserver 연결
- [ ] GDPR 동의 관리 구현
- [ ] 사용자 속성 설정

### Crashlytics

- [ ] Firebase Crashlytics 초기화
- [ ] FlutterError.onError 핸들러 설정
- [ ] PlatformDispatcher.instance.onError 핸들러 설정
- [ ] 사용자 식별자 설정
- [ ] 커스텀 키 설정
- [ ] 브레드크럼 로깅

### Performance

- [ ] Firebase Performance 초기화
- [ ] 커스텀 트레이스 추가
- [ ] HTTP 메트릭 자동 수집
- [ ] 화면 렌더링 성능 측정

### 알림

- [ ] AlertService 구현
- [ ] 임계값 설정
- [ ] Slack/PagerDuty 연동
- [ ] 알림 에스컬레이션 정책 수립

### 운영

- [ ] 일일 크래시 리포트 리뷰
- [ ] 주간 성능 메트릭 분석
- [ ] 월간 SLA 준수 여부 확인
- [ ] DebugView로 이벤트 확인

---

## Best Practices

### 모니터링 원칙

| 원칙 | 설명 |
|------|------|
| **민감 정보 보호** | PII를 로그나 크래시 리포트에 포함하지 않음 |
| **샘플링 적용** | 프로덕션에서는 성능 트레이스를 10-20%만 수집 |
| **환경 분리** | dev/staging/production 환경별 데이터 분리 |
| **비용 관리** | 불필요한 이벤트 전송 최소화 |
| **신속한 대응** | Critical 알림은 즉시 대응 체계 구축 |

### 안티패턴

```dart
// ❌ 문제: 민감 정보 로깅
AppLogger.info('User password: $password');
crashlytics.setCustomKey('credit_card', cardNumber);

// ✅ 해결: 민감 정보 제외
AppLogger.info('User authenticated');
crashlytics.setCustomKey('payment_method', 'credit_card');

// ❌ 문제: 과도한 이벤트 전송
for (final item in items) {
  analytics.logEvent('item_viewed', {'id': item.id});
}

// ✅ 해결: 배치 처리
analytics.logEvent('items_viewed', {'count': items.length});

// ❌ 문제: 프로덕션에서 100% 샘플링
options.tracesSampleRate = 1.0;

// ✅ 해결: 적절한 샘플링
options.tracesSampleRate = 0.2; // 20%
```

---

## 트러블슈팅

### Crashlytics 데이터가 보이지 않는 경우

```dart
// 1. Firebase 프로젝트 설정 확인
// 2. google-services.json / GoogleService-Info.plist 확인
// 3. 개발 모드에서는 기본적으로 비활성화됨
// 4. 실제 디바이스에서 테스트

// 테스트 크래시 발생
if (kDebugMode) {
  FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
}
FirebaseCrashlytics.instance.crash();
```

### Analytics 이벤트가 전송되지 않는 경우

```dart
// DebugView 활성화
// Android: adb shell setprop debug.firebase.analytics.app com.example.app
// iOS: -FIRAnalyticsDebugEnabled 런타임 인수 추가

// Firebase Console > DebugView에서 실시간 확인
```

### 성능 데이터가 부정확한 경우

```bash
# 릴리즈 모드로 빌드
flutter build apk --release
flutter run --release

# 디버그 모드는 느리므로 프로파일/릴리즈 모드에서 측정
```

---

## 참고자료

- [Firebase Analytics 문서](https://firebase.google.com/docs/analytics)
- [Firebase Crashlytics 문서](https://firebase.google.com/docs/crashlytics)
- [Firebase Performance Monitoring](https://firebase.google.com/docs/perf-mon)
- [Logger 패키지](https://pub.dev/packages/logger)
- [Sentry Flutter SDK](https://docs.sentry.io/platforms/flutter/)

---

## 실습 과제

### 과제 1: 통합 Observability 시스템 구축

Firebase Analytics, Crashlytics, Performance Monitoring을 모두 통합하고, 사용자 행동 추적, 에러 리포팅, 성능 측정을 구현하세요.

### 과제 2: 알림 기반 모니터링

임계값 기반 알림 시스템을 구현하고, API 에러율이 5%를 초과하면 Slack으로 알림을 보내도록 설정하세요.

### 과제 3: GDPR 준수 시스템

사용자 동의 관리 시스템을 구현하고, 동의 철회 시 사용자 데이터를 완전히 삭제하는 기능을 추가하세요.

---

## Self-Check

- [ ] Firebase Analytics를 초기화하고 커스텀 이벤트를 로깅할 수 있다
- [ ] 구조화된 로깅 시스템을 구축했다
- [ ] BlocObserver로 상태 변화를 추적하고 있다
- [ ] Crashlytics로 크래시와 비정상 종료를 모니터링할 수 있다
- [ ] Performance Monitoring으로 앱 성능을 측정하고 있다
- [ ] Debug/Release 모드별 로깅 설정을 분리했다
- [ ] 민감 정보를 로그에서 제외했다
- [ ] 알림 시스템이 정상 작동하는가
- [ ] Crash-free rate 목표(99.5%+)를 설정했다
- [ ] 분석 대시보드에서 주요 지표를 확인하고 해석할 수 있다
