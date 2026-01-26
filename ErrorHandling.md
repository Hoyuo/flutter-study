# Flutter 에러 처리 가이드

## 개요

일관된 에러 처리 전략은 앱의 안정성과 사용자 경험에 중요합니다. Failure 클래스 설계, 에러 분류, UI 표시 패턴, 재시도 로직을 다룹니다.

## Failure 클래스 설계

### 기본 Failure 클래스

```dart
// lib/core/error/failure.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
sealed class Failure with _$Failure {
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

      default:
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
      case >= 500:
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
    print('Unexpected error: $e\n$stack');
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

      final failure = result.getLeft().toNullable()!;

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
      }
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
    expect(
      result.getLeft().toNullable(),
      isA<NetworkFailure>(),
    );
  });

  test('should return server failure when server error', () async {
    when(() => mockDataSource.getProducts())
        .thenThrow(const ServerException(message: 'Error', statusCode: 500));

    final result = await repository.getProducts();

    expect(result.isLeft(), true);
    expect(
      result.getLeft().toNullable(),
      isA<ServerFailure>(),
    );
  });
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
