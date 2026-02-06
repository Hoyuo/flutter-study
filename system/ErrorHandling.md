# Flutter 에러 처리 가이드

## 학습 목표

이 문서를 학습하면 다음을 할 수 있습니다:

1. **Failure sealed class**를 설계하여 에러를 유형별로 분류할 수 있다
2. Dio 에러를 **Exception → Failure로 변환**하는 인터셉터와 Repository 패턴을 구현할 수 있다
3. **ErrorPresenter**를 활용하여 Failure 유형에 따라 적절한 UI(스낵바, 다이얼로그, 전체 화면)로 에러를 표시할 수 있다
4. **Exponential Backoff**와 **Circuit Breaker** 패턴으로 재시도 및 에러 복구 전략을 구현할 수 있다
5. **runZonedGuarded**와 **Error Boundary Widget**을 사용하여 전역 에러를 안전하게 처리할 수 있다

---

## 개요

일관된 에러 처리 전략은 앱의 안정성과 사용자 경험에 중요합니다. Failure 클래스 설계, 에러 분류, UI 표시 패턴, 재시도 로직을 다룹니다.

## Failure 클래스 설계

### 기본 Failure 클래스

```dart
// lib/core/error/failure.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
abstract class Failure with _$Failure {
  const Failure._();

  /// 네트워크 연결 없음
  const factory Failure.network({
    @Default('네트워크 연결을 확인해주세요') String message,
  }) = NetworkFailure;

  /// 서버 에러 (5xx)
  const factory Failure.server({
    @Default('서버 오류가 발생했습니다') String message,
    int? statusCode,
  }) = ServerFailure;

  /// 클라이언트 에러 (4xx)
  const factory Failure.client({
    required String message,
    int? statusCode,
    String? errorCode,
  }) = ClientFailure;

  /// 인증 에러 (401, 403)
  const factory Failure.unauthorized({
    @Default('로그인이 필요합니다') String message,
  }) = UnauthorizedFailure;

  /// 데이터 파싱 에러
  const factory Failure.parsing({
    @Default('데이터 처리 중 오류가 발생했습니다') String message,
  }) = ParsingFailure;

  /// 캐시/로컬 저장소 에러
  const factory Failure.cache({
    @Default('저장소 오류가 발생했습니다') String message,
  }) = CacheFailure;

  /// 유효성 검증 에러
  const factory Failure.validation({
    required String message,
    Map<String, String>? fieldErrors,
  }) = ValidationFailure;

  /// 비즈니스 로직 에러
  const factory Failure.business({
    required String message,
    String? errorCode,
  }) = BusinessFailure;

  /// 타임아웃
  const factory Failure.timeout({
    @Default('요청 시간이 초과되었습니다') String message,
  }) = TimeoutFailure;

  /// 취소됨
  const factory Failure.cancelled({
    @Default('작업이 취소되었습니다') String message,
  }) = CancelledFailure;

  /// 알 수 없는 에러
  const factory Failure.unknown({
    @Default('알 수 없는 오류가 발생했습니다') String message,
    Object? error,
  }) = UnknownFailure;

  /// 재시도 가능 여부
  bool get isRetryable => switch (this) {
        NetworkFailure() => true,
        ServerFailure() => true,
        TimeoutFailure() => true,
        _ => false,
      };

  /// 사용자에게 표시할 메시지
  String get displayMessage => message;

  /// 로그용 상세 메시지
  String get logMessage => switch (this) {
        ServerFailure(:final statusCode) => '$message (status: $statusCode)',
        ClientFailure(:final statusCode, :final errorCode) =>
          '$message (status: $statusCode, code: $errorCode)',
        UnknownFailure(:final error) => '$message (error: $error)',
        _ => message,
      };
}
```

### Exception 클래스

```dart
// lib/core/error/exceptions.dart

/// 서버 예외
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic response;

  const ServerException({
    required this.message,
    this.statusCode,
    this.response,
  });

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

/// 네트워크 예외
class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'Network connection failed']);

  @override
  String toString() => 'NetworkException: $message';
}

/// 캐시 예외
class CacheException implements Exception {
  final String message;

  const CacheException([this.message = 'Cache operation failed']);

  @override
  String toString() => 'CacheException: $message';
}

/// 인증 예외
class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException([this.message = 'Unauthorized']);

  @override
  String toString() => 'UnauthorizedException: $message';
}
```

## Dio 에러 변환

### Error Interceptor

```dart
// lib/core/network/error_interceptor.dart
import 'dart:io';

import 'package:dio/dio.dart';

import '../error/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _mapDioException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
        response: err.response,
      ),
    );
  }

  Exception _mapDioException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('요청 시간이 초과되었습니다');

      case DioExceptionType.connectionError:
        return const NetworkException('네트워크 연결을 확인해주세요');

      case DioExceptionType.badResponse:
        return _handleBadResponse(err.response);

      case DioExceptionType.cancel:
        return const NetworkException('요청이 취소되었습니다');

      case DioExceptionType.unknown:
        if (err.error is SocketException) {
          return const NetworkException('네트워크 연결을 확인해주세요');
        }
        return ServerException(
          message: err.message ?? '알 수 없는 오류가 발생했습니다',
        );
    }
  }

  Exception _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    // 서버 에러 메시지 추출
    String message = '오류가 발생했습니다';
    String? errorCode;

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? message;
      errorCode = data['code']?.toString();
    }

    switch (statusCode) {
      case 400:
        return ServerException(
          message: message,
          statusCode: statusCode,
          response: data,
        );
      case 401:
        return UnauthorizedException(message);
      case 403:
        return UnauthorizedException('접근 권한이 없습니다');
      case 404:
        return ServerException(
          message: '요청한 리소스를 찾을 수 없습니다',
          statusCode: statusCode,
        );
      case 409:
        return ServerException(
          message: message,
          statusCode: statusCode,
        );
      case 422:
        return ServerException(
          message: message,
          statusCode: statusCode,
          response: data,
        );
      case 429:
        return ServerException(
          message: '요청이 너무 많습니다. 잠시 후 다시 시도해주세요',
          statusCode: statusCode,
        );
      case int value when value >= 500:
        return ServerException(
          message: '서버 오류가 발생했습니다',
          statusCode: statusCode,
        );
      default:
        return ServerException(
          message: message,
          statusCode: statusCode,
        );
    }
  }
}
```

### Repository에서 에러 변환

```dart
// lib/features/product/data/repositories/product_repository_impl.dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final products = await _remoteDataSource.getProducts();
      return Right(products);
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } on UnauthorizedException catch (e) {
      return Left(Failure.unauthorized(message: e.message));
    } on ServerException catch (e) {
      if (e.statusCode != null && e.statusCode! >= 500) {
        return Left(Failure.server(
          message: e.message,
          statusCode: e.statusCode,
        ));
      }
      return Left(Failure.client(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString(), error: e));
    }
  }
}
```

### 공통 에러 핸들러

```dart
// lib/core/error/error_handler.dart
import 'package:fpdart/fpdart.dart';

import 'exceptions.dart';
import 'failure.dart';

/// API 호출을 래핑하여 에러를 Failure로 변환
Future<Either<Failure, T>> safeApiCall<T>(
  Future<T> Function() call,
) async {
  try {
    final result = await call();
    return Right(result);
  } on NetworkException catch (e) {
    return Left(Failure.network(message: e.message));
  } on UnauthorizedException catch (e) {
    return Left(Failure.unauthorized(message: e.message));
  } on ServerException catch (e) {
    if (e.statusCode != null && e.statusCode! >= 500) {
      return Left(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
      ));
    }
    return Left(Failure.client(
      message: e.message,
      statusCode: e.statusCode,
    ));
  } on CacheException catch (e) {
    return Left(Failure.cache(message: e.message));
  } on FormatException catch (e) {
    return Left(Failure.parsing(message: e.message));
  } catch (e, stack) {
    // 로깅
    // import 'package:your_app/core/utils/app_logger.dart';
    // 또는 debugPrint 사용: debugPrint('Unexpected error: $e');
    AppLogger.error('Unexpected error', error: e, stackTrace: stack);
    return Left(Failure.unknown(message: e.toString(), error: e));
  }
}

// 사용 예시
class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<Either<Failure, List<Product>>> getProducts() {
    return safeApiCall(() => _remoteDataSource.getProducts());
  }
}
```

## 에러 UI 패턴

### 에러 표시 유형

```dart
// lib/core/error/error_display_type.dart
enum ErrorDisplayType {
  /// 스낵바 (하단에 잠시 표시)
  snackbar,

  /// 토스트 (중앙에 잠시 표시)
  toast,

  /// 다이얼로그 (확인 필요)
  dialog,

  /// 전체 화면 에러
  fullScreen,

  /// 인라인 에러 (필드 아래 등)
  inline,

  /// 표시 안 함 (로깅만)
  silent,
}
```

### Failure별 표시 방법 결정

```dart
// lib/core/error/error_presenter.dart
import 'package:flutter/material.dart';

import 'failure.dart';
import 'error_display_type.dart';

class ErrorPresenter {
  /// Failure 유형에 따른 표시 방법 결정
  static ErrorDisplayType getDisplayType(Failure failure) {
    return switch (failure) {
      NetworkFailure() => ErrorDisplayType.snackbar,
      ServerFailure() => ErrorDisplayType.snackbar,
      TimeoutFailure() => ErrorDisplayType.snackbar,
      UnauthorizedFailure() => ErrorDisplayType.dialog,
      ValidationFailure() => ErrorDisplayType.inline,
      BusinessFailure() => ErrorDisplayType.dialog,
      CancelledFailure() => ErrorDisplayType.silent,
      _ => ErrorDisplayType.snackbar,
    };
  }

  /// 스낵바로 에러 표시
  static void showSnackbar(BuildContext context, Failure failure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure.displayMessage),
        behavior: SnackBarBehavior.floating,
        action: failure.isRetryable
            ? SnackBarAction(
                label: '다시 시도',
                onPressed: () {
                  // 재시도 콜백
                },
              )
            : null,
      ),
    );
  }

  /// 다이얼로그로 에러 표시
  static Future<void> showDialog(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(failure.displayMessage),
        actions: [
          if (failure.isRetryable && onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('다시 시도'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss?.call();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 에러 자동 표시
  static void present(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
  }) {
    final displayType = getDisplayType(failure);

    switch (displayType) {
      case ErrorDisplayType.snackbar:
        showSnackbar(context, failure);
      case ErrorDisplayType.dialog:
        showDialog(context, failure, onRetry: onRetry);
      case ErrorDisplayType.silent:
        // 로깅만
        debugPrint('Silent error: ${failure.logMessage}');
      default:
        showSnackbar(context, failure);
    }
  }
}
```

### 전체 화면 에러 위젯

```dart
// lib/core/widgets/error_view.dart
import 'package:flutter/material.dart';

import '../error/failure.dart';

class ErrorView extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.failure,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(),
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _getTitle(),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              failure.displayMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            if (failure.isRetryable && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    return switch (failure) {
      NetworkFailure() => Icons.wifi_off,
      ServerFailure() => Icons.cloud_off,
      UnauthorizedFailure() => Icons.lock_outline,
      _ => Icons.error_outline,
    };
  }

  String _getTitle() {
    return switch (failure) {
      NetworkFailure() => '네트워크 연결 없음',
      ServerFailure() => '서버 오류',
      UnauthorizedFailure() => '인증 필요',
      TimeoutFailure() => '요청 시간 초과',
      _ => '오류 발생',
    };
  }
}
```

### 빈 상태 위젯

```dart
// lib/core/widgets/empty_view.dart
import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

## Bloc에서 에러 처리

### 상태에 에러 포함

```dart
// lib/features/product/presentation/bloc/product_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/product.dart';

part 'product_state.freezed.dart';

@freezed
class ProductState with _$ProductState {
  const factory ProductState({
    required List<Product> products,
    required bool isLoading,
    Failure? failure,
  }) = _ProductState;

  factory ProductState.initial() => const ProductState(
        products: [],
        isLoading: false,
      );
}

extension ProductStateX on ProductState {
  bool get hasError => failure != null;
  bool get isEmpty => products.isEmpty && !isLoading && !hasError;
  bool get showLoading => isLoading && products.isEmpty;
  bool get showError => hasError && products.isEmpty;
}
```

### Bloc에서 에러 방출

```dart
// lib/features/product/presentation/bloc/product_bloc.dart
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase _getProductsUseCase;

  ProductBloc({required GetProductsUseCase getProductsUseCase})
      : _getProductsUseCase = getProductsUseCase,
        super(ProductState.initial()) {
    on<ProductEvent>((event, emit) async {
      await event.when(
        loaded: () => _onLoaded(emit),
        retried: () => _onRetried(emit),
      );
    });
  }

  Future<void> _onLoaded(Emitter<ProductState> emit) async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _getProductsUseCase();

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        failure: failure,
      )),
      (products) => emit(state.copyWith(
        isLoading: false,
        products: products,
      )),
    );
  }

  Future<void> _onRetried(Emitter<ProductState> emit) async {
    // 재시도 시 에러 클리어하고 다시 로드
    add(const ProductEvent.loaded());
  }
}
```

### UI에서 에러 표시

```dart
class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductBloc, ProductState>(
      // 에러 발생 시 스낵바/다이얼로그 표시
      listener: (context, state) {
        if (state.failure != null && state.products.isNotEmpty) {
          // 데이터가 있으면 스낵바로 표시
          ErrorPresenter.present(
            context,
            state.failure!,
            onRetry: () {
              context.read<ProductBloc>().add(const ProductEvent.retried());
            },
          );
        }
      },
      builder: (context, state) {
        // 로딩
        if (state.showLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 전체 화면 에러 (데이터 없음)
        if (state.showError) {
          return ErrorView(
            failure: state.failure!,
            onRetry: () {
              context.read<ProductBloc>().add(const ProductEvent.retried());
            },
          );
        }

        // 빈 상태
        if (state.isEmpty) {
          return const EmptyView(title: '상품이 없습니다');
        }

        // 데이터 표시
        return ListView.builder(
          itemCount: state.products.length,
          itemBuilder: (context, index) {
            return ProductListTile(product: state.products[index]);
          },
        );
      },
    );
  }
}
```

## 전역 에러 처리

### 인증 에러 전역 처리

```dart
// lib/core/network/auth_error_interceptor.dart
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';

class AuthErrorInterceptor extends Interceptor {
  final AuthBloc _authBloc;
  final GoRouter _router;

  AuthErrorInterceptor(this._authBloc, this._router);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // 토큰 만료 - 로그아웃 처리
      _authBloc.add(const AuthEvent.loggedOut());
      _router.go('/login');
    }
    handler.next(err);
  }
}
```

### 전역 에러 핸들러 (main.dart)

```dart
void main() async {
  // Flutter 에러 핸들링
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // Crashlytics 리포팅
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // 비동기 에러 핸들링
  PlatformDispatcher.instance.onError = (error, stack) {
    // Crashlytics 리포팅
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MyApp());
}
```

## 재시도 패턴

### Retry Mixin

```dart
// lib/core/utils/retry_mixin.dart
import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';

mixin RetryMixin {
  /// 재시도 로직
  Future<Either<Failure, T>> withRetry<T>(
    Future<Either<Failure, T>> Function() operation, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(Failure)? shouldRetry,
  }) async {
    int attempts = 0;

    while (attempts < maxAttempts) {
      final result = await operation();

      if (result.isRight()) {
        return result;
      }

      // fold를 사용한 안전한 접근
      return result.fold(
        (failure) async {
          // 재시도 불가능한 에러
          if (shouldRetry != null && !shouldRetry(failure)) {
            return result;
          }
          if (!failure.isRetryable) {
            return result;
          }

          attempts++;

          if (attempts < maxAttempts) {
            // 지수 백오프
            await Future.delayed(delay * attempts);
            return await operation();
          }

          return result;
        },
        (success) => result,
      );
    }

    return Left(const Failure.network(message: '여러 번 시도했지만 실패했습니다'));
  }
}
```

### UseCase에서 재시도

```dart
class GetProductsUseCase with RetryMixin {
  final ProductRepository _repository;

  GetProductsUseCase(this._repository);

  Future<Either<Failure, List<Product>>> call({bool retry = false}) async {
    if (retry) {
      return withRetry(
        () => _repository.getProducts(),
        maxAttempts: 3,
      );
    }
    return _repository.getProducts();
  }
}
```

## 테스트

### Failure 테스트

```dart
void main() {
  group('Failure', () {
    test('network failure should be retryable', () {
      const failure = Failure.network();
      expect(failure.isRetryable, true);
    });

    test('validation failure should not be retryable', () {
      const failure = Failure.validation(message: 'Invalid input');
      expect(failure.isRetryable, false);
    });

    test('server failure should have correct log message', () {
      const failure = Failure.server(message: 'Error', statusCode: 500);
      expect(failure.logMessage, contains('500'));
    });
  });
}
```

### Repository 에러 테스트

```dart
void main() {
  late ProductRepositoryImpl repository;
  late MockProductRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockProductRemoteDataSource();
    repository = ProductRepositoryImpl(mockDataSource);
  });

  test('should return network failure when network error', () async {
    when(() => mockDataSource.getProducts())
        .thenThrow(const NetworkException());

    final result = await repository.getProducts();

    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (success) => fail('Should return failure'),
    );
  });

  test('should return server failure when server error', () async {
    when(() => mockDataSource.getProducts())
        .thenThrow(const ServerException(message: 'Error', statusCode: 500));

    final result = await repository.getProducts();

    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure, isA<ServerFailure>()),
      (success) => fail('Should return failure'),
    );
  });
}
```

## 에러 복구 전략

앱이 에러 상황에서도 사용 가능한 상태를 유지하도록 하는 복구 전략을 구현합니다.

### 1. Fallback 데이터 패턴

네트워크 요청 실패 시 캐시된 데이터를 반환하여 사용자 경험을 유지합니다.

```dart
// lib/features/product/data/repositories/product_repository_impl.dart
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;

  ProductRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      // 1. 원격 데이터 요청
      final remote = await _remoteDataSource.getProducts();

      // 2. 성공 시 로컬에 캐시
      await _localDataSource.cacheProducts(remote);

      return Right(remote);
    } catch (e) {
      // 3. 네트워크 실패 시 캐시 데이터 반환
      try {
        final cached = await _localDataSource.getCachedProducts();

        if (cached.isNotEmpty) {
          // 캐시된 데이터가 있으면 반환 (오래된 데이터라도 표시)
          return Right(cached);
        }
      } catch (_) {
        // 캐시 조회 실패는 무시
      }

      // 4. 캐시도 없으면 에러 반환
      return Left(Failure.network());
    }
  }

  @override
  Future<Either<Failure, Product>> getProductDetail(String id) async {
    try {
      final remote = await _remoteDataSource.getProductDetail(id);
      await _localDataSource.cacheProduct(remote);
      return Right(remote);
    } on NetworkException {
      // Fallback to cache
      final cached = await _localDataSource.getCachedProduct(id);
      if (cached != null) {
        return Right(cached);
      }
      return Left(Failure.network());
    } on ServerException catch (e) {
      return Left(Failure.server(message: e.message));
    }
  }
}
```

### 2. 오프라인 모드 전략

네트워크 상태를 감지하고 오프라인 시 사용자에게 알립니다.

```dart
// pubspec.yaml
dependencies:
  connectivity_plus: ^5.0.0

// lib/core/network/network_info.dart
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfoImpl(this._connectivity);

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}

// lib/core/widgets/offline_banner.dart
import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.orange[700],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Text(
            '오프라인 모드 - 캐시된 데이터를 표시합니다',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// lib/features/product/presentation/bloc/product_bloc.dart
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase _getProductsUseCase;
  final NetworkInfo _networkInfo;

  ProductBloc({
    required GetProductsUseCase getProductsUseCase,
    required NetworkInfo networkInfo,
  })  : _getProductsUseCase = getProductsUseCase,
        _networkInfo = networkInfo,
        super(ProductState.initial()) {
    on<ProductEvent>((event, emit) async {
      await event.when(
        loaded: () => _onLoaded(emit),
        connectivityChanged: (isOnline) => _onConnectivityChanged(emit, isOnline),
      );
    });

    // 네트워크 상태 변화 감지
    _networkInfo.onConnectivityChanged.listen((results) {
      add(ProductEvent.connectivityChanged(!results.contains(ConnectivityResult.none)));
    });
  }

  Future<void> _onLoaded(Emitter<ProductState> emit) async {
    final isOnline = await _networkInfo.isConnected;

    emit(state.copyWith(
      isLoading: true,
      isOffline: !isOnline,
    ));

    final result = await _getProductsUseCase();

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        failure: failure,
      )),
      (products) => emit(state.copyWith(
        isLoading: false,
        products: products,
      )),
    );
  }

  void _onConnectivityChanged(Emitter<ProductState> emit, bool isOnline) {
    emit(state.copyWith(isOffline: !isOnline));

    // 온라인 복귀 시 자동 새로고침
    if (isOnline && state.failure != null) {
      add(const ProductEvent.loaded());
    }
  }
}

// lib/features/product/presentation/pages/product_list_page.dart
class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('상품 목록')),
      body: Column(
        children: [
          // 오프라인 배너
          BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state.isOffline) {
                return const OfflineBanner();
              }
              return const SizedBox.shrink();
            },
          ),
          // 상품 목록
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                // ... 기존 코드
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. Circuit Breaker 패턴

연속된 실패 발생 시 일정 시간 동안 요청을 차단하여 시스템 부하를 줄입니다.

```dart
// lib/core/network/circuit_breaker.dart
enum CircuitBreakerState {
  closed,  // 정상 작동
  open,    // 차단됨
  halfOpen, // 테스트 중
}

class CircuitBreaker {
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  CircuitBreakerState _state = CircuitBreakerState.closed;

  final int threshold; // 실패 임계값
  final Duration resetTimeout; // 차단 시간
  final int halfOpenMaxAttempts; // halfOpen 상태에서 테스트 횟수

  CircuitBreaker({
    this.threshold = 5,
    this.resetTimeout = const Duration(minutes: 1),
    this.halfOpenMaxAttempts = 3,
  });

  bool get isOpen => _state == CircuitBreakerState.open;
  CircuitBreakerState get state => _state;

  /// 요청 실행 전 체크
  bool canAttempt() {
    if (_state == CircuitBreakerState.closed) {
      return true;
    }

    if (_state == CircuitBreakerState.open) {
      // 타임아웃 경과 여부 확인
      if (_lastFailureTime != null &&
          DateTime.now().difference(_lastFailureTime!) >= resetTimeout) {
        _state = CircuitBreakerState.halfOpen;
        _successCount = 0;
        return true;
      }
      return false;
    }

    // halfOpen 상태
    return true;
  }

  /// 성공 기록
  void recordSuccess() {
    _failureCount = 0;

    if (_state == CircuitBreakerState.halfOpen) {
      _successCount++;
      if (_successCount >= halfOpenMaxAttempts) {
        _state = CircuitBreakerState.closed;
        _successCount = 0;
      }
    }
  }

  /// 실패 기록
  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_state == CircuitBreakerState.halfOpen) {
      _state = CircuitBreakerState.open;
      _successCount = 0;
      return;
    }

    if (_failureCount >= threshold) {
      _state = CircuitBreakerState.open;
    }
  }

  /// 상태 초기화
  void reset() {
    _failureCount = 0;
    _successCount = 0;
    _lastFailureTime = null;
    _state = CircuitBreakerState.closed;
  }
}

// lib/core/network/circuit_breaker_interceptor.dart
import 'package:dio/dio.dart';

class CircuitBreakerInterceptor extends Interceptor {
  final CircuitBreaker _circuitBreaker;

  CircuitBreakerInterceptor(this._circuitBreaker);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_circuitBreaker.canAttempt()) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: Exception('Circuit breaker is open'),
          type: DioExceptionType.cancel,
        ),
      );
      return;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _circuitBreaker.recordSuccess();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 5xx 에러만 circuit breaker에 기록
    if (err.response?.statusCode != null && err.response!.statusCode! >= 500) {
      _circuitBreaker.recordFailure();
    }
    handler.next(err);
  }
}

// lib/core/di/injection.dart
@module
abstract class NetworkModule {
  @singleton
  CircuitBreaker provideCircuitBreaker() => CircuitBreaker(
        threshold: 5,
        resetTimeout: const Duration(minutes: 1),
      );

  @singleton
  Dio provideDio(CircuitBreaker circuitBreaker) {
    final dio = Dio(BaseOptions(
      baseUrl: Environment.apiUrl,
      connectTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.addAll([
      CircuitBreakerInterceptor(circuitBreaker),
      ErrorInterceptor(),
      LogInterceptor(),
    ]);

    return dio;
  }
}
```

### 4. Graceful Degradation

핵심 기능은 유지하면서 부가 기능을 비활성화하여 제한된 환경에서도 앱을 사용할 수 있게 합니다.

```dart
// lib/core/utils/feature_flags.dart
class FeatureFlags {
  static bool _isOnline = true;
  static bool _hasLocationPermission = false;

  /// 네트워크 상태
  static bool get isOnline => _isOnline;
  static set isOnline(bool value) => _isOnline = value;

  /// 위치 권한
  static bool get hasLocationPermission => _hasLocationPermission;
  static set hasLocationPermission(bool value) => _hasLocationPermission = value;

  /// 실시간 기능 사용 가능 여부
  static bool get canUseRealtimeFeatures => _isOnline;

  /// 위치 기반 기능 사용 가능 여부
  static bool get canUseLocationFeatures => _hasLocationPermission;

  /// 이미지 업로드 가능 여부
  static bool get canUploadImages => _isOnline;

  /// 추천 기능 사용 가능 여부 (AI 기반)
  static bool get canUseRecommendations => _isOnline;
}

// lib/features/product/presentation/pages/product_detail_page.dart
class ProductDetailPage extends StatelessWidget {
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 기본 정보 (항상 표시)
            ProductInfoSection(product: product),

            // 추천 상품 (온라인일 때만)
            if (FeatureFlags.canUseRecommendations)
              RecommendedProductsSection(productId: product.id)
            else
              _buildFeatureDisabledCard(
                '추천 상품',
                '이 기능은 온라인 상태에서만 사용할 수 있습니다',
              ),

            // 리뷰 (온라인일 때만)
            if (FeatureFlags.isOnline)
              ProductReviewsSection(productId: product.id)
            else
              _buildFeatureDisabledCard(
                '상품 리뷰',
                '리뷰를 보려면 인터넷 연결이 필요합니다',
              ),

            // 구매 버튼 (항상 표시, 오프라인 시 장바구니에만 추가)
            PurchaseButton(
              product: product,
              isOnline: FeatureFlags.isOnline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureDisabledCard(String title, String message) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5. Retry with Exponential Backoff

재시도 간격을 점진적으로 늘려 서버 부하를 줄이고 성공 가능성을 높입니다.

```dart
// lib/core/utils/exponential_backoff.dart
import 'dart:math';

import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';

class ExponentialBackoff {
  final int maxAttempts;
  final Duration initialDelay;
  final int multiplier;
  final Duration maxDelay;
  final bool jitter; // Thundering herd 방지

  ExponentialBackoff({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.multiplier = 2,
    this.maxDelay = const Duration(seconds: 30),
    this.jitter = true,
  });

  /// 재시도 실행
  Future<Either<Failure, T>> execute<T>(
    Future<Either<Failure, T>> Function() operation, {
    bool Function(Failure)? shouldRetry,
  }) async {
    int attempt = 0;

    while (true) {
      attempt++;

      final result = await operation();

      // 성공
      if (result.isRight()) {
        return result;
      }

      // fold를 사용한 안전한 접근
      final shouldContinue = result.fold(
        (failure) {
          // 재시도 불가능한 에러
          if (shouldRetry != null && !shouldRetry(failure)) {
            return false;
          }
          if (!failure.isRetryable) {
            return false;
          }
          return true;
        },
        (success) => false,
      );

      if (!shouldContinue) {
        return result;
      }

      // 최대 시도 횟수 도달
      if (attempt >= maxAttempts) {
        return Left(Failure.network(
          message: '$maxAttempts번 시도했지만 실패했습니다',
        ));
      }

      // 지연 시간 계산 (지수 백오프)
      final delay = _calculateDelay(attempt);
      await Future.delayed(delay);
    }
  }

  Duration _calculateDelay(int attempt) {
    // 기본 지연: initialDelay * (multiplier ^ (attempt - 1))
    final exponentialDelay = initialDelay * pow(multiplier, attempt - 1);

    // maxDelay 제한
    var delay = exponentialDelay > maxDelay ? maxDelay : exponentialDelay;

    // Jitter 추가 (0~25% 랜덤 변동)
    if (jitter) {
      final random = Random();
      final jitterAmount = delay.inMilliseconds * (random.nextDouble() * 0.25);
      delay = Duration(
        milliseconds: delay.inMilliseconds + jitterAmount.toInt(),
      );
    }

    return delay;
  }
}

// lib/core/utils/retry_extensions.dart
import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';
import 'exponential_backoff.dart';

extension RetryExtension<T> on Future<Either<Failure, T>> Function() {
  /// Exponential backoff로 재시도
  Future<Either<Failure, T>> withExponentialBackoff({
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    bool Function(Failure)? shouldRetry,
  }) {
    final backoff = ExponentialBackoff(
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
    );

    return backoff.execute(this, shouldRetry: shouldRetry);
  }
}

// lib/features/product/data/repositories/product_repository_impl.dart
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<Product>>> getProducts({
    bool enableRetry = true,
  }) async {
    if (!enableRetry) {
      return safeApiCall(() => _remoteDataSource.getProducts());
    }

    // Exponential backoff로 재시도
    return (() => safeApiCall(() => _remoteDataSource.getProducts()))
        .withExponentialBackoff(
      maxAttempts: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: (failure) {
        // NetworkFailure와 ServerFailure만 재시도
        return failure is NetworkFailure || failure is ServerFailure;
      },
    );
  }
}

// lib/core/utils/retry_mixin.dart (기존 코드 개선)
mixin RetryMixin {
  /// 재시도 로직 (Exponential Backoff 적용)
  Future<Either<Failure, T>> withRetry<T>(
    Future<Either<Failure, T>> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    bool Function(Failure)? shouldRetry,
  }) {
    return operation.withExponentialBackoff(
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
      shouldRetry: shouldRetry,
    );
  }
}
```

## 14. 전역 에러 핸들링 (runZonedGuarded)

### 14.1 main.dart 설정

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  // 1. Zone 기반 전역 에러 캐치
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 2. Flutter 프레임워크 에러 핸들링
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _reportError(details.exception, details.stack);
      };

      // 3. PlatformDispatcher 에러 (플랫폼 채널 등)
      PlatformDispatcher.instance.onError = (error, stack) {
        _reportError(error, stack);
        return true; // 에러 처리됨
      };

      await _initializeApp();
      runApp(const MyApp());
    },
    // 4. 캐치되지 않은 비동기 에러
    (error, stackTrace) {
      _reportError(error, stackTrace);
    },
  );
}

void _reportError(Object error, StackTrace? stack) {
  // 개발 모드에서는 콘솔 출력
  if (kDebugMode) {
    debugPrint('ERROR: $error');
    debugPrint('STACK: $stack');
    return;
  }

  // 프로덕션에서는 Crashlytics/Sentry로 전송
  FirebaseCrashlytics.instance.recordError(
    error,
    stack,
    fatal: true,
  );
}
```

### 14.2 에러 유형별 처리

```dart
void _handleError(Object error, StackTrace? stack) {
  // 네트워크 에러는 무시 (사용자에게 이미 표시됨)
  if (error is DioException) return;

  // 취소된 작업은 무시
  if (error is CancelledException) return;

  // 의도적인 에러는 무시
  if (error is UserCancelledException) return;

  // 그 외 에러는 리포팅
  _reportError(error, stack);
}
```

## 15. Error Boundary Widget

### 15.1 ErrorBoundary 구현

```dart
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stack)? errorBuilder;
  final void Function(Object error, StackTrace? stack)? onError;

  const ErrorBoundary({
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    // ⚠️ 주의: 이 위젯은 FlutterError.onError를 전역으로 오버라이드합니다.
    // main()에서 설정한 다른 에러 핸들러와 충돌할 수 있습니다.
    // 프로덕션에서는 ErrorWidget.builder 사용을 권장합니다.
    // 이 위젯 하위에서 발생하는 에러 캐치
    FlutterError.onError = (details) {
      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });
      widget.onError?.call(details.exception, details.stack);
    };
  }

  void _reset() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!, _stackTrace) ??
          _DefaultErrorWidget(
            error: _error!,
            onRetry: _reset,
          );
    }
    return widget.child;
  }
}
```

### 15.2 기본 에러 위젯

```dart
class _DefaultErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '문제가 발생했습니다',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              kDebugMode ? error.toString() : '잠시 후 다시 시도해주세요',
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 15.3 사용 예시

```dart
// 특정 화면을 Error Boundary로 감싸기
class ProductDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: (error, stack) {
        AnalyticsService.logError('product_detail_error', error);
      },
      errorBuilder: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('상품 상세')),
        body: ErrorView(
          message: '상품 정보를 불러올 수 없습니다',
          onRetry: () => context.read<ProductBloc>().add(
            const ProductEvent.load(),
          ),
        ),
      ),
      child: _ProductDetailContent(),
    );
  }
}
```

### 15.4 글로벌 ErrorWidget 커스터마이징

```dart
void main() {
  // 릴리즈 모드에서 빨간 에러 화면 대신 커스텀 위젯 표시
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }
    return const Scaffold(
      body: Center(
        child: Text('오류가 발생했습니다.\n앱을 다시 시작해주세요.'),
      ),
    );
  };

  runApp(const MyApp());
}
```

## 체크리스트

- [ ] Failure sealed class 정의 (유형별 분류)
- [ ] Exception 클래스 정의
- [ ] Dio ErrorInterceptor 구현
- [ ] Repository에서 Exception → Failure 변환
- [ ] safeApiCall 헬퍼 함수
- [ ] ErrorPresenter로 UI 표시 방법 결정
- [ ] ErrorView 전체 화면 에러 위젯
- [ ] EmptyView 빈 상태 위젯
- [ ] Bloc State에 Failure 포함
- [ ] BlocConsumer로 에러 리스닝 및 표시
- [ ] 인증 에러 전역 처리 (401 → 로그아웃)
- [ ] 재시도 패턴 구현
- [ ] Crashlytics 연동
- [ ] 에러 처리 테스트
- [ ] Fallback 데이터 패턴 구현
- [ ] 오프라인 모드 감지 및 UI 표시
- [ ] Circuit Breaker 패턴 구현
- [ ] Graceful Degradation 적용
- [ ] Exponential Backoff 재시도 전략
- [ ] runZonedGuarded 전역 에러 핸들링
- [ ] Error Boundary Widget 구현
- [ ] 글로벌 ErrorWidget 커스터마이징

---

## 실습 과제

### 과제 1: 커스텀 Failure 클래스 설계
기존 Failure 클래스를 참고하여, **결제(Payment)** 도메인에 맞는 PaymentFailure sealed class를 설계하세요.
- `insufficientBalance`: 잔액 부족
- `cardDeclined`: 카드 거절
- `paymentTimeout`: 결제 시간 초과
- `duplicatePayment`: 중복 결제
- 각 유형별로 `isRetryable`, `displayMessage`를 적절히 구현하세요.

### 과제 2: safeApiCall + Exponential Backoff 통합
`safeApiCall` 헬퍼 함수와 `ExponentialBackoff` 클래스를 결합하여, 네트워크 요청 시 자동으로 재시도하는 `safeApiCallWithRetry<T>()` 함수를 구현하세요.
- 최대 3회 재시도, 초기 지연 1초, jitter 적용
- `NetworkFailure`와 `ServerFailure`만 재시도
- 재시도 횟수를 로깅하세요.

### 과제 3: 에러 UI 통합 페이지 구현
`BlocConsumer`를 활용하여 다음 상태를 모두 처리하는 페이지를 구현하세요.
- 로딩 중: `CircularProgressIndicator`
- 데이터 없음: `EmptyView`
- 네트워크 에러 (데이터 없음): `ErrorView` + 재시도 버튼
- 네트워크 에러 (캐시 데이터 있음): 스낵바 표시 + 캐시 데이터 유지
- 인증 에러: 다이얼로그 표시 후 로그인 화면으로 이동

---

## Self-Check 퀴즈

학습한 내용을 점검해 보세요:

- [ ] `Exception`과 `Failure`의 역할 차이를 설명할 수 있는가? (Exception은 데이터 레이어, Failure는 도메인 레이어)
- [ ] `ErrorPresenter`에서 Failure 유형별로 스낵바/다이얼로그/사일런트 중 어떤 방식을 선택하는지 설명할 수 있는가?
- [ ] Circuit Breaker 패턴의 세 가지 상태(closed, open, halfOpen)와 전환 조건을 설명할 수 있는가?
- [ ] `runZonedGuarded`와 `FlutterError.onError`의 차이점을 설명할 수 있는가?
- [ ] Exponential Backoff에서 jitter를 추가하는 이유(Thundering Herd 방지)를 설명할 수 있는가?
