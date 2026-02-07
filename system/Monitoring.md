# Flutter 앱 모니터링 가이드

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Firebase Crashlytics로 크래시를 모니터링할 수 있다
> - Performance Monitoring으로 앱 성능을 추적할 수 있다
> - 알림 규칙을 설정하여 장애를 조기에 감지할 수 있다

## 개요

프로덕션 환경에서 앱의 안정성과 성능을 지속적으로 추적하고 개선하기 위해서는 체계적인 모니터링 전략이 필수입니다. 이 가이드는 크래시 리포팅, 성능 모니터링, 에러 트래킹, 사용자 분석, 알림 설정을 포함한 완벽한 모니터링 시스템 구축 방법을 다룹니다.

### 모니터링의 핵심 목표

| 목표 | 설명 |
|------|------|
| **안정성 확보** | 크래시 감지 및 신속한 대응으로 앱 안정성 유지 |
| **성능 최적화** | 병목 지점 파악 및 사용자 경험 개선 |
| **문제 조기 발견** | 에러 패턴 분석으로 잠재적 문제 사전 예방 |
| **데이터 기반 의사결정** | 실시간 메트릭으로 제품 개선 방향 설정 |
| **SLA 준수** | 서비스 수준 목표 달성 여부 추적 |

### 핵심 모니터링 메트릭

| 메트릭 | 설명 | 목표값 |
|--------|------|--------|
| **Crash-free users** | 크래시 없이 앱을 사용한 사용자 비율 | > 99.5% |
| **Crash-free sessions** | 크래시 없이 완료된 세션 비율 | > 99.9% |
| **ANR rate** | Application Not Responding 발생률 | < 0.1% |
| **Cold start time** | 앱 콜드 스타트 시간 | < 2초 |
| **Warm start time** | 앱 웜 스타트 시간 | < 1초 |
| **API latency p50** | API 응답 시간 중앙값 | < 200ms |
| **API latency p95** | API 응답 시간 95퍼센타일 | < 500ms |
| **API latency p99** | API 응답 시간 99퍼센타일 | < 1초 |
| **Error rate** | 전체 요청 대비 에러 비율 | < 1% |
| **Memory usage** | 평균 메모리 사용량 | < 150MB |

---

## Setup

### 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  # Firebase 모니터링
  firebase_core: ^3.8.1
  firebase_crashlytics: ^4.2.1
  firebase_performance: ^0.10.1
  firebase_analytics: ^11.4.1

  # Sentry 모니터링
  sentry_flutter: ^8.12.0
  sentry_dio: ^8.12.0

  # 네트워크 모니터링
  dio: ^5.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

### 패키지 설치

```bash
fvm flutter pub get
```

---

## Firebase Crashlytics

Firebase Crashlytics는 실시간 크래시 리포팅 도구로, 앱의 안정성 문제를 추적하고 우선순위를 지정하며 해결하는 데 도움을 줍니다.

### 1. Firebase 프로젝트 설정

```dart
// lib/main.dart
import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  // 1. Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Crashlytics 설정
  await _initializeCrashlytics();

  // 4. 앱 실행
  runApp(const MyApp());
}

Future<void> _initializeCrashlytics() async {
  // 디버그 모드에서는 Crashlytics 비활성화 (선택사항)
  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    return;
  }

  // 프로덕션 모드에서 활성화
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  // Flutter 프레임워크 에러 핸들링
  FlutterError.onError = (FlutterErrorDetails details) {
    // 콘솔에 에러 출력
    FlutterError.presentError(details);

    // Crashlytics에 치명적 에러로 기록
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
```

### 2. Crashlytics 서비스 클래스

```dart
// lib/core/monitoring/crashlytics_service.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();

  factory CrashlyticsService() => _instance;

  CrashlyticsService._internal();

  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  /// 사용자 정보 설정
  Future<void> setUserIdentifier(String userId) async {
    if (kDebugMode) return;

    await _crashlytics.setUserIdentifier(userId);
    _log('User ID set: $userId');
  }

  /// 사용자 정보 초기화 (로그아웃 시)
  Future<void> clearUserIdentifier() async {
    if (kDebugMode) return;

    await _crashlytics.setUserIdentifier('');
    _log('User ID cleared');
  }

  /// 커스텀 키-값 쌍 설정
  Future<void> setCustomKey(String key, Object value) async {
    if (kDebugMode) return;

    await _crashlytics.setCustomKey(key, value);
  }

  /// 여러 커스텀 키 한번에 설정
  Future<void> setCustomKeys(Map<String, Object> keys) async {
    if (kDebugMode) return;

    for (final entry in keys.entries) {
      await _crashlytics.setCustomKey(entry.key, entry.value);
    }
  }

  /// 사용자 컨텍스트 설정 (로그인 후 호출)
  Future<void> setUserContext({
    required String userId,
    String? email,
    String? subscriptionType,
    String? appVersion,
  }) async {
    if (kDebugMode) return;

    await setUserIdentifier(userId);

    await setCustomKeys({
      if (email != null) 'email': _maskEmail(email),
      if (subscriptionType != null) 'subscription': subscriptionType,
      if (appVersion != null) 'app_version': appVersion,
      'login_time': DateTime.now().toIso8601String(),
    });
  }

  /// 브레드크럼 로그 추가
  void log(String message) {
    if (kDebugMode) {
      debugPrint('[Crashlytics] $message');
      return;
    }

    _crashlytics.log(message);
  }

  /// 비치명적 에러 기록
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? information,
  }) async {
    if (kDebugMode) {
      debugPrint('[Crashlytics Error] $error');
      debugPrint('[Stack Trace] $stackTrace');
      return;
    }

    // 추가 정보가 있으면 커스텀 키로 설정
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

  /// Flutter 에러 기록
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (kDebugMode) {
      FlutterError.presentError(details);
      return;
    }

    await _crashlytics.recordFlutterError(details);
  }

  /// 강제 크래시 테스트 (개발 전용)
  void testCrash() {
    if (!kDebugMode) {
      throw StateError('testCrash should only be called in debug mode');
    }
    _crashlytics.crash();
  }

  /// 이메일 마스킹
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***';
    final name = parts[0];
    final domain = parts[1];
    final maskedName = name.length > 2
        ? '${name[0]}***${name[name.length - 1]}'
        : '***';
    return '$maskedName@$domain';
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[CrashlyticsService] $message');
    }
  }
}
```

### 3. 사용자 이벤트 추적

```dart
// lib/core/monitoring/user_event_tracker.dart
import 'crashlytics_service.dart';

enum UserAction {
  login,
  logout,
  purchase,
  addToCart,
  checkout,
  search,
  viewProduct,
  share,
  favorite,
}

class UserEventTracker {
  final CrashlyticsService _crashlytics;

  UserEventTracker({CrashlyticsService? crashlytics})
      : _crashlytics = crashlytics ?? CrashlyticsService();

  /// 사용자 액션 추적 (브레드크럼)
  void trackAction(UserAction action, {Map<String, dynamic>? params}) {
    final message = _buildActionMessage(action, params);
    _crashlytics.log(message);
  }

  /// 화면 진입 추적
  void trackScreenView(String screenName, {String? screenClass}) {
    _crashlytics.log('Screen: $screenName${screenClass != null ? ' ($screenClass)' : ''}');
  }

  /// 버튼 클릭 추적
  void trackButtonTap(String buttonName, {String? screen}) {
    _crashlytics.log('Tap: $buttonName${screen != null ? ' on $screen' : ''}');
  }

  /// API 호출 추적
  void trackApiCall(String endpoint, {String? method, int? statusCode}) {
    final status = statusCode != null ? ' [$statusCode]' : '';
    _crashlytics.log('API ${method ?? 'GET'}: $endpoint$status');
  }

  /// 에러 컨텍스트 추적
  void trackErrorContext(String context, {Map<String, dynamic>? details}) {
    final detailsStr = details != null
        ? ' - ${details.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'
        : '';
    _crashlytics.log('Error Context: $context$detailsStr');
  }

  String _buildActionMessage(UserAction action, Map<String, dynamic>? params) {
    final actionName = action.name.toUpperCase();
    if (params == null || params.isEmpty) {
      return 'Action: $actionName';
    }
    final paramsStr = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
    return 'Action: $actionName ($paramsStr)';
  }
}
```

### 4. Bloc 에러 통합

```dart
// lib/core/monitoring/monitored_bloc_observer.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'crashlytics_service.dart';

class MonitoredBlocObserver extends BlocObserver {
  final CrashlyticsService _crashlytics;

  MonitoredBlocObserver({CrashlyticsService? crashlytics})
      : _crashlytics = crashlytics ?? CrashlyticsService();

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _crashlytics.log('Bloc created: ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _crashlytics.log('Event: ${bloc.runtimeType} <- ${event.runtimeType}');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _crashlytics.log(
      'Transition: ${bloc.runtimeType} '
      '${transition.currentState.runtimeType} -> ${transition.nextState.runtimeType}',
    );
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

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _crashlytics.log('Bloc closed: ${bloc.runtimeType}');
  }
}

// main.dart에서 설정
void main() async {
  // ... Firebase 초기화 ...

  Bloc.observer = MonitoredBlocObserver();

  runApp(const MyApp());
}
```

---

## Sentry 통합

Sentry는 더 상세한 에러 트래킹과 성능 모니터링을 제공합니다. Firebase Crashlytics와 함께 사용하거나 대안으로 사용할 수 있습니다.

### 1. Sentry 초기화

```dart
// lib/main.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      // DSN 설정
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: 'https://key@sentry.io/project',
      );

      // 환경 설정
      options.environment = const String.fromEnvironment(
        'ENV',
        defaultValue: 'development',
      );

      // 릴리즈 버전
      options.release = const String.fromEnvironment(
        'APP_VERSION',
        defaultValue: '1.0.0',
      );

      // 성능 샘플링 (20%)
      options.tracesSampleRate = 0.2;

      // 프로파일링 샘플링 (10%)
      options.profilesSampleRate = 0.1;

      // 세션 리플레이 (선택사항)
      options.experimental.replay.sessionSampleRate = 0.1;
      options.experimental.replay.onErrorSampleRate = 1.0;

      // 디버그 모드 설정
      options.debug = false;

      // 민감 정보 필터링
      options.beforeSend = _filterSensitiveData;

      // 브레드크럼 필터링
      options.beforeBreadcrumb = _filterBreadcrumb;

      // 자동 세션 추적
      options.autoSessionTrackingInterval = const Duration(milliseconds: 30000);

> ⚠️ **주의:** `anrEnabled`, `anrTimeoutInterval` 속성명은 Sentry SDK 버전에 따라 다를 수 있습니다. 최신 `sentry_flutter` 문서를 확인하세요.

      // 앱 행 감지
      options.anrEnabled = true;
      options.anrTimeoutInterval = const Duration(seconds: 5);
    },
    appRunner: () => runApp(
      SentryWidget(
        child: const MyApp(),
      ),
    ),
  );
}

/// 민감 정보 필터링
FutureOr<SentryEvent?> _filterSensitiveData(
  SentryEvent event, {
  Hint? hint,
}) {
  // 특정 에러 무시
  if (event.throwable is SocketException) {
    return null; // 네트워크 에러는 무시
  }

  // 사용자 데이터 익명화
  if (event.user != null) {
    event = event.copyWith(
      user: event.user?.copyWith(
        email: _maskEmail(event.user?.email),
        ipAddress: null, // IP 주소 제거
      ),
    );
  }

  // 민감한 태그 제거
  final tags = Map<String, String>.from(event.tags ?? {});
  tags.remove('auth_token');
  tags.remove('session_id');

  return event.copyWith(tags: tags);
}

/// 브레드크럼 필터링
Breadcrumb? _filterBreadcrumb(Breadcrumb? breadcrumb, {Hint? hint}) {
  if (breadcrumb == null) return null;

  // HTTP 요청에서 Authorization 헤더 제거
  if (breadcrumb.category == 'http') {
    final data = Map<String, dynamic>.from(breadcrumb.data ?? {});
    if (data.containsKey('headers')) {
      final headers = Map<String, dynamic>.from(data['headers'] as Map);
      headers.remove('Authorization');
      headers.remove('Cookie');
      data['headers'] = headers;
    }
    return breadcrumb.copyWith(data: data);
  }

  return breadcrumb;
}

String? _maskEmail(String? email) {
  if (email == null) return null;
  final parts = email.split('@');
  if (parts.length != 2) return '***';
  return '${parts[0][0]}***@${parts[1]}';
}
```

### 2. Sentry 서비스 클래스

```dart
// lib/core/monitoring/sentry_service.dart
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryService {
  static final SentryService _instance = SentryService._internal();

  factory SentryService() => _instance;

  SentryService._internal();

  /// 사용자 정보 설정
  void setUser({
    required String id,
    String? email,
    String? username,
    Map<String, String>? extras,
  }) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: id,
        email: email,
        username: username,
        data: extras,
      ));
    });
  }

  /// 사용자 정보 초기화
  void clearUser() {
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// 태그 설정
  void setTag(String key, String value) {
    Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// 여러 태그 설정
  void setTags(Map<String, String> tags) {
    Sentry.configureScope((scope) {
      for (final entry in tags.entries) {
        scope.setTag(entry.key, entry.value);
      }
    });
  }

  /// 컨텍스트 설정
  void setContext(String key, Map<String, dynamic> value) {
    Sentry.configureScope((scope) {
      scope.setContexts(key, value);
    });
  }

  /// 브레드크럼 추가
  void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) {
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category,
      data: data,
      level: level,
      timestamp: DateTime.now(),
    ));
  }

  /// 예외 캡처
  Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? extras,
    SentryLevel? level,
  }) async {
    if (kDebugMode) {
      debugPrint('[Sentry] Exception: $exception');
      debugPrint('[Sentry] Stack: $stackTrace');
      return;
    }

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (level != null) {
          scope.level = level;
        }
        if (extras != null) {
          for (final entry in extras.entries) {
            scope.setExtra(entry.key, entry.value);
          }
        }
      },
    );
  }

  /// 메시지 캡처
  Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extras,
  }) async {
    if (kDebugMode) {
      debugPrint('[Sentry] Message: $message');
      return;
    }

    await Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (extras != null) {
          for (final entry in extras.entries) {
            scope.setExtra(entry.key, entry.value);
          }
        }
      },
    );
  }
}
```

### 3. 성능 트랜잭션

```dart
// lib/core/monitoring/sentry_performance.dart
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryPerformance {
  /// API 호출 성능 측정
> ⚠️ **경고:** `SpanStatus.ok()`, `SpanStatus.internalError()` 등은 factory constructor이므로 `const`로 사용할 수 없습니다. `const`를 제거하세요.

  static Future<T> measureApiCall<T>({
    required String operation,
    required String description,
    required Future<T> Function() call,
  }) async {
    final transaction = Sentry.startTransaction(
      operation,
      'http.client',
      description: description,
    );

    try {
      final result = await call();
      transaction.status = const SpanStatus.ok();
      return result;
    } catch (e) {
      transaction.status = const SpanStatus.internalError();
      transaction.throwable = e;
      rethrow;
    } finally {
      await transaction.finish();
    }
  }

  /// 커스텀 작업 성능 측정
  static Future<T> measureOperation<T>({
    required String name,
    required String operation,
    required Future<T> Function(ISentrySpan span) task,
    Map<String, dynamic>? data,
  }) async {
    final transaction = Sentry.startTransaction(
      name,
      operation,
    );

    if (data != null) {
      for (final entry in data.entries) {
        transaction.setData(entry.key, entry.value);
      }
    }

    try {
      final result = await task(transaction);
      transaction.status = const SpanStatus.ok();
      return result;
    } catch (e) {
      transaction.status = const SpanStatus.internalError();
      transaction.throwable = e;
      rethrow;
    } finally {
      await transaction.finish();
    }
  }

  /// 하위 스팬 생성
  static ISentrySpan? startChild(
    ISentrySpan parent, {
    required String operation,
    String? description,
  }) {
    return parent.startChild(
      operation,
      description: description,
    );
  }
}

// 사용 예시
class ProductRepository {
  final Dio _dio;

  ProductRepository(this._dio);

  Future<List<Product>> getProducts() async {
    return SentryPerformance.measureApiCall(
      operation: 'getProducts',
      description: 'GET /api/products',
      call: () async {
        final response = await _dio.get('/api/products');
        return (response.data as List)
            .map((json) => Product.fromJson(json))
            .toList();
      },
    );
  }

  Future<void> checkout(Cart cart) async {
    return SentryPerformance.measureOperation(
      name: 'checkout',
      operation: 'task',
      data: {
        'items_count': cart.items.length,
        'total_price': cart.totalPrice,
      },
      task: (transaction) async {
        // 재고 확인
        final stockSpan = SentryPerformance.startChild(
          transaction,
          operation: 'check_stock',
          description: 'Verify item availability',
        );
        await _checkStock(cart.items);
        await stockSpan?.finish(status: const SpanStatus.ok());

        // 결제 처리
        final paymentSpan = SentryPerformance.startChild(
          transaction,
          operation: 'process_payment',
          description: 'Process payment',
        );
        await _processPayment(cart);
        await paymentSpan?.finish(status: const SpanStatus.ok());

        // 주문 생성
        final orderSpan = SentryPerformance.startChild(
          transaction,
          operation: 'create_order',
          description: 'Create order record',
        );
        await _createOrder(cart);
        await orderSpan?.finish(status: const SpanStatus.ok());
      },
    );
  }
}
```

### 4. Dio Sentry 통합

```dart
// lib/core/network/sentry_dio_interceptor.dart
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// sentry_dio 패키지를 사용한 자동 통합
Dio createDioWithSentry({String? baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? 'https://api.example.com',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // Sentry 자동 추적 추가
> ⚠️ **경고:** `SentryStatusCode.range()`는 실제 Sentry SDK에 존재하지 않는 가공된 API입니다. 상태 코드 필터링은 `beforeSend` 또는 `beforeSendTransaction` 콜백에서 직접 구현해야 합니다.

  dio.addSentry(
    captureFailedRequests: true,
    failedRequestStatusCodes: [
      SentryStatusCode.range(400, 599),
    ],
    sendDefaultPii: false, // 개인정보 전송 비활성화
  );

  return dio;
}

// 또는 수동 인터셉터
> ⚠️ **주의:** 이 클래스명은 `sentry_dio` 패키지의 기존 클래스와 충돌할 수 있습니다. 실제 프로젝트에서는 다른 이름을 사용하세요.

class SentryDioInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 트랜잭션 시작
    final transaction = Sentry.startTransaction(
      '${options.method} ${options.path}',
      'http.client',
      description: options.uri.toString(),
    );

    // 요청에 트랜잭션 저장
    options.extra['sentry_transaction'] = transaction;
    options.extra['start_time'] = DateTime.now();

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final transaction = response.requestOptions.extra['sentry_transaction']
        as ISentrySpan?;

    if (transaction != null) {
      transaction.setData('status_code', response.statusCode);
      transaction.setData('response_size', response.data?.toString().length ?? 0);
      transaction.status = const SpanStatus.ok();
      transaction.finish();
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final transaction = err.requestOptions.extra['sentry_transaction']
        as ISentrySpan?;

    if (transaction != null) {
      transaction.setData('error_type', err.type.toString());
      transaction.setData('status_code', err.response?.statusCode);
      transaction.status = const SpanStatus.internalError();
      transaction.throwable = err;
      transaction.finish();
    }

    handler.next(err);
  }
}
```

---

## Firebase Performance Monitoring

Firebase Performance Monitoring은 앱의 성능 특성을 이해하는 데 도움이 되는 자동 및 커스텀 성능 트레이스를 제공합니다.

### 1. 기본 설정

```dart
// lib/core/monitoring/performance_service.dart
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();

  factory PerformanceService() => _instance;

  PerformanceService._internal();

  final FirebasePerformance _performance = FirebasePerformance.instance;

  /// 성능 수집 활성화/비활성화
  Future<void> setPerformanceCollectionEnabled(bool enabled) async {
    await _performance.setPerformanceCollectionEnabled(enabled);
  }

  /// 커스텀 트레이스 생성
  Trace newTrace(String name) {
    return _performance.newTrace(name);
  }

  /// HTTP 메트릭 생성
  HttpMetric newHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }
}
```

### 2. 커스텀 트레이스

```dart
// lib/core/monitoring/trace_manager.dart
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class TraceManager {
  final PerformanceService _performanceService;
  final Map<String, Trace> _activeTraces = {};

  TraceManager({PerformanceService? performanceService})
      : _performanceService = performanceService ?? PerformanceService();

  /// 트레이스 시작
  Future<void> startTrace(String name) async {
    if (kDebugMode) {
      debugPrint('[Trace] Start: $name');
      return;
    }

    if (_activeTraces.containsKey(name)) {
      debugPrint('[Trace] Warning: $name already started');
      return;
    }

    final trace = _performanceService.newTrace(name);
    await trace.start();
    _activeTraces[name] = trace;
  }

  /// 트레이스 종료
  Future<void> stopTrace(String name, {Map<String, int>? metrics}) async {
    if (kDebugMode) {
      debugPrint('[Trace] Stop: $name');
      return;
    }

    final trace = _activeTraces.remove(name);
    if (trace == null) {
      debugPrint('[Trace] Warning: $name not found');
      return;
    }

    // 메트릭 추가
    if (metrics != null) {
      for (final entry in metrics.entries) {
        trace.setMetric(entry.key, entry.value);
      }
    }

    await trace.stop();
  }

  /// 트레이스에 속성 추가
  void putAttribute(String traceName, String key, String value) {
    final trace = _activeTraces[traceName];
    trace?.putAttribute(key, value);
  }

  /// 트레이스에 메트릭 추가
  void incrementMetric(String traceName, String metricName, int value) {
    final trace = _activeTraces[traceName];
    trace?.incrementMetric(metricName, value);
  }

  /// 비동기 작업 성능 측정
  Future<T> measureAsync<T>(
    String name,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    if (kDebugMode) {
      return operation();
    }

    final trace = _performanceService.newTrace(name);

    // 속성 추가
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

  /// 동기 작업 성능 측정
  T measureSync<T>(
    String name,
    T Function() operation, {
    Map<String, String>? attributes,
  }) {
    if (kDebugMode) {
      return operation();
    }

    final trace = _performanceService.newTrace(name);

    if (attributes != null) {
      for (final entry in attributes.entries) {
        trace.putAttribute(entry.key, entry.value);
      }
    }

> ⚠️ **주의:** `unawaited()`를 사용하려면 `import 'dart:async';`가 필요합니다.

    unawaited(trace.start());
    final stopwatch = Stopwatch()..start();

    try {
      final result = operation();
      trace.setMetric('success', 1);
      return result;
    } catch (e) {
      trace.setMetric('success', 0);
      trace.putAttribute('error', e.runtimeType.toString());
      rethrow;
    } finally {
      stopwatch.stop();
      trace.setMetric('duration_ms', stopwatch.elapsedMilliseconds);
      unawaited(trace.stop());
    }
  }
}
```

### 3. HTTP 메트릭 자동 수집

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
    options.extra['request_start'] = DateTime.now();

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _finishMetric(
      response.requestOptions,
      statusCode: response.statusCode,
      responseSize: _getResponseSize(response),
      contentType: response.headers.value('content-type'),
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _finishMetric(
      err.requestOptions,
      statusCode: err.response?.statusCode,
      responseSize: _getResponseSize(err.response),
    );

    handler.next(err);
  }

  void _finishMetric(
    RequestOptions options, {
    int? statusCode,
    int? responseSize,
    String? contentType,
  }) {
    final metric = options.extra['firebase_metric'] as HttpMetric?;
    if (metric == null) return;

    if (statusCode != null) {
      metric.httpResponseCode = statusCode;
    }

    if (responseSize != null) {
      metric.responsePayloadSize = responseSize;
    }

    if (contentType != null) {
      metric.responseContentType = contentType;
    }

    // 요청 크기
    final requestSize = _getRequestSize(options);
    if (requestSize != null) {
      metric.requestPayloadSize = requestSize;
    }

    metric.stop();
  }

  HttpMethod _getHttpMethod(String method) {
    return switch (method.toUpperCase()) {
      'GET' => HttpMethod.Get,
      'POST' => HttpMethod.Post,
      'PUT' => HttpMethod.Put,
      'DELETE' => HttpMethod.Delete,
      'PATCH' => HttpMethod.Patch,
      'OPTIONS' => HttpMethod.Options,
      'HEAD' => HttpMethod.Head,
      _ => HttpMethod.Get,
    };
  }

  int? _getResponseSize(Response? response) {
    if (response?.data == null) return null;

    if (response!.data is String) {
      return (response.data as String).length;
    }

    return response.data.toString().length;
  }

  int? _getRequestSize(RequestOptions options) {
    if (options.data == null) return null;

    if (options.data is String) {
      return (options.data as String).length;
    }

    return options.data.toString().length;
  }
}
```

### 4. 화면 렌더링 성능 측정

```dart
// lib/core/monitoring/screen_performance_observer.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'trace_manager.dart';

mixin ScreenPerformanceMixin<T extends StatefulWidget> on State<T> {
  final TraceManager _traceManager = TraceManager();
  late final String _screenName;
  DateTime? _initTime;

  @override
  void initState() {
    super.initState();
    _screenName = widget.runtimeType.toString();
    _initTime = DateTime.now();

    _traceManager.startTrace('screen_$_screenName');

    // 첫 프레임 렌더링 완료 후 측정
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _measureFirstFrame();
    });
  }

  void _measureFirstFrame() {
    if (_initTime == null) return;

    final duration = DateTime.now().difference(_initTime!);

    _traceManager.stopTrace('screen_$_screenName', metrics: {
      'first_frame_ms': duration.inMilliseconds,
    });
  }

  @override
  void dispose() {
    // 화면 체류 시간 기록
    if (_initTime != null) {
      final duration = DateTime.now().difference(_initTime!);
      _traceManager.measureSync(
        'screen_duration_$_screenName',
        () {},
        attributes: {
          'duration_seconds': duration.inSeconds.toString(),
        },
      );
    }
    super.dispose();
  }
}

// 사용 예시
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with ScreenPerformanceMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('상품 상세')),
      body: const Center(child: Text('Product Detail')),
    );
  }
}
```

---

## 커스텀 대시보드

### 1. 메트릭 수집 서비스

```dart
// lib/core/monitoring/metrics_collector.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

/// 앱 내부 메트릭 수집기
class MetricsCollector {
  static final MetricsCollector _instance = MetricsCollector._internal();

  factory MetricsCollector() => _instance;

  MetricsCollector._internal();

  final Map<String, List<double>> _metrics = {};
  final Map<String, int> _counters = {};
  final List<Map<String, dynamic>> _events = [];

  Timer? _flushTimer;
  final Duration _flushInterval = const Duration(minutes: 1);

  void Function(Map<String, dynamic>)? onFlush;

  /// 초기화
  void initialize({void Function(Map<String, dynamic>)? onFlush}) {
    this.onFlush = onFlush;
    _startPeriodicFlush();
  }

  /// 값 기록 (평균, 최소, 최대, p95 계산용)
  void recordValue(String name, double value) {
    _metrics.putIfAbsent(name, () => []);
    _metrics[name]!.add(value);

    // 메모리 관리: 최대 1000개 유지
    if (_metrics[name]!.length > 1000) {
      _metrics[name]!.removeAt(0);
    }
  }

  /// 카운터 증가
  void incrementCounter(String name, [int delta = 1]) {
    _counters[name] = (_counters[name] ?? 0) + delta;
  }

  /// 이벤트 기록
  void recordEvent(String name, {Map<String, dynamic>? properties}) {
    _events.add({
      'name': name,
      'timestamp': DateTime.now().toIso8601String(),
      'properties': properties,
    });

    // 메모리 관리: 최대 100개 유지
    if (_events.length > 100) {
      _events.removeAt(0);
    }
  }

  /// 현재 메트릭 스냅샷
  Map<String, dynamic> getSnapshot() {
    final snapshot = <String, dynamic>{};

    // 값 메트릭 통계
    for (final entry in _metrics.entries) {
      if (entry.value.isEmpty) continue;

      final sorted = List<double>.from(entry.value)..sort();
      final sum = sorted.reduce((a, b) => a + b);

      snapshot['${entry.key}_avg'] = sum / sorted.length;
      snapshot['${entry.key}_min'] = sorted.first;
      snapshot['${entry.key}_max'] = sorted.last;
      snapshot['${entry.key}_p50'] = _percentile(sorted, 50);
      snapshot['${entry.key}_p95'] = _percentile(sorted, 95);
      snapshot['${entry.key}_p99'] = _percentile(sorted, 99);
      snapshot['${entry.key}_count'] = sorted.length;
    }

    // 카운터
    for (final entry in _counters.entries) {
      snapshot['${entry.key}_total'] = entry.value;
    }

    // 이벤트 수
    snapshot['events_count'] = _events.length;

    return snapshot;
  }

  /// 데이터 초기화
  void reset() {
    _metrics.clear();
    _counters.clear();
    _events.clear();
  }

  /// 주기적 전송 시작
  void _startPeriodicFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());
  }

  /// 메트릭 전송
  void flush() {
    if (onFlush == null) return;

    final snapshot = getSnapshot();
    snapshot['flush_time'] = DateTime.now().toIso8601String();
    snapshot['events'] = List<Map<String, dynamic>>.from(_events);

    onFlush!(snapshot);

    // 전송 후 이벤트만 초기화 (메트릭은 유지)
    _events.clear();
  }

  /// 종료
  void dispose() {
    _flushTimer?.cancel();
    flush();
  }

  double _percentile(List<double> sorted, int percentile) {
    if (sorted.isEmpty) return 0;
    final index = ((percentile / 100) * sorted.length).floor();
    return sorted[index.clamp(0, sorted.length - 1)];
  }
}
```

### 2. 원격 메트릭 전송

```dart
// lib/core/monitoring/metrics_reporter.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MetricsReporter {
  final Dio _dio;
  final String _endpoint;
  final String _apiKey;

  MetricsReporter({
    required String endpoint,
    required String apiKey,
    Dio? dio,
  })  : _endpoint = endpoint,
        _apiKey = apiKey,
        _dio = dio ?? Dio();

  /// Grafana/DataDog/커스텀 백엔드로 메트릭 전송
  Future<void> report(Map<String, dynamic> metrics) async {
    if (kDebugMode) {
      debugPrint('[Metrics] ${metrics.toString()}');
      return;
    }

    try {
      await _dio.post(
        _endpoint,
        data: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'metrics': metrics,
          'app': 'my_flutter_app',
          'platform': defaultTargetPlatform.name,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );
    } catch (e) {
      debugPrint('[MetricsReporter] Failed to send metrics: $e');
    }
  }

  /// DataDog 형식으로 변환
  Map<String, dynamic> toDataDogFormat(Map<String, dynamic> metrics) {
    final series = <Map<String, dynamic>>[];

    for (final entry in metrics.entries) {
      if (entry.value is num) {
        series.add({
          'metric': 'flutter.${entry.key}',
          'points': [
            [DateTime.now().millisecondsSinceEpoch ~/ 1000, entry.value]
          ],
          'type': 'gauge',
          'tags': ['app:my_flutter_app'],
        });
      }
    }

    return {'series': series};
  }

  /// Prometheus 형식으로 변환
  String toPrometheusFormat(Map<String, dynamic> metrics) {
    final buffer = StringBuffer();

    for (final entry in metrics.entries) {
      if (entry.value is num) {
        final metricName = 'flutter_${entry.key}'.replaceAll('.', '_');
        buffer.writeln('# HELP $metricName Flutter app metric');
        buffer.writeln('# TYPE $metricName gauge');
        buffer.writeln('$metricName{app="my_flutter_app"} ${entry.value}');
      }
    }

    return buffer.toString();
  }
}
```

### 3. 실시간 대시보드 데이터

```dart
// lib/core/monitoring/realtime_metrics.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

/// 실시간 성능 메트릭 (개발용 대시보드)
class RealtimeMetrics extends ChangeNotifier {
  static final RealtimeMetrics _instance = RealtimeMetrics._internal();

  factory RealtimeMetrics() => _instance;

  RealtimeMetrics._internal();

  // API 메트릭
  int _apiCallCount = 0;
  int _apiErrorCount = 0;
  final List<int> _apiLatencies = [];

  // UI 메트릭
  int _screenViewCount = 0;
  int _userActionCount = 0;

  // 메모리 메트릭 (샘플)
  double _memoryUsageMB = 0;

  Timer? _updateTimer;

  // Getters
  int get apiCallCount => _apiCallCount;
  int get apiErrorCount => _apiErrorCount;
  double get apiErrorRate =>
      _apiCallCount > 0 ? _apiErrorCount / _apiCallCount * 100 : 0;
  double get avgApiLatency =>
      _apiLatencies.isNotEmpty
          ? _apiLatencies.reduce((a, b) => a + b) / _apiLatencies.length
          : 0;
  int get screenViewCount => _screenViewCount;
  int get userActionCount => _userActionCount;
  double get memoryUsageMB => _memoryUsageMB;

  /// 초기화
  void initialize() {
    _updateTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateMetrics(),
    );
  }

  /// API 호출 기록
  void recordApiCall({required int latencyMs, required bool success}) {
    _apiCallCount++;
    _apiLatencies.add(latencyMs);

    if (!success) {
      _apiErrorCount++;
    }

    // 최근 100개만 유지
    if (_apiLatencies.length > 100) {
      _apiLatencies.removeAt(0);
    }

    notifyListeners();
  }

  /// 화면 조회 기록
  void recordScreenView() {
    _screenViewCount++;
    notifyListeners();
  }

  /// 사용자 액션 기록
  void recordUserAction() {
    _userActionCount++;
    notifyListeners();
  }

  void _updateMetrics() {
    // 메모리 사용량 업데이트 (실제 구현 시 platform channel 사용)
    // _memoryUsageMB = await MemoryInfo.getUsedMemory();
    notifyListeners();
  }

  /// 초기화
  void reset() {
    _apiCallCount = 0;
    _apiErrorCount = 0;
    _apiLatencies.clear();
    _screenViewCount = 0;
    _userActionCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}
```

---

## 알림 설정

### 1. 알림 서비스

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
  final String? _pagerDutyKey;
  final String? _emailEndpoint;

  AlertService({
    Dio? dio,
    String? slackWebhookUrl,
    String? pagerDutyKey,
    String? emailEndpoint,
  })  : _dio = dio ?? Dio(),
        _slackWebhookUrl = slackWebhookUrl,
        _pagerDutyKey = pagerDutyKey,
        _emailEndpoint = emailEndpoint;

  /// 알림 전송
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

    // 심각도에 따라 채널 선택
    switch (severity) {
      case AlertSeverity.critical:
        await Future.wait([
          _sendToPagerDuty(title, message, metadata),
          _sendToSlack(title, message, severity, metadata),
          _sendEmail(title, message, metadata),
        ]);
      case AlertSeverity.error:
        await Future.wait([
          _sendToSlack(title, message, severity, metadata),
          _sendEmail(title, message, metadata),
        ]);
      case AlertSeverity.warning:
        await _sendToSlack(title, message, severity, metadata);
      case AlertSeverity.info:
        await _sendToSlack(title, message, severity, metadata);
    }
  }

  /// Slack 알림
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
              'fields': metadata?.entries
                  .map((e) => {
                        'title': e.key,
                        'value': e.value.toString(),
                        'short': true,
                      })
                  .toList(),
              'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            }
          ],
        },
      );
    } catch (e) {
      debugPrint('[AlertService] Slack failed: $e');
    }
  }

  /// PagerDuty 알림
  Future<void> _sendToPagerDuty(
    String title,
    String message,
    Map<String, dynamic>? metadata,
  ) async {
    if (_pagerDutyKey == null) return;

    try {
      await _dio.post(
        'https://events.pagerduty.com/v2/enqueue',
        data: {
          'routing_key': _pagerDutyKey,
          'event_action': 'trigger',
          'payload': {
            'summary': title,
            'source': 'flutter-app',
            'severity': 'critical',
            'custom_details': {
              'message': message,
              ...?metadata,
            },
          },
        },
      );
    } catch (e) {
      debugPrint('[AlertService] PagerDuty failed: $e');
    }
  }

  /// 이메일 알림
  Future<void> _sendEmail(
    String title,
    String message,
    Map<String, dynamic>? metadata,
  ) async {
    if (_emailEndpoint == null) return;

    try {
      await _dio.post(
        _emailEndpoint!,
        data: {
          'subject': '[Flutter App Alert] $title',
          'body': message,
          'metadata': metadata,
        },
      );
    } catch (e) {
      debugPrint('[AlertService] Email failed: $e');
    }
  }
}
```

### 2. 임계값 기반 자동 알림

```dart
// lib/core/monitoring/threshold_monitor.dart
import 'dart:async';

import 'alert_service.dart';
import 'metrics_collector.dart';

class ThresholdConfig {
  final String metricName;
  final double warningThreshold;
  final double criticalThreshold;
  final bool isUpperBound; // true: 초과 시 알림, false: 미만 시 알림

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

  /// 기본 임계값 설정
  static List<ThresholdConfig> get defaultThresholds => [
    // 에러율
    const ThresholdConfig(
      metricName: 'api_error_rate',
      warningThreshold: 1.0,  // 1%
      criticalThreshold: 5.0, // 5%
    ),
    // API 응답 시간 (p95)
    const ThresholdConfig(
      metricName: 'api_latency_p95',
      warningThreshold: 500,  // 500ms
      criticalThreshold: 1000, // 1초
    ),
    // 메모리 사용량
    const ThresholdConfig(
      metricName: 'memory_usage_mb',
      warningThreshold: 150,
      criticalThreshold: 200,
    ),
    // Crash-free rate
    const ThresholdConfig(
      metricName: 'crash_free_rate',
      warningThreshold: 99.5,
      criticalThreshold: 99.0,
      isUpperBound: false, // 미만 시 알림
    ),
  ];

  /// 모니터링 시작
  void start({Duration interval = const Duration(minutes: 1)}) {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(interval, (_) => _checkThresholds());
  }

  /// 모니터링 중지
  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  void _checkThresholds() {
    final snapshot = _metricsCollector.getSnapshot();

    for (final config in _thresholds) {
      final value = snapshot[config.metricName];
      if (value == null || value is! num) continue;

      final severity = _checkSeverity(value.toDouble(), config);
      final alertKey = config.metricName;

      if (severity != null) {
        // 새로운 알림이거나 심각도가 높아진 경우
        if (!_activeAlerts.contains(alertKey)) {
          _activeAlerts.add(alertKey);
          _alertService.sendAlert(
            title: '${config.metricName} 임계값 초과',
            message: '현재 값: $value (경고: ${config.warningThreshold}, '
                '심각: ${config.criticalThreshold})',
            severity: severity,
            metadata: {
              'metric': config.metricName,
              'value': value,
              'warning_threshold': config.warningThreshold,
              'critical_threshold': config.criticalThreshold,
            },
          );
        }
      } else {
        // 정상으로 복구됨
        if (_activeAlerts.contains(alertKey)) {
          _activeAlerts.remove(alertKey);
          _alertService.sendAlert(
            title: '${config.metricName} 정상 복구',
            message: '현재 값: $value',
            severity: AlertSeverity.info,
            metadata: {
              'metric': config.metricName,
              'value': value,
            },
          );
        }
      }
    }
  }

  AlertSeverity? _checkSeverity(double value, ThresholdConfig config) {
    if (config.isUpperBound) {
      if (value >= config.criticalThreshold) return AlertSeverity.critical;
      if (value >= config.warningThreshold) return AlertSeverity.warning;
    } else {
      if (value <= config.criticalThreshold) return AlertSeverity.critical;
      if (value <= config.warningThreshold) return AlertSeverity.warning;
    }
    return null;
  }

  void dispose() {
    stop();
  }
}
```

---

## 인시던트 대응 절차

> 📖 **인시던트 대응 프로세스, On-call 로테이션, Runbook 템플릿, 포스트모템 작성은 [ProductionOperations.md](ProductionOperations.md)의 10절을 참조하세요.** 이 섹션에서는 모니터링 관점의 알림 설정만 다룹니다.

### 알림 에스컬레이션 개요

모니터링 시스템에서 감지한 이상 징후는 다음과 같이 에스컬레이션됩니다:

| 심각도 | 초기 알림 채널 | 에스컬레이션 시간 |
|--------|---------------|------------------|
| **P1 (Critical)** | PagerDuty → On-call 개발자 | 0분 즉시, 5분 후 팀 전체 |
| **P2 (High)** | Slack #alerts → 담당 팀 | 30분 후 팀 리드 |
| **P3 (Medium)** | Slack #monitoring → 자동 티켓 | 24시간 후 스프린트 검토 |

**다음 단계:** 알림을 받은 후의 구체적인 대응 절차는 [ProductionOperations.md](ProductionOperations.md)를 참조하세요.

---

## 통합 모니터링 설정

### 1. 모니터링 초기화

```dart
// lib/core/monitoring/monitoring_initializer.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'alert_service.dart';
import 'crashlytics_service.dart';
import 'metrics_collector.dart';
import 'metrics_reporter.dart';
import 'monitored_bloc_observer.dart';
import 'sentry_service.dart';
import 'threshold_monitor.dart';

class MonitoringInitializer {
  static Future<void> initialize({
    required String environment,
    String? slackWebhookUrl,
    String? metricsEndpoint,
    String? metricsApiKey,
  }) async {
    // 1. Crashlytics 초기화
    // (main.dart에서 Firebase 초기화 후 호출됨)

    // 2. Bloc Observer 설정
    Bloc.observer = MonitoredBlocObserver();

    // 3. 메트릭 수집기 초기화
    final metricsCollector = MetricsCollector();

    // 4. 메트릭 리포터 설정
    MetricsReporter? reporter;
    if (metricsEndpoint != null && metricsApiKey != null) {
      reporter = MetricsReporter(
        endpoint: metricsEndpoint,
        apiKey: metricsApiKey,
      );
    }

    metricsCollector.initialize(
      onFlush: (metrics) {
        reporter?.report(metrics);
      },
    );

    // 5. 알림 서비스 설정
    final alertService = AlertService(
      slackWebhookUrl: slackWebhookUrl,
    );

    // 6. 임계값 모니터 설정
    if (!kDebugMode) {
      final thresholdMonitor = ThresholdMonitor(
        metricsCollector: metricsCollector,
        alertService: alertService,
        thresholds: ThresholdMonitor.defaultThresholds,
      );
      thresholdMonitor.start();
    }

    // 7. 환경 태그 설정
    SentryService().setTag('environment', environment);
    await CrashlyticsService().setCustomKey('environment', environment);
  }
}
```

### 2. main.dart 통합

```dart
// lib/main.dart
import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/monitoring/monitoring_initializer.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Firebase 초기화
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Crashlytics 설정
      if (!kDebugMode) {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      // Sentry 초기화
      await SentryFlutter.init(
        (options) {
          options.dsn = const String.fromEnvironment('SENTRY_DSN');
          options.environment = const String.fromEnvironment('ENV', defaultValue: 'dev');
          options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
        },
        appRunner: () async {
          // 모니터링 초기화
          await MonitoringInitializer.initialize(
            environment: const String.fromEnvironment('ENV', defaultValue: 'dev'),
            slackWebhookUrl: const String.fromEnvironment('SLACK_WEBHOOK'),
            metricsEndpoint: const String.fromEnvironment('METRICS_ENDPOINT'),
            metricsApiKey: const String.fromEnvironment('METRICS_API_KEY'),
          );

          runApp(
            SentryWidget(
              child: const MyApp(),
            ),
          );
        },
      );
    },
    (error, stack) {
      // Zone 에러 핸들링
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(error, stack);
        Sentry.captureException(error, stackTrace: stack);
      }
    },
  );
}
```

---

## Best Practices

### 모니터링 원칙

| 원칙 | 설명 |
|------|------|
| **민감 정보 보호** | PII(개인식별정보)를 로그나 크래시 리포트에 포함하지 않음 |
| **샘플링 적용** | 프로덕션에서는 성능 트레이스를 10-20%만 수집 |
| **환경 분리** | dev/staging/production 환경별 데이터 분리 |
| **비용 관리** | 불필요한 이벤트 전송 최소화 |
| **신속한 대응** | Critical 알림은 즉시 대응 체계 구축 |

### 체크리스트

```
## 크래시 리포팅
- [ ] Firebase Crashlytics 초기화
- [ ] FlutterError.onError 핸들러 설정
- [ ] PlatformDispatcher.instance.onError 핸들러 설정
- [ ] 사용자 식별자 설정 (로그인 후)
- [ ] 커스텀 키 설정 (구독 유형, 앱 버전 등)
- [ ] 브레드크럼 로깅 (주요 사용자 액션)
- [ ] 비치명적 에러 기록

## Sentry 통합
- [ ] Sentry DSN 환경 변수 설정
- [ ] 환경(environment) 태그 설정
- [ ] 샘플링 비율 설정 (tracesSampleRate)
- [ ] 민감 정보 필터링 (beforeSend)
- [ ] 성능 트랜잭션 추가
- [ ] Dio 자동 트래킹 설정

## 성능 모니터링
- [ ] Firebase Performance 초기화
- [ ] 커스텀 트레이스 추가 (주요 작업)
- [ ] HTTP 메트릭 자동 수집
- [ ] 화면 렌더링 성능 측정
- [ ] 앱 시작 시간 측정

## 대시보드 & 알림
- [ ] 핵심 메트릭 정의
- [ ] 메트릭 수집기 구현
- [ ] 원격 전송 설정 (Grafana/DataDog)
- [ ] 임계값 기반 알림 설정
- [ ] Slack/PagerDuty 연동
- [ ] 알림 에스컬레이션 정책 수립

## 운영
- [ ] 일일 크래시 리포트 리뷰
- [ ] 주간 성능 메트릭 분석
- [ ] 월간 SLA 준수 여부 확인
- [ ] 분기별 모니터링 전략 개선
```

### 안티패턴

```dart
// ❌ 문제: 민감 정보 로깅
crashlytics.log('User logged in with password: $password');
crashlytics.setCustomKey('credit_card', cardNumber);

// ✅ 해결: 민감 정보 제외
crashlytics.log('User logged in successfully');
crashlytics.setCustomKey('payment_method', 'credit_card');

// ❌ 문제: 과도한 이벤트 전송
for (final item in items) {
  analytics.logEvent('item_viewed', {'id': item.id});
}

// ✅ 해결: 배치 처리 또는 중요 이벤트만
analytics.logEvent('items_viewed', {'count': items.length});

// ❌ 문제: 프로덕션에서 100% 샘플링
options.tracesSampleRate = 1.0; // 비용 폭증!

// ✅ 해결: 적절한 샘플링
options.tracesSampleRate = 0.2; // 20%

// ❌ 문제: 동기적 에러 리포팅
try {
  await riskyOperation();
} catch (e) {
  await crashlytics.recordError(e); // 사용자 대기
  throw e;
}

// ✅ 해결: 비동기 처리
try {
  await riskyOperation();
} catch (e) {
  crashlytics.recordError(e); // fire-and-forget
  throw e;
}
```

---

## 트러블슈팅

### Crashlytics 데이터가 보이지 않는 경우

```dart
// 확인 사항:
// 1. Firebase 프로젝트 설정 확인
// 2. google-services.json / GoogleService-Info.plist 확인
// 3. 개발 모드에서는 기본적으로 비활성화됨
// 4. 실제 디바이스에서 테스트 (에뮬레이터는 제한적)

// 테스트 크래시 발생
if (kDebugMode) {
  FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
}
FirebaseCrashlytics.instance.crash();

// 앱 재시작 후 Firebase Console 확인 (최대 24시간 소요)
```

### Sentry 이벤트가 전송되지 않는 경우

```dart
// 확인 사항:
// 1. DSN이 올바른지 확인
// 2. 네트워크 연결 확인
// 3. beforeSend에서 null 반환하는지 확인
// 4. 샘플링으로 인해 드롭되는지 확인

// 디버그 모드에서 확인
options.debug = true;
options.diagnosticLevel = SentryLevel.debug;
```

### 성능 데이터가 부정확한 경우

```dart
// 확인 사항:
// 1. 디버그 모드가 아닌지 확인 (디버그는 느림)
// 2. 프로파일 모드에서 테스트
// 3. 실제 디바이스에서 측정

// 릴리즈 모드로 빌드
// flutter build apk --release
// flutter run --release
```

---

## 참고자료

- [Firebase Crashlytics 문서](https://firebase.google.com/docs/crashlytics)
- [Firebase Performance Monitoring](https://firebase.google.com/docs/perf-mon)
- [Sentry Flutter SDK](https://docs.sentry.io/platforms/flutter/)
- [DataDog Mobile SDK](https://docs.datadoghq.com/real_user_monitoring/mobile_and_tv_monitoring/flutter/)
- [Grafana Cloud](https://grafana.com/docs/grafana-cloud/)

---

## 실습 과제

### 과제 1: Crashlytics 통합
Firebase Crashlytics를 설정하고, 비정상 종료와 Non-fatal 에러를 모니터링하는 대시보드를 구성하세요.

### 과제 2: 커스텀 메트릭 추적
API 응답 시간, 화면 로딩 시간을 커스텀 트레이스로 측정하고 성능 기준(SLI)을 정의하세요.

## Self-Check

- [ ] Crashlytics가 크래시를 정상적으로 수집하는가?
- [ ] Crash-free rate 목표(99.5%+)를 설정했는가?
- [ ] 주요 API의 응답 시간을 모니터링하고 있는가?
- [ ] 장애 발생 시 알림이 자동으로 전송되는가?
