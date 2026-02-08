# Riverpod 상태 관리 가이드

> **난이도**: 고급 | **카테고리**: core
> **선행 학습**: [Bloc](./Bloc.md)
> **예상 학습 시간**: 3h

> **참고**: 이 프로젝트의 표준 상태 관리는 **Bloc 패턴**입니다 (`core/Bloc.md` 참조). Riverpod은 대안적 접근 방식으로, 특정 시나리오에서의 활용법을 학습 목적으로 다룹니다.

> **Flutter 3.27+ / Dart 3.6+** | riverpod ^3.0.0 | flutter_riverpod ^3.0.0 | riverpod_annotation ^3.0.0 | freezed ^3.2.4 | fpdart ^1.2.0

> 이 문서는 Riverpod을 사용한 선언적 상태 관리 패턴을 설명합니다. Riverpod은 Provider의 개선된 버전으로, 컴파일 타임 안전성과 테스트 용이성을 제공합니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Riverpod의 Provider 타입별 차이와 사용 시나리오를 이해할 수 있다
> - 코드 생성 기반 Riverpod으로 타입 안전한 상태 관리를 구현할 수 있다
> - Bloc과 Riverpod의 장단점을 비교하고 적절한 상태 관리 도구를 선택할 수 있다

## 목차

1. [개요](#1-개요)
2. [설치 및 설정](#2-설치-및-설정)
3. [Provider 종류](#3-provider-종류)
4. [Code Generation](#4-code-generation)
5. [Ref와 의존성 주입](#5-ref와-의존성-주입)
6. [AsyncValue 패턴](#6-asyncvalue-패턴)
7. [State Notifier 패턴](#7-state-notifier-패턴)
8. [Family와 autoDispose](#8-family와-autodispose)
9. [UI 연동](#9-ui-연동)
10. [스코핑과 오버라이드](#10-스코핑과-오버라이드)
11. [Clean Architecture 연동](#11-clean-architecture-연동)
12. [Bloc에서 마이그레이션](#12-bloc에서-마이그레이션)
13. [테스트](#13-테스트)
14. [Best Practices](#14-best-practices)

---

## 1. 개요

### 1.1 Riverpod이란?

Riverpod은 Provider를 다시 작성한 상태 관리 라이브러리로, 다음과 같은 개선점을 제공합니다.

```
Provider의 문제점 해결
├── BuildContext 의존성 제거 (어디서나 접근 가능)
├── 컴파일 타임 안전성 (Provider 타입 명시)
├── 테스트 용이성 (ProviderContainer로 독립 테스트)
└── 더 나은 개발자 경험 (Code Generation 지원)
```

### 1.2 Bloc vs Riverpod 비교

| 항목 | Bloc | Riverpod |
|------|------|----------|
| **아키텍처** | Event-Driven (Event → Bloc → State) | Reactive (Provider → State) |
| **보일러플레이트** | 많음 (Event, State, Bloc) | 적음 (Provider만) |
| **학습 곡선** | 높음 | 중간 |
| **디버깅** | Event 로그로 추적 용이 | Provider Inspector 사용 |
| **테스트** | BlocTest 라이브러리 | ProviderContainer 사용 |
| **적합한 경우** | 복잡한 비즈니스 로직, 명시적 이벤트 흐름 | 간단한 상태 관리, 빠른 개발 |
| **비동기 처리** | Emitter 사용 | AsyncValue 사용 |
| **의존성 주입** | GetIt/Injectable 권장 | Riverpod 내장 DI |

### 1.3 핵심 개념

| 개념 | 설명 | 예시 |
|------|------|------|
| **Provider** | 상태를 제공하는 객체 | `Provider`, `StateProvider`, `FutureProvider` |
| **Ref** | Provider를 읽고 감시하는 객체 | `ref.watch`, `ref.read`, `ref.listen` |
| **ProviderScope** | Provider의 스코프를 정의 | 앱 루트에 배치 |
| **Family** | 매개변수를 받는 Provider | `provider.family<String>((ref, id) => ...)` |
| **autoDispose** | 사용하지 않을 때 자동 해제 | `provider.autoDispose(...)` |

### 1.4 언제 Riverpod을 선택할까?

**Riverpod을 선택하세요:**
- 빠른 프로토타이핑이 필요할 때
- 보일러플레이트를 줄이고 싶을 때
- 간단한 상태 관리로 충분할 때
- Code Generation으로 타입 안전성을 원할 때

**Bloc을 선택하세요:**
- 복잡한 비즈니스 로직이 많을 때
- Event 기반 추적이 중요할 때
- 명시적인 상태 전환이 필요할 때
- 팀이 이미 Bloc에 익숙할 때

---

## 2. 설치 및 설정

### 2.1 의존성 추가

```yaml
# pubspec.yaml (2026년 2월 기준)
dependencies:
  flutter:
    sdk: flutter

  # Riverpod 코어
  flutter_riverpod: ^3.2.1  # Flutter용 Riverpod
  riverpod: ^3.2.1          # 순수 Dart용 (선택)

  # Code Generation (권장)
  riverpod_annotation: ^3.2.1

  # Functional Programming
  fpdart: ^1.2.0

  # 불변 데이터 클래스
  freezed_annotation: ^3.1.0

dev_dependencies:
  # Build Runner
  build_runner: ^2.11.0

  # Code Generation
  riverpod_generator: ^3.2.1
  freezed: ^3.2.5
  json_serializable: ^6.12.0

  # Lint
  riverpod_lint: ^3.0.0  # Riverpod 전용 린트
  custom_lint: ^0.7.0
```

### 2.2 분석 옵션 설정

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint
# riverpod_lint 규칙은 custom_lint 플러그인을 통해 자동 활성화됩니다
```

### 2.3 프로젝트 구조

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── providers/           # 글로벌 Provider
│   │   ├── dio_provider.dart
│   │   └── shared_prefs_provider.dart
│   └── errors/
│       └── failures.dart
├── features/
│   └── home/
│       ├── domain/
│       │   ├── entities/
│       │   │   └── home_item.dart
│       │   ├── repositories/
│       │   │   └── home_repository.dart
│       │   └── usecases/
│       │       └── get_home_items_usecase.dart
│       ├── data/
│       │   ├── models/
│       │   │   └── home_item_model.dart
│       │   ├── datasources/
│       │   │   └── home_remote_datasource.dart
│       │   └── repositories/
│       │       └── home_repository_impl.dart
│       └── presentation/
│           ├── providers/   # Feature별 Provider
│           │   ├── home_items_provider.dart
│           │   └── home_items_provider.g.dart  # 생성됨
│           ├── screens/
│           │   └── home_screen.dart
│           └── widgets/
│               └── home_item_card.dart
└── shared/
    └── providers/
        └── router_provider.dart
```

### 2.4 메인 앱 설정

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(
    // ProviderScope로 앱 전체를 감싸기 (필수)
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

```dart
// app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Riverpod Example',
      home: const HomeScreen(),
    );
  }
}
```

---

## 3. Provider 종류

### 3.1 Provider (불변 값 제공)

읽기 전용 값을 제공합니다. 한 번 생성되면 변경되지 않습니다.

```dart
// core/providers/dio_provider.dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

@riverpod
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  // 인터셉터 추가
  dio.interceptors.add(LogInterceptor(responseBody: true));

  return dio;
}
```

### 3.2 StateProvider (간단한 상태)

단순한 상태 변경에 사용합니다. 외부에서 직접 수정 가능합니다.

```dart
// presentation/providers/counter_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_provider.g.dart';

// 전통적 방식 (Code Generation 없이)
final counterProvider = StateProvider<int>((ref) => 0);

// UI에서 사용
// ref.read(counterProvider.notifier).state++;
```

**주의:** StateProvider는 간단한 상태에만 사용하세요. 복잡한 로직은 NotifierProvider를 사용하세요.

> **Riverpod 3.x 주의:** `StateProvider`는 레거시 API로 분류되었습니다 (`package:flutter_riverpod/legacy.dart`). 새 코드에서는 `Notifier` 기반 Provider를 사용하세요.

### 3.3 FutureProvider (비동기 데이터)

`Future`를 반환하는 비동기 작업에 사용합니다.

```dart
// presentation/providers/weather_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/entities/weather.dart';
import '../../../domain/usecases/get_weather_usecase.dart';

part 'weather_provider.g.dart';

@riverpod
Future<Weather> weather(Ref ref, String city) async {
  // UseCase 가져오기
  final usecase = ref.read(getWeatherUseCaseProvider);

  // 실행 (Either 패턴)
  final result = await usecase(city);

  // 에러 처리
  return result.fold(
    (failure) => throw Exception(failure.message),
    (weather) => weather,
  );
}
```

### 3.4 StreamProvider (실시간 데이터)

`Stream`을 제공합니다. 실시간 데이터에 적합합니다.

```dart
// presentation/providers/chat_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/repositories/chat_repository.dart';

part 'chat_provider.g.dart';

@riverpod
Stream<List<Message>> chatMessages(Ref ref, String roomId) {
  final repository = ref.read(chatRepositoryProvider);
  return repository.watchMessages(roomId);
}
```

### 3.5 NotifierProvider (복잡한 상태)

복잡한 상태 로직을 캡슐화합니다. Bloc의 Cubit과 유사합니다.

```dart
// presentation/providers/todo_list_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/entities/todo.dart';

part 'todo_list_provider.g.dart';

@riverpod
class TodoList extends _$TodoList {
  @override
  List<Todo> build() {
    // 초기 상태
    return [];
  }

  void addTodo(String title) {
    state = [...state, Todo(id: DateTime.now().toString(), title: title)];
  }

  void toggleTodo(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id)
          todo.copyWith(completed: !todo.completed)
        else
          todo,
    ];
  }

  void removeTodo(String id) {
    state = state.where((todo) => todo.id != id).toList();
  }
}
```

### 3.6 AsyncNotifierProvider (비동기 상태)

비동기 초기화가 필요한 상태에 사용합니다.

```dart
// presentation/providers/user_profile_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/usecases/get_user_profile_usecase.dart';

part 'user_profile_provider.g.dart';

@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  @override
  Future<UserProfile> build(String userId) async {
    // 비동기 초기화
    final usecase = ref.read(getUserProfileUseCaseProvider);
    final result = await usecase(userId);

    return result.fold(
      (failure) => throw Exception(failure.message),
      (profile) => profile,
    );
  }

  Future<void> updateName(String newName) async {
    // 낙관적 업데이트 (Optimistic Update)
    final previousState = state;

    state = AsyncValue.data(
      state.value!.copyWith(name: newName),
    );

    // API 호출
    final usecase = ref.read(updateUserProfileUseCaseProvider);
    final result = await usecase(state.value!);

    // 실패 시 복구
    result.fold(
      (failure) {
        state = previousState;
      },
      (_) {
        // 성공 - 이미 업데이트됨
      },
    );
  }
}
```

---

## 4. Code Generation

### 4.1 왜 Code Generation을 사용할까?

| 방식 | 장점 | 단점 |
|------|------|------|
| **수동 방식** | 설정 없음, 즉시 사용 | 타입 안전성 낮음, 보일러플레이트 많음 |
| **Code Generation** | 타입 안전, 보일러플레이트 적음, 자동완성 | 빌드 러너 실행 필요 |

**권장:** 프로덕션에서는 항상 Code Generation을 사용하세요.

### 4.2 기본 사용법

```dart
// presentation/providers/greeting_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'greeting_provider.g.dart';

// @riverpod 어노테이션 (함수 기반)
@riverpod
String greeting(Ref ref) {
  return 'Hello, Riverpod!';
}

// 매개변수를 받는 Provider
@riverpod
String personalGreeting(Ref ref, String name) {
  return 'Hello, $name!';
}

// 비동기 Provider
@riverpod
Future<String> asyncGreeting(Ref ref) async {
  await Future.delayed(const Duration(seconds: 1));
  return 'Hello after delay!';
}
```

### 4.3 빌드 러너 실행

```bash
# 한 번 생성
dart run build_runner build --delete-conflicting-outputs

# 감시 모드 (파일 변경 시 자동 생성)
dart run build_runner watch --delete-conflicting-outputs
```

### 4.4 생성된 코드 예시

```dart
// greeting_provider.g.dart (자동 생성됨)
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'greeting_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$greetingHash() => r'1a2b3c4d5e6f...';

/// See also [greeting].
@ProviderFor(greeting)
final greetingProvider = AutoDisposeProvider<String>.internal(
  greeting,
  name: r'greetingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$greetingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

// Riverpod 3.x에서는 아래 typedef가 더 이상 생성되지 않습니다.
// 모든 커스텀 Ref 서브클래스(XxxRef)가 제거되고 Ref로 통합되었습니다.
// typedef GreetingRef = AutoDisposeProviderRef<String>;  // 삭제됨
// ... 생략 ...
```

### 4.5 keepAlive 설정

```dart
// presentation/providers/config_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'config_provider.g.dart';

// 자동 dispose 방지 (앱 종료까지 유지)
@Riverpod(keepAlive: true)
String apiKey(Ref ref) {
  return 'YOUR_API_KEY';
}
```

---

## 5. Ref와 의존성 주입

### 5.1 Ref 객체

`Ref`는 Provider를 읽고 감시하는 핵심 객체입니다.

| 메서드 | 용도 | 재빌드 여부 |
|--------|------|-------------|
| `ref.watch` | 상태를 감시하고 변경 시 재빌드 | ✅ |
| `ref.read` | 상태를 한 번만 읽기 (이벤트 핸들러) | ❌ |
| `ref.listen` | 상태 변경을 리스닝 (사이드 이펙트) | ❌ |
| `ref.invalidate` | Provider를 초기화 | - |
| `ref.refresh` | Provider를 재실행 | - |

### 5.2 ref.watch (반응형 읽기)

build 메서드 내에서 사용하여 상태 변경 시 자동으로 재빌드합니다.

```dart
// presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/counter_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // counter가 변경되면 자동으로 재빌드됨
    final counter = ref.watch(counterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: Text('Count: $counter'),
      ),
    );
  }
}
```

### 5.3 ref.read (일회성 읽기)

이벤트 핸들러 내에서 사용합니다. 재빌드를 트리거하지 않습니다.

```dart
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);

    return Scaffold(
      body: Center(child: Text('Count: $counter')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // ✅ 올바른 사용: 이벤트 핸들러(콜백)에서 read 사용
          // build 메서드 본문에서 직접 read하면 재빌드되지 않음
          ref.read(counterProvider.notifier).state++;
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 5.4 ref.listen (사이드 이펙트)

상태 변경을 감시하지만 재빌드하지 않습니다. 네비게이션, 스낵바 등에 사용합니다.

```dart
// presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 로그인 상태를 감시하고 성공 시 네비게이션
    ref.listen<AsyncValue<User>>(
      authProvider,
      (previous, next) {
        next.whenOrNull(
          data: (user) {
            // 로그인 성공 시 홈으로 이동
            // import 'package:go_router/go_router.dart';
            context.go('/home');
          },
          error: (error, stack) {
            // 에러 시 스낵바 표시
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Login failed: $error')),
            );
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const LoginForm(),
    );
  }
}
```

### 5.5 Provider 간 의존성

Provider는 다른 Provider를 의존할 수 있습니다.

```dart
// core/providers/dio_provider.dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

@riverpod
Dio dio(Ref ref) {
  return Dio(BaseOptions(baseUrl: 'https://api.example.com'));
}

// data/datasources/user_remote_datasource.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/dio_provider.dart';

part 'user_remote_datasource.g.dart';

@riverpod
UserRemoteDataSource userRemoteDataSource(Ref ref) {
  // dio Provider를 의존
  final dio = ref.watch(dioProvider);
  return UserRemoteDataSourceImpl(dio);
}

// data/repositories/user_repository_impl.dart
@riverpod
UserRepository userRepository(Ref ref) {
  // datasource Provider를 의존
  final dataSource = ref.watch(userRemoteDataSourceProvider);
  return UserRepositoryImpl(dataSource);
}

// domain/usecases/get_user_usecase.dart
@riverpod
GetUserUseCase getUserUseCase(Ref ref) {
  // repository Provider를 의존
  final repository = ref.watch(userRepositoryProvider);
  return GetUserUseCase(repository);
}
```

---

## 6. AsyncValue 패턴

### 6.1 AsyncValue란?

비동기 작업의 로딩, 데이터, 에러 상태를 표현하는 타입입니다.

```dart
sealed class AsyncValue<T> {
  const AsyncValue.loading();   // 로딩 중
  const AsyncValue.data(T value);  // 성공
  const AsyncValue.error(Object error, StackTrace stackTrace);  // 실패
}
```

### 6.2 when() 메서드

모든 상태를 명시적으로 처리합니다.

```dart
// presentation/screens/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_profile_provider.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileNotifierProvider('user123'));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userProfileAsync.when(
        // 로딩 상태
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        // 데이터 상태
        data: (profile) => Column(
          children: [
            Text('Name: ${profile.name}'),
            Text('Email: ${profile.email}'),
          ],
        ),

        // 에러 상태
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
```

### 6.3 whenData() 메서드 (데이터 타입 변환)

`whenData()`는 위젯 빌더가 아니라 **데이터 타입을 변환**하는 메서드입니다. `AsyncValue<T>`를 `AsyncValue<R>`로 매핑합니다. 위젯을 빌드하려면 `when()`을 사용하세요.

```dart
// whenData()는 AsyncValue의 데이터 타입을 변환합니다
// AsyncValue<List<User>> → AsyncValue<int> (사용자 수만 추출)
final userCountAsync = ref.watch(usersProvider).whenData(
  (users) => users.length,
);

// 위젯 빌드에는 when()을 사용하세요
class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (users) => ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            return ListTile(title: Text(users[index].name));
          },
        ),
      ),
    );
  }
}
```

### 6.4 maybeWhen() 메서드

일부 상태만 처리하고 나머지는 기본값을 사용합니다.

```dart
class DataScreen extends ConsumerWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataProvider);

    return Scaffold(
      body: dataAsync.maybeWhen(
        data: (data) => Text('Data: $data'),
        // loading과 error는 기본 위젯 사용
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}
```

### 6.5 isLoading, hasValue, hasError

상태를 boolean으로 확인합니다.

```dart
class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataProvider);

    if (dataAsync.isLoading) {
      return const CircularProgressIndicator();
    }

    if (dataAsync.hasError) {
      return Text('Error: ${dataAsync.error}');
    }

    if (dataAsync.hasValue) {
      return Text('Data: ${dataAsync.value}');
    }

    return const SizedBox.shrink();
  }
}
```

---

## 7. State Notifier 패턴

### 7.1 Notifier (동기 상태)

동기적으로 상태를 변경하는 Notifier입니다.

```dart
// presentation/providers/cart_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/entities/cart_item.dart';

part 'cart_provider.g.dart';

@riverpod
class Cart extends _$Cart {
  @override
  List<CartItem> build() {
    return [];  // 초기 상태
  }

  void addItem(CartItem item) {
    // 상태는 불변(immutable)이어야 함
    state = [...state, item];
  }

  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  void updateQuantity(String itemId, int quantity) {
    state = [
      for (final item in state)
        if (item.id == itemId)
          item.copyWith(quantity: quantity)
        else
          item,
    ];
  }

  void clear() {
    state = [];
  }

  // Computed property
  double get totalPrice {
    return state.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }
}
```

### 7.2 AsyncNotifier (비동기 상태)

비동기 작업을 포함하는 Notifier입니다.

```dart
// presentation/providers/posts_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/usecases/get_posts_usecase.dart';
import '../../../domain/usecases/create_post_usecase.dart';

part 'posts_provider.g.dart';

@riverpod
class Posts extends _$Posts {
  @override
  Future<List<Post>> build() async {
    // 초기 데이터 로드
    return _fetchPosts();
  }

  Future<List<Post>> _fetchPosts() async {
    final usecase = ref.read(getPostsUseCaseProvider);
    final result = await usecase(NoParams());

    return result.fold(
      (failure) => throw Exception(failure.message),
      (posts) => posts,
    );
  }

  Future<void> createPost(String title, String content) async {
    // 로딩 상태로 전환
    state = const AsyncValue.loading();

    final usecase = ref.read(createPostUseCaseProvider);
    final result = await usecase(CreatePostParams(
      title: title,
      content: content,
    ));

    state = await result.fold(
      (failure) => AsyncValue.error(
        Exception(failure.message),
        StackTrace.current,
      ),
      (_) async {
        // 성공 시 전체 목록 다시 로드
        final posts = await _fetchPosts();
        return AsyncValue.data(posts);
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPosts());
  }
}
```

### 7.3 AsyncValue.guard() 사용

에러를 자동으로 AsyncValue.error로 변환합니다.

```dart
@riverpod
class Weather extends _$Weather {
  @override
  Future<WeatherData> build(String city) async {
    return _fetchWeather(city);
  }

  Future<WeatherData> _fetchWeather(String city) async {
    final usecase = ref.read(getWeatherUseCaseProvider);
    final result = await usecase(city);

    return result.fold(
      (failure) => throw Exception(failure.message),
      (weather) => weather,
    );
  }

  Future<void> refresh(String city) async {
    // guard가 try-catch를 자동으로 처리
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchWeather(city));
  }
}
```

---

## 8. Family와 autoDispose

### 8.1 Family (매개변수를 받는 Provider)

동적 인자를 받는 Provider를 생성합니다.

```dart
// presentation/providers/product_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/usecases/get_product_usecase.dart';

part 'product_provider.g.dart';

// 제품 ID를 받는 Provider
@riverpod
Future<Product> product(Ref ref, String productId) async {
  final usecase = ref.read(getProductUseCaseProvider);
  final result = await usecase(productId);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (product) => product,
  );
}

// UI에서 사용
// ref.watch(productProvider('product123'))
```

```dart
// 여러 매개변수를 받는 경우
@riverpod
Future<List<Product>> productsByCategory(
  Ref ref,
  String category,
  int page,
) async {
  final usecase = ref.read(getProductsByCategoryUseCaseProvider);
  final result = await usecase(ProductsParams(
    category: category,
    page: page,
  ));

  return result.fold(
    (failure) => throw Exception(failure.message),
    (products) => products,
  );
}

// UI에서 사용
// ref.watch(productsByCategoryProvider('electronics', 1))
```

### 8.2 autoDispose (자동 메모리 해제)

사용하지 않을 때 Provider를 자동으로 해제합니다.

```dart
// presentation/providers/search_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_provider.g.dart';

// Code Generation에서는 기본적으로 autoDispose가 활성화됨
@riverpod
Future<List<String>> searchResults(Ref ref, String query) async {
  // 화면을 벗어나면 자동으로 dispose됨
  await Future.delayed(const Duration(seconds: 1));
  return ['Result 1', 'Result 2', 'Result 3'];
}

// keepAlive로 자동 dispose 방지
@Riverpod(keepAlive: true)
Future<List<String>> persistentSearch(Ref ref, String query) async {
  // 화면을 벗어나도 유지됨
  await Future.delayed(const Duration(seconds: 1));
  return ['Result 1', 'Result 2', 'Result 3'];
}
```

### 8.3 keepAlive() 메서드

런타임에 keepAlive를 동적으로 설정합니다.

```dart
@riverpod
Future<UserData> userData(Ref ref, String userId) async {
  // 데이터를 로드한 후에는 캐시 유지
  final link = ref.keepAlive();

  // import 'dart:async'; 필요
  // 30초 후 자동 dispose 허용
  Timer(const Duration(seconds: 30), () {
    link.close();
  });

  final usecase = ref.read(getUserDataUseCaseProvider);
  final result = await usecase(userId);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (user) => user,
  );
}
```

### 8.4 Family + autoDispose 조합

```dart
// presentation/providers/paginated_posts_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'paginated_posts_provider.g.dart';

// 페이지별로 캐시되지만, 사용하지 않으면 해제됨
@riverpod
Future<List<Post>> paginatedPosts(Ref ref, int page) async {
  final usecase = ref.read(getPostsUseCaseProvider);
  final result = await usecase(GetPostsParams(page: page));

  return result.fold(
    (failure) => throw Exception(failure.message),
    (posts) => posts,
  );
}

// UI에서 사용
// ref.watch(paginatedPostsProvider(1))  // 페이지 1
// ref.watch(paginatedPostsProvider(2))  // 페이지 2 (별도 캐시)
```

---

## 9. UI 연동

### 9.1 ConsumerWidget

가장 기본적인 위젯입니다. StatelessWidget의 Riverpod 버전입니다.

```dart
// presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/posts_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (posts) => ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return ListTile(
              title: Text(post.title),
              subtitle: Text(post.content),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Provider 새로고침
          ref.invalidate(postsProvider);
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

### 9.2 Consumer (부분 재빌드)

위젯 트리의 일부만 재빌드합니다.

```dart
// presentation/widgets/user_avatar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Profile'),
        // Consumer만 재빌드됨
        Consumer(
          builder: (context, ref, child) {
            final userAsync = ref.watch(currentUserProvider);
            return userAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => const Icon(Icons.error),
              data: (user) => CircleAvatar(
                backgroundImage: NetworkImage(user.avatarUrl),
              ),
            );
          },
        ),
        const Text('Settings'),  // 재빌드 안됨
      ],
    );
  }
}
```

### 9.3 ConsumerStatefulWidget

StatefulWidget의 Riverpod 버전입니다.

```dart
// presentation/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          onChanged: (value) {
            setState(() {
              _query = value;
            });
          },
          decoration: const InputDecoration(
            hintText: 'Search...',
          ),
        ),
      ),
      body: searchResultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (results) => ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            return ListTile(title: Text(results[index]));
          },
        ),
      ),
    );
  }
}
```

### 9.4 HookConsumerWidget (flutter_hooks 연동)

flutter_hooks와 Riverpod을 함께 사용합니다.

```dart
// pubspec.yaml에 추가
// dependencies:
//   hooks_riverpod: ^3.0.0

// presentation/screens/animated_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AnimatedScreen extends HookConsumerWidget {
  const AnimatedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hook 사용
    final controller = useAnimationController(
      duration: const Duration(seconds: 1),
    );
    final textController = useTextEditingController();

    // Provider 사용
    final dataAsync = ref.watch(dataProvider);

    useEffect(() {
      controller.forward();
      return null;
    }, []);

    return Scaffold(
      body: Column(
        children: [
          FadeTransition(
            opacity: controller,
            child: const Text('Animated'),
          ),
          TextField(controller: textController),
        ],
      ),
    );
  }
}
```

---

## 10. 스코핑과 오버라이드

### 10.1 ProviderScope

Provider의 스코프를 정의합니다. 앱 루트에 반드시 배치해야 합니다.

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### 10.2 overrides (의존성 교체)

테스트나 특정 상황에서 Provider를 교체합니다.

```dart
// main.dart (개발 환경)
void main() {
  runApp(
    ProviderScope(
      overrides: [
        // Dio를 Mock으로 교체
        dioProvider.overrideWithValue(
          Dio(BaseOptions(baseUrl: 'https://dev.api.example.com')),
        ),
        // API 키 교체
        apiKeyProvider.overrideWithValue('DEV_API_KEY'),
      ],
      child: const MyApp(),
    ),
  );
}
```

### 10.3 중첩된 ProviderScope

서브트리에서 Provider를 오버라이드합니다.

```dart
// presentation/screens/preview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        // 이 서브트리에서만 Mock 데이터 사용
        userProvider.overrideWith((ref) async {
          return User(id: 'preview', name: 'Preview User');
        }),
      ],
      child: const UserProfileWidget(),
    );
  }
}
```

### 10.4 테스트에서의 오버라이드

```dart
// test/presentation/screens/home_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  testWidgets('HomeScreen displays posts', (tester) async {
    // Mock Repository
    final mockRepository = MockPostRepository();
    when(() => mockRepository.getPosts()).thenAnswer(
      (_) async => Right([
        Post(id: '1', title: 'Test Post'),
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Repository를 Mock으로 교체
          postRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Post'), findsOneWidget);
  });
}
```

---

## 11. Clean Architecture 연동

### 11.1 계층별 Provider 구성

```
Domain Layer (순수 Dart)
├── Entities (비즈니스 객체)
├── Repositories (인터페이스)
└── UseCases (비즈니스 로직)

Data Layer
├── Models (DTO, JSON 직렬화)
├── DataSources (API, Local DB)
└── Repositories (구현체)

Presentation Layer
├── Providers (Riverpod)
├── Screens (UI)
└── Widgets (재사용 컴포넌트)
```

### 11.2 전체 예시

```dart
// domain/entities/product.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required double price,
    required String imageUrl,
  }) = _Product;
}

// domain/repositories/product_repository.dart
import 'package:fpdart/fpdart.dart';
import '../entities/product.dart';
import '../../../core/errors/failures.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts();
  Future<Either<Failure, Product>> getProductById(String id);
}

// domain/usecases/get_products_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../data/repositories/product_repository_impl.dart';

part 'get_products_usecase.g.dart';

@riverpod
GetProductsUseCase getProductsUseCase(Ref ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetProductsUseCase(repository);
}

class GetProductsUseCase {
  final ProductRepository _repository;

  GetProductsUseCase(this._repository);

  Future<Either<Failure, List<Product>>> call() {
    return _repository.getProducts();
  }
}

// data/models/product_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/product.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class ProductModel with _$ProductModel {
  const ProductModel._();

  const factory ProductModel({
    required String id,
    required String name,
    required double price,
    @JsonKey(name: 'image_url') required String imageUrl,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  // Entity로 변환
  Product toEntity() {
    return Product(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
    );
  }
}

// data/datasources/product_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/product_model.dart';
import '../../../core/providers/dio_provider.dart';

part 'product_remote_datasource.g.dart';

@riverpod
ProductRemoteDataSource productRemoteDataSource(
  Ref ref,
) {
  final dio = ref.watch(dioProvider);
  return ProductRemoteDataSourceImpl(dio);
}

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel> getProductById(String id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final Dio _dio;

  ProductRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await _dio.get('/products');
    final List<dynamic> data = response.data;
    return data.map((json) => ProductModel.fromJson(json)).toList();
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    final response = await _dio.get('/products/$id');
    return ProductModel.fromJson(response.data);
  }
}

// data/repositories/product_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../core/errors/failures.dart';
import '../datasources/product_remote_datasource.dart';

part 'product_repository_impl.g.dart';

@riverpod
ProductRepository productRepository(Ref ref) {
  final dataSource = ref.watch(productRemoteDataSourceProvider);
  return ProductRepositoryImpl(dataSource);
}

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _dataSource;

  ProductRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final models = await _dataSource.getProducts();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      final model = await _dataSource.getProductById(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// presentation/providers/products_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/usecases/get_products_usecase.dart';

part 'products_provider.g.dart';

@riverpod
class Products extends _$Products {
  @override
  Future<List<Product>> build() async {
    return _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    final usecase = ref.read(getProductsUseCaseProvider);
    final result = await usecase();

    return result.fold(
      (failure) => throw Exception(failure.message),
      (products) => products,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProducts());
  }
}

// presentation/screens/products_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/products_provider.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: Image.network(product.imageUrl, width: 50, height: 50),
              title: Text(product.name),
              subtitle: Text('\$${product.price}'),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(productsProvider.notifier).refresh(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

---

## 12. Bloc에서 마이그레이션

### 12.1 마이그레이션 전략

| 단계 | 작업 | 비고 |
|------|------|------|
| 1 | 새 기능은 Riverpod으로 작성 | 점진적 전환 |
| 2 | 단순한 Bloc부터 변환 | 카운터, 토글 등 |
| 3 | 복잡한 Bloc은 유지 | 핵심 비즈니스 로직 |
| 4 | 공통 Provider 구축 | Dio, SharedPreferences 등 |
| 5 | 완전 전환 또는 혼용 | 프로젝트 상황에 따라 |

### 12.2 Bloc → Riverpod 변환 예시

**Before (Bloc):**

```dart
// presentation/bloc/counter_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'counter_event.dart';
part 'counter_state.dart';
part 'counter_bloc.freezed.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState(count: 0)) {
    on<CounterEvent>((event, emit) {
      event.when(
        increment: () => emit(state.copyWith(count: state.count + 1)),
        decrement: () => emit(state.copyWith(count: state.count - 1)),
      );
    });
  }
}

// UI
class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterBloc(),
      child: BlocBuilder<CounterBloc, CounterState>(
        builder: (context, state) {
          return Column(
            children: [
              Text('Count: ${state.count}'),
              ElevatedButton(
                onPressed: () => context.read<CounterBloc>().add(
                  const CounterEvent.increment(),
                ),
                child: const Text('Increment'),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

**After (Riverpod):**

```dart
// presentation/providers/counter_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_provider.g.dart';

@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
}

// UI
class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);

    return Column(
      children: [
        Text('Count: $count'),
        ElevatedButton(
          onPressed: () => ref.read(counterProvider.notifier).increment(),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

### 12.3 복잡한 Bloc → AsyncNotifier 변환

**Before (Bloc with UseCase):**

```dart
class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final GetPostsUseCase _getPostsUseCase;
  final CreatePostUseCase _createPostUseCase;

  PostsBloc(this._getPostsUseCase, this._createPostUseCase)
      : super(const PostsState.initial()) {
    on<_Load>(_onLoad);
    on<_Create>(_onCreate);
  }

  Future<void> _onLoad(_Load event, Emitter<PostsState> emit) async {
    emit(const PostsState.loading());

    final result = await _getPostsUseCase(NoParams());

    result.fold(
      (failure) => emit(PostsState.error(failure)),
      (posts) => emit(PostsState.loaded(posts)),
    );
  }

  Future<void> _onCreate(_Create event, Emitter<PostsState> emit) async {
    final result = await _createPostUseCase(CreatePostParams(
      title: event.title,
      content: event.content,
    ));

    result.fold(
      (failure) => emit(PostsState.error(failure)),
      (_) => add(const PostsEvent.load()),
    );
  }
}
```

**After (Riverpod AsyncNotifier):**

```dart
@riverpod
class Posts extends _$Posts {
  @override
  Future<List<Post>> build() async {
    return _fetchPosts();
  }

  Future<List<Post>> _fetchPosts() async {
    final usecase = ref.read(getPostsUseCaseProvider);
    final result = await usecase(NoParams());

    return result.fold(
      (failure) => throw Exception(failure.message),
      (posts) => posts,
    );
  }

  Future<void> createPost(String title, String content) async {
    state = const AsyncValue.loading();

    final usecase = ref.read(createPostUseCaseProvider);
    final result = await usecase(CreatePostParams(
      title: title,
      content: content,
    ));

    state = await result.fold(
      (failure) => AsyncValue.error(
        Exception(failure.message),
        StackTrace.current,
      ),
      (_) async => AsyncValue.data(await _fetchPosts()),
    );
  }
}
```

### 12.4 Bloc과 Riverpod 혼용

```dart
// main.dart - 두 시스템을 함께 사용
void main() {
  runApp(
    ProviderScope(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<AuthBloc>()),  // Bloc
          BlocProvider(create: (_) => getIt<ThemeBloc>()), // Bloc
        ],
        child: const MyApp(),
      ),
    ),
  );
}

// 화면에서 두 시스템 함께 사용
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod
    final postsAsync = ref.watch(postsProvider);

    return BlocBuilder<AuthBloc, AuthState>(  // Bloc
      builder: (context, authState) {
        return authState.when(
          authenticated: (user) => postsAsync.when(
            loading: () => const CircularProgressIndicator(),
            data: (posts) => PostsList(posts: posts),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
          unauthenticated: () => const LoginScreen(),
        );
      },
    );
  }
}
```

---

## 13. 테스트

### 13.1 Provider 단위 테스트

```dart
// test/presentation/providers/counter_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('Counter should increment', () {
    // ProviderContainer 생성
    final container = ProviderContainer();

    // 초기값 확인
    expect(container.read(counterProvider), 0);

    // Increment 실행
    container.read(counterProvider.notifier).increment();

    // 결과 확인
    expect(container.read(counterProvider), 1);

    // 정리
    container.dispose();
  });
}
```

### 13.2 AsyncNotifier 테스트

```dart
// test/presentation/providers/posts_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  late MockGetPostsUseCase mockUseCase;
  late ProviderContainer container;

  setUp(() {
    mockUseCase = MockGetPostsUseCase();

    container = ProviderContainer(
      overrides: [
        // UseCase를 Mock으로 교체
        getPostsUseCaseProvider.overrideWithValue(mockUseCase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('Posts should load successfully', () async {
    // Mock 설정
    when(() => mockUseCase(NoParams())).thenAnswer(
      (_) async => Right([
        Post(id: '1', title: 'Test Post'),
      ]),
    );

    // Provider 읽기
    final postsAsync = container.read(postsProvider.future);

    // 결과 확인
    final posts = await postsAsync;
    expect(posts.length, 1);
    expect(posts.first.title, 'Test Post');
  });

  test('Posts should handle error', () async {
    // Mock 설정
    when(() => mockUseCase(NoParams())).thenAnswer(
      (_) async => Left(ServerFailure('Network error')),
    );

    // Provider 읽기
    expect(
      () => container.read(postsProvider.future),
      throwsA(isA<Exception>()),
    );
  });
}
```

### 13.3 위젯 테스트

```dart
// test/presentation/screens/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  testWidgets('HomeScreen displays posts', (tester) async {
    // Mock 설정
    final mockUseCase = MockGetPostsUseCase();
    when(() => mockUseCase(NoParams())).thenAnswer(
      (_) async => Right([
        Post(id: '1', title: 'Test Post'),
      ]),
    );

    // 위젯 렌더링
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getPostsUseCaseProvider.overrideWithValue(mockUseCase),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // 로딩 확인
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 데이터 로드 대기
    await tester.pumpAndSettle();

    // 포스트 표시 확인
    expect(find.text('Test Post'), findsOneWidget);
  });
}
```

### 13.4 통합 테스트

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-end flow', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MyApp()),
    );

    // 로그인 화면 확인
    expect(find.text('Login'), findsOneWidget);

    // 로그인 실행
    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    // 홈 화면 확인
    expect(find.text('Home'), findsOneWidget);
  });
}
```

---

## 14. Best Practices

### 14.1 Do's and Don'ts

| ✅ DO | ❌ DON'T |
|-------|----------|
| Code Generation 사용 | 수동으로 Provider 작성 |
| build 메서드에서 `ref.watch` | build 메서드에서 `ref.read` |
| 이벤트 핸들러에서 `ref.read` | 이벤트 핸들러에서 `ref.watch` |
| Notifier로 복잡한 로직 캡슐화 | StateProvider에 복잡한 로직 |
| AsyncValue로 로딩/에러 처리 | try-catch로 에러 처리 |
| Family로 매개변수 전달 | 글로벌 변수 사용 |
| autoDispose로 메모리 관리 | 모든 Provider를 keepAlive |
| ProviderScope로 테스트 | 실제 API 호출 테스트 |

### 14.2 성능 최적화

```dart
// ❌ 나쁜 예: 전체 리스트를 watch
class TodoList extends ConsumerWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todosProvider);  // 전체 재빌드

    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) => TodoItem(todo: todos[index]),
    );
  }
}

// ✅ 좋은 예: select로 필요한 부분만 watch
class TodoList extends ConsumerWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoCount = ref.watch(
      todosProvider.select((todos) => todos.length),  // 개수만 감시
    );

    return ListView.builder(
      itemCount: todoCount,
      itemBuilder: (context, index) => TodoItemProvider(index: index),
    );
  }
}

class TodoItemProvider extends ConsumerWidget {
  final int index;
  const TodoItemProvider({required this.index, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(
      todosProvider.select((todos) => todos[index]),  // 개별 아이템만 감시
    );

    return TodoItem(todo: todo);
  }
}
```

### 14.3 에러 처리 패턴

```dart
// ✅ 좋은 예: Either 패턴 + AsyncValue
@riverpod
class UserProfile extends _$UserProfile {
  @override
  Future<User> build(String userId) async {
    final usecase = ref.read(getUserUseCaseProvider);
    final result = await usecase(userId);

    return result.fold(
      (failure) {
        // 구체적인 에러 타입으로 변환
        if (failure is NetworkFailure) {
          throw NetworkException(failure.message);
        } else if (failure is NotFoundFailure) {
          throw NotFoundException(failure.message);
        }
        throw UnknownException(failure.message);
      },
      (user) => user,
    );
  }
}

// UI에서 에러 타입별 처리
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileNotifierProvider('user123'));

    return userAsync.when(
      loading: () => const CircularProgressIndicator(),
      data: (user) => UserDetails(user: user),
      error: (error, stack) {
        if (error is NetworkException) {
          return const NetworkErrorWidget();
        } else if (error is NotFoundException) {
          return const NotFoundWidget();
        }
        return Center(child: Text('Error: ${error.toString()}'));
      },
    );
  }
}
```

### 14.4 Provider 조직화

```dart
// ❌ 나쁜 예: 모든 Provider를 하나의 파일에
// providers/providers.dart (1000+ lines)

// ✅ 좋은 예: 기능별로 분리
// core/providers/dio_provider.dart
// core/providers/shared_prefs_provider.dart
// features/auth/presentation/providers/auth_provider.dart
// features/home/presentation/providers/home_provider.dart
```

### 14.5 의존성 주입 패턴

```dart
// ✅ 좋은 예: 계층별 Provider 체이닝
@riverpod
Dio dio(Ref ref) => Dio();

@riverpod
UserRemoteDataSource userRemoteDataSource(Ref ref) {
  return UserRemoteDataSourceImpl(ref.watch(dioProvider));
}

@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepositoryImpl(ref.watch(userRemoteDataSourceProvider));
}

@riverpod
GetUserUseCase getUserUseCase(Ref ref) {
  return GetUserUseCase(ref.watch(userRepositoryProvider));
}

@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<UserEntity> build(String userId) async {
    final usecase = ref.watch(getUserUseCaseProvider);
    final result = await usecase(userId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (user) => user,
    );
  }
}
```

### 14.6 Debugging Tips

```dart
// Provider Inspector 사용 (DevTools)
// 1. DevTools 열기
// 2. Riverpod 탭 선택
// 3. Provider 상태 실시간 확인

// Provider Observer로 로깅
class MyProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    debugPrint('''
{
  "provider": "${provider.name ?? provider.runtimeType}",
  "previousValue": "$previousValue",
  "newValue": "$newValue"
}
''');
  }
}

// main.dart
void main() {
  runApp(
    ProviderScope(
      observers: [MyProviderObserver()],
      child: const MyApp(),
    ),
  );
}
```

---

## 요약

Riverpod은 Provider의 개선된 버전으로, 다음과 같은 이점을 제공합니다:

1. **컴파일 타임 안전성**: Code Generation으로 타입 안전성 보장
2. **테스트 용이성**: ProviderContainer로 독립 테스트
3. **적은 보일러플레이트**: Bloc 대비 간결한 코드
4. **내장 DI**: Provider 간 의존성 자동 해결
5. **AsyncValue**: 로딩/데이터/에러 상태를 명시적으로 처리

**언제 사용할까?**
- 빠른 프로토타이핑
- 간단한 상태 관리
- 보일러플레이트 최소화
- Code Generation 활용

**Bloc을 선택할 때:**
- 복잡한 비즈니스 로직
- Event 기반 추적 필요
- 팀이 Bloc에 익숙함

Riverpod과 Bloc은 각각의 장점이 있으며, 프로젝트 요구사항에 따라 선택하거나 혼용할 수 있습니다.

---

## 실습 과제

### 과제 1: Riverpod Provider 타입 실습
StateProvider, FutureProvider, StreamProvider, NotifierProvider를 각각 사용하여 간단한 카운터, API 호출, 실시간 데이터, 복합 상태 관리를 구현하세요.

### 과제 2: Bloc vs Riverpod 비교 프로젝트
동일한 기능(예: Todo 앱)을 Bloc과 Riverpod으로 각각 구현하고, 코드량, 보일러플레이트, 테스트 용이성, 러닝 커브를 비교 분석하세요.

## Self-Check

- [ ] Provider, StateProvider, FutureProvider, NotifierProvider의 차이를 설명할 수 있다
- [ ] @riverpod 어노테이션을 사용한 코드 생성 방식을 적용할 수 있다
- [ ] ref.watch, ref.read, ref.listen의 사용 시나리오를 구분할 수 있다
- [ ] Riverpod과 Bloc의 장단점을 프로젝트 맥락에서 비교할 수 있다

---
**다음 문서:** [Isolates](../system/Isolates.md) - Flutter Isolate & 동시성 프로그래밍
