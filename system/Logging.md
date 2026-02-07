# Flutter 로깅 가이드

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - 구조화된 로깅 시스템을 구축할 수 있다
> - BlocObserver로 상태 변화를 추적할 수 있다
> - Crashlytics와 연동하여 프로덕션 로그를 수집할 수 있다

## 개요

효과적인 로깅은 개발, 테스트, 프로덕션 단계에서 앱의 동작을 이해하고 문제를 해결하는 데 필수적입니다. 이 가이드는 구조화된 로깅, 조건부 로깅, 원격 모니터링을 포함한 완벽한 로깅 전략을 다룹니다.

### 로깅의 목적과 중요성

| 목적 | 설명 |
|------|------|
| **디버깅** | 개발 중 버그 추적 및 문제 해결 |
| **모니터링** | 프로덕션 환경 감시 및 성능 추적 |
| **분석** | 사용자 행동 및 앱 성능 분석 |
| **크래시 추적** | 에러 원인 파악 및 스택 트레이스 |
| **보안 감사** | 민감한 작업 기록 및 접근 제어 |

### 로그 레벨 정의

| 레벨 | 심각도 | 용도 | 릴리즈 모드 |
|------|--------|------|-----------|
| **Verbose** | 낮음 | 상세 추적 정보 | 비활성화 |
| **Debug** | 낮음 | 개발 정보 | 비활성화 |
| **Info** | 중간 | 중요한 정보 | 활성화 |
| **Warning** | 높음 | 경고 메시지 | 활성화 |
| **Error** | 매우 높음 | 에러 발생 | 활성화 |

---

## Setup

### 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  logger: ^2.5.0
  firebase_crashlytics: ^5.0.7
  dio: ^5.9.0
  sqflite: ^2.3.0
  path: ^1.8.3
  path_provider: ^2.1.0
  intl: ^0.19.0
  uuid: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

### Logger 패키지 설치

```bash
fvm flutter pub get
```

---

## 구조화된 로깅 구현

### 커스텀 로거 클래스

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

  // Private 생성자 - 싱글톤
  AppLogger._();

  /// Verbose 레벨 로깅 - 개발 중 상세 추적 정보
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

  /// Debug 레벨 로깅 - 개발 정보
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

  /// Info 레벨 로깅 - 중요한 정보
  static void info(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.i(message, time: time, error: error, stackTrace: stackTrace);
  }

  /// Warning 레벨 로깅 - 경고 메시지
  static void warning(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.w(message, time: time, error: error, stackTrace: stackTrace);
  }

  /// Error 레벨 로깅 - 에러 발생
  static void error(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(message, time: time, error: error, stackTrace: stackTrace);
  }

  /// 구조화된 로깅 - 맵 형식
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

### 로그 포맷 설계

```dart
// lib/core/logging/log_formatter.dart

class LogFormatter {
  /// 네트워크 요청 로그
  static String formatNetworkRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    return '''
Network Request:
  Method: $method
  URL: $url
  Headers: $headers
  Body: $body
    ''';
  }

  /// 네트워크 응답 로그
  static String formatNetworkResponse({
    required String url,
    required int statusCode,
    dynamic response,
    Duration? duration,
  }) {
    return '''
Network Response:
  URL: $url
  Status Code: $statusCode
  Duration: ${duration?.inMilliseconds ?? 'N/A'}ms
  Response: $response
    ''';
  }

  /// 상태 변경 로그
  static String formatStateChange({
    required String feature,
    required String previousState,
    required String currentState,
    Map<String, dynamic>? metadata,
  }) {
    return '''
State Change ($feature):
  Previous: $previousState
  Current: $currentState
  Metadata: $metadata
    ''';
  }

  /// 에러 로그
  static String formatError({
    required String context,
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
  }) {
    return '''
Error ($context):
  Message: $error
  Stack Trace: $stackTrace
  Details: $details
    ''';
  }
}
```

### 로그 필터링

```dart
// lib/core/logging/log_filter.dart
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class LogFilter {
  /// 민감한 정보를 마스킹
  static String maskSensitiveData(String input) {
    // 이메일 마스킹
    input = input.replaceAllMapped(
      RegExp(r'[\w\.-]+@[\w\.-]+\.\w+'),
      (match) {
        final email = match.group(0)!;
        final parts = email.split('@');
        return '${parts[0][0]}***@${parts[1]}';
      },
    );

    // 전화번호 마스킹
    input = input.replaceAllMapped(
      RegExp(r'\d{3}-\d{3,4}-\d{4}'),
      (match) => '***-***-****',
    );

    // 토큰 마스킹
    input = input.replaceAllMapped(
      RegExp(r'(token|bearer|authorization)[\s:=]*[\w\.]+', caseSensitive: false),
      (match) => 'TOKEN:***MASKED***',
    );

    return input;
  }

  /// 특정 태그의 로그만 필터링
  static bool shouldLog(String tag, Level level) {
    // 릴리즈 모드에서는 trace/debug 제외
    if (!kDebugMode && (level == Level.trace || level == Level.debug)) {
      return false;
    }

    // 특정 모듈 제외
    final excludedTags = ['dio', 'connectivity'];
    if (excludedTags.contains(tag)) {
      return false;
    }

    return true;
  }
}
```

---

## Bloc 로깅

### BlocObserver를 이용한 전역 로깅

```dart
// lib/core/logging/bloc_observer.dart
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
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    AppLogger.logStructured(
      'Bloc.Transition',
      bloc.runtimeType.toString(),
      {
        'event': transition.event.runtimeType.toString(),
        'from': transition.currentState.runtimeType.toString(),
        'to': transition.nextState.runtimeType.toString(),
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

### Bloc에 로깅 통합

```dart
// lib/features/product/presentation/bloc/product_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/logging/app_logger.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase _getProductsUseCase;

  ProductBloc({required GetProductsUseCase getProductsUseCase})
      : _getProductsUseCase = getProductsUseCase,
        super(ProductState.initial()) {
    on<ProductLoadRequested>(_onLoadRequested);
    on<ProductRefreshed>(_onRefreshed);
  }

  Future<void> _onLoadRequested(
    ProductLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    AppLogger.info('[ProductBloc] Loading products...');
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _getProductsUseCase();

    result.fold(
      (failure) {
        AppLogger.warning(
          '[ProductBloc] Failed to load products',
          error: failure,
        );
        emit(state.copyWith(
          isLoading: false,
          failure: failure,
        ));
      },
      (products) {
        AppLogger.logStructured(
          'Product.Loaded',
          'success',
          {
            'count': products.length,
            'ids': products.map((p) => p.id).toList(),
          },
        );
        emit(state.copyWith(
          isLoading: false,
          products: products,
        ));
      },
    );
  }

  Future<void> _onRefreshed(
    ProductRefreshed event,
    Emitter<ProductState> emit,
  ) async {
    AppLogger.info('[ProductBloc] Refreshing products...');
    final result = await _getProductsUseCase();

    result.fold(
      (failure) => AppLogger.error(
        '[ProductBloc] Refresh failed',
        error: failure,
      ),
      (_) => AppLogger.info('[ProductBloc] Refresh completed'),
    );
  }
}
```

---

## 네트워크 로깅

### Dio 인터셉터를 이용한 네트워크 로깅

```dart
// lib/core/network/logging_interceptor.dart
import 'package:dio/dio.dart';
import '../logging/app_logger.dart';
import '../logging/log_formatter.dart';
import '../logging/log_filter.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final url = options.uri.toString();

    // 요청 시작 시간 저장
    options.extra['requestStartTime'] = DateTime.now().millisecondsSinceEpoch;

    // 요청 로깅
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

    // 요청 시작 시간에서 현재까지의 duration 계산
    final startTime = response.requestOptions.extra['requestStartTime'] as int?;
    final duration = startTime != null
        ? Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - startTime)
        : null;

    // 응답 로깅
    AppLogger.logStructured(
      'Network.Response',
      '$method $statusCode',
      {
        'url': url,
        'statusCode': statusCode,
        'body': _maskBody(response.data),
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

    // 에러 로깅
    AppLogger.error(
      '[Network Error] $method $url',
      error: err,
      stackTrace: err.stackTrace,
    );

    AppLogger.logStructured(
      'Network.Error',
      method,
      {
        'url': url,
        'type': err.type.toString(),
        'message': err.message,
        'statusCode': err.response?.statusCode,
        'response': _maskBody(err.response?.data),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    handler.next(err);
  }

  /// 민감한 헤더 여부 확인
  bool _isSensitiveHeader(String key) {
    final sensitiveHeaders = [
      'authorization',
      'token',
      'cookie',
      'x-api-key',
    ];
    return sensitiveHeaders.contains(key.toLowerCase());
  }

  /// 민감한 정보 마스킹
  String _maskBody(dynamic body) {
    if (body == null) return 'null';
    return LogFilter.maskSensitiveData(body.toString());
  }
}
```

### HTTP 클라이언트 설정

```dart
// lib/core/network/dio_setup.dart
import 'package:dio/dio.dart';
import 'logging_interceptor.dart';

class DioSetup {
  static Dio createDio({String? baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? 'https://api.example.com',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // 로깅 인터셉터 추가
    dio.interceptors.add(LoggingInterceptor());

    return dio;
  }
}
```

---

## 크래시 리포팅

> 📖 Crashlytics 크래시 리포팅 및 모니터링 연동은 [Monitoring.md](Monitoring.md)를 참조하세요.

---

## 로그 분석

### 원격 로그 수집

```dart
// lib/core/logging/remote_logger.dart
import 'package:dio/dio.dart';
import 'app_logger.dart';

class RemoteLogger {
  final Dio _dio;
  final String _endpoint;
  final List<Map<String, dynamic>> _logBuffer = [];
  static const int _bufferSize = 50;

  RemoteLogger({
    required Dio dio,
    required String endpoint,
  })  : _dio = dio,
        _endpoint = endpoint;

  /// 로그 버퍼에 추가
  Future<void> addLog(
    String level,
    String tag,
    String message,
    Map<String, dynamic>? metadata,
  ) async {
    final log = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level,
      'tag': tag,
      'message': message,
      'metadata': metadata,
      'app_version': '1.0.0', // BuildInfo에서 동적으로 가져오기
      'device_info': {
        'platform': 'iOS' /* Platform.isIOS ? 'iOS' : 'Android' */,
      },
    };

    _logBuffer.add(log);

    // 버퍼 크기 도달 시 서버로 전송
    if (_logBuffer.length >= _bufferSize) {
      await flushLogs();
    }
  }

  /// 버퍼된 로그 서버로 전송
  Future<void> flushLogs() async {
    if (_logBuffer.isEmpty) return;

    final logs = List<Map<String, dynamic>>.from(_logBuffer);
    _logBuffer.clear();

    try {
      await _dio.post(
        _endpoint,
        data: {'logs': logs},
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      AppLogger.debug('[RemoteLogger] Flushed ${logs.length} logs');
    } catch (e) {
      // 전송 실패 시 로그 복구
      _logBuffer.addAll(logs);
      AppLogger.warning('[RemoteLogger] Failed to flush logs: $e');
    }
  }

  /// 앱 종료 시 호출
  Future<void> dispose() async {
    await flushLogs();
  }
}
```

### 로그 검색 및 필터링

```dart
// lib/core/logging/log_repository.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LogRepository {
  static final LogRepository _instance = LogRepository._internal();
  late Database _db;

  factory LogRepository() {
    return _instance;
  }

  LogRepository._internal();

  Future<void> initialize() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'app_logs.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            level TEXT NOT NULL,
            tag TEXT NOT NULL,
            message TEXT NOT NULL,
            metadata TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  /// 로그 저장
  Future<int> insertLog({
    required String timestamp,
    required String level,
    required String tag,
    required String message,
    String? metadata,
  }) async {
    return await _db.insert('logs', {
      'timestamp': timestamp,
      'level': level,
      'tag': tag,
      'message': message,
      'metadata': metadata,
    });
  }

  /// 로그 검색
  Future<List<Map<String, dynamic>>> searchLogs({
    String? tag,
    String? level,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (tag != null) {
      where += ' AND tag = ?';
      whereArgs.add(tag);
    }

    if (level != null) {
      where += ' AND level = ?';
      whereArgs.add(level);
    }

    if (startDate != null) {
      where += ' AND timestamp >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where += ' AND timestamp <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    return await _db.query(
      'logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: 1000,
    );
  }

  /// 모든 로그 조회
  Future<List<Map<String, dynamic>>> getAllLogs() async {
    return await _db.query('logs', orderBy: 'created_at DESC', limit: 1000);
  }

  /// 로그 삭제 (오래된 로그)
  Future<void> deleteLogs({required DateTime beforeDate}) async {
    await _db.delete(
      'logs',
      where: 'created_at < ?',
      whereArgs: [beforeDate.toIso8601String()],
    );
  }

  /// 데이터베이스 초기화
  Future<void> clearAllLogs() async {
    await _db.delete('logs');
  }

  Future<void> close() async {
    await _db.close();
  }
}
```

### 성능 모니터링

```dart
// lib/core/logging/performance_monitor.dart
import 'app_logger.dart';

class PerformanceMonitor {
  final Map<String, Stopwatch> _stopwatches = {};

  /// 성능 측정 시작
  void startMeasure(String name) {
    _stopwatches[name] = Stopwatch()..start();
    AppLogger.verbose('[Performance] Started measuring: $name');
  }

  /// 성능 측정 종료
  Duration? stopMeasure(String name) {
    final stopwatch = _stopwatches.remove(name);
    if (stopwatch == null) {
      AppLogger.warning('[Performance] No stopwatch found for: $name');
      return null;
    }

    stopwatch.stop();
    final duration = stopwatch.elapsed;

    AppLogger.logStructured(
      'Performance',
      name,
      {
        'duration_ms': duration.inMilliseconds,
        'duration_us': duration.inMicroseconds,
      },
    );

    return duration;
  }

  /// 비동기 작업 성능 측정
  Future<T> measure<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    startMeasure(name);
    try {
      final result = await operation();
      stopMeasure(name);
      return result;
    } catch (e) {
      stopMeasure(name);
      rethrow;
    }
  }

  /// 동기 작업 성능 측정
  T measureSync<T>(
    String name,
    T Function() operation,
  ) {
    startMeasure(name);
    try {
      final result = operation();
      stopMeasure(name);
      return result;
    } catch (e) {
      stopMeasure(name);
      rethrow;
    }
  }
}

// 사용 예시
class ProductRepository {
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  Future<List<Product>> getProducts() async {
    return await _performanceMonitor.measure(
      'getProducts',
      () async {
        // API 호출 로직
        await Future.delayed(const Duration(seconds: 2));
        return [];
      },
    );
  }
}
```

---

## 프로덕션 로깅 전략

### 로그 레벨 관리

```dart
// lib/core/logging/log_config.dart
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class LogConfig {
  static Level getLogLevel() {
    if (kDebugMode) {
      // 개발 모드: 모든 로그
      return Level.trace;
    } else {
      // 프로덕션: 주요 로그만
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

  /// 모듈별 로그 레벨 설정
  static bool shouldLogModule(String moduleName, Level currentLevel) {
    final moduleLogLevels = {
      'dio': Level.debug,
      'bloc': Level.debug,
      'repository': Level.info,
      'ui': Level.info,
    };

    final requiredLevel = moduleLogLevels[moduleName] ?? Level.info;
    // 높은 index = 높은 severity, currentLevel이 requiredLevel 이상일 때 로깅
    return currentLevel.index >= requiredLevel.index;
  }
}
```

### 로그 용량 관리

```dart
// lib/core/logging/log_rotation.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'app_logger.dart';

class LogRotation {
  static const int maxLogFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxLogFiles = 5;

  static Future<File> getLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final logDir = Directory('${directory.path}/logs');

    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    final dateFormat = DateFormat('yyyy-MM-dd');
    final fileName = 'app_${dateFormat.format(DateTime.now())}.log';

    return File('${logDir.path}/$fileName');
  }

  /// 로그 파일 로테이션 확인
  static Future<void> checkAndRotate() async {
    try {
      final logFile = await getLogFile();

      if (await logFile.exists()) {
        final fileSize = await logFile.length();

        if (fileSize > maxLogFileSizeBytes) {
          // 새 파일로 로테이션
          final timestamp = DateFormat('yyyyMMdd_HHmmss')
              .format(DateTime.now());
          final newName = logFile.path.replaceAll('.log', '_$timestamp.log');
          await logFile.rename(newName);

          AppLogger.info('[LogRotation] Log file rotated');
        }
      }

      // 오래된 로그 파일 삭제
      await _cleanupOldLogs();
    } catch (e) {
      AppLogger.error('[LogRotation] Rotation failed: $e');
    }
  }

  /// 오래된 로그 파일 삭제
  static Future<void> _cleanupOldLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!await logDir.exists()) return;

      final files = logDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.log'))
          .toList();

      if (files.length > maxLogFiles) {
        files.sort((a, b) => b.statSync().modified.compareTo(
              a.statSync().modified,
            ));

        for (int i = maxLogFiles; i < files.length; i++) {
          await files[i].delete();
          AppLogger.debug('[LogRotation] Deleted old log: ${files[i].path}');
        }
      }
    } catch (e) {
      AppLogger.error('[LogRotation] Cleanup failed: $e');
    }
  }
}
```

### 개인정보 보호

```dart
// lib/core/logging/privacy_helper.dart

class PrivacyHelper {
  /// PII (Personally Identifiable Information) 제거
  static String removePII(String input) {
    // 주민등록번호 형식 제거
    input = input.replaceAll(
      RegExp(r'\d{6}-[1-4]\d{6}'),
      'SSN:***',
    );

    // 신용카드 번호 제거
    input = input.replaceAll(
      RegExp(r'\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}'),
      'CARD:***',
    );

    // IP 주소 마스킹
    input = input.replaceAll(
      RegExp(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'),
      'IP:***',
    );

    return input;
  }

  /// 로그 메시지 정제
  static bool isLoggingAllowed(String tag, {required bool isProduction}) {
    if (isProduction) {
      // 프로덕션: 민감한 정보는 로깅 불가
      final restrictedTags = [
        'auth.token',
        'auth.password',
        'user.profile',
        'payment',
      ];
      return !restrictedTags.contains(tag);
    }
    return true;
  }
}
```

---

## 사용 예제

### 통합 예제 - 네트워크 API 호출

```dart
// lib/features/product/data/datasources/product_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/performance_monitor.dart';

class ProductRemoteDataSource {
  final Dio _dio;
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  ProductRemoteDataSource(this._dio);

  Future<List<ProductDto>> getProducts() async {
    return await _performanceMonitor.measure(
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
              {
                'count': products.length,
                'status': response.statusCode,
              },
            );

            return products;
          } else {
            throw Exception('Failed to load products');
          }
        } catch (e, stackTrace) {
          AppLogger.error(
            '[ProductRemoteDataSource] Failed to fetch products',
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

### 통합 예제 - Bloc 사용

```dart
// lib/features/product/presentation/bloc/product_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/logging/app_logger.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase _getProductsUseCase;

  ProductBloc({required GetProductsUseCase getProductsUseCase})
      : _getProductsUseCase = getProductsUseCase,
        super(ProductState.initial()) {
    on<ProductLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    ProductLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    AppLogger.verbose('[ProductBloc._onLoadRequested] Called');
    emit(state.copyWith(isLoading: true));

    final result = await _getProductsUseCase();

    result.fold(
      (failure) {
        AppLogger.warning(
          '[ProductBloc] Load failed: ${failure.toString()}',
        );
        emit(state.copyWith(isLoading: false, failure: failure));
      },
      (products) {
        AppLogger.info(
          '[ProductBloc] Loaded ${products.length} products successfully',
        );
        emit(state.copyWith(isLoading: false, products: products));
      },
    );
  }
}
```

---

## Best Practices

### 로깅 규칙

| 규칙 | 설명 |
|------|------|
| **명확한 태그** | 로그 출처를 명확히 하는 태그 사용 |
| **구조화된 형식** | JSON 형식의 로그 메타데이터 포함 |
| **적절한 레벨** | 로그 심각도에 맞는 레벨 선택 |
| **민감 정보 제외** | 토큰, 비밀번호 등 제외 |
| **성능 고려** | 너무 많은 로깅 피하기 |

### 로깅 체크리스트

```
- [ ] 커스텀 Logger 클래스 구현
- [ ] BlocObserver 등록
- [ ] LoggingInterceptor 등록
- [ ] Crashlytics 초기화
- [ ] RemoteLogger 구현
- [ ] LogRotation 설정
- [ ] 프로덕션 로그 레벨 설정
- [ ] 민감 정보 마스킹 확인
- [ ] 성능 모니터링 통합
- [ ] 로그 저장소 초기화
```

### 안티패턴

```dart
// ❌ 문제: 과도한 로깅
for (int i = 0; i < 10000; i++) {
  AppLogger.debug('Item $i'); // 성능 저하
}

// ✅ 해결: 필요한 정보만 로깅
AppLogger.info('Processing 10000 items', error: null);

// ❌ 문제: 민감 정보 노출
AppLogger.info('User password: $password');

// ✅ 해결: 민감 정보 마스킹
AppLogger.info('User authenticated', error: null);

// ❌ 문제: 예외 처리 부재
AppLogger.info(responseData.toString()); // null일 수 있음

// ✅ 해결: 안전한 로깅
AppLogger.info('Response: ${responseData?.toString() ?? 'null'}', error: null);
```

---

## 트러블슈팅

### 로그가 표시되지 않는 경우

```dart
// 확인 사항:
1. Logger 레벨이 현재 로그 레벨보다 낮은지 확인
2. 릴리즈 모드인 경우 Debug/Verbose 로그는 표시 안 됨
3. BlocObserver가 Bloc.observer에 등록되었는지 확인

// 해결:
AppLogger.debug('Test'); // kDebugMode만 실행
AppLogger.info('Test'); // 항상 실행 (릴리즈 모드 제외)
```

### Crashlytics 데이터가 전송되지 않는 경우

```dart
// 확인:
1. Firebase 프로젝트 설정 확인
2. 개발 모드에서는 자동으로 비활성화됨
3. 실제 디바이스에서 테스트 (에뮬레이터는 전송 불가)

// 테스트:
CrashlyticsService.recordError(
  Exception('Test'),
  StackTrace.current,
);
// 앱 재시작 후 Firebase Console에서 확인
```

### 로그 파일이 너무 크거나 많은 경우

```dart
// LogRotation 설정 확인:
- maxLogFileSizeBytes: 로그 파일 크기 제한
- maxLogFiles: 보관할 로그 파일 개수

// 또는 수동으로 정리:
final logRepo = LogRepository();
await logRepo.deleteLogs(
  beforeDate: DateTime.now().subtract(const Duration(days: 7)),
);
```

---

## 12. Distributed Tracing (분산 추적)

### 12.1 Request ID / Correlation ID

```dart
// lib/core/network/correlation_interceptor.dart
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../logging/app_logger.dart';

class CorrelationInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 모든 요청에 Correlation ID 추가
    final correlationId = const Uuid().v4();
    options.headers['X-Correlation-ID'] = correlationId;
    options.headers['X-Request-ID'] = correlationId;

    // 로그에 Correlation ID 포함
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

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final correlationId = response.requestOptions.headers['X-Correlation-ID'];

    AppLogger.logStructured(
      'API',
      'Response',
      {
        'correlationId': correlationId,
        'statusCode': response.statusCode,
        'duration': '${response.requestOptions.extra['startTime']}ms',
      },
    );

    handler.next(response);
  }
}
```

### 12.2 Sentry 연동

```dart
// pubspec.yaml
dependencies:
  sentry_flutter: ^8.0.0
  sentry_dio: ^8.0.0

// lib/core/logging/sentry_service.dart
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryService {
  static Future<void> init() async {
    await SentryFlutter.init(
      (options) {
        options.dsn = const String.fromEnvironment('SENTRY_DSN');
        options.environment = const String.fromEnvironment('ENV', defaultValue: 'dev');
        options.tracesSampleRate = 0.2; // 20% 샘플링
        options.profilesSampleRate = 0.1; // 10% 프로파일링

        // 민감 정보 필터링
        options.beforeSend = (event, {hint}) {
          return _sanitizeEvent(event);
        };

        // 브레드크럼 커스터마이징
        options.beforeBreadcrumb = (breadcrumb, {hint}) {
          if (breadcrumb?.category == 'http') {
            return _sanitizeBreadcrumb(breadcrumb!);
          }
          return breadcrumb;
        };
      },
      appRunner: () => runApp(const MyApp()),
    );
  }

  static SentryEvent _sanitizeEvent(SentryEvent event) {
    // Authorization 헤더 제거
    // 개인정보 마스킹
    return event;
  }

  /// 브레드크럼에서 민감한 정보 제거
  static Breadcrumb _sanitizeBreadcrumb(Breadcrumb breadcrumb) {
    // Authorization 헤더나 토큰 등 민감한 정보 제거
    final data = breadcrumb.data?.map((key, value) {
      if (key.toLowerCase().contains('auth') ||
          key.toLowerCase().contains('token') ||
          key.toLowerCase().contains('password')) {
        return MapEntry(key, '***REDACTED***');
      }
      return MapEntry(key, value);
    });

    return breadcrumb.copyWith(data: data);
  }

  /// 이메일 마스킹
  static String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    if (username.length <= 2) return email;
    return '${username.substring(0, 2)}***@${parts[1]}';
  }

  /// 사용자 정보 설정
  static void setUser(String userId, String email) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: userId,
        email: _maskEmail(email),
      ));
    });
  }

  /// 에러 보고 (자동 스택트레이스)
  static Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? extras,
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        extras?.forEach((key, value) {
          scope.setExtra(key, value);
        });
      },
    );
  }

  /// 메시지 보고
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
  }) async {
    await Sentry.captureMessage(message, level: level);
  }
}

// Dio에 Sentry 연동
final dio = Dio()
  ..interceptors.add(SentryDioInterceptor()); // sentry_dio 패키지 제공
```

### 12.3 로그 수준별 Sentry 연동

```dart
class AppLogger {
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);

    // Error 이상은 Sentry로 전송
    if (error != null) {
      SentryService.captureException(error, stackTrace: stackTrace);
    }
  }

  static void warning(String message, {Map<String, dynamic>? data}) {
    _logger.w(message);

    // Warning은 브레드크럼으로만 기록
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      level: SentryLevel.warning,
      data: data,
    ));
  }
}
```

---

## 성능 최적화 팁

1. **조건부 로깅**: kDebugMode 활용으로 릴리즈 모드 최적화
2. **버퍼링**: RemoteLogger로 배치 전송
3. **로그 로테이션**: 디스크 공간 관리
4. **비동기 처리**: 로깅 작업을 백그라운드에서 수행
5. **필터링**: 불필요한 로그 제외

---

## 참고자료

- [Logger 패키지](https://pub.dev/packages/logger)
- [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics)
- [Flutter 디버깅 가이드](https://flutter.dev/docs/testing/debugging)

---

## 실습 과제

### 과제 1: 구조화된 로거 구현
로그 레벨(debug, info, warning, error)을 지원하는 LoggerService를 구현하고 DI로 주입하세요.

### 과제 2: BlocObserver 로깅
BlocObserver를 구현하여 모든 Bloc의 이벤트, 상태 변화, 에러를 자동으로 로깅하세요.

## Self-Check

- [ ] 로그 레벨에 따라 출력을 필터링할 수 있는가?
- [ ] 프로덕션 빌드에서 디버그 로그가 노출되지 않는가?
- [ ] BlocObserver로 상태 변화를 추적하고 있는가?
- [ ] Crashlytics에 에러 로그가 정상적으로 전송되는가?
