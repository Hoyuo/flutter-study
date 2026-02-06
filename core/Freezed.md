# Freezed 가이드

Dart에서 불변(immutable) 데이터 클래스를 쉽게 생성하기 위한 Freezed 패키지 사용 가이드입니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Freezed를 사용하여 불변 데이터 클래스를 자동 생성할 수 있습니다
> - Union 타입(sealed class)으로 복잡한 상태 분기를 타입 안전하게 처리할 수 있습니다
> - copyWith, when, map 등 Freezed가 제공하는 메서드를 활용할 수 있습니다

---

## 목차

1. [Freezed 개요](#1-freezed-개요)
2. [설치 및 설정](#2-설치-및-설정)
3. [기본 사용법](#3-기본-사용법)
4. [copyWith](#4-copywith)
5. [Union 타입 (sealed class)](#5-union-타입-sealed-class)
6. [JSON 직렬화](#6-json-직렬화)
7. [고급 기능](#7-고급-기능)
8. [실전 패턴](#8-실전-패턴)
9. [Best Practices](#9-best-practices)

---

## 1. Freezed 개요

### Freezed란?

Freezed는 코드 생성을 통해 불변 데이터 클래스를 자동으로 생성해주는 패키지입니다.

### 주요 기능

| 기능 | 설명 |
|------|------|
| **불변성** | 모든 필드가 final |
| **copyWith** | 일부 필드만 변경한 복사본 생성 |
| **Union 타입** | sealed class 대안 (패턴 매칭) |
| **JSON 직렬화** | json_serializable 통합 |
| **==, hashCode** | 자동 생성 |
| **toString** | 자동 생성 |

### 수동 작성 vs Freezed

```dart
// 수동 작성: 약 50줄
class User {
  final String id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ email.hashCode;

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

// Freezed: 약 15줄
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

---

## 2. 설치 및 설정

### 의존성 추가

> **⚠️ 버전 선택 가이드 (2026년 1월 기준)**
>
> Freezed는 현재 두 가지 버전이 공존하고 있습니다:
> - **Freezed 2.5.x**: 기존 프로젝트에 적합한 안정 버전
> - **Freezed 3.x**: 새로운 안정 버전 (상속, 비상수 기본값 등 신규 기능 포함)

#### 옵션 1: Freezed 2.x (기존 프로젝트)

```yaml
# pubspec.yaml - Freezed 2.x (기존 프로젝트)
dependencies:
  freezed_annotation: ^2.2.0
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.10.5
  freezed: ^2.5.7
  json_serializable: ^6.11.4
```

#### 옵션 2: Freezed 3.x (신규 프로젝트 권장)

```yaml
# pubspec.yaml - Freezed 3.x (신규 프로젝트)
dependencies:
  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.10.5
  freezed: ^3.2.4
  json_serializable: ^6.11.4
```

> **💡 Freezed 3.x 안내:**
>
> Freezed 3.x는 pub.dev에서 **안정 버전(stable)**으로 공개되었습니다.
> - **신규 프로젝트**: Freezed 3.x 사용 권장 (새 기능 활용 가능)
> - **기존 프로젝트**: Freezed 2.5.x 유지 가능 (마이그레이션 시 충분한 테스트 필요)
> - **주요 변경사항**: Dart 3.6.0 이상 필수
>
> **Freezed 3.0 주요 기능:**
> - **상속(extends) 지원**: Freezed 클래스가 다른 클래스를 상속 가능
> - **비상수 기본값**: `@Default`에서 non-constant 값 사용 가능
> - **Mixed mode**: Factory와 일반 생성자 혼합 가능
> - Dart 3.6.0 이상 필수
>
> ```dart
> // Freezed 3.0 상속 예시
> @freezed
> class Person extends Entity with _$Person {
>   const factory Person({
>     required String name,
>     required super.id,  // 상속된 필드!
>   }) = _Person;
> }
> ```

### 코드 생성 명령어

```bash
# 일회성 빌드
dart run build_runner build --delete-conflicting-outputs

# 파일 감시 (개발 중 권장)
dart run build_runner watch --delete-conflicting-outputs

# FVM 사용 시
fvm dart run build_runner build --delete-conflicting-outputs
```

### analysis_options.yaml 설정

```yaml
analyzer:
  errors:
    invalid_annotation_target: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
```

---

## 3. 기본 사용법

### 기본 데이터 클래스

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';  // JSON 직렬화 사용 시

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    String? profileImageUrl,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### 기본값 설정

```dart
@freezed
class Settings with _$Settings {
  const factory Settings({
    @Default(false) bool isDarkMode,
    @Default('ko') String language,
    @Default(14.0) double fontSize,
    @Default([]) List<String> favoriteCategories,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}

// 사용
final settings = Settings();  // 모든 기본값 적용
final darkSettings = Settings(isDarkMode: true);  // 일부만 지정
```

### nullable 필드

```dart
@freezed
class Profile with _$Profile {
  const factory Profile({
    required String userId,
    String? bio,           // nullable, 기본값 없음
    String? website,
    @Default(null) String? avatarUrl,  // nullable, 기본값 명시
  }) = _Profile;
}
```

### Assert 추가

> **⚠️ 중요: @Assert는 debug 모드에서만 동작합니다**
>
> - **Debug 모드**: Assert 검증 실행 → 조건 위반 시 AssertionError 발생
> - **Release 모드**: Assert 검증 무시 → 성능 최적화를 위해 무시됨
> - 프로덕션 환경에서는 별도의 유효성 검사 로직이 필요합니다

```dart
@freezed
class Product with _$Product {
  @Assert('price >= 0', 'Price must be non-negative')
  @Assert('name.isNotEmpty', 'Name cannot be empty')
  const factory Product({
    required String name,
    required double price,
    @Default(0) int quantity,
  }) = _Product;
}

// 사용 (Debug 모드에서만 AssertionError 발생)
final product = Product(name: '', price: 100);  // AssertionError! (Debug only)
final product2 = Product(name: 'Item', price: -1);  // AssertionError! (Debug only)
```

---

## 4. copyWith

### 기본 copyWith

```dart
final user = User(
  id: '1',
  name: 'John',
  email: 'john@example.com',
);

// 이름만 변경
final updatedUser = user.copyWith(name: 'Jane');
// User(id: '1', name: 'Jane', email: 'john@example.com')
```

### 중첩 객체 copyWith

```dart
@freezed
class Address with _$Address {
  const factory Address({
    required String street,
    required String city,
    required String country,
  }) = _Address;
}

@freezed
class Person with _$Person {
  const factory Person({
    required String name,
    required Address address,
  }) = _Person;
}

// Deep copy
final person = Person(
  name: 'John',
  address: Address(
    street: '123 Main St',
    city: 'Seoul',
    country: 'Korea',
  ),
);

// 중첩 객체의 일부만 변경
final movedPerson = person.copyWith.address(city: 'Busan');
// Person(name: 'John', Address(street: '123 Main St', city: 'Busan', country: 'Korea'))
```

### nullable 필드를 null로 설정

```dart
@freezed
class Profile with _$Profile {
  const factory Profile({
    required String name,
    String? bio,
  }) = _Profile;
}

final profile = Profile(name: 'John', bio: 'Hello');

// bio를 null로 설정
final cleared = profile.copyWith(bio: null);  // Profile(name: 'John', bio: null)
```

---

## 5. Union 타입 (sealed class)

### Dart 3 sealed class vs Freezed Union

| 항목 | Dart 3 sealed class | Freezed Union |
|------|---------------------|---------------|
| 코드 생성 | 불필요 | 필요 (build_runner) |
| copyWith | 수동 구현 | 자동 생성 |
| JSON 직렬화 | 수동 구현 | json_serializable 통합 |
| when/map 메서드 | switch expression 사용 | 자동 생성 |
| 추천 상황 | 단순한 상태 분기 | 복잡한 데이터 모델 |

### 기본 Union 타입

```dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(User user) = Authenticated;
  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.error(String message) = AuthError;
}
```

### 패턴 매칭: when

모든 케이스를 처리해야 합니다.

```dart
final state = AuthState.authenticated(user);

// 모든 케이스 처리 (필수)
final message = state.when(
  initial: () => '초기화 중...',
  loading: () => '로딩 중...',
  authenticated: (user) => '안녕하세요, ${user.name}님!',
  unauthenticated: () => '로그인이 필요합니다.',
  error: (message) => '오류: $message',
);
```

### 패턴 매칭: maybeWhen

일부 케이스만 처리합니다.

```dart
final state = AuthState.authenticated(user);

// 일부만 처리, 나머지는 orElse
final isLoggedIn = state.maybeWhen(
  authenticated: (_) => true,
  orElse: () => false,
);
```

### 패턴 매칭: map / maybeMap

타입 캐스팅된 객체를 받습니다.

```dart
// map: 모든 케이스 처리
final widget = state.map(
  initial: (_) => const InitialWidget(),
  loading: (_) => const LoadingWidget(),
  authenticated: (state) => HomeWidget(user: state.user),
  unauthenticated: (_) => const LoginWidget(),
  error: (state) => ErrorWidget(message: state.message),
);

// maybeMap: 일부만 처리
final user = state.maybeMap(
  authenticated: (state) => state.user,
  orElse: () => null,
);
```

### 패턴 매칭: whenOrNull / mapOrNull

orElse 없이 null 반환합니다.

```dart
// 인증 상태일 때만 user 반환, 아니면 null
final user = state.whenOrNull(
  authenticated: (user) => user,
);

// mapOrNull도 동일
final user = state.mapOrNull(
  authenticated: (state) => state.user,
);
```

### Union 타입 비교

| 메서드 | 필수 처리 | 반환 타입 | 파라미터 |
|--------|-----------|-----------|----------|
| `when` | 모든 케이스 | T | 필드 값들 |
| `maybeWhen` | orElse 필수 | T | 필드 값들 |
| `whenOrNull` | 선택적 | T? | 필드 값들 |
| `map` | 모든 케이스 | T | 타입 캐스팅된 객체 |
| `maybeMap` | orElse 필수 | T | 타입 캐스팅된 객체 |
| `mapOrNull` | 선택적 | T? | 타입 캐스팅된 객체 |

### Union 타입에 공통 필드/메서드 추가

```dart
@freezed
class Result<T> with _$Result<T> {
  const Result._();  // private 생성자 추가 필수

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(String message) = Failure<T>;

  // 공통 getter
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  // 공통 메서드
  T? get dataOrNull => whenOrNull(success: (data) => data);

  Result<R> mapData<R>(R Function(T data) mapper) {
    return when(
      success: (data) => Result.success(mapper(data)),
      failure: (message) => Result.failure(message),
    );
  }
}
```

---

## 6. JSON 직렬화

### 기본 JSON 직렬화

```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// 사용
final json = {'id': '1', 'name': 'John', 'email': 'john@example.com'};
final user = User.fromJson(json);
final backToJson = user.toJson();
```

### 필드 이름 커스텀

```dart
@freezed
class User with _$User {
  const factory User({
    @JsonKey(name: 'user_id') required String id,
    @JsonKey(name: 'full_name') required String name,
    @JsonKey(name: 'email_address') required String email,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// JSON 형태
// {
//   "user_id": "1",
//   "full_name": "John",
//   "email_address": "john@example.com",
//   "created_at": "2024-01-01T00:00:00.000Z"
// }
```

### 기본값 및 필드 무시

```dart
@freezed
class ApiResponse with _$ApiResponse {
  const factory ApiResponse({
    required String status,
    @JsonKey(defaultValue: []) required List<String> data,
    @JsonKey(includeFromJson: false, includeToJson: false) String? localCache,
    @JsonKey(includeToJson: false) DateTime? fetchedAt,
  }) = _ApiResponse;

  factory ApiResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseFromJson(json);
}
```

### Union 타입 JSON 직렬화

```dart
@Freezed(unionKey: 'type')
class PaymentMethod with _$PaymentMethod {
  const factory PaymentMethod.card({
    required String cardNumber,
    required String expiryDate,
  }) = CardPayment;

  const factory PaymentMethod.bank({
    required String accountNumber,
    required String bankName,
  }) = BankPayment;

  const factory PaymentMethod.cash() = CashPayment;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json);
}

// JSON 형태
// Card: {"type": "card", "cardNumber": "1234", "expiryDate": "12/25"}
// Bank: {"type": "bank", "accountNumber": "9876", "bankName": "KB"}
// Cash: {"type": "cash"}
```

### 커스텀 타입 변환

```dart
// import 'dart:ui' show Color;
// 또는
// import 'package:flutter/material.dart';

@freezed
class Event with _$Event {
  const factory Event({
    required String title,
    @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
    required DateTime date,
    @JsonKey(fromJson: _colorFromJson, toJson: _colorToJson)
    required Color color,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}

DateTime _dateFromJson(String json) => DateTime.parse(json);
String _dateToJson(DateTime date) => date.toIso8601String();

// Flutter 3.27+: Color.fromARGB32() 사용 (Color(int) 생성자는 deprecated)
Color _colorFromJson(int json) => Color.fromARGB32(json);
// Flutter 3.27+ (Dart 3.6+): toARGB32() 사용
// Flutter 3.27 미만: color.value 사용
int _colorToJson(Color color) => color.toARGB32();
```

### Generic JSON 직렬화

```dart
@Freezed(genericArgumentFactories: true)
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required bool success,
    required T data,
    String? message,
  }) = _ApiResponse<T>;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);
}

// 사용
final response = ApiResponse<User>.fromJson(
  json,
  (json) => User.fromJson(json as Map<String, dynamic>),
);

// List 타입
final listResponse = ApiResponse<List<User>>.fromJson(
  json,
  (json) => (json as List)
      .map((e) => User.fromJson(e as Map<String, dynamic>))
      .toList(),
);
```

---

## 7. 고급 기능

### Private 생성자와 메서드 추가

```dart
@freezed
class Temperature with _$Temperature {
  const Temperature._();  // private 생성자 필수!

  const factory Temperature.celsius(double value) = _Celsius;
  const factory Temperature.fahrenheit(double value) = _Fahrenheit;

  // 커스텀 getter
  double get inCelsius => when(
    celsius: (v) => v,
    fahrenheit: (v) => (v - 32) * 5 / 9,
  );

  double get inFahrenheit => when(
    celsius: (v) => v * 9 / 5 + 32,
    fahrenheit: (v) => v,
  );

  // 커스텀 메서드
  Temperature add(double delta) => when(
    celsius: (v) => Temperature.celsius(v + delta),
    fahrenheit: (v) => Temperature.fahrenheit(v + delta),
  );

  // 연산자 오버로딩
  Temperature operator +(Temperature other) {
    return Temperature.celsius(inCelsius + other.inCelsius);
  }
}
```

### implements / mixin

```dart
abstract class Identifiable {
  String get id;
}

abstract class Timestamped {
  DateTime get createdAt;
  DateTime get updatedAt;
}

@freezed
class Article with _$Article implements Identifiable, Timestamped {
  const factory Article({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Article;

  factory Article.fromJson(Map<String, dynamic> json) =>
      _$ArticleFromJson(json);
}
```

### Generic 타입

```dart
@freezed
class Pair<A, B> with _$Pair<A, B> {
  const factory Pair({
    required A first,
    required B second,
  }) = _Pair<A, B>;
}

@freezed
class Box<T> with _$Box<T> {
  const Box._();

  const factory Box.empty() = EmptyBox<T>;
  const factory Box.filled(T value) = FilledBox<T>;

  T? get valueOrNull => whenOrNull(filled: (v) => v);
}
```

### 불변성 비활성화 (권장하지 않음)

특수한 경우에만 사용합니다.

```dart
@unfreezed
class MutableUser with _$MutableUser {
  factory MutableUser({
    required String id,
    required String name,
  }) = _MutableUser;
}

// 직접 수정 가능
final user = MutableUser(id: '1', name: 'John');
user.name = 'Jane';  // OK
```

### toString 커스터마이징

```dart
@freezed
class CustomToString with _$CustomToString {
  const CustomToString._();  // private 생성자로 toString 오버라이드 가능하게

  const factory CustomToString({
    required String id,
    required String name,
    required String email,
  }) = _CustomToString;

  @override
  String toString() => 'User($name)';  // 커스텀 toString
}
```

### equal 동작 커스터마이징

```dart
@Freezed(equal: false)
class UniqueEvent with _$UniqueEvent {
  const factory UniqueEvent({
    required String id,
    required String name,
  }) = _UniqueEvent;
}

// 모든 인스턴스가 서로 다름 (identity 비교)
final e1 = UniqueEvent(id: '1', name: 'A');
final e2 = UniqueEvent(id: '1', name: 'A');
print(e1 == e2);  // false
```

---

## 8. 실전 패턴

### API Response 모델

```dart
@Freezed(genericArgumentFactories: true)
class ApiResponse<T> with _$ApiResponse<T> {
  const ApiResponse._();

  const factory ApiResponse.success({
    required T data,
    @Default(200) int statusCode,
  }) = ApiSuccess<T>;

  const factory ApiResponse.error({
    required String message,
    @Default(500) int statusCode,
    String? errorCode,
  }) = ApiError<T>;

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isError => this is ApiError<T>;

  T? get dataOrNull => whenOrNull(success: (data, _) => data);

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);
}
```

### Bloc State

```dart
@freezed
class ProductListState with _$ProductListState {
  const factory ProductListState({
    @Default([]) List<Product> products,
    @Default(false) bool isLoading,
    @Default(false) bool hasReachedMax,
    @Default(1) int currentPage,
    String? errorMessage,
  }) = _ProductListState;

  factory ProductListState.initial() => const ProductListState();
}

// 또는 Union 타입으로
@freezed
class ProductListState with _$ProductListState {
  const factory ProductListState.initial() = ProductListInitial;
  const factory ProductListState.loading() = ProductListLoading;
  const factory ProductListState.loaded({
    required List<Product> products,
    @Default(false) bool hasReachedMax,
  }) = ProductListLoaded;
  const factory ProductListState.error(String message) = ProductListError;
}
```

### Bloc Event

```dart
@freezed
class ProductListEvent with _$ProductListEvent {
  const factory ProductListEvent.started() = ProductListStarted;
  const factory ProductListEvent.refreshed() = ProductListRefreshed;
  const factory ProductListEvent.loadMore() = ProductListLoadMore;
  const factory ProductListEvent.productSelected(String productId) =
      ProductSelected;
  const factory ProductListEvent.filterChanged({
    String? category,
    double? minPrice,
    double? maxPrice,
  }) = ProductFilterChanged;
}
```

### Entity 모델

```dart
@freezed
class User with _$User {
  const User._();

  const factory User({
    required String id,
    required String email,
    required String name,
    String? profileImageUrl,
    @Default(false) bool isVerified,
    required DateTime createdAt,
    DateTime? lastLoginAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  // 도메인 로직
  bool get hasProfileImage => profileImageUrl != null;

  String get displayName => isVerified ? '$name ✓' : name;

  Duration get accountAge => DateTime.now().difference(createdAt);

  bool get isNewUser => accountAge.inDays < 7;
}
```

### Form State

```dart
@freezed
class LoginFormState with _$LoginFormState {
  const LoginFormState._();

  const factory LoginFormState({
    @Default('') String email,
    @Default('') String password,
    @Default(false) bool isSubmitting,
    @Default(false) bool showErrors,
    String? emailError,
    String? passwordError,
    String? generalError,
  }) = _LoginFormState;

  bool get isValid =>
      emailError == null &&
      passwordError == null &&
      email.isNotEmpty &&
      password.isNotEmpty;

  bool get canSubmit => isValid && !isSubmitting;
}
```

### Failure 타입

```dart
@freezed
class Failure with _$Failure {
  const Failure._();

  // 네트워크 관련
  const factory Failure.network({
    @Default('네트워크 연결을 확인해주세요') String message,
  }) = NetworkFailure;

  // 서버 에러
  const factory Failure.server({
    required int statusCode,
    String? message,
  }) = ServerFailure;

  // 인증 에러
  const factory Failure.unauthorized({
    @Default('인증이 필요합니다') String message,
  }) = UnauthorizedFailure;

  // 유효성 검사 에러
  const factory Failure.validation({
    required Map<String, String> errors,
  }) = ValidationFailure;

  // 알 수 없는 에러
  const factory Failure.unknown({
    Object? error,
    StackTrace? stackTrace,
  }) = UnknownFailure;

  String get displayMessage => when(
    network: (msg) => msg,
    server: (code, msg) => msg ?? '서버 오류가 발생했습니다 ($code)',
    unauthorized: (msg) => msg,
    validation: (_) => '입력값을 확인해주세요',
    unknown: (_, __) => '알 수 없는 오류가 발생했습니다',
  );
}
```

---

## 9. Best Practices

### DO (이렇게 하세요)

| 항목 | 설명 |
|------|------|
| **const factory 사용** | 성능 최적화 |
| **required 명시** | 필수 필드 명확화 |
| **@Default 활용** | 선택적 필드 기본값 |
| **private 생성자** | 메서드 추가 시 필수 |
| **part 파일 관리** | .freezed.dart, .g.dart 분리 |

### DON'T (이렇게 하지 마세요)

| 항목 | 이유 |
|------|------|
| **mutable 필드** | 불변성 원칙 위반 |
| **너무 많은 필드** | 클래스 분리 필요 |
| **비즈니스 로직 과다** | 모델은 데이터 중심 |
| **@unfreezed 남용** | 특수한 경우에만 사용 |

### 파일 구조

```
lib/
├── features/
│   └── auth/
│       ├── data/
│       │   ├── models/
│       │   │   ├── user.dart
│       │   │   ├── user.freezed.dart
│       │   │   └── user.g.dart
│       │   └── dto/
│       │       ├── login_request.dart
│       │       ├── login_request.freezed.dart
│       │       └── login_request.g.dart
│       └── domain/
│           └── entities/
│               ├── auth_state.dart
│               └── auth_state.freezed.dart
```

### build.yaml 설정 (선택)

```yaml
# build.yaml
targets:
  $default:
    builders:
      freezed:
        options:
          # 모든 클래스에 기본 설정 적용
          map: true
          when: true
          copy_with: true
          equal: true
          to_string: true

      json_serializable:
        options:
          # JSON 설정
          explicit_to_json: true
          include_if_null: false
          field_rename: snake
```

### 성능 고려사항

```dart
// 좋은 예: const 활용
const state = AuthState.initial();

// 좋은 예: const factory
@freezed
class Config with _$Config {
  const factory Config({
    @Default(false) bool debugMode,
    @Default('prod') String environment,
  }) = _Config;
}

// const로 생성 가능
const config = Config();
const debugConfig = Config(debugMode: true);
```

### 마이그레이션 팁

기존 클래스를 Freezed로 전환할 때:

```dart
// 1단계: 기존 클래스 유지하면서 Freezed 클래스 생성
@freezed
class UserV2 with _$UserV2 {
  const factory UserV2({
    required String id,
    required String name,
  }) = _UserV2;

  // 기존 클래스에서 변환
  factory UserV2.fromLegacy(User legacy) => UserV2(
    id: legacy.id,
    name: legacy.name,
  );
}

// 2단계: 점진적으로 UserV2 사용으로 전환

// 3단계: 기존 User 클래스 제거, UserV2를 User로 rename
```

---

## 참고 자료

- [Freezed 공식 문서](https://pub.dev/packages/freezed)
- [json_serializable 패키지](https://pub.dev/packages/json_serializable)
- [Freezed GitHub](https://github.com/rrousselGit/freezed)

---
## 실습 과제

### 과제 1: User Entity 구현
Freezed로 불변 User 클래스를 구현하세요.

1. User 클래스 정의 (id, email, name, profileImageUrl, isVerified, createdAt)
2. @Default를 사용한 기본값 설정
3. JSON 직렬화 추가 (fromJson, toJson)
4. 커스텀 getter 추가 (hasProfileImage, displayName, accountAge)
5. build_runner로 코드 생성 및 사용 예제 작성

### 과제 2: Union 타입으로 API Response 구현
성공/실패를 표현하는 ApiResponse를 구현하세요.

1. ApiResponse<T> 정의 (success, error)
2. genericArgumentFactories 사용
3. when, map, maybeWhen 메서드로 분기 처리
4. 커스텀 메서드 추가 (isSuccess, dataOrNull)
5. User, List<Product> 등 다양한 타입으로 테스트

### 과제 3: Bloc State를 Union 타입으로 구현
ProductListState를 Union 타입으로 리팩토링하세요.

1. sealed class로 initial, loading, loaded, error 정의
2. loaded에 products, hasReachedMax 필드 포함
3. Bloc에서 when을 사용한 상태 처리
4. UI에서 map을 사용한 위젯 분기
5. 기존 방식과 비교하여 장단점 분석

## Self-Check
- [ ] Freezed의 주요 기능(불변성, copyWith, Union 타입)을 설명할 수 있다
- [ ] @freezed 어노테이션을 사용하여 데이터 클래스를 정의할 수 있다
- [ ] @Default를 사용하여 기본값을 설정할 수 있다
- [ ] copyWith로 일부 필드만 변경한 복사본을 생성할 수 있다
- [ ] Union 타입(sealed class)과 일반 클래스의 차이를 설명할 수 있다
- [ ] when, map, maybeWhen의 차이를 이해하고 적절히 사용할 수 있다
- [ ] private 생성자(_)를 추가하여 커스텀 메서드를 구현할 수 있다
- [ ] JSON 직렬화를 위한 설정(@JsonKey, genericArgumentFactories)을 할 수 있다
- [ ] build_runner를 실행하여 .freezed.dart와 .g.dart 파일을 생성할 수 있다
- [ ] Freezed vs 수동 작성의 장단점을 비교할 수 있다
