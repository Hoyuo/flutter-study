# Dart & Flutter 인터뷰 치트시트

> **레벨 표시**: 🟢 L4 (주니어) | 🟡 L5 (미드) | 🔴 L6 (시니어)
> **마지막 업데이트**: 2026-02-08 | **Flutter 3.38** | **Dart 3.10**

---

## 1. Dart 언어 핵심

### 1.1 타입 시스템 🟢

| 키워드 | 타입 체크 | null 허용 | 용도 |
|--------|----------|----------|------|
| `var` | 추론 (고정) | X | 로컬 변수, 타입 명확할 때 |
| `dynamic` | 없음 (런타임) | O | JSON 파싱, 플랫폼 채널 |
| `Object` | 있음 (컴파일) | X | 모든 타입의 최상위 |
| `Object?` | 있음 (컴파일) | O | nullable 최상위 |
| `final` | 추론 (고정) | X | 한 번 할당, 런타임 결정 가능 |
| `const` | 추론 (고정) | X | 컴파일 타임 상수 |
| `late` | 추론 (고정) | X | 지연 초기화, non-nullable 보장 |

```dart
// Null Safety 핵심 연산자
String? name;           // nullable 선언
name!                   // null assertion (위험)
name ?? 'default'       // null 대체
name?.length            // null-aware 접근
name ??= 'fallback'    // null이면 할당

// late 활용
late final String token;  // 나중에 1번만 할당
late final db = Database.open();  // 최초 접근 시 초기화
```

### 1.2 컬렉션 주요 메서드 🟢

| 메서드 | List | Map | Set | 반환 타입 |
|--------|------|-----|-----|----------|
| `map()` | O | O | O | `Iterable<T>` |
| `where()` | O | - | O | `Iterable<T>` |
| `fold()` | O | - | O | `T` |
| `reduce()` | O | - | O | `T` |
| `any()` | O | - | O | `bool` |
| `every()` | O | - | O | `bool` |
| `expand()` | O | - | O | `Iterable<T>` |
| `toList()` | - | - | O | `List<T>` |
| `toSet()` | O | - | - | `Set<T>` |
| `entries` | - | O | - | `Iterable<MapEntry>` |
| `putIfAbsent()` | - | O | - | `V` |
| `update()` | - | O | - | `V` |

```dart
// Spread & Collection if/for
final merged = [...listA, ...listB];
final filtered = [for (final x in list) if (x > 0) x * 2];

// 자주 쓰는 패턴
list.firstWhereOrNull((e) => e.id == id);  // package:collection
map.entries.map((e) => '${e.key}: ${e.value}');
{...setA, ...setB}  // Set 합집합
setA.intersection(setB)  // 교집합
```

### 1.3 비동기: Future vs Stream 🟢

| 항목 | Future | Stream |
|------|--------|--------|
| **값** | 단일 값 | 연속 값 (0~N개) |
| **완료** | 1회 완료 | 여러 번 emit, 명시적 close |
| **생성** | `async` / `Future.value()` | `async*` / `StreamController` |
| **소비** | `await` / `.then()` | `await for` / `.listen()` |
| **에러** | `try-catch` | `onError` 콜백 / `handleError` |
| **변환** | `.then()` 체이닝 | `.map()` / `.where()` / `.expand()` |
| **취소** | 불가 (CancelToken 별도) | `subscription.cancel()` |
| **종류** | - | Single / Broadcast |

```dart
// Future 패턴
Future<List<T>> fetchAll() async {
  final results = await Future.wait([fetchA(), fetchB()]);  // 병렬
  final first = await Future.any([fetchA(), fetchB()]);     // 경쟁
  return results;
}

// Stream 패턴
Stream<int> counter(int max) async* {
  for (var i = 0; i < max; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i;  // 값 방출
  }
}

// StreamController
final controller = StreamController<String>.broadcast();
controller.stream.listen((data) => print(data));
controller.add('hello');
controller.close();  // 반드시 close!
```

### 1.4 Generics: 공변/반공변 🟡

```dart
// 공변 (Covariant) - Dart 기본
List<Dog> dogs = [Dog()];
List<Animal> animals = dogs;  // OK (Dart는 기본 공변, 단 unsound)
// animals.add(Cat());        // 런타임 TypeError!

// covariant 키워드 - 파라미터 타입을 하위로 좁힘
class AnimalShelter {
  void adopt(covariant Animal a) {}
}
class DogShelter extends AnimalShelter {
  @override
  void adopt(Dog d) {}  // Dog로 좁힘 가능
}

// Bounded Generics
class Repository<T extends Entity> { ... }
T max<T extends Comparable<T>>(T a, T b) => a.compareTo(b) >= 0 ? a : b;
```

| 개념 | 설명 | Dart 지원 |
|------|------|----------|
| 공변 (Covariant) | `List<Dog>` -> `List<Animal>` | 기본 (unsound) |
| 반공변 (Contravariant) | `Comparator<Animal>` -> `Comparator<Dog>` | 미지원 |
| 불변 (Invariant) | 타입 정확히 일치 | `covariant` 미사용 시 |

### 1.5 Extension Methods 대표 패턴 🟢

```dart
// String Extension
extension StringX on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(this);
  String truncate(int max, {String suffix = '...'}) =>
      length <= max ? this : '${substring(0, max - suffix.length)}$suffix';
}

// Nullable Extension
extension NullableX<T> on T? {
  T orElse(T fallback) => this ?? fallback;
  R? let<R>(R Function(T) fn) => this != null ? fn(this as T) : null;
}

// List Extension
extension ListX<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) { if (test(e)) return e; }
    return null;
  }
  Map<K, List<T>> groupBy<K>(K Function(T) key) {
    final map = <K, List<T>>{};
    for (final e in this) { map.putIfAbsent(key(e), () => []).add(e); }
    return map;
  }
}
```

### 1.6 Sealed Class + Pattern Matching (Dart 3.x) 🟡

```dart
// Sealed Class 정의
sealed class Result<T> {
  const Result();
}
class Success<T> extends Result<T> { final T data; const Success(this.data); }
class Failure<T> extends Result<T> { final String msg; const Failure(this.msg); }
class Loading<T> extends Result<T> { const Loading(); }

// switch expression (exhaustive)
String handle<T>(Result<T> r) => switch (r) {
  Success(:final data) => 'OK: $data',
  Failure(:final msg)  => 'Error: $msg',
  Loading()            => 'Loading...',
};

// Guard clause
double area(Shape s) => switch (s) {
  Circle(:final r) when r > 0   => pi * r * r,
  Circle()                       => throw ArgumentError('Invalid'),
  Rectangle(:final w, :final h) => w * h,
};
```

| 패턴 매칭 문법 | 용도 | 예시 |
|---------------|------|------|
| 변수 패턴 | 값 바인딩 | `case Success(:final data)` |
| 타입 체크 | 타입 검사 | `case int x` |
| Guard | 조건 추가 | `when x > 0` |
| 와일드카드 | 무시 | `case _` |
| 리스트 패턴 | 리스트 분해 | `case [first, ...rest]` |
| 맵 패턴 | 맵 분해 | `case {'key': value}` |
| 레코드 패턴 | 레코드 분해 | `case (int a, String b)` |

### 1.7 Mixin vs Abstract class vs Extension type 비교 🟡

| 항목 | `abstract class` | `mixin` | `mixin class` | `extension type` |
|------|-----------------|---------|---------------|-----------------|
| **목적** | 인터페이스 + 부분 구현 | 코드 재사용 (다중) | class + mixin 겸용 | Zero-cost 타입 래핑 |
| **사용** | `extends` / `implements` | `with` | `extends` / `with` | 직접 생성 |
| **다중 사용** | 단일 상속만 | 여러 개 with 가능 | 여러 개 with 가능 | - |
| **on 제약** | - | `on TargetClass` | 불가 | - |
| **런타임 비용** | 있음 | 있음 | 있음 | 없음 (컴파일 타임만) |
| **인스턴스화** | 불가 | 불가 | 가능 | 가능 |

```dart
// Mixin with on 제약
mixin Flyable on Animal {
  void fly() => print('$species flying');
}
class Bird extends Animal with Flyable { ... }

// Extension Type (Dart 3.3+) - zero-cost wrapper
extension type UserId(String value) implements String {
  bool get isValid => value.length >= 3;
}
// UserId와 ProductId를 혼용하면 컴파일 에러!
```

### 1.8 Isolate vs compute() 🟡

| 항목 | `Isolate.run()` | `Isolate.spawn()` | `compute()` |
|------|----------------|-------------------|-------------|
| **도입** | Dart 2.19+ | Dart 초기 | Flutter |
| **통신** | 단방향 (결과 반환) | 양방향 (SendPort) | 단방향 |
| **사용 난이도** | 쉬움 | 복잡 | 쉬움 |
| **적합 용도** | 단일 연산 | 지속적 통신 | 단일 연산 |
| **권장도** | Dart 팀 공식 권장 | 고급 시나리오 | Flutter 레거시 |

```dart
// Isolate.run() - 권장
final result = await Isolate.run(() {
  return heavyComputation(data);
});

// compute() - Flutter 전용
final result = await compute(heavyComputation, data);

// 주의: Isolate에 전달하는 함수는 반드시 top-level 또는 static
```

---

## 2. Widget 시스템

### 2.1 Widget / Element / RenderObject 관계 🟢

```
Widget (불변 설계도)        Element (변경 가능 인스턴스)    RenderObject (레이아웃+페인팅)
────────────────────      ──────────────────────────    ──────────────────────────
- 가벼움, 매번 재생성 가능   - Widget과 1:1 매핑           - 실제 크기/위치 계산
- immutable               - 재사용 여부 판단             - 화면에 그리기 (paint)
- createElement() 호출     - State 보유 (StatefulElement) - 비용이 큼

         Widget
           |  createElement()
           v
        Element  ──── 재사용 판단: runtimeType + key 비교
           |  createRenderObject()
           v
      RenderObject
```

**Element 재사용 조건** (`Widget.canUpdate`):
```dart
static bool canUpdate(Widget old, Widget new_) =>
    old.runtimeType == new_.runtimeType && old.key == new_.key;
```

### 2.2 StatelessWidget vs StatefulWidget 선택 기준 🟢

```
UI가 외부 파라미터/InheritedWidget에만 의존하는가?
    |
    ├── Yes -> StatelessWidget
    |
    └── No -> 내부에서 변경 가능한 상태가 필요한가?
              |
              ├── Yes -> StatefulWidget (또는 Bloc/Riverpod 사용 시 StatelessWidget)
              |
              └── No  -> StatelessWidget + 상태 관리 라이브러리
```

| 판단 기준 | StatelessWidget | StatefulWidget |
|----------|----------------|----------------|
| 내부 상태 변경 | 없음 | 있음 (setState) |
| Controller 필요 | 없음 | TextEditingController, ScrollController 등 |
| 리소스 해제 필요 | 없음 | dispose()에서 해제 |
| 애니메이션 | 없음 | AnimationController |
| Bloc 사용 시 | 대부분 Stateless로 가능 | Controller 관리 시에만 |

### 2.3 State Lifecycle 🟢

```
createState()
    |
    v
initState()  ← 1회 호출. 컨트롤러 초기화, 구독 시작
    |
    v
didChangeDependencies()  ← InheritedWidget 변경 시에도 호출
    |
    v
build()  ← setState() 호출 시마다 재실행
    |
    v
didUpdateWidget()  ← 부모가 같은 runtimeType으로 리빌드 시
    |
    v
deactivate()  ← 트리에서 제거 (재삽입 가능)
    |
    v
dispose()  ← 영구 제거. 컨트롤러 dispose, 구독 cancel
```

| 메서드 | 호출 시점 | 용도 |
|--------|---------|------|
| `initState` | State 생성 직후 (1회) | 컨트롤러 초기화, Bloc 이벤트 발행 |
| `didChangeDependencies` | 의존 InheritedWidget 변경 시 | Theme, MediaQuery 등 참조 |
| `build` | setState 또는 의존성 변경 시 | UI 선언 |
| `didUpdateWidget` | 부모 리빌드로 Widget 교체 시 | 이전/현재 widget 비교 |
| `dispose` | 트리에서 영구 제거 시 | 리소스 해제 |

### 2.4 Key 종류별 사용 시점 🟢

| Key | 비교 기준 | 사용 시점 | 예시 |
|-----|----------|---------|------|
| `ValueKey<T>` | 값 (`value`) | 고유 ID가 있을 때 | `ValueKey(item.id)` |
| `ObjectKey` | 객체 참조 | 객체 자체가 식별자 | `ObjectKey(person)` |
| `UniqueKey` | 인스턴스 자체 | State 강제 초기화 | `UniqueKey()` |
| `GlobalKey` | 글로벌 고유 | 외부에서 State 접근 | `GlobalKey<FormState>()` |
| `PageStorageKey` | 값 | 스크롤 위치 보존 | `PageStorageKey('list')` |

```dart
// Key 사용 필수 상황
// 1) 리스트 아이템 순서 변경 시 State 보존
ListView(children: items.map((e) => Tile(key: ValueKey(e.id))).toList())

// 2) State 강제 리셋
_Counter(key: UniqueKey())  // Key 바뀌면 State 새로 생성

// 3) 외부에서 State 접근
final formKey = GlobalKey<FormState>();
formKey.currentState?.validate();
```

### 2.5 BuildContext 핵심 메서드 🟡

| 메서드 | 패키지 | 구독 여부 | 용도 |
|--------|--------|---------|------|
| `Theme.of(context)` | Flutter | 구독 | 테마 데이터 접근 |
| `MediaQuery.of(context)` | Flutter | 구독 | 화면 크기, 패딩 |
| `Navigator.of(context)` | Flutter | 미구독 | 네비게이션 |
| `context.read<T>()` | provider/bloc | 미구독 | 1회성 접근 (이벤트 핸들러) |
| `context.watch<T>()` | provider/bloc | 구독 | build 내에서 변경 감지 |
| `context.select<T,R>()` | provider/bloc | 부분 구독 | 특정 필드만 감지 |
| `ScaffoldMessenger.of(context)` | Flutter | 미구독 | SnackBar 표시 |

```dart
// read: 이벤트 핸들러에서 (1회성)
onPressed: () => context.read<CartBloc>().add(AddItem(item))

// watch: build 내에서 (구독)
final count = context.watch<CounterBloc>().state;

// select: 특정 값만 (부분 구독 -> 최적화)
final isLoading = context.select<LoginBloc, bool>((b) => b.state.isLoading);
```

### 2.6 자주 쓰는 Widget 패턴 🟢

| 패턴 | Widget | 용도 |
|------|--------|------|
| Builder | `Builder` | Scaffold 아래 context 확보 |
| 값 감지 | `ValueListenableBuilder` | ValueNotifier 변경 감지 |
| 스트림 감지 | `StreamBuilder` | Stream 데이터 반영 |
| Future 감지 | `FutureBuilder` | 비동기 결과 반영 |
| 레이아웃 감지 | `LayoutBuilder` | 부모 Constraints 접근 |
| Bloc 상태 | `BlocBuilder` | Bloc State -> UI |
| Bloc 이펙트 | `BlocListener` | 네비게이션, 스낵바 등 |
| Bloc 결합 | `BlocConsumer` | Builder + Listener |
| Bloc 선택 | `BlocSelector` | State 일부만 rebuild |

### 2.7 const 사용 체크리스트 🟢

```
[ ] Widget 클래스에 const 생성자 선언했는가?
[ ] 인스턴스 생성 시 const 키워드 붙였는가?
[ ] SizedBox, Padding, Icon 등에 const 적용했는가?
[ ] const 불가능한 이유: 런타임 값 의존 (변수, 함수 호출 결과)
[ ] 리스트/맵 리터럴도 const 가능한지 확인했는가?
```

```dart
// const 적용 가능
const SizedBox(height: 16)
const Text('정적 텍스트')
const EdgeInsets.all(8)
const [1, 2, 3]

// const 적용 불가
Text(variable)              // 변수 의존
SizedBox(height: calc())    // 함수 호출
Container(color: themeColor) // 런타임 값
```

---

## 3. 상태 관리

### 3.1 Bloc 구성요소 다이어그램 🟢

```
  사용자 액션          비즈니스 로직           UI 업데이트
 ┌──────────┐     ┌──────────────┐     ┌──────────────┐
 │  Event   │ --> │     Bloc     │ --> │    State     │ --> UI
 └──────────┘     │              │     └──────────────┘
                  │ on<Event>()  │
                  │ emit(State)  │
                  └──────────────┘

 Event: 사용자 액션 (LoginSubmitted, DataLoadRequested)
 Bloc:  Event -> State 변환 로직
 State: 현재 UI 상태 (Loading, Loaded, Error)
```

### 3.2 Cubit vs Bloc 비교 🟢

| 항목 | Cubit | Bloc |
|------|-------|------|
| **입력** | 메서드 직접 호출 | Event 클래스 |
| **코드량** | 적음 | 많음 |
| **추적성** | 메서드 호출만 추적 | Event 로그 추적 가능 |
| **Transformer** | 없음 | droppable, restartable 등 |
| **디바운스/쓰로틀** | 직접 구현 | Transformer로 내장 |
| **테스트** | 메서드 호출 | Event emit 검증 |
| **권장 용도** | 단순 상태 (토글, 카운터) | 복잡한 비즈니스 로직 |

```dart
// Cubit - 단순
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}

// Bloc - 복잡한 로직
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}
```

### 3.3 BlocProvider / Builder / Listener / Consumer 선택 가이드 🟢

| Widget | 용도 | Builder | Listener | 언제 사용 |
|--------|------|---------|----------|---------|
| `BlocProvider` | Bloc 제공 | - | - | Bloc을 하위 트리에 주입 |
| `BlocBuilder` | UI 빌드 | O | - | State에 따라 UI 변경 |
| `BlocListener` | Side Effect | - | O | 네비게이션, 스낵바, 다이얼로그 |
| `BlocConsumer` | 둘 다 | O | O | UI 변경 + Side Effect 동시 |
| `BlocSelector` | 부분 빌드 | O | - | State 일부만 구독해 성능 최적화 |

```dart
// 선택 가이드 플로우
State 변경 시 해야 할 일은?
  |
  ├── UI를 다시 그려야 함 -> BlocBuilder (또는 BlocSelector)
  |
  ├── Side Effect만 (스낵바, 라우팅) -> BlocListener
  |
  └── 둘 다 -> BlocConsumer

// buildWhen / listenWhen 으로 불필요한 실행 방지
BlocBuilder<LoginBloc, LoginState>(
  buildWhen: (prev, curr) => prev.status != curr.status,
  builder: (context, state) => ...,
)
```

### 3.4 Transformer 선택 가이드 🟡

| Transformer | 동작 | 적합 용도 |
|-------------|------|---------|
| `concurrent()` | 모든 이벤트 병렬 (기본) | 독립 이벤트 |
| `sequential()` | 순차 처리 (큐) | 순서 중요한 이벤트 |
| `droppable()` | 처리 중 새 이벤트 무시 | 로그인, 결제 (중복 방지) |
| `restartable()` | 이전 취소 후 새 이벤트 | 검색, 자동완성 |
| `debounce(300ms)` | 입력 안정 후 실행 | 검색 입력 |
| `throttle(100ms)` | 주기적 실행 | 스크롤 이벤트 |

```dart
on<SearchChanged>(_onSearch, transformer: restartable());
on<LoginSubmitted>(_onLogin, transformer: droppable());
on<ScrollChanged>(_onScroll, transformer: throttle(Duration(milliseconds: 100)));
```

### 3.5 Freezed 핵심 문법 요약 🟢

```dart
// 데이터 클래스
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    @Default('') String bio,
  }) = _User;
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// Union 타입 (State 정의)
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(User user) = Authenticated;
  const factory AuthState.error(String message) = AuthError;
}
```

| 기능 | 사용법 | 설명 |
|------|-------|------|
| `copyWith` | `user.copyWith(name: 'new')` | 일부 필드만 변경한 복사본 |
| Deep copy | `person.copyWith.address(city: 'Seoul')` | 중첩 객체 필드 변경 |
| `when` | `state.when(initial: () => ..., ...)` | 모든 케이스 처리 (필수) |
| `maybeWhen` | `state.maybeWhen(loaded: (d) => d, orElse: () => null)` | 일부만 처리 |
| `map` | `state.map(loaded: (s) => s.data, ...)` | 타입 캐스팅된 객체 접근 |
| `toJson` | `user.toJson()` | JSON 직렬화 |
| `fromJson` | `User.fromJson(json)` | JSON 역직렬화 |
| `@JsonKey` | `@JsonKey(name: 'user_id')` | JSON 필드명 매핑 |
| `@Assert` | `@Assert('price >= 0')` | 디버그 모드 검증 |

### 3.6 Riverpod 핵심 Provider 종류 비교 🟡

| Provider | 반환 타입 | 용도 | 자동 dispose |
|----------|----------|------|-------------|
| `Provider` | `T` | 읽기 전용 값 (DI) | X |
| `StateProvider` | `T` | 단순 상태 (토글, 카운터) | X |
| `FutureProvider` | `AsyncValue<T>` | 비동기 데이터 (1회) | X |
| `StreamProvider` | `AsyncValue<T>` | 실시간 데이터 | X |
| `NotifierProvider` | `T` | 복잡한 상태 + 로직 | X |
| `AsyncNotifierProvider` | `AsyncValue<T>` | 비동기 상태 + 로직 | X |
| `.autoDispose` | - | 수식어 | O (리스너 없으면) |
| `.family` | - | 수식어 (파라미터) | - |

```dart
// Riverpod 2.x 기본 패턴
final userProvider = FutureProvider.autoDispose.family<User, String>((ref, id) async {
  return ref.watch(userRepositoryProvider).getUser(id);
});

// 소비
Consumer(builder: (context, ref, child) {
  final user = ref.watch(userProvider('123'));
  return user.when(
    data: (user) => Text(user.name),
    loading: () => CircularProgressIndicator(),
    error: (e, st) => Text('Error: $e'),
  );
});
```

### 3.7 상태 관리 패턴 비교 🔴

| 항목 | Bloc | Riverpod | Provider | GetX |
|------|------|----------|----------|------|
| **학습 곡선** | 높음 | 중간 | 낮음 | 낮음 |
| **보일러플레이트** | 많음 | 중간 | 적음 | 적음 |
| **테스트 용이성** | 매우 좋음 | 좋음 | 보통 | 나쁨 |
| **확장성** | 매우 좋음 | 좋음 | 보통 | 나쁨 |
| **추적/디버깅** | BlocObserver | ProviderObserver | 제한적 | 제한적 |
| **이벤트 제어** | Transformer | - | - | - |
| **DI 통합** | injectable | 내장 | 별도 | 내장 |
| **대규모 앱** | 권장 | 권장 | 비권장 | 비권장 |
| **커뮤니티** | 매우 큼 | 큼 | 큼 | 큼 |
| **Google 권장** | 공식 권장 | - | 공식 권장 | - |

> **실무 권장**: 대규모 앱 -> Bloc + Freezed + fpdart, 중규모 -> Riverpod, 소규모/프로토타입 -> Provider

---

## 4. 네트워킹 & 데이터

### 4.1 Dio Interceptor 체인 순서 🟡

```
Request 흐름:
  Client -> [LoggingInterceptor] -> [AuthInterceptor] -> [ErrorInterceptor] -> Server

Response 흐름:
  Server -> [ErrorInterceptor] -> [AuthInterceptor] -> [LoggingInterceptor] -> Client

Error 흐름 (401 예시):
  Server 401 -> ErrorInterceptor -> AuthInterceptor (토큰 갱신)
    ├── 갱신 성공 -> 원래 요청 재시도 -> handler.resolve(response)
    └── 갱신 실패 -> 로그아웃 -> handler.next(err)
```

```dart
dio.interceptors.addAll([
  LoggingInterceptor(),    // 1순위: 요청/응답 로깅
  AuthInterceptor(),       // 2순위: 토큰 주입 + 401 갱신
  ErrorInterceptor(),      // 3순위: DioException -> NetworkException 변환
]);
```

### 4.2 JWT 토큰 갱신 시퀀스 🟡

```
Client                    Server                  Token Storage
  |                         |                         |
  |--- API Request -------->|                         |
  |    (Access Token)       |                         |
  |<--- 401 Unauthorized ---|                         |
  |                         |                         |
  |--- Refresh Request ---->|                         |
  |    (Refresh Token)      |                         |
  |<--- New Tokens ---------|                         |
  |                         |             Save ------>|
  |--- Retry Original ----->|                         |
  |    (New Access Token)   |                         |
  |<--- 200 OK ------------|                         |
```

**핵심 포인트**:
- 갱신 요청은 **새 Dio 인스턴스** 사용 (순환 방지)
- 동시 401 발생 시 **Completer로 중복 갱신 방지**
- Refresh Token도 만료 시 **로그아웃 처리**

### 4.3 Either<Failure, T> 패턴 코드 템플릿 🟡

```dart
// 1. Failure 정의
@freezed
class Failure with _$Failure {
  const factory Failure.network() = NetworkFailure;
  const factory Failure.server(int code, String? msg) = ServerFailure;
  const factory Failure.unauthorized() = UnauthorizedFailure;
  const factory Failure.unknown(Object? error) = UnknownFailure;
}

// 2. Repository 인터페이스
abstract class UserRepository {
  Future<Either<Failure, User>> getUser(String id);
  Future<Either<Failure, Unit>> deleteUser(String id);
}

// 3. Repository 구현
class UserRepositoryImpl implements UserRepository {
  Future<Either<Failure, User>> getUser(String id) async {
    try {
      final dto = await _api.getUser(id);
      return Right(dto.toEntity());
    } on DioException catch (e) {
      return Left(_mapError(e));
    }
  }
}

// 4. Bloc에서 처리
final result = await _getUser(id);
result.fold(
  (failure) => emit(UserState.error(failure)),
  (user) => emit(UserState.loaded(user)),
);
```

### 4.4 HTTP 상태 코드별 처리 전략 🟢

| 코드 | 의미 | 처리 전략 |
|------|------|---------|
| 200 | OK | 정상 처리 |
| 201 | Created | 생성 성공 |
| 204 | No Content | `Right(unit)` 반환 |
| 400 | Bad Request | `ValidationFailure` (입력 검증 실패) |
| 401 | Unauthorized | 토큰 갱신 시도 -> 실패 시 로그아웃 |
| 403 | Forbidden | `UnauthorizedFailure` (권한 부족) |
| 404 | Not Found | `NotFoundFailure` |
| 409 | Conflict | 충돌 처리 (중복 요청 등) |
| 422 | Unprocessable | 서버 측 유효성 검사 실패 |
| 429 | Too Many Requests | 지수 백오프 재시도 |
| 500 | Server Error | `ServerFailure` + 재시도 옵션 |
| 502/503 | Bad Gateway / Unavailable | 재시도 (서버 일시 장애) |

### 4.5 캐싱 전략 비교 🟡

| 전략 | 저장 위치 | 속도 | 용량 | 지속성 | 적합 용도 |
|------|---------|------|------|--------|---------|
| **Memory Cache** | RAM (Map) | 매우 빠름 | 작음 | 앱 종료 시 삭제 | 이미지, 자주 접근 데이터 |
| **Disk Cache** | 파일 시스템 | 빠름 | 큼 | 앱 종료 후 유지 | API 응답, 파일 |
| **Network** | 서버 | 느림 | 무제한 | 영구 | 원본 데이터 |

```
요청 -> Memory Cache 확인
         |
         ├── Hit -> 반환
         |
         └── Miss -> Disk Cache 확인
                      |
                      ├── Hit + 유효 -> 반환 (+ Memory Cache 저장)
                      |
                      └── Miss 또는 만료 -> Network 요청
                                            |
                                            └── 응답 -> Memory + Disk 저장 -> 반환
```

| 패턴 | 설명 | 구현 |
|------|------|------|
| **Cache First** | 캐시 우선, 없으면 네트워크 | 오프라인 지원 |
| **Network First** | 네트워크 우선, 실패 시 캐시 | 최신 데이터 중요 |
| **Stale While Revalidate** | 캐시 즉시 반환 + 백그라운드 갱신 | UX 최적화 |
| **Cache Only** | 캐시만 사용 | 오프라인 전용 |

---

## 5. 렌더링 & 성능

### 5.1 Flutter 렌더링 파이프라인 요약 🟢

```
VSync 신호 (16.67ms @ 60fps)
    |
    v
1. Build Phase     - Widget.build() 호출, Widget/Element 트리 갱신
    |                dirty 체크된 Element만 rebuild
    v
2. Layout Phase    - RenderObject 크기/위치 계산
    |                Constraints 하향 전파, Size 상향 보고
    v
3. Paint Phase     - RenderObject.paint() 호출
    |                Layer 트리 구성, RepaintBoundary로 격리
    v
4. Composite Phase - Layer 트리를 GPU로 전송
                     래스터화 + 화면 표시
```

| Phase | 병목 원인 | 해결 방법 |
|-------|---------|---------|
| Build | 불필요한 rebuild | const, BlocSelector, Widget 분리 |
| Layout | 복잡한 중첩 레이아웃 | LayoutBuilder, Sliver |
| Paint | 과도한 repaint | RepaintBoundary |
| Composite | 과도한 Layer | Opacity -> AnimatedOpacity |

### 5.2 Impeller vs Skia 비교 🟡

| 항목 | Skia | Impeller |
|------|------|---------|
| **런타임 셰이더 컴파일** | 있음 (Jank 원인) | 없음 (미리 컴파일) |
| **첫 프레임** | 셰이더 컴파일로 느림 | 일정한 성능 |
| **iOS 지원** | 레거시 | 기본 (Flutter 3.16+) |
| **Android 지원** | 기본 | 기본 (Flutter 3.22+) |
| **Custom Shader** | GLSL (SkSL) | GLSL (Impeller GLES/Vulkan) |
| **최적화 전략** | SkSL 워밍업 필요 | 워밍업 불필요 |
| **saveLayer 비용** | 매우 높음 | 비교적 낮음 (텍스처 패스) |
| **클리핑 비용** | 높음 | 보통 |

### 5.3 성능 최적화 체크리스트 (Top 10) 🟢

| # | 항목 | 레벨 | 효과 |
|---|------|------|------|
| 1 | `const` 생성자 적극 사용 | 🟢 | 높음 |
| 2 | `ListView.builder` 사용 (대량 리스트) | 🟢 | 매우 높음 |
| 3 | Widget 분리 (rebuild 범위 축소) | 🟢 | 높음 |
| 4 | `BlocSelector` / `buildWhen`으로 부분 rebuild | 🟡 | 높음 |
| 5 | `RepaintBoundary`로 repaint 격리 | 🟡 | 중간 |
| 6 | 이미지 캐싱 (`cached_network_image`) | 🟢 | 높음 |
| 7 | 무거운 연산 Isolate로 분리 | 🟡 | 높음 |
| 8 | `Opacity` -> `AnimatedOpacity`/`FadeTransition` | 🟡 | 중간 |
| 9 | `build()` 내 객체 생성 금지 (Controller 등) | 🟢 | 중간 |
| 10 | profile/release 모드에서 성능 측정 | 🟢 | - |

### 5.4 DevTools 주요 탭별 용도 🟢

| 탭 | 용도 | 핵심 지표 |
|----|------|---------|
| **Flutter Inspector** | Widget 트리 탐색 | 위젯 속성, 레이아웃 Constraints |
| **Performance** | 프레임 분석 | Build/Layout/Paint 시간, Jank 감지 |
| **CPU Profiler** | 함수별 실행 시간 | 핫스팟 함수 식별 |
| **Memory** | 메모리 사용 분석 | 힙 크기, GC 빈도, 누수 탐지 |
| **Network** | HTTP 요청 분석 | 요청/응답 시간, 페이로드 크기 |
| **Logging** | 로그 확인 | debugPrint, print 출력 |

```dart
// Performance Overlay 활성화
MaterialApp(
  showPerformanceOverlay: true,  // 프레임 그래프 표시
)

// Timeline 이벤트 추가
import 'dart:developer';
Timeline.startSync('expensive_operation');
// ... 연산 ...
Timeline.finishSync();
```

### 5.5 메모리 릭 원인 Top 5 🟡

| # | 원인 | 해결 |
|---|------|------|
| 1 | **StreamSubscription 미해제** | `dispose()`에서 `.cancel()` |
| 2 | **Controller 미해제** | `dispose()`에서 `.dispose()` |
| 3 | **Timer 미해제** | `dispose()`에서 `.cancel()` |
| 4 | **클로저의 강한 참조** | WeakReference 또는 참조 끊기 |
| 5 | **무한 성장 캐시** | LRU 캐시, 크기 제한 |

```dart
// 안전한 리소스 해제 패턴
class _MyState extends State<MyWidget> {
  late final ScrollController _scroll;
  StreamSubscription? _sub;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    _sub = stream.listen((_) {});
    _timer = Timer.periodic(Duration(seconds: 1), (_) {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    _scroll.dispose();
    super.dispose();
  }
}

// 비동기 후 mounted 체크
Future<void> _load() async {
  final data = await fetchData();
  if (!mounted) return;  // 위젯 제거됐으면 중단
  setState(() => _data = data);
}
```

---

## 부록: 자주 나오는 면접 질문 요약

### Dart 🟢

| 질문 | 핵심 답변 |
|------|---------|
| `final` vs `const` 차이? | final: 런타임 1회 할당, const: 컴파일 타임 상수 |
| Null Safety란? | 타입 시스템에서 null 가능성을 명시 (`?`, `!`, `late`) |
| `Future` vs `Stream`? | Future: 단일 비동기 값, Stream: 연속 비동기 값 |
| `async*` vs `async`? | async: Future 반환, async*: Stream 반환 (yield 사용) |
| `Isolate`는 왜 필요? | Dart는 단일 스레드, 무거운 연산 시 UI 프레임 드롭 방지 |

### Flutter 🟢

| 질문 | 핵심 답변 |
|------|---------|
| Widget은 왜 immutable? | 가볍게 재생성하고, Element가 재사용 판단 |
| `BuildContext`란? | Widget Tree에서의 위치 핸들, 실제로는 Element 참조 |
| `Key`는 왜 필요? | Element 재사용 판단 기준 (runtimeType + key) |
| Hot Reload 원리? | Widget 트리만 재빌드, State와 RenderObject는 유지 |
| `setState` vs Bloc? | setState: 로컬 상태, Bloc: 분리된 비즈니스 로직 |

### 상태 관리 🟡

| 질문 | 핵심 답변 |
|------|---------|
| Bloc의 데이터 흐름? | Event -> Bloc (on<Event> 처리) -> emit(State) -> UI rebuild |
| `droppable`은 언제? | 중복 요청 방지 (로그인, 결제) |
| `restartable`은 언제? | 이전 작업 취소 후 새 작업 (검색 자동완성) |
| Either<L,R> 패턴? | 명시적 에러 처리: Left=실패, Right=성공, fold로 분기 |

### 성능 🟡

| 질문 | 핵심 답변 |
|------|---------|
| Flutter가 60fps 유지하려면? | 각 프레임 16ms 내 Build+Layout+Paint+Composite 완료 |
| Jank 원인? | 무거운 build(), 과도한 rebuild, 메인 스레드 블로킹 |
| `RepaintBoundary` 역할? | Paint 영역 격리, 다른 위젯 repaint 방지 |
| Impeller 장점? | 런타임 셰이더 컴파일 제거 -> 일관된 프레임 성능 |

### 아키텍처 🔴

| 질문 | 핵심 답변 |
|------|---------|
| Clean Architecture 레이어? | Presentation -> Domain -> Data (의존성 안쪽 방향) |
| Repository 패턴 장점? | 데이터 소스 추상화, 테스트 용이, 캐싱 전략 캡슐화 |
| DI가 왜 필요? | 결합도 낮춤, 테스트 시 Mock 주입 용이 |
| Freezed를 쓰는 이유? | ==, hashCode, copyWith, toJson 보일러플레이트 자동 생성 |
