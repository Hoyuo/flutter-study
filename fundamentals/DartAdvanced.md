# Dart 언어 심화 가이드

> Flutter Clean Architecture + Bloc 패턴 기반 교육 자료
> Package versions: flutter_bloc ^9.1.1, freezed ^3.2.4, fpdart ^1.2.0, go_router ^17.0.1, get_it ^9.2.0, injectable ^2.5.0

> **학습 목표**:
> - Dart의 고급 타입 시스템(Generics, Sealed Class, Records)을 실전에서 활용할 수 있다
> - Extension Methods와 Mixin을 활용해 재사용 가능한 코드를 작성할 수 있다
> - 비동기 프로그래밍의 심화 기법(Stream, Zone, Isolate)을 이해하고 적용할 수 있다

## 목차

1. [Generics 심화](#1-generics-심화)
2. [Extension Methods](#2-extension-methods)
3. [Mixin](#3-mixin)
4. [Sealed Class & Pattern Matching](#4-sealed-class--pattern-matching)
5. [Records & Destructuring](#5-records--destructuring)
6. [비동기 심화](#6-비동기-심화)
7. [메타프로그래밍](#7-메타프로그래밍)
8. [메모리 관리](#8-메모리-관리)
9. [Isolate 기초](#9-isolate-기초)
10. [실습 과제](#실습-과제)
11. [Self-Check](#self-check)

---

## 1. Generics 심화

### 1.1 제네릭 클래스와 메서드

Generics는 타입 안정성을 유지하면서 재사용 가능한 코드를 작성하는 핵심 기법입니다.

```dart
// 기본 제네릭 클래스
class Result<T> {
  final T? data;
  final String? error;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}

// 사용 예시
Result<User> userResult = Result.success(User(name: 'Alice'));
Result<int> countResult = Result.failure('Network error');
```

### 1.2 타입 바운드 (Type Bounds)

제네릭 타입에 제약을 걸어 특정 타입만 허용할 수 있습니다.

```dart
// Comparable을 구현한 타입만 허용
class SortedList<T extends Comparable<T>> {
  final List<T> _items = [];

  void add(T item) {
    _items.add(item);
    _items.sort();
  }

  T? get min => _items.isEmpty ? null : _items.first;
  T? get max => _items.isEmpty ? null : _items.last;
}

// 사용 가능
final numbers = SortedList<int>();
numbers.add(5);
numbers.add(2);
print(numbers.min); // 2
```

### 1.3 제네릭 메서드

```dart
// 제네릭 메서드
T firstWhere<T>(List<T> items, bool Function(T) test, {required T orElse}) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return orElse;
}

// 사용 예시
final numbers = [1, 2, 3, 4, 5];
final result = firstWhere<int>(
  numbers,
  (n) => n > 3,
  orElse: -1,
); // 4
```

### 1.4 공변과 반변 (Covariance & Contravariance)

Dart의 제네릭은 기본적으로 공변(covariant)입니다.

```dart
class Animal {
  void makeSound() => print('Some sound');
}

class Dog extends Animal {
  @override
  void makeSound() => print('Bark');
}

// 공변: Iterable은 읽기 전용이므로 안전
void printAnimalsIterable(Iterable<Animal> animals) {
  for (final animal in animals) {
    animal.makeSound();
  }
}

void covariantExample() {
  final dogs = <Dog>[Dog(), Dog()];
  printAnimalsIterable(dogs); // OK!
}

// ⚠️ 주의: Dart의 제네릭 공변성은 unsound합니다
// 컴파일은 통과하지만 런타임 에러가 발생할 수 있습니다
void unsoundExample() {
  List<Animal> animals = <Dog>[Dog(), Dog()]; // 컴파일 OK
  // animals.add(Cat()); // 런타임 TypeError! List<Dog>에 Cat 추가 불가
}

// covariant 키워드: 메서드 파라미터의 타입을 하위 타입으로 좁힐 때
class AnimalShelter {
  void adopt(covariant Animal animal) {}
}

class DogShelter extends AnimalShelter {
  @override
  void adopt(Dog dog) {} // covariant 덕분에 Dog로 좁힐 수 있음
}
```

---

## 2. Extension Methods

Extension Methods는 기존 클래스를 수정하지 않고 새로운 기능을 추가할 수 있는 강력한 기능입니다.

### 2.1 기본 Extension

```dart
// String 확장
extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  // 참고: 실무에서는 서버 측 검증을 병행하세요
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    return emailRegex.hasMatch(this);
  }

  // Dart 내장: 'abc' * 3 == 'abcabcabc'
  // 대신 더 유용한 extension을 정의합시다
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }
}

// 사용
print('hello'.capitalize()); // Hello
print('test@example.com'.isValidEmail); // true
print('Hello, World!'.truncate(8)); // Hello...
```

### 2.2 List Extension

```dart
// 참고: package:collection에 동일한 extension이 존재합니다
// 실무에서는 공식 패키지 사용을 권장하며, 여기서는 학습 목적으로 직접 구현합니다
extension ListExtensions<T> on List<T> {
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  Map<K, List<T>> groupBy<K>(K Function(T) keySelector) {
    final map = <K, List<T>>{};
    for (final element in this) {
      final key = keySelector(element);
      map.putIfAbsent(key, () => []).add(element);
    }
    return map;
  }
}
```

### 2.3 Nullable Extension

```dart
extension NullableExtensions<T> on T? {
  T orElse(T defaultValue) {
    return this ?? defaultValue;
  }

  R? let<R>(R Function(T) transform) {
    final value = this;
    return value != null ? transform(value) : null;
  }
}
```

---

## 3. Mixin

Mixin은 클래스의 코드를 다른 클래스에서 재사용하는 방법입니다.

### 3.1 기본 Mixin

```dart
mixin Timestamps {
  DateTime? createdAt;
  DateTime? updatedAt;

  void markCreated() {
    createdAt = DateTime.now();
  }

  void markUpdated() {
    updatedAt = DateTime.now();
  }
}

mixin Validation {
  final List<String> _errors = [];

  List<String> get errors => List.unmodifiable(_errors);
  bool get isValid => _errors.isEmpty;

  void addError(String error) {
    _errors.add(error);
  }

  void clearErrors() {
    _errors.clear();
  }
}

// Mixin 사용
class User with Timestamps, Validation {
  String name;
  String email;

  User(this.name, this.email) {
    markCreated();
    validate();
  }

  void validate() {
    clearErrors();
    if (name.isEmpty) addError('Name is required');
    if (!email.contains('@')) addError('Invalid email');
  }
}
```

### 3.2 Mixin의 제약 조건

```dart
abstract class Animal {
  String get species;
  void makeSound();
}

mixin Flyable on Animal {
  double wingSpan = 0;

  void fly() {
    print('$species is flying with ${wingSpan}m wingspan');
  }
}

mixin Swimmable on Animal {
  double swimSpeed = 0;

  void swim() {
    print('$species is swimming at ${swimSpeed}km/h');
  }
}

// Animal을 상속한 클래스만 Flyable, Swimmable 사용 가능
class Duck extends Animal with Flyable, Swimmable {
  @override
  String get species => 'Duck';

  @override
  void makeSound() => print('Quack');

  Duck() {
    wingSpan = 0.5;
    swimSpeed = 3.0;
  }
}
```

### 3.3 Mixin Class (Dart 3.0+)

`mixin class`는 클래스와 mixin 두 가지 역할을 동시에 수행할 수 있습니다.

```dart
// mixin class: 클래스로도, mixin으로도 사용 가능
mixin class Identifiable {
  String id = '';

  String get shortId => id.substring(0, 8);
}

// mixin으로 사용
class User with Identifiable {
  String name;
  User(this.name);
}

// 클래스로 상속
class AdminUser extends Identifiable {
  String role;
  AdminUser(this.role);
}
```

> **mixin vs mixin class**: 일반 `mixin`은 `with`로만 사용 가능하고, `mixin class`는 `extends`와 `with` 모두 가능합니다. 단, `mixin class`는 `on` 절을 사용할 수 없습니다.

---

## 4. Sealed Class & Pattern Matching

Dart 3.0에서 도입된 Sealed Class는 타입 안전한 상태 관리와 패턴 매칭을 가능하게 합니다.

### 4.1 Sealed Class 기본

```dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  const Failure(this.message);
}

class Loading<T> extends Result<T> {
  const Loading();
}

// 패턴 매칭
String handleResult<T>(Result<T> result) {
  return switch (result) {
    Success(:final data) => 'Success: $data',
    Failure(:final message) => 'Error: $message',
    Loading() => 'Loading...',
  };
}
```

### 4.2 Guard Clauses

```dart
sealed class Shape {}

class Circle extends Shape {
  final double radius;
  Circle(this.radius);
}

class Rectangle extends Shape {
  final double width;
  final double height;
  Rectangle(this.width, this.height);
}

// import 'dart:math' show pi;
double calculateArea(Shape shape) {
  return switch (shape) {
    Circle(:final radius) when radius > 0 => pi * radius * radius,
    Circle() => throw ArgumentError('Invalid radius'),
    Rectangle(:final width, :final height) when width > 0 && height > 0 =>
      width * height,
    Rectangle() => throw ArgumentError('Invalid dimensions'),
  };
}
```

---

## 5. Records & Destructuring

Dart 3.0에서 도입된 Records는 여러 값을 묶어 반환하거나 전달하는 간단한 방법을 제공합니다.

### 5.1 Record 기본

```dart
// Positional record
(int, String) getUserInfo() {
  return (42, 'Alice');
}

// Named record
({int age, String name}) getUserInfoNamed() {
  return (age: 42, name: 'Alice');
}

// 사용
void recordExample() {
  // Destructuring
  final (age, name) = getUserInfo();
  print('$name is $age years old');

  // Named destructuring
  final (age: userAge, name: userName) = getUserInfoNamed();
  print('$userName is $userAge years old');
}
```

### 5.2 Multiple Return Values

```dart
// 통계 계산
(double mean, double median) calculateStats(List<double> values) {
  if (values.isEmpty) return (0, 0);

  final sum = values.reduce((a, b) => a + b);
  final mean = sum / values.length;

  final sorted = List<double>.from(values)..sort();
  final mid = sorted.length ~/ 2;
  final median = sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;

  return (mean, median);
}

// 사용
final (mean, median) = calculateStats([1.0, 2.0, 3.0, 4.0, 5.0]);
print('Mean: $mean, Median: $median');
```

---

## 6. 비동기 심화

### 6.1 Future 고급 패턴

```dart
// 병렬 실행
Future<void> parallelExecution() async {
  final futures = [
    fetchData(1),
    fetchData(2),
    fetchData(3),
  ];

  final results = await Future.wait(futures);
  print('Results: $results');
}

// 첫 번째 완료된 결과만 사용
Future<void> raceExecution() async {
  final result = await Future.any([
    fetchData(1, delay: 3),
    fetchData(2, delay: 1),
    fetchData(3, delay: 2),
  ]);
  print('First result: $result');
}

Future<int> fetchData(int id, {int delay = 1}) async {
  await Future.delayed(Duration(seconds: delay));
  return id * 10;
}
```

### 6.2 Stream 기초와 심화

```dart
// 기본 Stream 생성
Stream<int> countStream(int max) async* {
  for (var i = 1; i <= max; i++) {
    await Future.delayed(Duration(milliseconds: 500));
    yield i;
  }
}

// import 'dart:async';
class EventBus {
  final _controller = StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void emit(String event) {
    _controller.add(event);
  }

  void close() {
    _controller.close();
  }
}
```

### 6.3 Retry 패턴

```dart
// 지수 백오프를 사용한 재시도
Future<T> retryWithExponentialBackoff<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
  double backoffMultiplier = 2.0,
}) async {
  var attempt = 0;
  var delay = initialDelay;

  while (true) {
    try {
      return await operation();
    } catch (e) {
      attempt++;
      if (attempt >= maxAttempts) rethrow;

      print('Attempt $attempt failed, retrying in ${delay.inSeconds}s...');
      await Future.delayed(delay);
      delay = delay * backoffMultiplier;
    }
  }
}
```

---

## 7. 메타프로그래밍

### 7.1 Annotation 기초

```dart
// 커스텀 annotation
class ApiEndpoint {
  final String path;
  final String method;

  const ApiEndpoint({
    required this.path,
    this.method = 'GET',
  });
}

// 사용
@ApiEndpoint(path: '/users', method: 'GET')
class UserApi {
  // API 엔드포인트 구현
}
```

### 7.2 freezed 패턴

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    int? age,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

> **코드 생성 실행**: freezed, injectable 등은 `build_runner`로 코드를 생성합니다.
> ```bash
> # 일회성 빌드
> dart run build_runner build --delete-conflicting-outputs
>
> # 파일 변경 감지 자동 빌드 (개발 중 권장)
> dart run build_runner watch --delete-conflicting-outputs
> ```
> `part 'user.freezed.dart'`는 build_runner가 생성할 파일을 선언합니다. 이 파일은 직접 수정하지 않으며, 소스 코드 변경 시 자동으로 재생성됩니다.

### 7.3 injectable 패턴

```dart
import 'package:injectable/injectable.dart';

@injectable
class ApiService {
  Future<String> fetchData() async {
    return 'Data from API';
  }
}

@injectable
class UserRepository {
  final ApiService _apiService;

  UserRepository(this._apiService);

  Future<User?> getUser(String id) async {
    return null;
  }
}

@singleton
class AppSettings {
  String apiUrl = 'https://api.example.com';
}
```

---

## 8. 메모리 관리

### 8.1 Garbage Collection 이해

```dart
import 'dart:async';

// ❌ Bad: 캐시 크기 제한 없음 → 메모리 무한 증가
class UnboundedCache {
  final Map<String, Object> _cache = {};

  void put(String key, Object value) {
    _cache[key] = value; // 계속 쌓임
  }
}

// ✅ Good: LRU 방식으로 크기 제한
class BoundedCache {
  final int maxSize;
  final Map<String, Object> _cache = {};

  BoundedCache({this.maxSize = 100});

  void put(String key, Object value) {
    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first); // 가장 오래된 항목 제거
    }
    _cache[key] = value;
  }

  Object? get(String key) => _cache[key];
}

// Stream 구독 누수 방지
class StreamExample {
  StreamSubscription? _subscription;

  void startListening(Stream<int> stream) {
    _subscription = stream.listen((data) {
      print(data);
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
```

### 8.2 WeakReference

```dart
class CacheWithWeakReference {
  final Map<String, WeakReference<Object>> _cache = {};

  void put(String key, Object value) {
    _cache[key] = WeakReference(value);
  }

  Object? get(String key) {
    final ref = _cache[key];
    return ref?.target;
  }

  void cleanup() {
    _cache.removeWhere((key, ref) => ref.target == null);
  }
}
```

---

## 9. Isolate 기초

### 9.1 Isolate.run() (권장)

Dart 2.19+에서 도입된 `Isolate.run()`은 가장 간단한 Isolate 사용법입니다.

```dart
import 'dart:isolate';

// 단순하고 현대적인 방식 (권장)
Future<int> calculateInBackground(int n) async {
  return await Isolate.run(() {
    var sum = 0;
    for (var i = 1; i <= n; i++) {
      sum += i;
    }
    return sum;
  });
}
```

### 9.2 Isolate.spawn (양방향 통신)

양방향으로 메시지를 주고받아야 할 때는 `Isolate.spawn`을 사용합니다.

```dart
import 'dart:isolate';

Future<int> runInIsolate(int n) async {
  final receivePort = ReceivePort();

  await Isolate.spawn(_calculateSum, [receivePort.sendPort, n]);

  final result = await receivePort.first as int;
  return result;
}

void _calculateSum(List<dynamic> args) {
  final sendPort = args[0] as SendPort;
  final n = args[1] as int;

  var sum = 0;
  for (var i = 1; i <= n; i++) {
    sum += i;
  }

  sendPort.send(sum);
}
```

### 9.3 Compute 함수 (Flutter)

```dart
import 'package:flutter/foundation.dart';

int _heavyComputation(int n) {
  var sum = 0;
  for (var i = 1; i <= n; i++) {
    sum += i;
  }
  return sum;
}

Future<void> computeExample() async {
  final result = await compute(_heavyComputation, 1000000);
  print('Result: $result');
}
```

> **참고**: Flutter 3.x에서 `compute`는 여전히 사용 가능하지만, `Isolate.run()`이 Dart 팀이 공식 권장하는 대안입니다.

### 9.4 참고

Isolate에 대한 더 자세한 내용은 [core/Isolates.md](../core/Isolates.md)를 참조하세요.

---

## 실습 과제

### 과제 1: Generic Repository 구현

다음 요구사항을 만족하는 Generic Repository를 구현하세요:

**요구사항:**
1. `Repository<T extends Entity>` 인터페이스 정의
2. `InMemoryRepository<T>` 구현
3. Extension Methods 추가
4. 테스트 코드 작성

**평가 기준:**
- 타입 안정성
- Stream 메모리 누수 방지
- Extension 활용

### 과제 2: Sealed Class로 상태 관리 구현

Bloc 패턴을 사용하여 Todo 앱의 상태 관리를 구현하세요:

**요구사항:**
1. Sealed Class로 상태 정의
2. Sealed Class로 이벤트 정의
3. TodoBloc 구현
4. Widget에서 사용

**평가 기준:**
- Sealed class의 exhaustive checking 활용
- Pattern matching의 가독성
- 상태 전환 로직의 정확성

### 과제 3: 비동기 처리 고급 패턴

실전에서 자주 사용하는 비동기 패턴을 구현하세요:

**요구사항:**
1. `RetryPolicy` 클래스
2. `CacheManager` 클래스
3. `ApiClient` 클래스
4. Stream 변환 유틸리티

**평가 기준:**
- 비동기 에러 처리의 견고성
- 메모리 누수 방지
- 실전 활용 가능성

---

## Self-Check

다음 항목을 체크하며 학습 내용을 점검하세요:

- [ ] Generics의 공변/반변 개념을 이해하고, 타입 바운드를 적절히 사용할 수 있다
- [ ] Extension Methods를 활용해 기존 클래스를 확장하고, nullable 타입을 안전하게 처리할 수 있다
- [ ] Mixin과 mixin class의 차이를 이해하고, on 키워드로 제약을 설정할 수 있다
- [ ] Sealed class로 exhaustive pattern matching을 구현하고, guard clause를 활용할 수 있다
- [ ] Records와 destructuring을 사용해 다중 값을 반환하고 간결한 코드를 작성할 수 있다
- [ ] Future와 Stream의 차이를 이해하고, StreamController로 커스텀 스트림을 만들 수 있다
- [ ] Future.wait, Future.any를 활용한 병렬/경쟁 실행 패턴을 이해하고, retry 패턴을 구현할 수 있다
- [ ] build_runner와 code generation의 원리를 이해하고, freezed/injectable을 활용할 수 있다
- [ ] WeakReference를 사용한 캐시 패턴을 이해하고, Stream 구독 해제로 메모리 누수를 방지할 수 있다
- [ ] Isolate의 메모리 격리 개념을 이해하고, compute 함수로 무거운 연산을 백그라운드에서 처리할 수 있다

---

**학습 완료 후**: [fundamentals/WidgetFundamentals.md](./WidgetFundamentals.md)로 진행하여 Widget/Element/RenderObject 트리와 BuildContext를 학습하세요.
