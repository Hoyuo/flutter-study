# Flutter Networking Guide - Part 1: Dio

> **난이도**: 중급 | **카테고리**: networking
> **선행 학습**: [Architecture](../core/Architecture.md), [ErrorHandling](../core/ErrorHandling.md) | **예상 학습 시간**: 2h

> 이 문서는 Dio를 사용한 네트워크 통신 설정 및 패턴을 설명합니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Dio를 설정하고 RESTful API 통신을 구현할 수 있다
> - Interceptor를 활용한 토큰 갱신, 로깅, 에러 처리를 구현할 수 있다
> - SSL Pinning과 네트워크 보안 설정을 적용할 수 있다

## 1. 개요

### 1.1 Dio란?

Dio는 Flutter/Dart에서 가장 널리 사용되는 HTTP 클라이언트 라이브러리입니다.

| 기능 | 설명 |
|------|------|
| Interceptors | 요청/응답 가로채기 |
| FormData | 파일 업로드 |
| Timeout | 연결/요청 타임아웃 |
| Transformer | 요청/응답 변환 |
| Cancel Token | 요청 취소 |

### 1.2 프로젝트 구조

```
core/
└── core_network/
    └── lib/
        ├── core_network.dart          # Barrel 파일
        └── src/
            ├── dio_client.dart        # Dio 설정
            ├── interceptors/
            │   ├── auth_interceptor.dart
            │   ├── logging_interceptor.dart
            │   ├── error_interceptor.dart
            │   └── retry_interceptor.dart
            ├── exceptions/
            │   └── network_exception.dart
            └── injection.dart
```

## 2. 프로젝트 설정

### 2.1 의존성 추가

```yaml
# core/core_network/pubspec.yaml (2026년 2월 기준)
dependencies:
  dio: ^5.9.1
  pretty_dio_logger: ^1.4.0
  connectivity_plus: ^7.0.0  # List<ConnectivityResult> 반환
  injectable: ^2.7.1
  freezed_annotation: ^3.1.0
  fpdart: ^1.2.0
  crypto: ^3.0.7  # for SSL pinning (sha256)

dev_dependencies:
  injectable_generator: ^2.12.0
  build_runner: ^2.11.0
  freezed: ^3.2.5
```

## 3. Dio Client 설정

### 3.1 기본 Dio Client

```dart
// core/core_network/lib/src/dio_client.dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

abstract class DioClient {
  Dio get dio;
}

@LazySingleton(as: DioClient)
class DioClientImpl implements DioClient {
  // 아래 클래스들은 프로젝트에서 별도 정의 필요:
  // - AppConfig: 환경 설정 (baseUrl 등) - Environment.md 참조
  // - TokenStorage: 토큰 저장소 - LocalStorage.md 참조
  // - AuthService: 인증 서비스 - 프로젝트별 구현
  final AppConfig _config;
  Dio? _dio;

  DioClientImpl(this._config);

  @override
  Dio get dio {
    _dio ??= _createDio();
    return _dio!;
  }

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _config.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    return dio;
  }
}
```

### 3.2 환경별 설정

```dart
// core/core_network/lib/src/config/app_config.dart
import 'package:injectable/injectable.dart';

abstract class AppConfig {
  String get baseUrl;
  bool get enableLogging;
  Duration get timeout;
}

@LazySingleton(as: AppConfig)
@Environment('dev')
class DevConfig implements AppConfig {
  @override
  String get baseUrl => 'https://api.dev.example.com';

  @override
  bool get enableLogging => true;

  @override
  Duration get timeout => const Duration(seconds: 30);
}

@LazySingleton(as: AppConfig)
@Environment('staging')
class StagingConfig implements AppConfig {
  @override
  String get baseUrl => 'https://api.staging.example.com';

  @override
  bool get enableLogging => true;

  @override
  Duration get timeout => const Duration(seconds: 20);
}

@LazySingleton(as: AppConfig)
@Environment('prod')
class ProdConfig implements AppConfig {
  @override
  String get baseUrl => 'https://api.example.com';

  @override
  bool get enableLogging => false;

  @override
  Duration get timeout => const Duration(seconds: 15);
}
```

## 4. Interceptors

### 4.1 Auth Interceptor (토큰 관리)

```dart
// core/core_network/lib/src/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';

// 주의: @injectable 제거 - DioClient에서 수동으로 생성
class AuthInterceptor extends Interceptor {
  final Dio _dio;  // 원본 Dio 참조 (baseUrl 보존용)
  final TokenStorage _tokenStorage;
  final AuthService _authService;
  final AppConfig _config;

  AuthInterceptor(this._dio, this._tokenStorage, this._authService, this._config);

  // ⚠️ 주의: Interceptor의 onRequest/onResponse/onError는 void 반환
  // async 사용 시 에러가 전파되지 않을 수 있음
  // 내부에서 try-catch로 에러 처리 필수
  //
  // ⚠️ async void 경고:
  // - void 반환 타입과 async를 함께 사용하면 에러가 호출자에게 전파되지 않음
  // - 반드시 내부에서 try-catch로 모든 예외를 처리해야 함
  // - Dio의 Interceptor는 void를 요구하므로 이 패턴 불가피
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 토큰이 필요 없는 엔드포인트 스킵
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // 토큰 만료 - 갱신 시도
      final refreshed = await _refreshToken();
      if (refreshed) {
        // 원래 요청 재시도
        final response = await _retry(err.requestOptions);
        return handler.resolve(response);
      } else {
        // 갱신 실패 - 로그아웃 처리
        await _authService.logout();
      }
    }

    handler.next(err);
  }

  bool _isPublicEndpoint(String path) {
    const publicEndpoints = [
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
    ];
    return publicEndpoints.any((e) => path.contains(e));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      // 새 Dio 인스턴스로 갱신 (순환 방지)
      final dio = Dio();
      final response = await dio.post(
        '${_config.baseUrl}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'];
      final newRefreshToken = response.data['refresh_token'];

      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _tokenStorage.getAccessToken();
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );

    // 원본 Dio 사용 (baseUrl 보존)
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
```

### 4.2 Logging Interceptor

```dart
// core/core_network/lib/src/interceptors/logging_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:injectable/injectable.dart';

@injectable
class LoggingInterceptor extends Interceptor {
  final AppConfig _config;

  LoggingInterceptor(this._config);

  /// PrettyDioLogger 인스턴스 반환 (개발 환경에서만 사용)
  Interceptor? get prettyLogger {
    if (!_config.enableLogging || kReleaseMode) {
      return null;
    }

    return PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
    );
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_config.enableLogging && kDebugMode) {
      debugPrint('┌─────────────────────────────────────────────');
      debugPrint('│ [REQUEST] ${options.method} ${options.uri}');
      debugPrint('│ Headers: ${options.headers}');
      if (options.data != null) {
        debugPrint('│ Body: ${options.data}');
      }
      debugPrint('└─────────────────────────────────────────────');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_config.enableLogging && kDebugMode) {
      debugPrint('┌─────────────────────────────────────────────');
      debugPrint('│ [RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('│ Data: ${response.data}');
      debugPrint('└─────────────────────────────────────────────');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_config.enableLogging && kDebugMode) {
      debugPrint('┌─────────────────────────────────────────────');
      debugPrint('│ [ERROR] ${err.type}');
      debugPrint('│ Message: ${err.message}');
      debugPrint('│ Response: ${err.response?.data}');
      debugPrint('└─────────────────────────────────────────────');
    }
    handler.next(err);
  }
}
```

### 4.3 Error Interceptor

```dart
// core/core_network/lib/src/interceptors/error_interceptor.dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@injectable
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final networkException = _mapToNetworkException(err);

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: networkException,
      ),
    );
  }

  NetworkException _mapToNetworkException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException.timeout();

      case DioExceptionType.connectionError:
        return const NetworkException.noConnection();

      case DioExceptionType.badCertificate:
        return const NetworkException.badCertificate();

      case DioExceptionType.badResponse:
        return _handleBadResponse(err.response);

      case DioExceptionType.cancel:
        return const NetworkException.cancelled();

      case DioExceptionType.unknown:
      default:
        return NetworkException.unknown(err.message);
    }
  }

  NetworkException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode ?? 0;
    final data = response?.data;

    // 서버 에러 메시지 추출
    String? serverMessage;
    if (data is Map<String, dynamic>) {
      serverMessage = data['message'] as String? ??
          data['error'] as String? ??
          data['error_description'] as String?;
    }

    switch (statusCode) {
      case 400:
        return NetworkException.badRequest(serverMessage);
      case 401:
        return const NetworkException.unauthorized();
      case 403:
        return const NetworkException.forbidden();
      case 404:
        return const NetworkException.notFound();
      case 409:
        return NetworkException.conflict(serverMessage);
      case 422:
        return NetworkException.validationError(serverMessage);
      case 429:
        return const NetworkException.tooManyRequests();
      case 500:
      case 501:
      case 502:
      case 503:
        return NetworkException.serverError(statusCode, serverMessage);
      default:
        return NetworkException.unknown('Status code: $statusCode');
    }
  }
}
```

### 4.4 Retry Interceptor

```dart
// core/core_network/lib/src/interceptors/retry_interceptor.dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@injectable
class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor(
    this._dio, {
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

      if (retryCount < maxRetries) {
        // 재시도 전 대기 (지수 백오프)
        final delay = Duration(
          milliseconds: retryDelay.inMilliseconds * (retryCount + 1),
        );
        await Future.delayed(delay);

        // 재시도 횟수 증가
        err.requestOptions.extra['retryCount'] = retryCount + 1;

        try {
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          debugPrint('Retry attempt failed: $e');
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500 &&
            err.response!.statusCode! < 600);
  }
}
```

### 4.5 Connectivity Interceptor

```dart
// core/core_network/lib/src/interceptors/connectivity_interceptor.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@injectable
class ConnectivityInterceptor extends Interceptor {
  final Connectivity _connectivity;

  ConnectivityInterceptor(this._connectivity);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    // connectivity_plus 5.0.0+ 대응 (List<ConnectivityResult> 반환)
    final hasConnection = !connectivityResult.contains(ConnectivityResult.none);

    if (!hasConnection) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const NetworkException.noConnection(),
        ),
      );
    }

    handler.next(options);
  }
}
```

### 4.6 SSL Pinning / Certificate Pinning

SSL Pinning은 중간자 공격(MITM)을 방지하기 위해 서버의 인증서를 앱에 고정하는 보안 기법입니다.

#### 4.6.1 http_certificate_pinning 사용

```yaml
# core/core_network/pubspec.yaml
dependencies:
  # SSL Pinning 옵션:
  # Option 1: http_certificate_pinning (권장)
  http_certificate_pinning: ^3.0.1
  # Option 2: 직접 구현 (4.6.3 섹션 참조)
```

```dart
// core/core_network/lib/src/dio_client.dart
import 'package:http_certificate_pinning/http_certificate_pinning.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: DioClient)
class DioClientImpl implements DioClient {
  final AppConfig _config;
  Dio? _dio;

  DioClientImpl(this._config);

  @override
  Dio get dio {
    _dio ??= _createDio();
    return _dio!;
  }

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _config.baseUrl,
        connectTimeout: _config.timeout,
        receiveTimeout: _config.timeout,
        sendTimeout: _config.timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // SSL Pinning 설정 (프로덕션에서만)
    if (_config.enableSslPinning) {
      _configureSslPinning(dio);
    }

    // Interceptors 추가...
    return dio;
  }

  void _configureSslPinning(Dio dio) {
    // http_certificate_pinning 패키지 사용
    // 주의: 아래는 개념적 예시이며, 실제 API는 패키지 문서를 참고하세요.
    // 패키지 문서: https://pub.dev/packages/http_certificate_pinning

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();

      client.badCertificateCallback = (cert, host, port) {
        // SHA-256 핀 검증
        // http_certificate_pinning 패키지의 실제 API를 사용하거나
        // 아래 4.6.3의 수동 구현 방식을 참고하세요.
        final validPins = {
          'api.example.com': [
            'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
            'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
          ],
        };

        // 실제 검증 로직은 패키지 또는 4.6.3 섹션 참조
        return _checkCertificate(cert, host, validPins[host] ?? []);
      };

      return client;
    };
  }

  bool _checkCertificate(dynamic cert, String host, List<String> validPins) {
    // 실제 구현은 4.6.3 섹션의 수동 SSL Pinning 참조
    // 또는 http_certificate_pinning 패키지의 API 사용
    return true; // Placeholder
  }
}
```

#### 4.6.2 인증서 해시 추출 방법

```bash
# OpenSSL로 서버 인증서의 DER 해시 추출 (4.6.3 Dart 코드와 동일 방식)
# 1. 인증서 DER 다운로드 후 SHA-256 해시 계산
openssl s_client -servername api.example.com -connect api.example.com:443 < /dev/null \
  | openssl x509 -outform DER \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64
```

#### 4.6.3 수동 SSL Pinning (패키지 없이 직접 구현)

```dart
import 'dart:io';
import 'dart:convert'; // for base64
import 'package:crypto/crypto.dart'; // for sha256
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void _configureSslPinning(Dio dio) {
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();

    client.badCertificateCallback = (cert, host, port) {
      // PEM에서 DER 바이트 추출 후 SHA-256 해시 계산
      // (4.6.2의 OpenSSL 명령과 동일한 해시 결과)
      final certPem = cert.pem;
      final pemLines = certPem
          .split('\n')
          .where((line) =>
              !line.startsWith('-----') && line.trim().isNotEmpty)
          .join();
      final derBytes = base64.decode(pemLines);
      final certSha256 = sha256.convert(derBytes);
      final certPin = base64.encode(certSha256.bytes);

      // 등록된 핀 목록 (4.6.2 OpenSSL 명령으로 추출한 해시)
      const validPins = [
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
      ];

      // 핀 검증
      if (host == 'api.example.com' && validPins.contains(certPin)) {
        return true;
      }

      // 검증 실패 시 로깅
      debugPrint('SSL Pinning failed for $host');
      debugPrint('Expected pins: $validPins');
      debugPrint('Received pin: $certPin');

      return false;
    };

    return client;
  };
}
```

#### 4.6.4 개발 환경 처리

```dart
// core/core_network/lib/src/config/app_config.dart
abstract class AppConfig {
  String get baseUrl;
  bool get enableLogging;
  bool get enableSslPinning;  // 추가
  Duration get timeout;
}

@LazySingleton(as: AppConfig)
@Environment('dev')
class DevConfig implements AppConfig {
  @override
  String get baseUrl => 'https://api.dev.example.com';

  @override
  bool get enableLogging => true;

  @override
  bool get enableSslPinning => false;  // 개발에서는 비활성화

  @override
  Duration get timeout => const Duration(seconds: 30);
}

@LazySingleton(as: AppConfig)
@Environment('prod')
class ProdConfig implements AppConfig {
  @override
  String get baseUrl => 'https://api.example.com';

  @override
  bool get enableLogging => false;

  @override
  bool get enableSslPinning => true;  // 프로덕션에서 활성화

  @override
  Duration get timeout => const Duration(seconds: 15);
}
```

#### 4.6.5 주의사항

| 항목 | 설명 |
|------|------|
| **인증서 갱신** | 서버 인증서 갱신 시 앱도 업데이트 필요 (여러 핀 등록 권장) |
| **개발 환경** | 로컬/개발 서버는 SSL Pinning 비활성화 |
| **에러 처리** | Pinning 실패 시 명확한 에러 메시지 제공 |
| **백업 핀** | 현재 인증서 + 다음 인증서 핀을 함께 등록 |
| **테스트** | Charles Proxy 등 테스트 도구 사용 불가 |

### 4.7 토큰 갱신 동시성 처리 (Mutex/Lock)

여러 요청이 동시에 401을 받았을 때, 토큰 갱신이 중복으로 실행되는 것을 방지합니다.

#### 4.7.1 Mutex 구현

```dart
// core/core_network/lib/src/utils/mutex.dart
import 'dart:async';

/// 비동기 작업의 동시 실행을 방지하는 Mutex
class Mutex {
  Completer<void>? _completer;

  /// Mutex를 획득하고 작업 실행
  Future<T> acquire<T>(Future<T> Function() operation) async {
    // 이미 잠금이 있으면 대기
    while (_completer != null) {
      await _completer!.future;
    }

    // 새 잠금 생성
    _completer = Completer<void>();

    try {
      // 작업 실행
      return await operation();
    } finally {
      // 잠금 해제
      final completer = _completer;
      _completer = null;
      completer?.complete();
    }
  }

  /// 현재 잠금 상태 확인
  bool get isLocked => _completer != null;
}
```

#### 4.7.2 AuthInterceptor에서 Mutex 사용

```dart
// core/core_network/lib/src/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final AuthService _authService;
  final AppConfig _config;
  final Mutex _refreshMutex = Mutex();  // Mutex 추가

  AuthInterceptor(this._dio, this._tokenStorage, this._authService, this._config);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Mutex로 토큰 갱신 동시성 제어
      final refreshed = await _refreshMutex.acquire(() => _refreshToken());

      if (refreshed) {
        // 원래 요청 재시도
        try {
          final response = await _retry(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // 재시도 실패 시 원래 에러 전달
        }
      } else {
        // 갱신 실패 - 로그아웃 처리
        await _authService.logout();
      }
    }

    handler.next(err);
  }

  bool _isPublicEndpoint(String path) {
    const publicEndpoints = [
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
    ];
    return publicEndpoints.any((e) => path.contains(e));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      debugPrint('[AuthInterceptor] Refreshing token...');

      // 새 Dio 인스턴스로 갱신 (순환 방지)
      final dio = Dio();
      final response = await dio.post(
        '${_config.baseUrl}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'];
      final newRefreshToken = response.data['refresh_token'];

      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      debugPrint('[AuthInterceptor] Token refreshed successfully');
      return true;
    } catch (e) {
      debugPrint('[AuthInterceptor] Token refresh failed: $e');
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _tokenStorage.getAccessToken();
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
```

#### 4.7.3 대안: synchronized 패키지 사용

```dart
// core/core_network/pubspec.yaml
dependencies:
  synchronized: ^3.4.0
```

```dart
// core/core_network/lib/src/interceptors/auth_interceptor.dart
import 'package:synchronized/synchronized.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final AuthService _authService;
  final AppConfig _config;
  final Lock _refreshLock = Lock();  // Lock 사용

  AuthInterceptor(this._dio, this._tokenStorage, this._authService, this._config);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Lock으로 동시성 제어
      final refreshed = await _refreshLock.synchronized(() => _refreshToken());

      if (refreshed) {
        try {
          final response = await _retry(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // 재시도 실패
        }
      } else {
        await _authService.logout();
      }
    }

    handler.next(err);
  }

  // _refreshToken, _retry 메서드는 동일
}
```

#### 4.7.4 시나리오 비교

| 상황 | Mutex 없이 | Mutex 사용 |
|------|----------|-----------|
| 3개 요청 동시 401 | 토큰 갱신 3번 실행 | 토큰 갱신 1번만 실행 |
| 갱신 실패 | 3개 모두 재시도 → 실패 | 1번 갱신 실패 → 모두 로그아웃 |
| 서버 부하 | /auth/refresh 3번 호출 | /auth/refresh 1번만 호출 |
| 갱신 중 새 요청 | 또 갱신 시도 | 갱신 완료 대기 후 새 토큰 사용 |

## 5. Network Exception

### 5.1 Exception 정의 (Freezed)

```dart
// core/core_network/lib/src/exceptions/network_exception.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_exception.freezed.dart';

@freezed
class NetworkException with _$NetworkException implements Exception {
  // Connection Errors
  const factory NetworkException.noConnection() = _NoConnection;
  const factory NetworkException.timeout() = _Timeout;
  const factory NetworkException.cancelled() = _Cancelled;
  const factory NetworkException.badCertificate() = _BadCertificate;

  // Client Errors (4xx)
  const factory NetworkException.badRequest([String? message]) = _BadRequest;
  const factory NetworkException.unauthorized() = _Unauthorized;
  const factory NetworkException.forbidden() = _Forbidden;
  const factory NetworkException.notFound() = _NotFound;
  const factory NetworkException.conflict([String? message]) = _Conflict;
  const factory NetworkException.validationError([String? message]) = _ValidationError;
  const factory NetworkException.tooManyRequests() = _TooManyRequests;

  // Server Errors (5xx)
  const factory NetworkException.serverError(int statusCode, [String? message]) = _ServerError;

  // Unknown
  const factory NetworkException.unknown([String? message]) = _Unknown;

  const NetworkException._();

  /// 사용자에게 표시할 메시지
  String get userMessage => when(
        noConnection: () => '인터넷 연결을 확인해주세요.',
        timeout: () => '요청 시간이 초과되었습니다. 다시 시도해주세요.',
        cancelled: () => '요청이 취소되었습니다.',
        badCertificate: () => '보안 인증서 오류가 발생했습니다.',
        badRequest: (message) => message ?? '잘못된 요청입니다.',
        unauthorized: () => '로그인이 필요합니다.',
        forbidden: () => '접근 권한이 없습니다.',
        notFound: () => '요청한 정보를 찾을 수 없습니다.',
        conflict: (message) => message ?? '요청이 충돌했습니다.',
        validationError: (message) => message ?? '입력값을 확인해주세요.',
        tooManyRequests: () => '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
        serverError: (code, message) => message ?? '서버 오류가 발생했습니다. ($code)',
        unknown: (message) => message ?? '알 수 없는 오류가 발생했습니다.',
      );

  /// 재시도 가능 여부
  bool get isRetryable => maybeWhen(
        timeout: () => true,
        noConnection: () => true,
        serverError: (_, __) => true,
        orElse: () => false,
      );
}
```

## 6. Dio Client 완성

### 6.1 Interceptor 통합

```dart
// core/core_network/lib/src/dio_client.dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: DioClient)
class DioClientImpl implements DioClient {
  final AppConfig _config;
  final TokenStorage _tokenStorage;
  final AuthService _authService;
  final ErrorInterceptor _errorInterceptor;
  final LoggingInterceptor _loggingInterceptor;
  final ConnectivityInterceptor _connectivityInterceptor;

  Dio? _dio;

  DioClientImpl(
    this._config,
    this._tokenStorage,
    this._authService,
    this._errorInterceptor,
    this._loggingInterceptor,
    this._connectivityInterceptor,
  );

  @override
  Dio get dio {
    _dio ??= _createDio();
    return _dio!;
  }

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _config.baseUrl,
        connectTimeout: _config.timeout,
        receiveTimeout: _config.timeout,
        sendTimeout: _config.timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor 순서 중요!
    // 1. Connectivity (연결 체크 먼저)
    dio.interceptors.add(_connectivityInterceptor);

    // 2. Auth (토큰 추가) - Dio 인스턴스를 전달하여 생성
    dio.interceptors.add(
      AuthInterceptor(dio, _tokenStorage, _authService, _config),
    );

    // 3. Retry (재시도 로직)
    dio.interceptors.add(RetryInterceptor(dio));

    // 4. Error (에러 변환)
    dio.interceptors.add(_errorInterceptor);

    // 5. Logging (마지막에 로깅)
    final prettyLogger = _loggingInterceptor.prettyLogger;
    if (prettyLogger != null) {
      dio.interceptors.add(prettyLogger);
    }

    return dio;
  }
}
```

## 7. DataSource에서 사용

### 7.1 기본 사용법

```dart
// features/home/lib/data/datasources/home_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

abstract class HomeRemoteDataSource {
  Future<HomeDto> getHomeData();
  Future<List<HomeItemDto>> getHomeItems({int page = 1, int limit = 20});
  Future<void> updateHomeItem(String id, UpdateHomeItemRequest request);
  Future<void> deleteHomeItem(String id);
}

@LazySingleton(as: HomeRemoteDataSource)
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final Dio _dio;

  HomeRemoteDataSourceImpl(this._dio);

  @override
  Future<HomeDto> getHomeData() async {
    final response = await _dio.get('/api/v1/home');
    return HomeDto.fromJson(response.data);
  }

  @override
  Future<List<HomeItemDto>> getHomeItems({int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      '/api/v1/home/items',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final List<dynamic> items = response.data['items'];
    return items.map((json) => HomeItemDto.fromJson(json)).toList();
  }

  @override
  Future<void> updateHomeItem(String id, UpdateHomeItemRequest request) async {
    await _dio.put(
      '/api/v1/home/items/$id',
      data: request.toJson(),
    );
  }

  @override
  Future<void> deleteHomeItem(String id) async {
    await _dio.delete('/api/v1/home/items/$id');
  }
}
```

### 7.2 Repository에서 에러 처리

```dart
// features/home/lib/data/repositories/home_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _dataSource;
  final HomeMapper _mapper;

  HomeRepositoryImpl(this._dataSource, this._mapper);

  @override
  Future<Either<HomeFailure, HomeData>> getHomeData() async {
    try {
      final dto = await _dataSource.getHomeData();
      return Right(_mapper.toEntity(dto));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return const Left(HomeFailure.unknown());
    }
  }

  HomeFailure _mapDioError(DioException e) {
    final error = e.error;

    // 주의: when()은 모든 케이스 필수, 일부만 처리하려면 maybeWhen() 사용
    if (error is NetworkException) {
      return error.maybeWhen(
        noConnection: () => const HomeFailure.network(),
        timeout: () => const HomeFailure.network(),
        unauthorized: () => const HomeFailure.unauthorized(),
        serverError: (_, message) => HomeFailure.server(message ?? 'Server error'),
        orElse: () => const HomeFailure.unknown(),
      );
    }

    return const HomeFailure.unknown();
  }
}
```

## 8. 파일 업로드

### 8.1 FormData 사용

```dart
// features/profile/lib/data/datasources/profile_remote_datasource.dart
import 'dart:io';
import 'package:dio/dio.dart';

@LazySingleton(as: ProfileRemoteDataSource)
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio _dio;

  ProfileRemoteDataSourceImpl(this._dio);

  @override
  Future<String> uploadProfileImage(File imageFile) async {
    final fileName = imageFile.path.split('/').last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      '/api/v1/profile/image',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    return response.data['image_url'];
  }

  @override
  Future<void> uploadMultipleFiles(List<File> files) async {
    final formData = FormData();

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = file.path.split('/').last;

      formData.files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(file.path, filename: fileName),
        ),
      );
    }

    await _dio.post(
      '/api/v1/files/upload',
      data: formData,
    );
  }
}
```

### 8.2 업로드 진행률 표시

```dart
Future<String> uploadWithProgress(
  File file,
  void Function(int sent, int total) onProgress,
) async {
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(file.path),
  });

  final response = await _dio.post(
    '/api/v1/upload',
    data: formData,
    onSendProgress: onProgress,
  );

  return response.data['url'];
}
```

## 9. 요청 취소

### 9.1 CancelToken 사용

```dart
// features/search/lib/data/datasources/search_remote_datasource.dart
@LazySingleton(as: SearchRemoteDataSource)
class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final Dio _dio;
  CancelToken? _searchCancelToken;

  SearchRemoteDataSourceImpl(this._dio);

  @override
  Future<List<SearchResultDto>> search(String query) async {
    // 이전 요청 취소
    _searchCancelToken?.cancel('New search started');
    _searchCancelToken = CancelToken();

    try {
      final response = await _dio.get(
        '/api/v1/search',
        queryParameters: {'q': query},
        cancelToken: _searchCancelToken,
      );

      final List<dynamic> results = response.data['results'];
      return results.map((json) => SearchResultDto.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // 취소된 요청은 빈 결과 반환 또는 무시
        return [];
      }
      rethrow;
    }
  }

  void cancelSearch() {
    _searchCancelToken?.cancel('Search cancelled by user');
    _searchCancelToken = null;
  }
}
```

## 10. Best Practices

### 10.1 DO (이렇게 하세요)

| 항목 | 설명 |
|------|------|
| Interceptor 순서 | Connectivity → Auth → Retry → Error → Logging |
| 환경별 설정 | BaseUrl, Timeout 등은 환경별로 분리 |
| 타임아웃 설정 | connect, receive, send 모두 설정 |
| 에러 통합 | NetworkException으로 일관된 에러 처리 |
| 취소 토큰 | 검색 등 빈번한 요청에는 CancelToken 사용 |

### 10.2 DON'T (하지 마세요)

```dart
// ❌ Feature에서 직접 Dio 생성
class HomeDataSource {
  final dio = Dio();  // Core에서 주입받아야 함
}

// ❌ 하드코딩된 URL
final response = await dio.get('https://api.example.com/home');

// ❌ 에러 처리 없이 사용
final response = await dio.get('/api/home');
return HomeDto.fromJson(response.data);  // try-catch 필요

// ❌ Interceptor 순서 무시
dio.interceptors.add(loggingInterceptor);  // Logging이 먼저?
dio.interceptors.add(authInterceptor);     // 순서가 중요함
```

## 11. 디버깅 팁

### 11.1 cURL 명령어 출력

```dart
import 'dart:convert';

@injectable
class CurlInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint(_toCurl(options));
    handler.next(options);
  }

  String _toCurl(RequestOptions options) {
    final components = ['curl -X ${options.method}'];

    options.headers.forEach((key, value) {
      components.add("-H '$key: $value'");
    });

    if (options.data != null) {
      components.add("-d '${jsonEncode(options.data)}'");
    }

    components.add("'${options.uri}'");

    return components.join(' \\\n  ');
  }
}
```

### 11.2 응답 시간 측정

```dart
@injectable
class PerformanceInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['startTime'] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra['startTime'] as DateTime;
    final duration = DateTime.now().difference(startTime);
    debugPrint(
      '[PERF] ${response.requestOptions.method} ${response.requestOptions.path} '
      '- ${duration.inMilliseconds}ms',
    );
    handler.next(response);
  }
}
```

## 12. HTTP 캐싱 전략

### 12.1 dio_cache_interceptor 설정

```yaml
# pubspec.yaml
dependencies:
  dio_cache_interceptor: ^4.0.5
  dio_cache_interceptor_hive_store: ^4.0.0
```

```dart
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';

class CachedDioClient {
  late final Dio _dio;
  late final CacheOptions _cacheOptions;

  Future<void> init() async {
    // Hive 기반 영구 캐시 저장소
    final cacheStore = HiveCacheStore(
      await getApplicationDocumentsDirectory().then((d) => d.path),
    );

    _cacheOptions = CacheOptions(
      store: cacheStore,
      policy: CachePolicy.request, // 캐시 먼저, 없으면 네트워크
      maxStale: const Duration(days: 7), // 오프라인 시 7일 된 캐시도 사용
      priority: CachePriority.normal,
      hitCacheOnErrorExcept: [401, 403], // 에러 시 캐시 사용 (인증 에러 제외)
    );

    _dio = Dio()
      ..interceptors.add(DioCacheInterceptor(options: _cacheOptions));
  }

  /// 캐시 정책 오버라이드 가능한 GET
  Future<Response> get(
    String path, {
    CachePolicy? cachePolicy,
    Duration? maxStale,
  }) {
    return _dio.get(
      path,
      options: _cacheOptions
          .copyWith(
            policy: cachePolicy,
            maxStale: maxStale, // 4.x에서는 Nullable 래퍼 불필요 (직접 nullable 전달)
          )
          .toOptions(),
    );
  }
}
```

### 12.2 캐시 정책 종류

```dart
// 1. CachePolicy.request (기본)
// 캐시 있으면 캐시, 없으면 네트워크
await dio.get('/products', options: Options(
  extra: {'cachePolicy': CachePolicy.request},
));

// 2. CachePolicy.forceCache
// 무조건 캐시만 (오프라인 모드)
await dio.get('/products', options: Options(
  extra: {'cachePolicy': CachePolicy.forceCache},
));

// 3. CachePolicy.refresh
// 무조건 네트워크 (Pull-to-refresh)
await dio.get('/products', options: Options(
  extra: {'cachePolicy': CachePolicy.refresh},
));

// 4. CachePolicy.noCache
// 캐시 사용 안함 (민감한 데이터)
await dio.get('/user/profile', options: Options(
  extra: {'cachePolicy': CachePolicy.noCache},
));
```

### 12.3 엔드포인트별 캐시 전략

```dart
class ApiEndpoints {
  // 정적 데이터: 긴 캐시
  static CacheOptions categories = CacheOptions(
    policy: CachePolicy.request,
    maxStale: const Duration(days: 30),
  );

  // 자주 변경: 짧은 캐시
  static CacheOptions products = CacheOptions(
    policy: CachePolicy.request,
    maxStale: const Duration(hours: 1),
  );

  // 사용자 데이터: 캐시 안함
  static CacheOptions userProfile = CacheOptions(
    policy: CachePolicy.noCache,
  );
}

// 사용
await dio.get('/categories', options: ApiEndpoints.categories.toOptions());
```

### 12.4 캐시 무효화

```dart
class CacheManager {
  final CacheStore _store;

  /// 특정 URL 캐시 삭제
  Future<void> invalidate(String path) async {
    await _store.delete(CacheOptions.defaultCacheKeyBuilder(
      RequestOptions(path: path),
    ));
  }

  /// 패턴 매칭으로 캐시 삭제
  Future<void> invalidatePattern(String pattern) async {
    // 상품 관련 모든 캐시 삭제: /products/*
    await _store.deleteFromPath(RegExp(pattern));
  }

  /// 전체 캐시 삭제
  Future<void> clearAll() async {
    await _store.clean();
  }
}

// 상품 수정 후 캐시 무효화
await updateProduct(product);
await cacheManager.invalidate('/products/${product.id}');
await cacheManager.invalidatePattern(r'/products\?.*'); // 목록 캐시도 삭제
```

### 12.5 캐시 헤더 존중

```dart
// 서버의 Cache-Control 헤더 존중
_cacheOptions = CacheOptions(
  policy: CachePolicy.request,
  // 서버 헤더 우선 사용
  maxStale: null, // 서버의 max-age 사용
);

// 응답 헤더 예시:
// Cache-Control: public, max-age=3600
// → 1시간 캐시
```

## 13. 참고

- [Dio 공식 문서](https://pub.dev/packages/dio)
- [Pretty Dio Logger](https://pub.dev/packages/pretty_dio_logger)
- [Connectivity Plus](https://pub.dev/packages/connectivity_plus)
- [dio_cache_interceptor](https://pub.dev/packages/dio_cache_interceptor)
- Part 2: [Retrofit 가이드](./Networking_Retrofit.md)

---

## 실습 과제

### 과제 1: Dio Interceptor 체인 구현
AuthInterceptor(토큰 자동 갱신), LogInterceptor(요청/응답 로깅), ErrorInterceptor(에러 코드별 처리)를 구현하고 체인으로 구성하세요. 토큰 만료 시 자동 갱신 후 재요청하는 로직을 포함해 주세요.

### 과제 2: API 클라이언트 아키텍처 설계
BaseOptions, 환경별 baseUrl 설정, 타임아웃 정책, SSL Pinning을 포함한 프로덕션급 Dio 클라이언트를 Clean Architecture 구조로 구현하세요.

## Self-Check

- [ ] Dio 인스턴스를 설정하고 GET/POST/PUT/DELETE 요청을 구현할 수 있다
- [ ] Interceptor를 작성하고 요청/응답/에러 파이프라인을 구성할 수 있다
- [ ] 토큰 갱신 동시성 처리(Mutex/Lock)를 구현할 수 있다
- [ ] SSL Pinning 설정과 네트워크 보안 기본 사항을 적용할 수 있다
