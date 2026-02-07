# Flutter Functional Programming with fpdart

> **Package Versions (2025-01 기준)**
> - fpdart: ^1.2.0

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Either<Failure, Success> 패턴을 사용하여 명시적으로 에러를 처리할 수 있습니다
> - Repository와 UseCase에서 Either를 반환하고 Bloc에서 fold로 처리할 수 있습니다
> - Option, TaskEither, Unit 등 함수형 타입을 실무에 적용할 수 있습니다
> 이 문서는 fpdart 라이브러리를 사용한 함수형 프로그래밍 패턴을 설명합니다.

---

## 1. 개요

### 1.1 fpdart란?

fpdart는 Dart/Flutter에서 함수형 프로그래밍을 지원하는 라이브러리입니다.

| 타입 | 용도 | 비유 |
|------|------|------|
| `Either<L, R>` | 성공/실패 표현 | Result 타입 |
| `Option<T>` | 값 있음/없음 표현 | nullable 대체 |
| `TaskEither<L, R>` | 비동기 Either | Future + Either |
| `Unit` | 반환값 없음 표현 | void 대체 |

### 1.2 왜 fpdart를 사용할까?

```dart
// ❌ 예외 기반 (전통적 방식)
Future<User> getUser(String id) async {
  try {
    final response = await api.getUser(id);
    return User.fromJson(response);
  } catch (e) {
    throw UserException(e.toString());  // 어디서 처리?
  }
}

// ✅ Either 기반 (함수형)
Future<Either<UserFailure, User>> getUser(String id) async {
  try {
    final response = await api.getUser(id);
    return Right(User.fromJson(response));  // 성공
  } catch (e) {
    return Left(UserFailure.fromException(e));  // 실패
  }
}
```

### 1.3 장점

```
Either 기반 에러 처리
├── 명시적 에러 타입 (컴파일 타임 체크)
├── 에러 전파 없음 (호출자가 명시적 처리)
├── 체이닝 가능 (flatMap, map)
└── 테스트 용이 (예외 없이 값으로 처리)
```

## 2. 프로젝트 설정

### 2.1 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  fpdart: ^1.2.0  # stable, v2.0 개발 중
```

> **참고:** fpdart v2.0은 현재 개발 중 (`2.0.0-dev.x`)입니다. `Effect` 클래스 기반의 완전히 새로운 API를 제공합니다. 프로덕션에서는 1.x stable을 사용하세요.

## 3. Either

### 3.1 기본 개념

```dart
import 'package:fpdart/fpdart.dart';

// Either<L, R>
// L = Left = 실패 타입
// R = Right = 성공 타입

Either<String, int> divide(int a, int b) {
  if (b == 0) {
    return const Left('Cannot divide by zero');  // 실패
  }
  return Right(a ~/ b);  // 성공
}

// 사용
final result = divide(10, 2);
result.fold(
  (error) => print('Error: $error'),
  (value) => print('Result: $value'),
);
```

### 3.2 Repository에서 사용

```dart
// features/user/lib/domain/repositories/user_repository.dart
import 'package:fpdart/fpdart.dart';

abstract class UserRepository {
  Future<Either<UserFailure, User>> getUser(String id);
  Future<Either<UserFailure, List<User>>> getUsers();
  Future<Either<UserFailure, Unit>> updateUser(User user);
  Future<Either<UserFailure, Unit>> deleteUser(String id);
}
```

```dart
// features/user/lib/data/repositories/user_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _dataSource;
  final UserMapper _mapper;

  UserRepositoryImpl(this._dataSource, this._mapper);

  @override
  Future<Either<UserFailure, User>> getUser(String id) async {
    try {
      final dto = await _dataSource.getUser(id);
      return Right(_mapper.toEntity(dto));
    // import 'package:dio/dio.dart';
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return const Left(UserFailure.unknown());
    }
  }

  @override
  Future<Either<UserFailure, Unit>> updateUser(User user) async {
    try {
      await _dataSource.updateUser(_mapper.toDto(user));
      return const Right(unit);  // 성공, 반환값 없음
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return const Left(UserFailure.unknown());
    }
  }

  UserFailure _mapDioError(DioException e) {
    // 에러 매핑 로직
    return const UserFailure.network();
  }
}
```

### 3.3 유틸리티 생성자

```dart
// tryCatch - 예외를 Either로 변환
final result = Either.tryCatch(
  () => int.parse(input),
  (error, stackTrace) => 'Invalid number: $input',
);

// fromNullable - nullable을 Either로 변환
final either = Either<String, User>.fromNullable(
  nullableValue,
  () => 'Value was null',
);

// fromOption - Option을 Either로 변환
final either = someOption.toEither(() => 'Option was None');
```

### 3.4 UseCase에서 사용

```dart
// features/user/lib/domain/usecases/get_user_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetUserUseCase {
  final UserRepository _repository;

  GetUserUseCase(this._repository);

  Future<Either<UserFailure, User>> call(String id) {
    return _repository.getUser(id);
  }
}
```

### 3.5 Bloc에서 Either 처리

```dart
// features/user/lib/presentation/bloc/user_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserUseCase _getUserUseCase;

  UserBloc(this._getUserUseCase) : super(const UserState.initial()) {
    on<UserEvent>(_onEvent);
  }

  Future<void> _onEvent(UserEvent event, Emitter<UserState> emit) async {
    await event.when(
      started: (userId) => _onStarted(userId, emit),
    );
  }

  Future<void> _onStarted(String userId, Emitter<UserState> emit) async {
    emit(const UserState.loading());

    final result = await _getUserUseCase(userId);

    // fold로 성공/실패 처리
    result.fold(
      (failure) => emit(UserState.error(_mapFailureMessage(failure))),
      (user) => emit(UserState.loaded(user)),
    );
  }

  String _mapFailureMessage(UserFailure failure) {
    return failure.when(
      network: () => '네트워크 오류가 발생했습니다.',
      notFound: () => '사용자를 찾을 수 없습니다.',
      unauthorized: () => '권한이 없습니다.',
      unknown: () => '알 수 없는 오류가 발생했습니다.',
    );
  }
}
```

## 4. Either 체이닝

### 4.1 map - 성공 값 변환

```dart
// 성공 값만 변환 (실패는 그대로 통과)
final result = await getUserUseCase(id);

final userName = result.map((user) => user.name);
// Either<UserFailure, String>
```

### 4.2 flatMap - Either 연결

```dart
// 여러 Either 연산을 연결
// ❌ 잘못된 방법: Either.flatMap은 동기적으로 Either를 반환해야 함
// return userResult.flatMap((user) async { ... });  // 컴파일 에러! (Future 반환 불가)
// 참고: TaskEither.flatMap은 동기적으로 TaskEither를 반환하며, 비동기 작업은 TaskEither 내부에서 처리

// ✅ 방법 1: fold 사용
Future<Either<UserFailure, Profile>> getUserProfile(String userId) async {
  final userResult = await _userRepository.getUser(userId);

  // fold를 사용하면 비동기 처리 가능
  return userResult.fold(
    (failure) async => Left(failure),  // 실패는 그대로 전달
    (user) async {
      // 성공 시 다음 비동기 작업 수행
      final profileResult = await _profileRepository.getProfile(user.profileId);
      return profileResult;
    },
  );
}

// ✅ 방법 2: TaskEither 사용 (더 함수형)
Future<Either<UserFailure, Profile>> getUserProfile(String userId) async {
  return TaskEither(() => _userRepository.getUser(userId))
      .flatMap((user) => TaskEither(() => _profileRepository.getProfile(user.profileId)))
      .run();
}
```

### 4.3 체이닝 예시

> **⚠️ 아래 코드는 fold 중첩(콜백 지옥)을 보여주는 예시입니다.** 4.4에서 더 깔끔한 방법을 소개합니다.

```dart
// features/order/lib/domain/usecases/create_order_usecase.dart
@injectable
class CreateOrderUseCase {
  final CartRepository _cartRepository;
  final OrderRepository _orderRepository;
  final PaymentRepository _paymentRepository;

  CreateOrderUseCase(
    this._cartRepository,
    this._orderRepository,
    this._paymentRepository,
  );

  Future<Either<OrderFailure, Order>> call(CreateOrderParams params) async {
    // 1. 장바구니 검증
    final cartResult = await _cartRepository.getCart(params.cartId);

    return cartResult.fold(
      (failure) => Left(OrderFailure.cartError(failure.message)),
      (cart) async {
        // 2. 재고 확인
        final stockResult = await _orderRepository.checkStock(cart.items);

        return stockResult.fold(
          (failure) => Left(failure),
          (stockValid) async {
            if (!stockValid) {
              return const Left(OrderFailure.outOfStock());
            }

            // 3. 결제 처리
            final paymentResult = await _paymentRepository.process(
              amount: cart.totalAmount,
              method: params.paymentMethod,
            );

            return paymentResult.fold(
              (failure) => Left(OrderFailure.paymentError(failure.message)),
              (payment) async {
                // 4. 주문 생성
                final orderResult = await _orderRepository.createOrder(
                  cart: cart,
                  paymentId: payment.id,
                );

                return orderResult;
              },
            );
          },
        );
      },
    );
  }
}
```

### 4.4 더 깔끔한 체이닝 (flatMap 사용)

```dart
// ❌ 잘못된 방법: Future<Either>에는 mapLeft, flatMap이 없음
// Future<Either<OrderFailure, Order>> call(CreateOrderParams params) async {
//   return _cartRepository
//       .getCart(params.cartId)  // Future<Either> 반환
//       .mapLeft((f) => ...)     // 에러! Future에는 mapLeft가 없음
//       .flatMap((cart) => ...); // 에러! Future에는 flatMap이 없음
// }

// ✅ 방법 1: await 후 Either 메서드 사용
Future<Either<OrderFailure, Order>> call(CreateOrderParams params) async {
  // 1. Future를 await로 풀어서 Either 얻기
  final cartResult = await _cartRepository.getCart(params.cartId);

  // 2. Either에 mapLeft, flatMap 사용 가능
  return cartResult
      .mapLeft((f) => OrderFailure.cartError(f.message))
      .fold(
        (failure) async => Left(failure),
        (cart) async {
          final stockResult = await _validateStock(cart);
          return stockResult.fold(
            (failure) async => Left(failure),
            (validCart) async {
              final paymentResult = await _processPayment(validCart, params.paymentMethod);
              return paymentResult.fold(
                (failure) async => Left(failure),
                (payment) => _createOrder(payment),
              );
            },
          );
        },
      );
}

// ✅ 방법 2: TaskEither로 체이닝 (더 깔끔)
Future<Either<OrderFailure, Order>> call(CreateOrderParams params) async {
  return TaskEither(() => _cartRepository.getCart(params.cartId))
      .mapLeft((f) => OrderFailure.cartError(f.message))
      .flatMap((cart) => TaskEither(() => _validateStock(cart)))
      .flatMap((cart) => TaskEither(() => _processPayment(cart, params.paymentMethod)))
      .flatMap((payment) => TaskEither(() => _createOrder(payment)))
      .run();
}

Future<Either<OrderFailure, Cart>> _validateStock(Cart cart) async {
  final result = await _orderRepository.checkStock(cart.items);
  // 동기적 flatMap 사용 가능
  return result.flatMap((valid) {
    if (!valid) return const Left(OrderFailure.outOfStock());
    return Right(cart);
  });
}
```

## 5. Option

### 5.1 기본 개념

```dart
import 'package:fpdart/fpdart.dart';

// Option<T> = Some(value) | None
// nullable 대신 사용

Option<User> findUserByEmail(String email, List<User> users) {
  final user = users.where((u) => u.email == email).firstOrNull;
  return Option.fromNullable(user);
}

// 사용
final userOption = findUserByEmail('test@test.com', users);

userOption.fold(
  () => print('User not found'),
  (user) => print('Found: ${user.name}'),
);

// 또는 match 사용
userOption.match(
  () => print('User not found'),
  (user) => print('Found: ${user.name}'),
);
```

### 5.2 Option 메서드

```dart
final option = Option.of(5);

// map - 값 변환
final doubled = option.map((n) => n * 2);  // Some(10)

// flatMap - Option 연결
final result = option.flatMap((n) => n > 0 ? Some(n) : const None());

// getOrElse - 기본값
final value = option.getOrElse(() => 0);  // 5

// toNullable - nullable로 변환
final nullable = option.toNullable();  // int?

// toEither - Either로 변환
final either = option.toEither(() => 'No value');  // Either<String, int>
```

### 5.3 Option 사용 예시

```dart
// features/user/lib/data/datasources/user_local_datasource.dart
abstract class UserLocalDataSource {
  Option<CachedUser> getCachedUser(String id);
  Future<void> cacheUser(CachedUser user);
}

@LazySingleton(as: UserLocalDataSource)
class UserLocalDataSourceImpl implements UserLocalDataSource {
  final IsarDatabase _database;

  UserLocalDataSourceImpl(this._database);

  @override
  Option<CachedUser> getCachedUser(String id) {
    final user = _database.instance.cachedUsers
        .where()
        .odIdEqualTo(id)
        .findFirstSync();

    return Option.fromNullable(user);
  }
}
```

```dart
// Repository에서 캐시 활용
@override
Future<Either<UserFailure, User>> getUser(String id) async {
  // 1. 캐시 확인
  final cachedUser = _localDataSource.getCachedUser(id);

  return cachedUser.fold(
    // 캐시 없음 → API 호출
    () async {
      try {
        final dto = await _remoteDataSource.getUser(id);
        await _localDataSource.cacheUser(_mapper.toCached(dto));
        return Right(_mapper.toEntity(dto));
      } on DioException catch (e) {
        return Left(_mapDioError(e));
      }
    },
    // 캐시 있음 → 캐시 반환
    (cached) async {
      // 캐시가 오래되었으면 백그라운드에서 갱신
      if (_isCacheExpired(cached)) {
        _refreshCacheInBackground(id);
      }
      return Right(_mapper.cachedToEntity(cached));
    },
  );
}
```

## 6. TaskEither

### 6.1 기본 개념

```dart
import 'package:fpdart/fpdart.dart';

// TaskEither<L, R> = () => Future<Either<L, R>>
// 비동기 연산을 지연 실행하고 체이닝 가능

TaskEither<UserFailure, User> getUser(String id) {
  return TaskEither(() async {
    try {
      final response = await api.getUser(id);
      return Right(User.fromJson(response));
    } catch (e) {
      return const Left(UserFailure.network());
    }
  });
}

// 실행
final result = await getUser('123').run();
```

### 6.2 TaskEither 체이닝

```dart
// 여러 비동기 작업을 순차적으로 체이닝
TaskEither<OrderFailure, Order> createOrder(CreateOrderParams params) {
  return getCart(params.cartId)
      .flatMap((cart) => validateStock(cart))
      .flatMap((cart) => processPayment(cart, params.paymentMethod))
      .flatMap((payment) => saveOrder(payment));
}

// TaskEither.tryCatch는 예외를 던지는 함수를 감쌉니다 (Either 반환 함수가 아님!)
// _cartDataSource.getCart()는 Future<Cart>를 반환하고 실패 시 예외를 던집니다.
TaskEither<OrderFailure, Cart> getCart(String cartId) {
  return TaskEither.tryCatch(
    () => _cartDataSource.getCart(cartId),  // Future<Cart>, 예외 가능
    (error, stackTrace) => OrderFailure.cartError(error.toString()),
  );
}

// TaskEither.tryCatch는 예외를 던지는 함수를 감쌉니다 (Either 반환 함수가 아님!)
// _orderDataSource.checkStock()는 Future<bool>를 반환하고 실패 시 예외를 던집니다.
TaskEither<OrderFailure, Cart> validateStock(Cart cart) {
  return TaskEither.tryCatch(
    () => _orderDataSource.checkStock(cart.items),  // Future<bool>, 예외 가능
    (error, stackTrace) {
      if (error is NetworkException) return OrderFailure.networkError();
      return const OrderFailure.outOfStock();
    },
  ).flatMap((valid) {
    if (!valid) return TaskEither.left(const OrderFailure.outOfStock());
    return TaskEither.right(cart);
  });
}
```

### 6.3 TaskEither vs Future<Either>

```dart
// Future<Either> - 즉시 실행
Future<Either<Failure, Data>> getData() async {
  // 이 함수가 호출되면 바로 실행됨
  return Right(await api.fetch());
}

// TaskEither - 지연 실행
TaskEither<Failure, Data> getData() {
  return TaskEither(() async {
    // .run()이 호출될 때까지 실행되지 않음
    return Right(await api.fetch());
  });
}

// TaskEither의 장점: 체이닝과 합성이 더 자연스러움
final pipeline = getData()
    .flatMap(processData)
    .flatMap(saveData)
    .map(formatResult);

// 실행
final result = await pipeline.run();
```

### 6.4 Future<Either> vs TaskEither 선택 기준

| 상황 | 권장 |
|------|------|
| Repository 구현 | Future<Either> (단순성) |
| 복잡한 비동기 체이닝 | TaskEither (합성 용이) |
| 지연 실행 필요 | TaskEither |
| 팀이 FP에 익숙하지 않음 | Future<Either> |

## 7. Unit 타입

### 7.1 기본 개념

```dart
import 'package:fpdart/fpdart.dart';

// Unit = void의 함수형 대체
// Either<Failure, void>가 아닌 Either<Failure, Unit> 사용

Future<Either<UserFailure, Unit>> deleteUser(String id) async {
  try {
    await _dataSource.deleteUser(id);
    return const Right(unit);  // unit 상수 사용
  } catch (e) {
    return const Left(UserFailure.unknown());
  }
}
```

### 7.2 Unit 사용 이유

```dart
// ❌ void 사용 시 문제
Future<Either<Failure, void>> delete() async {
  // void는 값이 아니라 타입 체크 어려움
  return Right(null);  // 애매함
}

// ✅ Unit 사용
Future<Either<Failure, Unit>> delete() async {
  return const Right(unit);  // 명확한 "성공, 반환값 없음" 표현
}
```

## 8. 실전 패턴

### 8.1 여러 Either 조합

```dart
// 여러 Either 결과를 조합
Future<Either<Failure, ProfileData>> getProfileData(String userId) async {
  final userResult = await _userRepository.getUser(userId);
  final settingsResult = await _settingsRepository.getSettings(userId);
  final statsResult = await _statsRepository.getStats(userId);

  // 모든 결과가 성공인 경우에만 조합
  return userResult.fold(
    (failure) => Left(failure),
    (user) => settingsResult.fold(
      (failure) => Left(failure),
      (settings) => statsResult.fold(
        (failure) => Left(failure),
        (stats) => Right(ProfileData(
          user: user,
          settings: settings,
          stats: stats,
        )),
      ),
    ),
  );
}
```

### 8.2 Either.Do 문법 (권장)

```dart
// ❌ 잘못된 방법: Either.Do는 동기적으로만 동작
// Future<Either<Failure, ProfileData>> getProfileData(String userId) async {
//   return Either.Do(($) async {  // async 사용 불가!
//     final user = await $(await _userRepository.getUser(userId));  // 에러!
//     ...
//   });
// }

// ✅ 방법 1: Either.Do를 동기적으로 사용 (모든 Future를 먼저 await)
Future<Either<Failure, ProfileData>> getProfileData(String userId) async {
  // 1. 모든 비동기 작업을 먼저 완료
  final userResult = await _userRepository.getUser(userId);
  final settingsResult = await _settingsRepository.getSettings(userId);
  final statsResult = await _statsRepository.getStats(userId);

  // 2. Either.Do로 동기적 조합
  return Either.Do(($) {
    // $는 Either에서 Right 값을 추출
    // Left면 즉시 반환됨
    final user = $(userResult);
    final settings = $(settingsResult);
    final stats = $(statsResult);

    return ProfileData(
      user: user,
      settings: settings,
      stats: stats,
    );
  });
}

// ✅ 방법 2: TaskEither.Do 사용 (진짜 비동기 Do 표기법)
Future<Either<Failure, ProfileData>> getProfileData(String userId) async {
  return TaskEither<Failure, ProfileData>.Do(($) async {
    // TaskEither.Do는 async 지원!
    final user = await $(TaskEither(() => _userRepository.getUser(userId)));
    final settings = await $(TaskEither(() => _settingsRepository.getSettings(userId)));
    final stats = await $(TaskEither(() => _statsRepository.getStats(userId)));

    return ProfileData(
      user: user,
      settings: settings,
      stats: stats,
    );
  }).run();  // .run()으로 실행
}
```

### 8.3 병렬 실행

```dart
// 여러 요청을 병렬로 실행
Future<Either<Failure, DashboardData>> getDashboardData() async {
  // 병렬 실행
  final results = await Future.wait([
    _userRepository.getCurrentUser(),
    _notificationRepository.getUnreadCount(),
    _orderRepository.getRecentOrders(),
  ]);

  final userResult = results[0] as Either<Failure, User>;
  final notificationResult = results[1] as Either<Failure, int>;
  final ordersResult = results[2] as Either<Failure, List<Order>>;

  // 💡 더 안전한 방법: Dart 3 record를 사용한 병렬 실행
  // final (userResult, notificationResult, ordersResult) = await (
  //   _userRepository.getCurrentUser(),
  //   _notificationRepository.getUnreadCount(),
  //   _orderRepository.getRecentOrders(),
  // ).wait;

  // 결과 조합
  return Either.Do(($) {
    final user = $(userResult);
    final unreadCount = $(notificationResult);
    final orders = $(ordersResult);

    return DashboardData(
      user: user,
      unreadNotifications: unreadCount,
      recentOrders: orders,
    );
  });
}
```

### 8.4 에러 변환

```dart
// 하위 레이어의 에러를 상위 레이어 에러로 변환
Future<Either<OrderFailure, Order>> createOrder(OrderParams params) async {
  // CartFailure를 OrderFailure로 변환
  final cartResult = await _cartRepository.getCart(params.cartId);

  return cartResult
      .mapLeft((f) => OrderFailure.fromCartFailure(f))
      .fold(
        (failure) async => Left(failure),
        (cart) async {
          final paymentResult = await _paymentRepository.process(cart.total);
          return paymentResult
              .mapLeft((f) => OrderFailure.fromPaymentFailure(f))
              .fold(
                (failure) async => Left(failure),
                (payment) => _orderRepository.create(cart, payment),
              );
        },
      );
}
```

## 9. 테스트

### 9.1 Either 테스트

```dart
// test/domain/usecases/get_user_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late GetUserUseCase useCase;
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
    useCase = GetUserUseCase(mockRepository);
  });

  group('GetUserUseCase', () {
    test('성공 시 Right(User) 반환', () async {
      // Arrange
      final user = User(id: '1', name: 'Test');
      when(() => mockRepository.getUser(any()))
          .thenAnswer((_) async => Right(user));

      // Act
      final result = await useCase('1');

      // Assert
      expect(result.isRight(), true);
      expect(result.getOrElse((_) => throw Exception()), user);

      // 또는
      result.fold(
        (failure) => fail('Expected Right, got Left'),
        (value) => expect(value, user),
      );
    });

    test('실패 시 Left(UserFailure) 반환', () async {
      // Arrange
      when(() => mockRepository.getUser(any()))
          .thenAnswer((_) async => const Left(UserFailure.notFound()));

      // Act
      final result = await useCase('999');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, const UserFailure.notFound()),
        (value) => fail('Expected Left, got Right'),
      );
    });
  });
}
```

### 9.2 Option 테스트

```dart
test('캐시에 사용자가 있으면 Some 반환', () {
  // Arrange
  final cachedUser = CachedUser()..odId = '1'..name = 'Test';
  when(() => mockDatabase.getCachedUser('1'))
      .thenReturn(Some(cachedUser));

  // Act
  final result = dataSource.getCachedUser('1');

  // Assert
  expect(result.isSome(), true);
  result.fold(
    () => fail('Expected Some'),
    (user) => expect(user.name, 'Test'),
  );
});

test('캐시에 사용자가 없으면 None 반환', () {
  // Arrange
  when(() => mockDatabase.getCachedUser('999'))
      .thenReturn(const None());

  // Act
  final result = dataSource.getCachedUser('999');

  // Assert
  expect(result.isNone(), true);
});
```

## 10. Best Practices

### 10.1 언제 Either를 사용할까?

| 상황 | Either 사용 | Exception 사용 |
|------|------------|---------------|
| Repository 반환값 | ✅ | ❌ |
| UseCase 반환값 | ✅ | ❌ |
| DataSource 내부 | ❌ (try-catch) | ✅ |
| 비즈니스 로직 에러 | ✅ | ❌ |
| 시스템 에러 | 상황에 따라 | ✅ |

### 10.2 DO (이렇게 하세요)

```dart
// ✅ Repository 반환값에 Either 사용
Future<Either<UserFailure, User>> getUser(String id);

// ✅ Unit으로 반환값 없음 표현
Future<Either<UserFailure, Unit>> deleteUser(String id);

// ✅ fold로 명시적 처리
result.fold(
  (failure) => emit(UserState.error(failure.message)),
  (user) => emit(UserState.loaded(user)),
);

// ✅ 에러 타입을 도메인에 맞게 정의
@freezed
class UserFailure with _$UserFailure {
  const factory UserFailure.network() = NetworkFailure;
  const factory UserFailure.notFound() = NotFoundFailure;
  const factory UserFailure.unauthorized() = UnauthorizedFailure;
  const factory UserFailure.unknown() = UnknownFailure;
}
```

### 10.3 DON'T (하지 마세요)

```dart
// ❌ Either를 무시하고 getOrElse만 사용
final user = (await getUser(id)).getOrElse((_) => User.empty());
// 에러 처리가 누락됨!

// ❌ 모든 곳에 Either 사용 (오버엔지니어링)
Either<Failure, int> add(int a, int b) {
  return Right(a + b);  // 실패할 수 없는 연산에 불필요
}

// ❌ Exception과 Either 혼용
Future<Either<Failure, User>> getUser() async {
  final user = await api.getUser();  // Exception 발생 가능!
  return Right(user);  // try-catch 필요
}
```

### 10.4 Either 패턴 요약

```dart
// 1. DataSource: Exception 발생 가능
class UserRemoteDataSource {
  Future<UserDto> getUser(String id) async {
    final response = await dio.get('/users/$id');  // Exception 가능
    return UserDto.fromJson(response.data);
  }
}

// 2. Repository: Exception을 Either로 변환
class UserRepositoryImpl implements UserRepository {
  @override
  Future<Either<UserFailure, User>> getUser(String id) async {
    try {
      final dto = await _dataSource.getUser(id);
      return Right(_mapper.toEntity(dto));
    } catch (e) {
      return Left(_mapError(e));  // Either로 변환
    }
  }
}

// 3. UseCase: Either 전달
class GetUserUseCase {
  Future<Either<UserFailure, User>> call(String id) {
    return _repository.getUser(id);  // Either 그대로 전달
  }
}

// 4. Bloc: Either 처리
class UserBloc {
  Future<void> _onLoad(Emitter emit) async {
    final result = await _useCase(id);
    result.fold(
      (failure) => emit(Error(failure)),  // Left 처리
      (user) => emit(Loaded(user)),       // Right 처리
    );
  }
}
```

## 11. 참고

- [fpdart 공식 문서](https://pub.dev/packages/fpdart)
- [fpdart GitHub](https://github.com/SandroMaglione/fpdart)
- [Functional Programming in Dart](https://www.sandromaglione.com/articles/functional-programming-in-dart-and-flutter)

## 관련 문서

| 문서 | 설명 |
|------|------|
| [Architecture.md](./Architecture.md) | Either 패턴이 적용되는 전체 아키텍처 |
| [ErrorHandling.md](../system/ErrorHandling.md) | Failure 클래스 설계와 에러 분류 |
| [Bloc.md](./Bloc.md) | Bloc에서 Either 결과 처리 |
| [Networking_Dio.md](../networking/Networking_Dio.md) | DioException → Either 변환 |

---
## 실습 과제

### 과제 1: Repository에 Either 적용
기존 예외 기반 코드를 Either 패턴으로 리팩토링하세요.

1. UserRepository 인터페이스를 Either<UserFailure, User> 반환하도록 수정
2. UserRepositoryImpl에서 try-catch로 DioException 처리
3. UserFailureMapper로 DioException → UserFailure 변환
4. GetUserUseCase에서 Either 전달
5. UserBloc에서 fold로 성공/실패 처리

### 과제 2: 복잡한 비즈니스 로직 체이닝
여러 비동기 작업을 Either로 연결하세요.

1. CreateOrderUseCase 구현 (장바구니 검증 → 재고 확인 → 결제 처리 → 주문 생성)
2. fold를 사용한 순차 체이닝 구현
3. TaskEither로 리팩토링하여 flatMap 사용
4. 각 단계의 Failure를 OrderFailure로 변환
5. 중간 실패 시 롤백 로직 추가

### 과제 3: Option으로 캐시 처리
로컬 캐시를 Option으로 구현하세요.

1. UserLocalDataSource에서 Option<CachedUser> 반환
2. Repository에서 캐시 확인 (Some → 캐시 반환, None → API 호출)
3. 캐시가 오래된 경우 백그라운드 갱신
4. Either.Do 문법으로 여러 Option 조합
5. Option과 nullable의 차이 분석

## Self-Check
- [ ] Either<L, R>의 개념과 Left/Right의 의미를 설명할 수 있다
- [ ] 예외 기반 에러 처리와 Either 기반 에러 처리의 차이를 설명할 수 있다
- [ ] Repository에서 Either를 반환하고 Bloc에서 fold로 처리할 수 있다
- [ ] map으로 성공 값만 변환하고, mapLeft로 실패 값만 변환할 수 있다
- [ ] fold를 사용하여 비동기 Either 작업을 체이닝할 수 있다
- [ ] TaskEither의 개념과 Future<Either>와의 차이를 설명할 수 있다
- [ ] Option<T>을 사용하여 nullable 값을 안전하게 처리할 수 있다
- [ ] Unit 타입을 사용하여 반환값이 없는 성공을 표현할 수 있다
- [ ] Either.Do와 TaskEither.Do의 차이를 이해하고 적절히 사용할 수 있다
- [ ] 언제 Either를 사용하고 언제 Exception을 사용해야 하는지 판단할 수 있다

---

**다음 문서:** [ModularArchitecture - 모듈러 아키텍처](./ModularArchitecture.md)
