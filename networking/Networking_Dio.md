# Flutter Networking Guide - Part 1: Dio

> 이 문서는 Dio를 사용한 네트워크 통신 설정 및 패턴을 설명합니다.

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
# core/core_network/pubspec.yaml (2026년 1월 기준)
dependencies:
  dio: ^5.9.0
  pretty_dio_logger: ^1.4.0
  connectivity_plus: ^6.0.0  # List<ConnectivityResult> 반환
  injectable: ^2.7.1
  freezed_annotation: ^3.1.0
  fpdart: ^1.2.0

dev_dependencies:
  injectable_generator: ^2.12.0
  build_runner: ^2.10.5
  freezed: ^3.2.4
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
        // 재시도 전 대기
        await Future.delayed(retryDelay * (retryCount + 1));

        // 재시도 횟수 증가
        err.requestOptions.extra['retryCount'] = retryCount + 1;

        try {
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // 재시도 실패 시 다음 인터셉터로 전달
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

## 12. 참고

- [Dio 공식 문서](https://pub.dev/packages/dio)
- [Pretty Dio Logger](https://pub.dev/packages/pretty_dio_logger)
- [Connectivity Plus](https://pub.dev/packages/connectivity_plus)
- Part 2: [Retrofit 가이드](./Networking_Retrofit.md)
