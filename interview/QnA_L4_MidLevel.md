# Flutter 면접 Q&A — L4 Mid-Level

> **대상**: SWE L4 (Mid-Level, 2-4년 경력)
> **포지션**: 모바일 엔지니어 + 시스템 설계
> **마지막 업데이트**: 2026-02-08 | **Flutter 3.38** | **Dart 3.10**
> **문항 수**: 37개

---

## 목차

1. [Dart 언어 (5문항)](#1-dart-언어)
2. [Widget & 렌더링 (7문항)](#2-widget--렌더링)
3. [상태 관리 (6문항)](#3-상태-관리)
4. [아키텍처 (5문항)](#4-아키텍처)
5. [네트워킹 (5문항)](#5-네트워킹)
6. [테스트 (4문항)](#6-테스트)
7. [모바일 실무 (5문항)](#7-모바일-실무)

---

## 1. Dart 언어

### Q1. Null Safety의 핵심 개념과 실무 활용법을 설명하세요.

**핵심 키워드**: Non-nullable by default, `?`, `!`, `??`, `?.`, late, required

**모범 답변**:
Dart의 Null Safety는 컴파일 타임에 null 참조 오류를 방지하는 타입 시스템입니다.

기본 원칙:
```dart
// 1. 기본적으로 non-nullable
String name = 'Flutter'; // null 할당 불가
String? nickname;        // nullable 타입

// 2. Null 체크 연산자
String greeting = nickname ?? 'Guest';           // null 병합
int? length = nickname?.length;                  // null-aware 접근
String forcedName = nickname!;                   // null 아님을 단언 (위험)

// 3. late: 나중에 초기화되지만 사용 전 반드시 초기화됨을 보장
class UserProfile {
  late final String userId;  // 생성자 외부에서 초기화

  void init(String id) {
    userId = id;  // 한 번만 할당 가능
  }
}

// 4. required: 생성자 파라미터 필수화
class Button extends StatelessWidget {
  const Button({
    required this.onPressed,  // 반드시 전달해야 함
    this.label,               // 선택적
  });

  final VoidCallback onPressed;
  final String? label;
}
```

실무 패턴:
```dart
// API 응답 처리
Future<User?> fetchUser(String id) async {
  try {
    final response = await dio.get('/users/$id');
    return User.fromJson(response.data);
  } catch (e) {
    return null;  // 실패 시 null 반환
  }
}

// 안전한 사용
final user = await fetchUser('123');
if (user != null) {
  print(user.name);  // 이 블록 안에서는 User 타입으로 promote
}
```

**평가 기준**:
- ✅ 좋은 답변: `?`, `!`, `??`, `late`, `required`를 구분하고 실무 예제 제시
- ❌ 나쁜 답변: "null을 체크한다" 수준의 추상적 설명

**꼬리 질문**:
1. `late`를 사용하면 안 되는 경우는?
2. `!` 연산자 사용을 피하려면 어떻게 리팩토링하나요?

**참고 문서**: [../dart/03_null_safety.md](../dart/03_null_safety.md)

---

### Q2. async/await, Future, Stream의 차이와 사용 시나리오를 비교하세요.

**핵심 키워드**: 단일 값 vs 연속 값, Hot/Cold Stream, StreamController, async*

**모범 답변**:

**Future vs Stream**:
```dart
// Future: 단일 비동기 결과
Future<String> fetchUserName() async {
  await Future.delayed(Duration(seconds: 1));
  return 'John Doe';
}

// Stream: 연속적인 비동기 이벤트
Stream<int> countDown(int from) async* {
  for (int i = from; i > 0; i--) {
    await Future.delayed(Duration(seconds: 1));
    yield i;  // 값을 방출
  }
}
```

**실무 사용 사례**:
```dart
// 1. API 호출 → Future
class UserRepository {
  Future<User> getUser(String id) async {
    final response = await dio.get('/users/$id');
    return User.fromJson(response.data);
  }
}

// 2. 실시간 데이터 → Stream
class ChatRepository {
  Stream<List<Message>> watchMessages(String chatId) {
    return firestore
        .collection('chats/$chatId/messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromJson(doc.data()))
            .toList());
  }
}

// 3. 사용자 액션 → StreamController
class SearchBloc {
  final _queryController = StreamController<String>();

  Stream<List<Product>> get searchResults =>
      _queryController.stream
          .debounceTime(Duration(milliseconds: 300))
          .switchMap((query) => _searchRepository.search(query));

  void updateQuery(String query) => _queryController.add(query);

  void dispose() => _queryController.close();
}
```

**Hot vs Cold Stream**:
```dart
// Cold Stream: 구독할 때마다 새로운 실행
Stream<int> coldStream() async* {
  print('Stream started');
  for (int i = 0; i < 3; i++) {
    yield i;
  }
}

// Hot Stream: 구독과 무관하게 데이터 방출
final hotStream = coldStream().asBroadcastStream();
```

**평가 기준**:
- ✅ 좋은 답변: 단일 값/연속 값 차이, async* yield 문법, 실무 예제
- ❌ 나쁜 답변: "Stream은 여러 개 값을 받는다" 수준

**꼬리 질문**:
1. StreamController의 메모리 누수를 방지하려면?
2. Stream 변환 메서드(map, where, asyncMap) 차이는?

**참고 문서**: [../dart/04_async_programming.md](../dart/04_async_programming.md)

---

### Q3. Sealed class와 Pattern Matching을 활용한 타입 안전 설계를 설명하세요.

**핵심 키워드**: Exhaustive checking, switch expression, sealed modifier, Result 패턴

**모범 답변**:

Dart 3.0의 sealed class는 모든 서브타입이 같은 파일에 정의되어야 하며, 컴파일러가 완전성 검사를 수행합니다.

**기본 구조**:
```dart
// API 응답 상태를 타입으로 표현
sealed class ApiResult<T> {}

class Success<T> extends ApiResult<T> {
  final T data;
  Success(this.data);
}

class Loading<T> extends ApiResult<T> {}

class Error<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  Error(this.message, {this.statusCode});
}
```

**Pattern Matching 활용**:
```dart
Widget buildResultView(ApiResult<User> result) {
  return switch (result) {
    Success(data: final user) => UserProfileView(user: user),
    Loading() => CircularProgressIndicator(),
    Error(message: final msg, statusCode: 404) => NotFoundView(msg),
    Error(message: final msg) => ErrorView(message: msg),
  };
  // 모든 케이스 처리하지 않으면 컴파일 에러
}
```

**실무 패턴: Either 구현**:
```dart
sealed class Either<L, R> {}

class Left<L, R> extends Either<L, R> {
  final L value;
  Left(this.value);
}

class Right<L, R> extends Either<L, R> {
  final R value;
  Right(this.value);
}

// Repository 레이어
class UserRepository {
  Future<Either<Failure, User>> getUser(String id) async {
    try {
      final response = await dio.get('/users/$id');
      return Right(User.fromJson(response.data));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}

// Bloc에서 사용
void _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
  emit(UserLoading());

  final result = await repository.getUser(event.userId);

  emit(switch (result) {
    Left(value: final failure) => UserError(failure.message),
    Right(value: final user) => UserLoaded(user),
  });
}
```

**고급 패턴**:
```dart
// Record pattern과 조합
(ApiResult<User>, ApiResult<Settings>) results = await Future.wait([
  fetchUser(),
  fetchSettings(),
]);

final view = switch (results) {
  (Success(data: final user), Success(data: final settings)) =>
    ProfileView(user: user, settings: settings),
  (Success(), Loading()) || (Loading(), Success()) || (Loading(), Loading()) =>
    LoadingView(),
  _ => ErrorView('Failed to load data'),
};
```

**평가 기준**:
- ✅ 좋은 답변: Exhaustive checking 이점, switch expression, Result/Either 패턴
- ❌ 나쁜 답변: abstract class와의 차이를 모름

**꼬리 질문**:
1. sealed class 대신 enum을 사용할 수 있는 경우는?
2. Pattern matching의 성능 오버헤드는?

**참고 문서**: [../dart/08_sealed_classes_pattern_matching.md](../dart/08_sealed_classes_pattern_matching.md)

---

### Q4. Generics와 Extension의 실무 활용법을 예제와 함께 설명하세요.

**핵심 키워드**: Type parameter, bounded generics, extension method, extension type

**모범 답변**:

**Generics 기본**:
```dart
// 재사용 가능한 Repository 베이스 클래스
abstract class Repository<T> {
  Future<T?> getById(String id);
  Future<List<T>> getAll();
  Future<void> save(T entity);
}

class UserRepository extends Repository<User> {
  @override
  Future<User?> getById(String id) async {
    // User 특화 로직
  }
}

// Bounded generics
class JsonRepository<T extends JsonSerializable> {
  Future<T> fetch(String endpoint) async {
    final response = await dio.get(endpoint);
    return jsonDecode<T>(response.data);  // T는 반드시 JsonSerializable
  }
}
```

**Extension 활용**:
```dart
// 1. 기본 타입 확장
extension StringExtensions on String {
  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

// 사용
final email = 'user@example.com';
if (email.isValidEmail) { /* ... */ }

// 2. BuildContext 확장 (실무 필수 패턴)
extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colors => theme.colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
}

// 사용
Text('Title', style: context.textTheme.headlineMedium);
context.showSnackBar('Saved successfully');

// 3. Nullable 타입 확장
extension NullableStringExtensions on String? {
  String get orEmpty => this ?? '';
  bool get isNullOrEmpty => this?.isEmpty ?? true;
}

final String? nullableValue = null;
print(nullableValue.orEmpty);  // ''

// 4. Collection 확장
extension IterableExtensions<T> on Iterable<T> {
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
      (map[key] ??= []).add(element);
    }
    return map;
  }
}

// 사용
final users = <User>[/* ... */];
final admin = users.firstWhereOrNull((u) => u.role == 'admin');
final grouped = users.groupBy((u) => u.department);
```

**고급 패턴: Generic State 관리**:
```dart
// BLoC 제네릭 패턴
abstract class DataBloc<T> extends Bloc<DataEvent, DataState<T>> {
  DataBloc() : super(DataInitial()) {
    on<LoadData>((event, emit) async {
      emit(DataLoading());
      try {
        final data = await fetchData();
        emit(DataLoaded(data));
      } catch (e) {
        emit(DataError(e.toString()));
      }
    });
  }

  Future<T> fetchData();
}

class UserBloc extends DataBloc<User> {
  @override
  Future<User> fetchData() => repository.getUser();
}
```

**평가 기준**:
- ✅ 좋은 답변: Bounded generics, 실무 extension 패턴(BuildContext 등)
- ❌ 나쁜 답변: "List<int> 같은 거 쓴다" 수준

**꼬리 질문**:
1. Extension method는 언제 컴파일되나요? (정적 vs 동적)
2. Extension type(Dart 3.3)의 사용 사례는?

**참고 문서**: [../dart/05_generics.md](../dart/05_generics.md), [../dart/06_extensions.md](../dart/06_extensions.md)

---

### Q5. Isolate와 compute의 차이, 언제 멀티스레딩이 필요한지 설명하세요.

**핵심 키워드**: Event loop, compute, Isolate.spawn, 메모리 격리, 대용량 데이터 처리

**모범 답변**:

**Event Loop vs Isolate**:
```dart
// Dart는 단일 스레드 + Event Loop
// UI 스레드를 블로킹하면 안 됨
void badExample() {
  // ❌ UI 프리징 발생
  final result = heavyComputation();  // 5초 걸림
}

void goodExample() async {
  // ✅ UI는 응답성 유지
  final result = await compute(heavyComputation, data);
}
```

**compute 사용 (간단한 병렬 작업)**:
```dart
// Top-level 또는 static 함수여야 함
List<User> _parseUsers(String jsonString) {
  final List<dynamic> list = jsonDecode(jsonString);
  return list.map((json) => User.fromJson(json)).toList();
}

Future<List<User>> loadUsers() async {
  final String jsonString = await rootBundle.loadString('users.json');

  // 별도 Isolate에서 JSON 파싱 (메인 스레드 블로킹 없음)
  return await compute(_parseUsers, jsonString);
}

// 이미지 리사이징
Future<Uint8List> resizeImage(Uint8List imageData) async {
  return await compute(_resizeImageIsolate, imageData);
}

Uint8List _resizeImageIsolate(Uint8List data) {
  final image = img.decodeImage(data)!;
  final resized = img.copyResize(image, width: 800);
  return Uint8List.fromList(img.encodeJpg(resized));
}
```

**Isolate 직접 사용 (복잡한 통신)**:
```dart
class DataProcessor {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;

  Future<void> start() async {
    _receivePort = ReceivePort();

    _isolate = await Isolate.spawn(
      _isolateEntry,
      _receivePort!.sendPort,
    );

    // Isolate의 SendPort 받기
    _sendPort = await _receivePort!.first as SendPort;
  }

  static void _isolateEntry(SendPort mainSendPort) {
    final isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort);

    isolateReceivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        final result = processData(message['data']);
        final resultPort = message['resultPort'] as SendPort;
        resultPort.send(result);
      }
    });
  }

  Future<List<int>> process(List<int> data) async {
    final responsePort = ReceivePort();

    _sendPort!.send({
      'data': data,
      'resultPort': responsePort.sendPort,
    });

    return await responsePort.first as List<int>;
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
  }
}
```

**멀티스레딩이 필요한 시나리오**:
```dart
// 1. 대용량 JSON 파싱
Future<List<Product>> loadProducts() async {
  final jsonString = await api.fetchProducts();  // 10MB+
  return compute(parseProducts, jsonString);
}

// 2. 암호화/복호화
Future<String> encryptData(String data) async {
  return compute(_encrypt, data);
}

// 3. 이미지 처리
Future<Uint8List> applyFilter(Uint8List image) async {
  return compute(_applyFilterIsolate, image);
}

// 4. 데이터베이스 대량 쿼리 (SQLite)
Future<List<Record>> queryLargeDataset() async {
  return compute(_queryDatabase, query);
}
```

**주의사항**:
```dart
// ❌ Isolate에서 UI 접근 불가
compute(() {
  // BuildContext, Navigator 등 사용 불가
  Navigator.of(context).push(...);  // 런타임 에러
}, null);

// ❌ 작은 작업에는 오버헤드
await compute((x) => x + 1, 5);  // Isolate 생성 비용 > 연산 비용

// ✅ 기준: 16ms 이상 걸리는 작업만 Isolate 사용
```

**평가 기준**:
- ✅ 좋은 답변: Event Loop 이해, compute vs Isolate.spawn 차이, 실무 예제
- ❌ 나쁜 답변: "무거운 작업은 Isolate 쓴다" 수준

**꼬리 질문**:
1. Isolate 간 메모리 공유가 안 되는 이유는?
2. Flutter Web에서 Isolate는 어떻게 동작하나요?

**참고 문서**: [../dart/07_isolates_concurrency.md](../dart/07_isolates_concurrency.md)

---

## 2. Widget & 렌더링

### Q6. StatelessWidget과 StatefulWidget의 생명주기와 사용 기준을 설명하세요.

**핵심 키워드**: build, setState, initState, dispose, didUpdateWidget, immutable

**모범 답변**:

**StatelessWidget**:
```dart
// 불변 위젯 - 외부 데이터만 의존
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.size = 40.0,
  });

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundImage: NetworkImage(imageUrl),
    );
  }
}
```

**StatefulWidget 생명주기**:
```dart
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key, this.initialCount = 0});

  final int initialCount;

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  late int _count;
  Timer? _timer;

  // 1. initState: 위젯 트리에 삽입될 때 한 번 호출
  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;  // widget으로 부모 데이터 접근

    // 리소스 초기화
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() => _count++);
    });
  }

  // 2. didUpdateWidget: 부모가 재빌드하여 설정이 변경될 때
  @override
  void didUpdateWidget(CounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCount != widget.initialCount) {
      _count = widget.initialCount;  // 초기값 변경 반영
    }
  }

  // 3. build: setState 또는 부모 재빌드 시 호출
  @override
  Widget build(BuildContext context) {
    return Text('Count: $_count');
  }

  // 4. dispose: 위젯이 트리에서 영구 제거될 때
  @override
  void dispose() {
    _timer?.cancel();  // 리소스 정리 필수
    super.dispose();
  }
}
```

**사용 기준**:
```dart
// ✅ StatelessWidget 사용
// - 내부 상태 없음
// - 순수하게 props만 렌더링
class ProductCard extends StatelessWidget {
  const ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Image.network(product.imageUrl),
          Text(product.name),
          Text('\$${product.price}'),
        ],
      ),
    );
  }
}

// ✅ StatefulWidget 사용
// - 사용자 입력 추적
// - 애니메이션
// - 리소스 관리 (Controller, Subscription)
class SearchField extends StatefulWidget {
  const SearchField({required this.onSearch});
  final ValueChanged<String> onSearch;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 300), () {
      widget.onSearch(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onTextChanged,
    );
  }
}
```

**setState 동작 원리**:
```dart
void _incrementCounter() {
  setState(() {
    _count++;  // 상태 변경
  });
  // setState가 끝나면:
  // 1. State 객체를 dirty로 마킹
  // 2. 다음 프레임에 build() 호출 예약
  // 3. Widget tree → Element tree → RenderObject tree 재구성
}

// ❌ 잘못된 사용
void _badIncrement() {
  _count++;
  setState(() {});  // 빈 함수는 안티패턴
}

// ❌ 비동기 후 setState (위젯이 dispose된 경우 에러)
Future<void> _loadData() async {
  final data = await api.fetch();
  setState(() => _data = data);  // 에러 가능
}

// ✅ 올바른 비동기 처리
Future<void> _loadData() async {
  final data = await api.fetch();
  if (mounted) {  // 위젯이 아직 트리에 있는지 확인
    setState(() => _data = data);
  }
}
```

**평가 기준**:
- ✅ 좋은 답변: 생명주기 순서, dispose 중요성, setState 동작 원리
- ❌ 나쁜 답변: "변하는 건 Stateful, 안 변하는 건 Stateless"

**꼬리 질문**:
1. didChangeDependencies는 언제 호출되나요?
2. setState를 build 안에서 호출하면 어떻게 되나요?

**참고 문서**: [../widgets/01_stateless_vs_stateful.md](../widgets/01_stateless_vs_stateful.md)

---

### Q7. Widget, Element, RenderObject의 관계와 렌더링 파이프라인을 설명하세요.

**핵심 키워드**: Three trees, immutable widget, mutable element, RenderObject, dirty marking

**모범 답변**:

**Three Trees 구조**:
```
Widget Tree (설정)  →  Element Tree (관리)  →  RenderObject Tree (렌더링)
   Container              ContainerElement          RenderContainer
      ↓                          ↓                         ↓
   Padding                PaddingElement            RenderPadding
      ↓                          ↓                         ↓
    Text                   TextElement               RenderParagraph
```

**각 트리의 역할**:
```dart
// 1. Widget: 불변 설정 객체 (재생성 비용 낮음)
class MyWidget extends StatelessWidget {
  const MyWidget({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(color: color);  // 매번 새 Widget 생성
  }
}

// 2. Element: Widget의 인스턴스화, 생명주기 관리
abstract class Element {
  Widget _widget;
  RenderObject? _renderObject;

  void update(Widget newWidget) {
    if (Widget.canUpdate(_widget, newWidget)) {
      _widget = newWidget;
      _renderObject?.markNeedsPaint();  // RenderObject 업데이트
    }
  }
}

// 3. RenderObject: 실제 레이아웃/페인팅
class RenderContainer extends RenderBox {
  Color _color;

  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();  // 리페인트 예약
  }

  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.drawRect(
      offset & size,
      Paint()..color = _color,
    );
  }
}
```

**렌더링 파이프라인**:
```dart
// 프레임 처리 순서
void frameCallback() {
  // 1. Build Phase
  //    - setState() 호출된 Widget의 build() 실행
  //    - 새로운 Widget tree 생성

  // 2. Layout Phase
  //    - RenderObject의 performLayout() 호출
  //    - 부모 → 자식 방향으로 constraints 전달
  //    - 자식 → 부모 방향으로 size 반환

  // 3. Paint Phase
  //    - RenderObject의 paint() 호출
  //    - Layer tree 생성

  // 4. Compositing Phase
  //    - Layer를 GPU로 전송
  //    - Rasterization
}
```

**Widget 재사용 최적화**:
```dart
// ❌ 비효율적: 매번 새 Widget 생성
class BadExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Title'),
        Container(
          padding: EdgeInsets.all(16),  // 매번 새 EdgeInsets
          child: Text('Content'),
        ),
      ],
    );
  }
}

// ✅ 효율적: const 생성자 사용
class GoodExample extends StatelessWidget {
  const GoodExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text('Title'),  // const로 재사용
        Padding(
          padding: EdgeInsets.all(16),  // const로 재사용
          child: Text('Content'),
        ),
      ],
    );
  }
}
```

**Element 업데이트 vs 재생성**:
```dart
// Widget.canUpdate() 로직
static bool canUpdate(Widget oldWidget, Widget newWidget) {
  return oldWidget.runtimeType == newWidget.runtimeType &&
         oldWidget.key == newWidget.key;
}

// 시나리오 1: Element 재사용 (효율적)
// Before
Container(color: Colors.red)
// After
Container(color: Colors.blue)
// → 같은 Element 유지, RenderObject만 업데이트

// 시나리오 2: Element 재생성 (비효율적)
// Before
Container(child: Text('A'))
// After
SizedBox(child: Text('A'))
// → runtimeType 다름 → Element 재생성
```

**실무 최적화 패턴**:
```dart
class OptimizedList extends StatelessWidget {
  const OptimizedList({required this.items});
  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        // ✅ Key 사용으로 Element 재사용
        return ItemCard(
          key: ValueKey(items[index].id),
          item: items[index],
        );
      },
    );
  }
}
```

**평가 기준**:
- ✅ 좋은 답변: Three trees 역할, Widget.canUpdate, const 최적화
- ❌ 나쁜 답변: "Widget이 화면에 그려진다" 수준

**꼬리 질문**:
1. RepaintBoundary는 어떤 원리로 성능을 개선하나요?
2. RenderObject를 직접 만들어야 하는 경우는?

**참고 문서**: [../widgets/02_widget_element_renderobject.md](../widgets/02_widget_element_renderobject.md)

---

### Q8. BuildContext의 정체와 InheritedWidget 조회 메커니즘을 설명하세요.

**핵심 키워드**: Element 참조, of() 패턴, dependOnInheritedWidgetOfExactType, widget tree 순회

**모범 답변**:

**BuildContext의 정체**:
```dart
// BuildContext는 사실 Element의 인터페이스
abstract class BuildContext {
  Widget get widget;
  // ...
}

class Element implements BuildContext {
  Widget _widget;
  Element? _parent;

  @override
  Widget get widget => _widget;
}

// build 메서드의 context는 현재 Element
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // context = MyWidget의 Element 객체
    print(context.widget);  // MyWidget 인스턴스
  }
}
```

**InheritedWidget 조회**:
```dart
// 테마 제공
class AppTheme extends InheritedWidget {
  const AppTheme({
    required this.data,
    required super.child,
  });

  final ThemeData data;

  // ✅ 정적 메서드로 조회 제공
  static ThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    assert(theme != null, 'AppTheme not found in widget tree');
    return theme!.data;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) {
    return data != oldWidget.data;  // 데이터 변경 시 의존자에게 알림
  }
}

// 사용
class MyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);  // 트리 순회하여 AppTheme 찾기
    return Container(color: theme.primaryColor);
  }
}
```

**조회 메커니즘**:
```dart
// dependOnInheritedWidgetOfExactType 내부 동작
@override
T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>() {
  // 1. 현재 Element부터 부모 방향으로 순회
  Element? ancestor = _parent;
  while (ancestor != null) {
    if (ancestor.widget is T) {
      // 2. 찾으면 의존 관계 등록
      _inheritedWidgets[T] = ancestor;
      return ancestor.widget as T;
    }
    ancestor = ancestor._parent;
  }
  return null;
}

// updateShouldNotify가 true 반환하면
// 등록된 모든 의존 Element의 build() 재실행
```

**실무 패턴**:
```dart
// 1. Provider 패턴 구현
class UserProvider extends InheritedWidget {
  const UserProvider({
    required this.user,
    required super.child,
  });

  final User? user;

  static User? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<UserProvider>()
        ?.user;
  }

  static User requireUser(BuildContext context) {
    final user = of(context);
    if (user == null) {
      throw StateError('UserProvider not found');
    }
    return user;
  }

  @override
  bool updateShouldNotify(UserProvider oldWidget) =>
      user != oldWidget.user;
}

// 2. Bloc Provider
class BlocProvider<T extends Bloc> extends StatefulWidget {
  const BlocProvider({
    required this.create,
    required this.child,
  });

  final T Function(BuildContext) create;
  final Widget child;

  static T of<T extends Bloc>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<_InheritedBloc<T>>();
    assert(provider != null, 'BlocProvider<$T> not found');
    return provider!.bloc;
  }

  @override
  State<BlocProvider<T>> createState() => _BlocProviderState<T>();
}

class _BlocProviderState<T extends Bloc> extends State<BlocProvider<T>> {
  late T _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.create(context);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedBloc<T>(
      bloc: _bloc,
      child: widget.child,
    );
  }
}

class _InheritedBloc<T extends Bloc> extends InheritedWidget {
  const _InheritedBloc({
    required this.bloc,
    required super.child,
  });

  final T bloc;

  @override
  bool updateShouldNotify(_InheritedBloc<T> oldWidget) =>
      bloc != oldWidget.bloc;
}
```

**Context 사용 주의사항**:
```dart
class BuildContextDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // ✅ 안전: build 시점의 context
        Navigator.of(context).push(...);
      },
      child: Text('Navigate'),
    );
  }
}

// ❌ 위험: 비동기에서 context 사용
class AsyncContextDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await Future.delayed(Duration(seconds: 2));
        // 이 시점에 위젯이 dispose될 수 있음
        if (context.mounted) {  // ✅ mounted 체크 필수
          Navigator.of(context).pop();
        }
      },
      child: Text('Delayed Pop'),
    );
  }
}
```

**평가 기준**:
- ✅ 좋은 답변: BuildContext = Element, 트리 순회, 의존 관계 등록
- ❌ 나쁜 답변: "위젯의 위치를 나타낸다" 수준

**꼬리 질문**:
1. `of()` vs `maybeOf()`의 차이는?
2. `context.findAncestorWidgetOfExactType`과 `dependOnInheritedWidgetOfExactType`의 차이는?

**참고 문서**: [../widgets/03_buildcontext.md](../widgets/03_buildcontext.md)

---

### Q9. Key의 종류와 각각의 사용 시나리오를 비교하세요.

**핵심 키워드**: ValueKey, ObjectKey, UniqueKey, GlobalKey, Element 재사용

**모범 답변**:

**Key의 역할**:
```dart
// Widget.canUpdate() 로직
static bool canUpdate(Widget oldWidget, Widget newWidget) {
  return oldWidget.runtimeType == newWidget.runtimeType &&
         oldWidget.key == newWidget.key;  // key가 다르면 재생성
}
```

**Local Keys**:
```dart
// 1. ValueKey: 값 기반 식별
class TodoList extends StatelessWidget {
  const TodoList({required this.todos});
  final List<Todo> todos;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return TodoItem(
          key: ValueKey(todo.id),  // ✅ ID로 Element 추적
          todo: todo,
        );
      },
    );
  }
}

// ❌ Key 없으면 문제 발생
// Before: [Todo(1, 'A'), Todo(2, 'B'), Todo(3, 'C')]
// After:  [Todo(1, 'A'), Todo(3, 'C')]  // Todo(2) 삭제
// → Key 없으면 index 기반 매칭 → 잘못된 데이터 표시

// 2. ObjectKey: 객체 인스턴스 식별
class UserCard extends StatelessWidget {
  const UserCard({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ObjectKey(user),  // user 인스턴스로 식별
      child: Text(user.name),
    );
  }
}

// 3. UniqueKey: 항상 새로운 위젯으로 취급
class RandomColorBox extends StatefulWidget {
  const RandomColorBox({super.key});

  @override
  State<RandomColorBox> createState() => _RandomColorBoxState();
}

class _RandomColorBoxState extends State<RandomColorBox> {
  late Color _color;

  @override
  void initState() {
    super.initState();
    _color = _randomColor();
  }

  Color _randomColor() => Color(Random().nextInt(0xFFFFFFFF));

  @override
  Widget build(BuildContext context) {
    return Container(color: _color);
  }
}

// 사용
ListView(
  children: [
    RandomColorBox(key: UniqueKey()),  // 매번 새 State 생성
    RandomColorBox(key: UniqueKey()),
  ],
)
```

**GlobalKey**:
```dart
// 1. State 직접 접근
class ParentWidget extends StatefulWidget {
  @override
  State<ParentWidget> createState() => _ParentWidgetState();
}

class _ParentWidgetState extends State<ParentWidget> {
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();  // Form의 State 메서드 호출
      // 제출 로직
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          ElevatedButton(
            onPressed: _submit,
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}

// 2. Widget 위치 추적
class ScrollToTopDemo extends StatefulWidget {
  @override
  State<ScrollToTopDemo> createState() => _ScrollToTopDemoState();
}

class _ScrollToTopDemoState extends State<ScrollToTopDemo> {
  final _topKey = GlobalKey();

  void _scrollToTop() {
    final context = _topKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: Duration(milliseconds: 300),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(key: _topKey, height: 100, color: Colors.blue),
        Expanded(child: ListView.builder(...)),
        FloatingActionButton(
          onPressed: _scrollToTop,
          child: Icon(Icons.arrow_upward),
        ),
      ],
    );
  }
}

// 3. Widget 이동 (reparenting)
GlobalKey _cardKey = GlobalKey();

// Widget을 다른 부모로 이동해도 State 유지
Widget buildCard() {
  return MyCard(key: _cardKey, data: data);
}
```

**Key 선택 가이드**:
```dart
// ✅ ValueKey: 리스트 아이템 (ID 있음)
ListView.builder(
  itemBuilder: (context, index) => ListTile(
    key: ValueKey(items[index].id),
  ),
)

// ✅ ObjectKey: 복잡한 객체 비교
GridView.builder(
  itemBuilder: (context, index) => ProductCard(
    key: ObjectKey(products[index]),
  ),
)

// ✅ UniqueKey: 강제 재생성
ListView(
  children: items.map((item) => ItemWidget(
    key: UniqueKey(),  // 매번 새로 생성
  )).toList(),
)

// ✅ GlobalKey: State 접근, 위치 추적
final formKey = GlobalKey<FormState>();
Form(key: formKey, ...)

// ❌ 불필요한 Key 사용 (오버헤드)
Container(
  key: ValueKey('static_container'),  // 정적 위젯에는 불필요
  child: Text('Hello'),
)
```

**평가 기준**:
- ✅ 좋은 답변: ValueKey/ObjectKey/GlobalKey 시나리오, Element 재사용 원리
- ❌ 나쁜 답변: "리스트에 Key 쓴다" 수준

**꼬리 질문**:
1. GlobalKey의 성능 오버헤드는?
2. PageStorageKey는 언제 사용하나요?

**참고 문서**: [../widgets/04_keys.md](../widgets/04_keys.md)

---

### Q10. setState 호출 시 내부 동작 과정을 단계별로 설명하세요.

**핵심 키워드**: Dirty marking, BuildOwner, drawFrame, Element.rebuild, renderObject.markNeedsPaint

**모범 답변**:

**setState 내부 구현**:
```dart
@protected
void setState(VoidCallback fn) {
  // 1. 상태 변경 함수 실행
  fn();

  // 2. Element를 dirty로 마킹
  _element!.markNeedsBuild();
}

// Element.markNeedsBuild()
void markNeedsBuild() {
  if (_dirty) return;  // 이미 dirty면 스킵

  _dirty = true;

  // 3. BuildOwner에 dirty element 등록
  owner!.scheduleBuildFor(this);
}

// BuildOwner.scheduleBuildFor()
void scheduleBuildFor(Element element) {
  _dirtyElements.add(element);

  // 4. 다음 프레임에 빌드 예약
  SchedulerBinding.instance.ensureVisualUpdate();
}
```

**프레임 렌더링 파이프라인**:
```dart
// SchedulerBinding.handleDrawFrame()
void handleDrawFrame() {
  // Phase 1: Build - dirty elements 재빌드
  buildOwner.buildScope();  // 모든 dirty element의 build() 호출

  // Phase 2: Layout - RenderObject 크기/위치 계산
  pipelineOwner.flushLayout();

  // Phase 3: Compositing Bits - 레이어 구조 업데이트
  pipelineOwner.flushCompositingBits();

  // Phase 4: Paint - 화면에 그리기
  pipelineOwner.flushPaint();

  // Phase 5: Semantics - 접근성 정보 업데이트
  pipelineOwner.flushSemantics();

  // Phase 6: Compositing - GPU로 전송
  renderView.compositeFrame();
}
```

**Build Phase 상세**:
```dart
// BuildOwner.buildScope()
void buildScope() {
  // dirty elements를 깊이 순으로 정렬 (부모 → 자식)
  _dirtyElements.sort((a, b) => a.depth - b.depth);

  for (final element in _dirtyElements) {
    if (element._dirty && element._active) {
      element.rebuild();  // build() 호출
    }
  }

  _dirtyElements.clear();
}

// Element.rebuild()
void rebuild() {
  if (!_active || !_dirty) return;

  performRebuild();  // StatelessElement 또는 StatefulElement 구현
}

// StatefulElement.performRebuild()
@override
void performRebuild() {
  final built = _state.build(this);  // build() 호출

  // Widget tree 비교 및 Element tree 업데이트
  _child = updateChild(_child, built, slot);

  _dirty = false;
}
```

**실무 시나리오**:
```dart
class CounterDemo extends StatefulWidget {
  @override
  State<CounterDemo> createState() => _CounterDemoState();
}

class _CounterDemoState extends State<CounterDemo> {
  int _count = 0;

  void _increment() {
    print('1. Before setState');

    setState(() {
      _count++;  // 상태 변경
      print('2. Inside setState');
    });

    print('3. After setState');
    // 출력 순서: 1 → 2 → 3 → (다음 프레임) build 호출
  }

  @override
  Widget build(BuildContext context) {
    print('4. build() called with count=$_count');
    return Text('$_count');
  }
}
```

**최적화 패턴**:
```dart
// ❌ 비효율적: 전체 화면 재빌드
class BadExample extends StatefulWidget {
  @override
  State<BadExample> createState() => _BadExampleState();
}

class _BadExampleState extends State<BadExample> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bad Example')),
      body: Column(
        children: [
          ExpensiveWidget(),  // 매번 재빌드
          Text('$_counter'),
          ExpensiveWidget2(),  // 매번 재빌드
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _counter++),
      ),
    );
  }
}

// ✅ 효율적: 필요한 부분만 재빌드
class GoodExample extends StatefulWidget {
  @override
  State<GoodExample> createState() => _GoodExampleState();
}

class _GoodExampleState extends State<GoodExample> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Good Example')),
      body: Column(
        children: [
          const ExpensiveWidget(),  // const로 재빌드 방지
          _CounterDisplay(counter: _counter),  // 이것만 재빌드
          const ExpensiveWidget2(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _counter++),
      ),
    );
  }
}

class _CounterDisplay extends StatelessWidget {
  const _CounterDisplay({required this.counter});
  final int counter;

  @override
  Widget build(BuildContext context) {
    print('Only this widget rebuilds');
    return Text('$counter');
  }
}
```

**디버깅**:
```dart
// Flutter DevTools Performance 탭에서 확인
// - Build phase 소요 시간
// - 재빌드된 Widget 수
// - Frame drop 여부

// 코드로 추적
void _increment() {
  setState(() {
    print('Timeline event: Increment counter');
    Timeline.startSync('CounterIncrement');
    _count++;
    Timeline.finishSync();
  });
}
```

**평가 기준**:
- ✅ 좋은 답변: Dirty marking, BuildOwner, 프레임 파이프라인, 최적화
- ❌ 나쁜 답변: "setState 호출하면 화면이 다시 그려진다"

**꼬리 질문**:
1. setState를 build 안에서 호출하면 어떻게 되나요?
2. 여러 setState를 연속 호출하면 build가 몇 번 실행되나요?

**참고 문서**: [../widgets/01_stateless_vs_stateful.md](../widgets/01_stateless_vs_stateful.md)

---

### Q11. const 생성자의 성능 이점과 적용 가이드라인을 설명하세요.

**핵심 키워드**: Compile-time constant, Widget canonicalization, 재빌드 방지, identical

**모범 답변**:

**const 생성자 동작 원리**:
```dart
// const는 컴파일 타임에 객체 생성
const widget1 = Text('Hello');
const widget2 = Text('Hello');
print(identical(widget1, widget2));  // true - 같은 인스턴스

// 일반 생성자는 런타임에 매번 생성
final widget3 = Text('Hello');
final widget4 = Text('Hello');
print(identical(widget3, widget4));  // false - 다른 인스턴스
```

**성능 이점**:
```dart
class CounterApp extends StatefulWidget {
  @override
  State<CounterApp> createState() => _CounterAppState();
}

class _CounterAppState extends State<CounterApp> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ❌ 매번 새 Widget 생성 → Element.updateChild() 호출
        Text('Counter: $_count'),

        // ✅ const로 재사용 → Element.updateChild() 스킵
        const SizedBox(height: 20),
        const Text('Static Title'),

        ElevatedButton(
          onPressed: () => setState(() => _count++),
          child: const Text('Increment'),  // ✅ child는 불변
        ),
      ],
    );
  }
}
```

**Element 업데이트 로직**:
```dart
// Element.updateChild() 내부
Element? updateChild(Element? child, Widget? newWidget, Object? slot) {
  if (newWidget == null) {
    // Widget 제거
    if (child != null) deactivateChild(child);
    return null;
  }

  if (child != null) {
    if (identical(child.widget, newWidget)) {
      // ✅ 동일 인스턴스면 아무 작업 안 함 (const 효과)
      return child;
    }

    if (Widget.canUpdate(child.widget, newWidget)) {
      // Widget 업데이트
      child.update(newWidget);
      return child;
    }

    // Element 재생성
    deactivateChild(child);
  }

  return inflateWidget(newWidget, slot);
}
```

**적용 가이드라인**:
```dart
// ✅ const 적용 가능
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.name,
    this.age,
  });

  final String name;
  final int? age;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(name),
          if (age != null) Text('Age: $age'),
          const SizedBox(height: 16),  // ✅ const
          const Divider(),             // ✅ const
        ],
      ),
    );
  }
}

// 사용
const ProfileCard(name: 'John', age: 30)  // ✅ 모든 파라미터가 상수

// ❌ const 불가능
class DynamicCard extends StatelessWidget {
  const DynamicCard({required this.onTap});

  final VoidCallback onTap;  // ❌ 함수는 const 불가

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Card(),  // ✅ child는 const 가능
    );
  }
}
```

**실무 패턴**:
```dart
// 1. 공용 위젯 상수화
class AppSpacing {
  static const small = SizedBox(height: 8);
  static const medium = SizedBox(height: 16);
  static const large = SizedBox(height: 24);
}

// 2. 테마 위젯 상수화
class AppWidgets {
  static const loadingIndicator = Center(
    child: CircularProgressIndicator(),
  );

  static const divider = Divider(height: 1, thickness: 1);

  static const emptyState = Center(
    child: Text('No data available'),
  );
}

// 3. 조건부 const
Widget buildCard({required bool isHighlighted}) {
  return Card(
    color: isHighlighted ? Colors.yellow : null,
    child: isHighlighted
        ? Text('Highlighted')  // ❌ const 불가 (조건부)
        : const Text('Normal'),  // ✅ const 가능
  );
}

// 4. ListView 최적화
class ProductList extends StatelessWidget {
  const ProductList({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: products.length,
      itemBuilder: (context, index) => ProductCard(
        key: ValueKey(products[index].id),
        product: products[index],
      ),
      separatorBuilder: (context, index) => const Divider(),  // ✅ const
    );
  }
}
```

**성능 측정**:
```dart
// DevTools Performance 탭에서 비교
// const 없음:
// - Build time: 12.3ms
// - Widget instances: 1,542

// const 적용:
// - Build time: 8.7ms
// - Widget instances: 987
```

**제약 사항**:
```dart
// ❌ const 불가
const widget1 = Text(DateTime.now().toString());  // 런타임 값
const widget2 = Container(color: Theme.of(context).primaryColor);  // context
const widget3 = ElevatedButton(onPressed: () {}, child: Text('OK'));  // 함수

// ✅ const 가능
const widget4 = Text('Static');
const widget5 = Padding(padding: EdgeInsets.all(16), child: Text('OK'));
const widget6 = Icon(Icons.home, size: 24);
```

**평가 기준**:
- ✅ 좋은 답변: Canonicalization, Element.updateChild 스킵, 실무 패턴
- ❌ 나쁜 답변: "const 쓰면 빠르다" 수준

**꼬리 질문**:
1. const와 final의 차이는?
2. @immutable 어노테이션의 역할은?

**참고 문서**: [../widgets/01_stateless_vs_stateful.md](../widgets/01_stateless_vs_stateful.md)

---

### Q12. InheritedWidget의 동작 원리와 커스텀 구현 방법을 설명하세요.

**핵심 키워드**: dependOnInheritedWidgetOfExactType, updateShouldNotify, InheritedNotifier, Provider 패턴

**모범 답변**:

**InheritedWidget 기본 구조**:
```dart
class AppConfig extends InheritedWidget {
  const AppConfig({
    super.key,
    required this.apiBaseUrl,
    required this.enableAnalytics,
    required super.child,
  });

  final String apiBaseUrl;
  final bool enableAnalytics;

  // 정적 메서드로 조회 제공
  static AppConfig of(BuildContext context) {
    final config = context.dependOnInheritedWidgetOfExactType<AppConfig>();
    assert(config != null, 'AppConfig not found in widget tree');
    return config!;
  }

  // 데이터 변경 시 의존자 재빌드 여부 결정
  @override
  bool updateShouldNotify(AppConfig oldWidget) {
    return apiBaseUrl != oldWidget.apiBaseUrl ||
           enableAnalytics != oldWidget.enableAnalytics;
  }
}

// 사용
class ApiService extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final config = AppConfig.of(context);  // 의존 관계 등록
    return Text('API: ${config.apiBaseUrl}');
  }
}
```

**의존 관계 추적**:
```dart
// Element 내부 구조
class Element {
  Map<Type, InheritedElement>? _inheritedWidgets;

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>() {
    // 1. 부모 트리 순회하여 T 타입 찾기
    final ancestor = _findAncestorInheritedElement<T>();

    if (ancestor != null) {
      // 2. 의존 관계 등록
      _inheritedWidgets ??= {};
      _inheritedWidgets![T] = ancestor;

      return ancestor.widget as T;
    }

    return null;
  }
}

// InheritedElement.updated() 내부
void updated(InheritedWidget oldWidget) {
  if ((widget as InheritedWidget).updateShouldNotify(oldWidget)) {
    // 3. 의존하는 모든 Element에게 알림
    _dependents.forEach((element) {
      element.didChangeDependencies();  // build 재실행 유발
    });
  }
}
```

**실무 패턴: ChangeNotifier 통합**:
```dart
// 1. InheritedNotifier 활용
class UserProvider extends InheritedNotifier<UserNotifier> {
  const UserProvider({
    super.key,
    required UserNotifier super.notifier,
    required super.child,
  });

  static UserNotifier of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<UserProvider>()!
        .notifier!;
  }
}

class UserNotifier extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  void setUser(User user) {
    _user = user;
    notifyListeners();  // 의존자 재빌드
  }
}

// 2. Provider 패턴 구현
class Provider<T> extends StatefulWidget {
  const Provider({
    super.key,
    required this.create,
    this.dispose,
    required this.child,
  });

  final T Function(BuildContext) create;
  final void Function(BuildContext, T)? dispose;
  final Widget child;

  static T of<T>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<_InheritedProvider<T>>();
    assert(provider != null, 'Provider<$T> not found');
    return provider!.value;
  }

  @override
  State<Provider<T>> createState() => _ProviderState<T>();
}

class _ProviderState<T> extends State<Provider<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.create(context);
  }

  @override
  void dispose() {
    widget.dispose?.call(context, _value);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedProvider<T>(
      value: _value,
      child: widget.child,
    );
  }
}

class _InheritedProvider<T> extends InheritedWidget {
  const _InheritedProvider({
    required this.value,
    required super.child,
  });

  final T value;

  @override
  bool updateShouldNotify(_InheritedProvider<T> oldWidget) {
    return value != oldWidget.value;
  }
}
```

**고급 패턴: Selector**:
```dart
// 부분 재빌드를 위한 Selector 구현
class Selector<T, R> extends StatelessWidget {
  const Selector({
    super.key,
    required this.selector,
    required this.builder,
  });

  final R Function(T value) selector;
  final Widget Function(BuildContext context, R value) builder;

  @override
  Widget build(BuildContext context) {
    final fullValue = Provider.of<T>(context);
    final selectedValue = selector(fullValue);

    return _SelectorWidget<R>(
      value: selectedValue,
      builder: (context) => builder(context, selectedValue),
    );
  }
}

class _SelectorWidget<R> extends StatefulWidget {
  const _SelectorWidget({
    required this.value,
    required this.builder,
  });

  final R value;
  final Widget Function(BuildContext) builder;

  @override
  State<_SelectorWidget<R>> createState() => _SelectorWidgetState<R>();
}

class _SelectorWidgetState<R> extends State<_SelectorWidget<R>> {
  late R _oldValue;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
  }

  @override
  void didUpdateWidget(_SelectorWidget<R> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_oldValue != widget.value) {
      _oldValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    // value가 변경될 때만 재빌드
    return widget.builder(context);
  }
}

// 사용
Selector<AppState, int>(
  selector: (state) => state.counter,  // counter만 관찰
  builder: (context, counter) => Text('$counter'),
)
```

**평가 기준**:
- ✅ 좋은 답변: 의존 관계 등록, updateShouldNotify, Provider 패턴
- ❌ 나쁜 답변: "데이터를 하위로 전달한다" 수준

**꼬리 질문**:
1. InheritedWidget vs Provider 패키지 차이는?
2. 여러 InheritedWidget이 중첩되면 성능은?

**참고 문서**: [../widgets/05_inherited_widget.md](../widgets/05_inherited_widget.md)

---

## 3. 상태 관리

### Q13. Bloc의 Event → State 흐름과 내부 동작 원리를 설명하세요.

**핵심 키워드**: EventHandler, Emitter, EventTransformer, Stream pipeline, on<Event>

**모범 답변**:

**Bloc 아키텍처**:
```dart
// Event: 사용자 액션 또는 외부 이벤트
sealed class CounterEvent {}
class Increment extends CounterEvent {}
class Decrement extends CounterEvent {}

// State: UI 상태
class CounterState {
  const CounterState(this.count);
  final int count;
}

// Bloc: Event → State 변환 로직
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterState(0)) {
    // Event Handler 등록
    on<Increment>(_onIncrement);
    on<Decrement>(_onDecrement);
  }

  void _onIncrement(Increment event, Emitter<CounterState> emit) {
    emit(CounterState(state.count + 1));
  }

  void _onDecrement(Decrement event, Emitter<CounterState> emit) {
    emit(CounterState(state.count - 1));
  }
}
```

**내부 동작 흐름**:
```dart
// Bloc.add() 호출 시
void add(Event event) {
  // 1. Event를 internal stream에 추가
  _eventController.add(event);
}

// Bloc 생성자에서 설정된 Stream pipeline
Bloc() {
  // 2. Event stream 구독
  _eventStreamSubscription = _eventController.stream
      .transform(_eventTransformer)  // 3. 이벤트 변환 (debounce 등)
      .listen((event) {
        // 4. 등록된 EventHandler 실행
        _handleEvent(event);
      });
}

void _handleEvent(Event event) {
  final handler = _eventHandlers[event.runtimeType];

  if (handler != null) {
    // 5. Emitter를 통해 State 방출
    final emitter = _Emitter<State>(
      onEmit: (state) {
        _stateController.add(state);  // Stream에 추가
        _state = state;  // 현재 상태 업데이트
      },
    );

    handler(event, emitter);
  }
}
```

**실무 패턴: 비동기 처리**:
```dart
sealed class UserEvent {}
class LoadUser extends UserEvent {
  LoadUser(this.userId);
  final String userId;
}
class RefreshUser extends UserEvent {}

sealed class UserState {}
class UserInitial extends UserState {}
class UserLoading extends UserState {}
class UserLoaded extends UserState {
  UserLoaded(this.user);
  final User user;
}
class UserError extends UserState {
  UserError(this.message);
  final String message;
}

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc(this._repository) : super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
    on<RefreshUser>(_onRefreshUser);
  }

  final UserRepository _repository;

  Future<void> _onLoadUser(
    LoadUser event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    try {
      final user = await _repository.getUser(event.userId);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onRefreshUser(
    RefreshUser event,
    Emitter<UserState> emit,
  ) async {
    // 현재 state 유지하면서 재로딩
    final currentState = state;
    if (currentState is! UserLoaded) return;

    try {
      final user = await _repository.getUser(currentState.user.id);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
```

**EventTransformer 활용**:
```dart
// 1. Debounce: 연속 입력 방지
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchInitial()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: debounce(Duration(milliseconds: 300)),
    );
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    final results = await _search(event.query);
    emit(SearchLoaded(results));
  }
}

EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events
      .debounceTime(duration)
      .switchMap(mapper);
}

// 2. Throttle: 일정 간격으로만 처리
on<ButtonTapped>(
  _onButtonTapped,
  transformer: throttle(Duration(seconds: 1)),
);

EventTransformer<E> throttle<E>(Duration duration) {
  return (events, mapper) => events
      .throttleTime(duration)
      .asyncExpand(mapper);
}

// 3. Sequential: 순차 처리 (기본값)
on<SaveData>(_onSaveData);  // 이전 요청 완료 후 다음 처리

// 4. Concurrent: 병렬 처리
on<FetchMultiplePages>(
  _onFetchPages,
  transformer: concurrent(),
);
```

**에러 처리 패턴**:
```dart
class RobustBloc extends Bloc<RobustEvent, RobustState> {
  RobustBloc() : super(RobustInitial()) {
    on<FetchData>(_onFetchData);
  }

  Future<void> _onFetchData(
    FetchData event,
    Emitter<RobustState> emit,
  ) async {
    emit(RobustLoading());

    try {
      final data = await _repository.fetch();
      emit(RobustLoaded(data));
    } on NetworkException catch (e) {
      emit(RobustError('Network error: ${e.message}', retry: true));
    } on ServerException catch (e) {
      emit(RobustError('Server error: ${e.statusCode}'));
    } catch (e) {
      emit(RobustError('Unexpected error', retry: false));
      rethrow;  // 로깅을 위해 재발생
    }
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    // 전역 에러 핸들러
    logger.error('Bloc error', error, stackTrace);
    super.onError(error, stackTrace);
  }
}
```

**평가 기준**:
- ✅ 좋은 답변: Event stream, Emitter, EventTransformer, 비동기 처리
- ❌ 나쁜 답변: "Event 보내면 State 나온다" 수준

**꼬리 질문**:
1. EventTransformer의 성능 영향은?
2. Bloc.add()를 연속 호출하면 순서가 보장되나요?

**참고 문서**: [../state-management/02_bloc_cubit.md](../state-management/02_bloc_cubit.md)

---

### Q14. Cubit과 Bloc의 차이, 각각 언제 사용하는지 설명하세요.

**핵심 키워드**: Method vs Event, 단순성 vs 확장성, Testability, EventTransformer

**모범 답변**:

**Cubit: 메서드 기반**:
```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
  void reset() => emit(0);
}

// 사용
final cubit = CounterCubit();
cubit.increment();  // 직접 메서드 호출
```

**Bloc: 이벤트 기반**:
```dart
sealed class CounterEvent {}
class Increment extends CounterEvent {}
class Decrement extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
    on<Decrement>((event, emit) => emit(state - 1));
  }
}

// 사용
final bloc = CounterBloc();
bloc.add(Increment());  // Event 발송
```

**비교 표**:
```
|                    | Cubit              | Bloc                  |
|--------------------|--------------------|-----------------------|
| 상태 변경          | 메서드 호출        | Event 발송            |
| 코드 복잡도        | 낮음               | 높음                  |
| Testability        | 단순               | Event replay 가능     |
| 비동기 제어        | 수동               | EventTransformer 내장 |
| 추적성             | 낮음               | 높음 (Event 로깅)     |
| 적합한 시나리오    | 단순 상태 전환     | 복잡한 비즈니스 로직  |
```

**Cubit 사용 시나리오**:
```dart
// 1. UI 상태 토글
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void toggleTheme() {
    emit(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }
}

// 2. Form 입력 관리
class LoginFormCubit extends Cubit<LoginFormState> {
  LoginFormCubit() : super(LoginFormState.initial());

  void emailChanged(String email) {
    emit(state.copyWith(
      email: email,
      isEmailValid: _validateEmail(email),
    ));
  }

  void passwordChanged(String password) {
    emit(state.copyWith(password: password));
  }
}

// 3. 간단한 카운터, 페이지네이션
class PageCubit extends Cubit<int> {
  PageCubit() : super(0);

  void nextPage() => emit(state + 1);
  void previousPage() => emit(state - 1);
  void goToPage(int page) => emit(page);
}
```

**Bloc 사용 시나리오**:
```dart
// 1. 복잡한 비즈니스 로직
sealed class CheckoutEvent {}
class AddToCart extends CheckoutEvent {
  AddToCart(this.product);
  final Product product;
}
class RemoveFromCart extends CheckoutEvent {
  RemoveFromCart(this.productId);
  final String productId;
}
class ApplyCoupon extends CheckoutEvent {
  ApplyCoupon(this.code);
  final String code;
}
class Checkout extends CheckoutEvent {}

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc(this._repository) : super(CheckoutState.initial()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ApplyCoupon>(_onApplyCoupon);
    on<Checkout>(_onCheckout, transformer: sequential());  // 순차 처리
  }

  final CheckoutRepository _repository;

  Future<void> _onCheckout(
    Checkout event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(status: CheckoutStatus.processing));

    try {
      final order = await _repository.createOrder(state.cart);
      await _repository.processPayment(order.id);
      emit(state.copyWith(
        status: CheckoutStatus.success,
        orderId: order.id,
      ));
    } catch (e) {
      emit(state.copyWith(status: CheckoutStatus.error));
    }
  }
}

// 2. 검색 (Debounce 필요)
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._repository) : super(SearchInitial()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: debounce(Duration(milliseconds: 300)),
    );
  }
}

// 3. 실시간 데이터 (Stream 기반)
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(this._repository) : super(ChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<MessageReceived>(_onMessageReceived);
  }

  Future<void> _onStarted(
    ChatStarted event,
    Emitter<ChatState> emit,
  ) async {
    await emit.forEach(
      _repository.watchMessages(event.chatId),
      onData: (messages) => ChatLoaded(messages),
      onError: (error, stackTrace) => ChatError(error.toString()),
    );
  }
}
```

**마이그레이션 패턴**:
```dart
// Cubit에서 Bloc으로 전환
// Before (Cubit)
class UserCubit extends Cubit<UserState> {
  UserCubit(this._repository) : super(UserInitial());

  Future<void> loadUser(String id) async {
    emit(UserLoading());
    try {
      final user = await _repository.getUser(id);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}

// After (Bloc)
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc(this._repository) : super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
  }

  Future<void> _onLoadUser(
    LoadUser event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final user = await _repository.getUser(event.userId);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
```

**선택 가이드**:
```dart
// ✅ Cubit 사용
// - 상태 전환이 단순 (5개 이하 메서드)
// - Event 로깅이 불필요
// - 팀이 Bloc 패턴에 익숙하지 않음

// ✅ Bloc 사용
// - 복잡한 비즈니스 로직 (10+ 상태 전환)
// - Event replay, undo/redo 필요
// - Debounce/Throttle 등 이벤트 변환 필요
// - 여러 곳에서 같은 Event 발송
// - 감사 로그 필요 (Event 기록)
```

**평가 기준**:
- ✅ 좋은 답변: 메서드 vs Event, 사용 시나리오, tradeoff 이해
- ❌ 나쁜 답변: "Cubit이 간단한 버전이다" 수준

**꼬리 질문**:
1. Cubit을 Bloc처럼 Event 패턴으로 만들 수 없나요?
2. HydratedBloc은 Cubit에도 적용 가능한가요?

**참고 문서**: [../state-management/02_bloc_cubit.md](../state-management/02_bloc_cubit.md)

---

### Q15. BlocProvider, BlocBuilder, BlocListener, BlocConsumer의 차이와 사용법을 설명하세요.

**핵심 키워드**: Dependency injection, Rebuild optimization, Side effect, listenWhen/buildWhen

**모범 답변**:

**1. BlocProvider: Bloc 인스턴스 제공**:
```dart
// Bloc 생성 및 제공
BlocProvider(
  create: (context) => CounterBloc(
    repository: context.read<CounterRepository>(),
  ),
  child: CounterPage(),
)

// 조회
final bloc = context.read<CounterBloc>();  // 재빌드 없음
final bloc2 = context.watch<CounterBloc>();  // state 변경 시 재빌드

// 다중 Provider
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => AuthBloc()),
    BlocProvider(create: (_) => UserBloc()),
  ],
  child: App(),
)
```

**2. BlocBuilder: State 기반 UI 재빌드**:
```dart
// 기본 사용
BlocBuilder<CounterBloc, int>(
  builder: (context, state) {
    return Text('Count: $state');
  },
)

// buildWhen으로 재빌드 최적화
BlocBuilder<UserBloc, UserState>(
  buildWhen: (previous, current) {
    // name만 변경되었을 때만 재빌드
    if (previous is UserLoaded && current is UserLoaded) {
      return previous.user.name != current.user.name;
    }
    return true;
  },
  builder: (context, state) {
    return switch (state) {
      UserLoading() => CircularProgressIndicator(),
      UserLoaded(user: final user) => Text(user.name),
      UserError(message: final msg) => Text('Error: $msg'),
      _ => SizedBox.shrink(),
    };
  },
)
```

**3. BlocListener: Side effect 처리 (UI 재빌드 없음)**:
```dart
// Navigation, SnackBar 등
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    switch (state) {
      case AuthAuthenticated():
        context.go('/home');
      case AuthUnauthenticated():
        context.go('/login');
      case AuthError(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
    }
  },
  child: LoginForm(),
)

// listenWhen으로 필터링
BlocListener<CheckoutBloc, CheckoutState>(
  listenWhen: (previous, current) {
    // status만 변경되었을 때만 리스닝
    return previous.status != current.status;
  },
  listener: (context, state) {
    if (state.status == CheckoutStatus.success) {
      context.go('/order/${state.orderId}');
    }
  },
  child: CheckoutView(),
)

// 다중 Listener
MultiBlocListener(
  listeners: [
    BlocListener<AuthBloc, AuthState>(
      listener: (context, state) { /* ... */ },
    ),
    BlocListener<CartBloc, CartState>(
      listener: (context, state) { /* ... */ },
    ),
  ],
  child: HomePage(),
)
```

**4. BlocConsumer: Builder + Listener 결합**:
```dart
// UI 재빌드 + Side effect
BlocConsumer<ProductBloc, ProductState>(
  listener: (context, state) {
    // Side effect
    if (state is ProductError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) {
    // UI 렌더링
    return switch (state) {
      ProductLoading() => CircularProgressIndicator(),
      ProductLoaded(products: final products) => ProductList(products),
      ProductError() => ErrorView(),
      _ => SizedBox.shrink(),
    };
  },
)

// buildWhen + listenWhen 조합
BlocConsumer<CartBloc, CartState>(
  listenWhen: (previous, current) =>
      current.status == CartStatus.checkoutSuccess,
  buildWhen: (previous, current) =>
      previous.items.length != current.items.length,
  listener: (context, state) {
    context.go('/order/${state.orderId}');
  },
  builder: (context, state) {
    return CartItemsList(items: state.items);
  },
)
```

**실무 패턴**:
```dart
// 1. 부분 재빌드 최적화
class ProductCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // 가격만 변경되었을 때 이 부분만 재빌드
          BlocBuilder<ProductBloc, ProductState>(
            buildWhen: (prev, curr) =>
                prev is ProductLoaded &&
                curr is ProductLoaded &&
                prev.product.price != curr.product.price,
            builder: (context, state) {
              if (state is ProductLoaded) {
                return Text('\$${state.product.price}');
              }
              return SizedBox.shrink();
            },
          ),

          // 재고만 변경되었을 때 이 부분만 재빌드
          BlocBuilder<ProductBloc, ProductState>(
            buildWhen: (prev, curr) =>
                prev is ProductLoaded &&
                curr is ProductLoaded &&
                prev.product.stock != curr.product.stock,
            builder: (context, state) {
              if (state is ProductLoaded) {
                return Text('Stock: ${state.product.stock}');
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

// 2. 인증 가드
class AuthGuard extends StatelessWidget {
  const AuthGuard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return switch (state) {
            AuthAuthenticated() => child,
            AuthLoading() => LoadingScreen(),
            _ => LoginPrompt(),
          };
        },
      ),
    );
  }
}

// 3. Error Boundary
class ErrorBoundary extends StatelessWidget {
  const ErrorBoundary({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UserBloc, UserState>(
          listenWhen: (_, curr) => curr is UserError,
          listener: (context, state) =>
              _showError(context, (state as UserError).message),
        ),
        BlocListener<ProductBloc, ProductState>(
          listenWhen: (_, curr) => curr is ProductError,
          listener: (context, state) =>
              _showError(context, (state as ProductError).message),
        ),
      ],
      child: child,
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
```

**성능 비교**:
```dart
// ❌ 비효율적: 전체 재빌드
BlocBuilder<UserBloc, UserState>(
  builder: (context, state) {
    return Column(
      children: [
        Text(state.name),      // name 변경 시 재빌드
        Text(state.email),     // email 변경 시 재빌드
        Text(state.address),   // address 변경 시 재빌드
      ],
    );
  },
)

// ✅ 효율적: 필요한 부분만 재빌드
Column(
  children: [
    BlocBuilder<UserBloc, UserState>(
      buildWhen: (p, c) => p.name != c.name,
      builder: (context, state) => Text(state.name),
    ),
    BlocBuilder<UserBloc, UserState>(
      buildWhen: (p, c) => p.email != c.email,
      builder: (context, state) => Text(state.email),
    ),
  ],
)
```

**평가 기준**:
- ✅ 좋은 답변: buildWhen/listenWhen 최적화, 사용 시나리오 구분
- ❌ 나쁜 답변: "BlocBuilder는 화면 그리고 BlocListener는 동작한다"

**꼬리 질문**:
1. context.read vs context.watch의 차이는?
2. BlocSelector는 언제 사용하나요?

**참고 문서**: [../state-management/02_bloc_cubit.md](../state-management/02_bloc_cubit.md)

---

### Q16. Freezed를 사용한 불변 State 설계의 이점과 패턴을 설명하세요.

**핵심 키워드**: Immutability, copyWith, Union types, Sealed class, Code generation

**모범 답변**:

**Freezed의 핵심 기능**:
```dart
// 1. 불변 클래스 생성
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    String? email,
    @Default(false) bool isVerified,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// 생성된 코드:
// - 불변 프로퍼티
// - copyWith 메서드
// - == / hashCode
// - toString
// - JSON serialization
```

**copyWith로 불변 업데이트**:
```dart
final user = User(id: '1', name: 'John');

// ❌ 가변 클래스였다면
// user.name = 'Jane';  // 컴파일 에러

// ✅ 불변 업데이트
final updatedUser = user.copyWith(name: 'Jane');

print(user.name);         // 'John' (원본 유지)
print(updatedUser.name);  // 'Jane'

// 부분 업데이트
final user2 = user.copyWith(email: 'john@example.com');
print(user2.name);   // 'John' (다른 필드 유지)
print(user2.email);  // 'john@example.com'
```

**Union Types (Sealed Class)**:
```dart
@freezed
class ApiResult<T> with _$ApiResult<T> {
  const factory ApiResult.loading() = Loading<T>;
  const factory ApiResult.success(T data) = Success<T>;
  const factory ApiResult.error(String message, {int? statusCode}) = Error<T>;
}

// 패턴 매칭 (Exhaustive)
Widget buildView(ApiResult<User> result) {
  return result.when(
    loading: () => CircularProgressIndicator(),
    success: (user) => UserProfile(user: user),
    error: (msg, statusCode) => ErrorView(message: msg),
  );
  // 하나라도 빠지면 컴파일 에러
}

// 선택적 처리
result.maybeWhen(
  success: (user) => print(user.name),
  orElse: () => print('Not success'),
);

// Map 변환
final message = result.map(
  loading: (_) => 'Loading...',
  success: (s) => 'Loaded: ${s.data.name}',
  error: (e) => 'Error: ${e.message}',
);
```

**Bloc State 설계**:
```dart
@freezed
class UserState with _$UserState {
  const factory UserState.initial() = Initial;
  const factory UserState.loading() = Loading;
  const factory UserState.loaded({
    required User user,
    required List<Post> posts,
    @Default(false) bool isRefreshing,
  }) = Loaded;
  const factory UserState.error(String message) = Error;
}

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(UserState.initial()) {
    on<LoadUser>(_onLoadUser);
    on<RefreshPosts>(_onRefreshPosts);
  }

  Future<void> _onLoadUser(
    LoadUser event,
    Emitter<UserState> emit,
  ) async {
    emit(UserState.loading());

    try {
      final user = await _repository.getUser(event.userId);
      final posts = await _repository.getUserPosts(event.userId);

      emit(UserState.loaded(user: user, posts: posts));
    } catch (e) {
      emit(UserState.error(e.toString()));
    }
  }

  Future<void> _onRefreshPosts(
    RefreshPosts event,
    Emitter<UserState> emit,
  ) async {
    final currentState = state;
    if (currentState is! Loaded) return;

    // isRefreshing만 업데이트
    emit(currentState.copyWith(isRefreshing: true));

    try {
      final posts = await _repository.getUserPosts(currentState.user.id);
      emit(currentState.copyWith(
        posts: posts,
        isRefreshing: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isRefreshing: false));
    }
  }
}
```

**복잡한 State 관리**:
```dart
@freezed
class CheckoutState with _$CheckoutState {
  const factory CheckoutState({
    required List<CartItem> items,
    String? couponCode,
    double? discount,
    required CheckoutStatus status,
    String? orderId,
    String? errorMessage,
  }) = _CheckoutState;

  factory CheckoutState.initial() => CheckoutState(
    items: [],
    status: CheckoutStatus.idle,
  );
}

enum CheckoutStatus {
  idle,
  validatingCoupon,
  processing,
  success,
  error,
}

// 사용
void _onApplyCoupon(ApplyCoupon event, Emitter<CheckoutState> emit) async {
  emit(state.copyWith(status: CheckoutStatus.validatingCoupon));

  final result = await _validateCoupon(event.code);

  result.when(
    success: (discount) => emit(state.copyWith(
      couponCode: event.code,
      discount: discount,
      status: CheckoutStatus.idle,
    )),
    error: (message) => emit(state.copyWith(
      couponCode: null,
      discount: null,
      status: CheckoutStatus.error,
      errorMessage: message,
    )),
  );
}
```

**불변성의 이점**:
```dart
// 1. 예측 가능한 상태 변경
final state1 = UserState.loaded(user: user, posts: []);
final state2 = state1.copyWith(posts: newPosts);

print(identical(state1, state2));  // false
print(state1.posts.length);        // 0 (원본 유지)
print(state2.posts.length);        // 10

// 2. 안전한 State 비교
BlocBuilder<UserBloc, UserState>(
  buildWhen: (previous, current) {
    // Freezed가 == 연산자 생성
    return previous != current;
  },
  builder: (context, state) { /* ... */ },
)

// 3. 시간 여행 디버깅
final stateHistory = <UserState>[];

bloc.stream.listen((state) {
  stateHistory.add(state);  // 각 상태가 독립적으로 보존됨
});

// 4. Undo/Redo 구현
class UndoableBloc extends Bloc<UndoableEvent, UndoableState> {
  final List<UndoableState> _history = [];
  int _currentIndex = -1;

  void _addState(UndoableState state) {
    _history.removeRange(_currentIndex + 1, _history.length);
    _history.add(state);
    _currentIndex++;
  }

  void undo() {
    if (_currentIndex > 0) {
      _currentIndex--;
      emit(_history[_currentIndex]);
    }
  }

  void redo() {
    if (_currentIndex < _history.length - 1) {
      _currentIndex++;
      emit(_history[_currentIndex]);
    }
  }
}
```

**JSON 직렬화**:
```dart
@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required double price,
    @JsonKey(name: 'image_url') String? imageUrl,
    @Default([]) List<String> tags,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

// 사용
final json = {'id': '1', 'name': 'Widget', 'price': 9.99};
final product = Product.fromJson(json);
final jsonOut = product.toJson();
```

**평가 기준**:
- ✅ 좋은 답변: copyWith, Union types, 불변성 이점, when/map 활용
- ❌ 나쁜 답변: "Freezed는 boilerplate 줄여준다" 수준

**꼬리 질문**:
1. Freezed 없이 불변 클래스를 직접 구현하면?
2. @unfreezed는 언제 사용하나요?

**참고 문서**: [../state-management/02_bloc_cubit.md](../state-management/02_bloc_cubit.md)

---

### Q17. 여러 Bloc 간 데이터 공유와 통신 패턴을 설명하세요.

**핵심 키워드**: Repository 공유, Bloc 간 의존, Stream subscription, Event forwarding

**모범 답변**:

**1. Repository 공유 (추천)**:
```dart
// Bloc들이 같은 Repository 인스턴스 사용
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc(this._repository) : super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
  }

  final UserRepository _repository;
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repository) : super(ProfileInitial()) {
    on<UpdateProfile>(_onUpdateProfile);
  }

  final UserRepository _repository;  // 같은 Repository
}

// 의존성 주입
MultiBlocProvider(
  providers: [
    RepositoryProvider(
      create: (context) => UserRepository(),
    ),
    BlocProvider(
      create: (context) => UserBloc(
        context.read<UserRepository>(),
      ),
    ),
    BlocProvider(
      create: (context) => ProfileBloc(
        context.read<UserRepository>(),
      ),
    ),
  ],
  child: App(),
)
```

**2. Bloc 간 직접 의존**:
```dart
// AuthBloc의 상태를 UserBloc에서 관찰
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc(this._authBloc) : super(UserInitial()) {
    on<LoadUser>(_onLoadUser);

    // AuthBloc 변화 감지
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        add(LoadUser(authState.userId));
      } else if (authState is AuthUnauthenticated) {
        add(ClearUser());
      }
    });
  }

  final AuthBloc _authBloc;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

// 사용
BlocProvider(
  create: (context) => UserBloc(
    context.read<AuthBloc>(),  // AuthBloc 주입
  ),
  child: UserPage(),
)
```

**3. Event Forwarding**:
```dart
// CartBloc의 이벤트를 CheckoutBloc으로 전달
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc(this._cartBloc) : super(CheckoutInitial()) {
    on<StartCheckout>(_onStartCheckout);

    _cartSubscription = _cartBloc.stream.listen((cartState) {
      if (cartState is CartUpdated) {
        add(UpdateCheckoutCart(cartState.items));
      }
    });
  }

  final CartBloc _cartBloc;
  StreamSubscription<CartState>? _cartSubscription;

  Future<void> _onStartCheckout(
    StartCheckout event,
    Emitter<CheckoutState> emit,
  ) async {
    // Cart 데이터 가져오기
    final cartState = _cartBloc.state;
    if (cartState is! CartLoaded) return;

    emit(CheckoutInProgress(items: cartState.items));
  }

  @override
  Future<void> close() {
    _cartSubscription?.cancel();
    return super.close();
  }
}
```

**4. 공유 Stream**:
```dart
// 실시간 데이터를 여러 Bloc에서 구독
class NotificationRepository {
  Stream<List<Notification>> watchNotifications() {
    return _firestore
        .collection('notifications')
        .snapshots()
        .map((snapshot) => /* ... */);
  }
}

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc(this._repository) : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    await emit.forEach(
      _repository.watchNotifications(),
      onData: (notifications) => NotificationLoaded(notifications),
    );
  }
}

class BadgeBloc extends Bloc<BadgeEvent, BadgeState> {
  BadgeBloc(this._repository) : super(BadgeState(count: 0)) {
    on<UpdateBadge>(_onUpdateBadge);
  }

  Future<void> _onUpdateBadge(
    UpdateBadge event,
    Emitter<BadgeState> emit,
  ) async {
    await emit.forEach(
      _repository.watchNotifications(),
      onData: (notifications) => BadgeState(
        count: notifications.where((n) => !n.isRead).length,
      ),
    );
  }
}
```

**5. Global Event Bus (신중히 사용)**:
```dart
// 이벤트 버스
class EventBus {
  static final _controller = StreamController<GlobalEvent>.broadcast();

  static Stream<T> on<T extends GlobalEvent>() =>
      _controller.stream.where((event) => event is T).cast<T>();

  static void fire(GlobalEvent event) => _controller.add(event);
}

sealed class GlobalEvent {}
class UserLoggedIn extends GlobalEvent {
  UserLoggedIn(this.userId);
  final String userId;
}
class UserLoggedOut extends GlobalEvent {}

// Bloc에서 구독
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  AnalyticsBloc() : super(AnalyticsState()) {
    _userLoginSubscription = EventBus.on<UserLoggedIn>().listen((event) {
      add(TrackLogin(event.userId));
    });
  }

  StreamSubscription? _userLoginSubscription;

  @override
  Future<void> close() {
    _userLoginSubscription?.cancel();
    return super.close();
  }
}

// 이벤트 발생
void _onAuthSuccess(AuthSuccess event, Emitter<AuthState> emit) {
  EventBus.fire(UserLoggedIn(event.userId));
  emit(AuthAuthenticated(userId: event.userId));
}
```

**실무 패턴: Feature 모듈 간 통신**:
```dart
// features/auth/bloc/auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // ...
}

// features/user/bloc/user_bloc.dart
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc({
    required AuthBloc authBloc,
    required UserRepository repository,
  }) : _authBloc = authBloc,
       _repository = repository,
       super(UserInitial()) {
    _authSubscription = _authBloc.stream.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(AuthState authState) {
    authState.whenOrNull(
      authenticated: (userId) => add(LoadUser(userId)),
      unauthenticated: () => add(ClearUser()),
    );
  }
}

// features/settings/bloc/settings_bloc.dart
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required AuthBloc authBloc,
    required UserBloc userBloc,
  }) : _authBloc = authBloc,
       _userBloc = userBloc,
       super(SettingsInitial()) {
    _userSubscription = _userBloc.stream.listen(_onUserStateChanged);
  }
}

// 의존성 그래프
// AuthBloc (root)
//    ↓
// UserBloc (listens to AuthBloc)
//    ↓
// SettingsBloc (listens to UserBloc)
```

**안티패턴**:
```dart
// ❌ Bloc 간 순환 참조
class BlocA extends Bloc<EventA, StateA> {
  BlocA(this.blocB);
  final BlocB blocB;
}

class BlocB extends Bloc<EventB, StateB> {
  BlocB(this.blocA);  // 순환 참조
  final BlocA blocA;
}

// ✅ Repository를 통한 간접 통신
class BlocA extends Bloc<EventA, StateA> {
  BlocA(this.repository);
  final SharedRepository repository;
}

class BlocB extends Bloc<EventB, StateB> {
  BlocB(this.repository);
  final SharedRepository repository;
}
```

**평가 기준**:
- ✅ 좋은 답변: Repository 공유, Stream subscription, 순환 참조 방지
- ❌ 나쁜 답변: "Global 변수로 공유한다" 수준

**꼬리 질문**:
1. Bloc 간 의존이 3단계 이상이면 어떻게 리팩토링하나요?
2. EventBus vs Bloc 직접 의존의 tradeoff는?

**참고 문서**: [../state-management/02_bloc_cubit.md](../state-management/02_bloc_cubit.md)

---

### Q18. Riverpod과 Bloc의 차이, 각각의 장단점을 비교하세요.

**핵심 키워드**: Compile-time safety, Provider, Reactive programming, Boilerplate, Testing

**모범 답변**:

**Riverpod 특징**:
```dart
// 1. Provider 선언 (전역)
final counterProvider = StateProvider<int>((ref) => 0);

final userProvider = FutureProvider<User>((ref) async {
  final api = ref.watch(apiProvider);
  return await api.getUser();
});

// 2. 사용 (ConsumerWidget)
class CounterView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);

    return Column(
      children: [
        Text('$count'),
        ElevatedButton(
          onPressed: () => ref.read(counterProvider.notifier).state++,
          child: Text('Increment'),
        ),
      ],
    );
  }
}

// 3. Provider 조합
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider);
  final filter = ref.watch(filterProvider);

  return products.where((p) => p.category == filter).toList();
});
```

**Bloc 특징**:
```dart
// 1. Bloc 정의
sealed class CounterEvent {}
class Increment extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}

// 2. 사용
class CounterView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterBloc, int>(
      builder: (context, count) {
        return Column(
          children: [
            Text('$count'),
            ElevatedButton(
              onPressed: () => context.read<CounterBloc>().add(Increment()),
              child: Text('Increment'),
            ),
          ],
        );
      },
    );
  }
}
```

**비교 표**:
```
| 항목                | Riverpod                    | Bloc                          |
|---------------------|-----------------------------|---------------------------------|
| 상태 변경           | 직접 할당 / notifier        | Event 발송                     |
| Boilerplate         | 낮음                        | 높음 (Event/State 클래스)      |
| 타입 안전성         | 컴파일 타임 보장            | 런타임 타입 체크              |
| 비동기 처리         | FutureProvider 내장         | async/await in EventHandler   |
| 테스트              | Provider override           | blocTest 패키지               |
| DevTools            | Riverpod Inspector          | Bloc Observer                 |
| 학습 곡선           | 낮음                        | 중간                          |
| 구조화              | Provider 조합               | Event-driven                  |
| 적합한 규모         | 소규모~중규모               | 중규모~대규모                 |
```

**Riverpod 장점**:
```dart
// 1. 간결한 코드
final counterProvider = StateProvider<int>((ref) => 0);

// 2. 컴파일 타임 안전성
ref.watch(counterProvider);  // 타입 추론
ref.watch(unknownProvider);  // 컴파일 에러

// 3. Provider 자동 dispose
// ref가 스코프를 벗어나면 자동 정리

// 4. Provider 조합 (의존성 그래프)
final userPostsProvider = FutureProvider<List<Post>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final api = ref.watch(apiProvider);
  return await api.getPosts(userId);
});

// 5. Family: 파라미터화된 Provider
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  final api = ref.watch(apiProvider);
  return await api.getUser(userId);
});

// 사용
ref.watch(userProvider('user-123'));
```

**Bloc 장점**:
```dart
// 1. 명시적 Event (추적성)
bloc.add(LoadUser('user-123'));
// DevTools에서 Event 히스토리 확인 가능

// 2. 복잡한 비즈니스 로직
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc() : super(CheckoutInitial()) {
    on<ValidateCart>(_onValidateCart);
    on<ApplyCoupon>(_onApplyCoupon, transformer: debounce(...));
    on<ProcessPayment>(_onProcessPayment, transformer: sequential());
  }

  // 복잡한 상태 전환 로직
}

// 3. 테스트 용이성
blocTest<CounterBloc, int>(
  'emits [1] when Increment is added',
  build: () => CounterBloc(),
  act: (bloc) => bloc.add(Increment()),
  expect: () => [1],
);

// 4. EventTransformer
on<SearchQueryChanged>(
  _onQueryChanged,
  transformer: debounce(Duration(milliseconds: 300)),
);

// 5. 대규모 팀에서의 일관성
// Event 기반 → 같은 패턴 반복
```

**실무 선택 가이드**:
```dart
// ✅ Riverpod 추천
// - 소규모 앱 (~50개 화면)
// - 빠른 프로토타이핑
// - 단순한 CRUD
// - 적은 boilerplate 선호
// - FutureProvider로 충분한 비동기 처리

// ✅ Bloc 추천
// - 대규모 앱 (100+ 화면)
// - 복잡한 비즈니스 로직
// - Event 추적/로깅 필요
// - 명시적 상태 전환
// - 팀 규모 10명 이상
```

**혼합 사용 패턴**:
```dart
// Bloc으로 비즈니스 로직, Riverpod으로 의존성 주입
final authBlocProvider = Provider<AuthBloc>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthBloc(repository);
});

class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authBloc = ref.watch(authBlocProvider);

    return BlocProvider.value(
      value: authBloc,
      child: LoginForm(),
    );
  }
}
```

**마이그레이션 고려사항**:
```dart
// Riverpod → Bloc (규모 증가 시)
// - Provider를 Bloc으로 점진적 교체
// - 복잡한 로직부터 우선 마이그레이션

// Bloc → Riverpod (간소화 필요 시)
// - 단순한 Bloc을 StateProvider로 교체
// - BlocProvider를 Provider로 교체
```

**평가 기준**:
- ✅ 좋은 답변: Compile-time safety, Boilerplate 차이, 사용 시나리오
- ❌ 나쁜 답변: "Riverpod이 더 최신이다" 수준

**꼬리 질문**:
1. Riverpod의 StateNotifierProvider vs Bloc의 Cubit?
2. Provider 패키지 대신 Riverpod을 사용하는 이유는?

**참고 문서**: [../state-management/02_bloc_cubit.md](../state-management/02_bloc_cubit.md), [../state-management/03_riverpod.md](../state-management/03_riverpod.md)

---

## 4. 아키텍처

### Q19. Clean Architecture의 3계층 구조와 각 계층의 책임을 설명하세요.

**핵심 키워드**: Presentation/Domain/Data, 의존성 규칙, Repository 인터페이스, UseCase

**모범 답변**:

**3계층 구조**:
```
lib/
├── presentation/          # UI 레이어
│   ├── pages/
│   ├── widgets/
│   └── bloc/
├── domain/                # 비즈니스 로직 레이어
│   ├── entities/
│   ├── repositories/      # 인터페이스만
│   └── usecases/
└── data/                  # 데이터 레이어
    ├── models/
    ├── repositories/      # 구현체
    └── datasources/
```

**의존성 규칙**:
```
Presentation → Domain ← Data
(UI)           (비즈니스 로직)  (데이터 소스)

- Domain은 다른 계층 의존 X (순수 Dart)
- Presentation과 Data는 Domain에만 의존
```

**Domain 레이어**:
```dart
// entities/user.dart - 비즈니스 엔티티
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;
}

// repositories/user_repository.dart - 인터페이스
abstract class UserRepository {
  Future<User> getUser(String id);
  Future<void> updateUser(User user);
}

// usecases/get_user.dart - 비즈니스 로직
class GetUser {
  const GetUser(this._repository);

  final UserRepository _repository;

  Future<User> call(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    return await _repository.getUser(userId);
  }
}
```

**Data 레이어**:
```dart
// models/user_model.dart - JSON 매핑
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
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

// datasources/user_remote_datasource.dart
abstract class UserRemoteDataSource {
  Future<UserModel> getUser(String id);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<UserModel> getUser(String id) async {
    final response = await _dio.get('/users/$id');
    return UserModel.fromJson(response.data);
  }
}

// repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._remoteDataSource);

  final UserRemoteDataSource _remoteDataSource;

  @override
  Future<User> getUser(String id) async {
    try {
      final userModel = await _remoteDataSource.getUser(id);
      return userModel;  // UserModel은 User를 상속
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }
}
```

**Presentation 레이어**:
```dart
// bloc/user_bloc.dart
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc(this._getUser) : super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
  }

  final GetUser _getUser;  // UseCase 의존

  Future<void> _onLoadUser(
    LoadUser event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    try {
      final user = await _getUser(event.userId);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}

// pages/user_page.dart
class UserPage extends StatelessWidget {
  const UserPage({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UserBloc>()
        ..add(LoadUser(userId)),
      child: Scaffold(
        body: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            return switch (state) {
              UserLoading() => CircularProgressIndicator(),
              UserLoaded(user: final user) => UserProfile(user: user),
              UserError(message: final msg) => ErrorView(message: msg),
              _ => SizedBox.shrink(),
            };
          },
        ),
      ),
    );
  }
}
```

**의존성 주입**:
```dart
// injection.dart
final getIt = GetIt.instance;

void setupDependencies() {
  // Data layer
  getIt.registerLazySingleton<Dio>(() => Dio(
    BaseOptions(baseUrl: 'https://api.example.com'),
  ));

  getIt.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(getIt()),
  );

  // Domain layer
  getIt.registerLazySingleton(() => GetUser(getIt()));
  getIt.registerLazySingleton(() => UpdateUser(getIt()));

  // Presentation layer
  getIt.registerFactory(() => UserBloc(getIt()));
}
```

**실무 패턴: Feature-First 구조**:
```
lib/
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── models/
    │   │   ├── repositories/
    │   │   └── datasources/
    │   ├── domain/
    │   │   ├── entities/
    │   │   ├── repositories/
    │   │   └── usecases/
    │   └── presentation/
    │       ├── pages/
    │       ├── widgets/
    │       └── bloc/
    └── product/
        ├── data/
        ├── domain/
        └── presentation/
```

**장점**:
```dart
// 1. 테스트 용이성
test('GetUser returns user when repository succeeds', () async {
  // Domain은 순수 Dart → 빠른 테스트
  final mockRepository = MockUserRepository();
  final getUser = GetUser(mockRepository);

  when(() => mockRepository.getUser('1'))
      .thenAnswer((_) async => testUser);

  final result = await getUser('1');

  expect(result, testUser);
});

// 2. 데이터 소스 교체 용이
// RemoteDataSource ↔ LocalDataSource
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<User> getUser(String id) async {
    try {
      return await _remoteDataSource.getUser(id);
    } catch (e) {
      return await _localDataSource.getUser(id);  // Fallback
    }
  }
}

// 3. 비즈니스 로직 재사용
final updateUserFromProfile = UpdateUser(userRepository);
final updateUserFromSettings = UpdateUser(userRepository);  // 같은 UseCase
```

**평가 기준**:
- ✅ 좋은 답변: 의존성 규칙, Repository 인터페이스, UseCase 패턴
- ❌ 나쁜 답변: "3개 폴더로 나눈다" 수준

**꼬리 질문**:
1. UseCase가 1줄이어도 만들어야 하나요?
2. Entity와 Model의 차이는?

**참고 문서**: [../architecture/01_clean_architecture.md](../architecture/01_clean_architecture.md)

---

### Q20. Repository 패턴의 역할과 구현 방법을 설명하세요.

**핵심 키워드**: Data source abstraction, 캐싱 전략, 에러 처리, Remote/Local 통합

**모범 답변**:

**Repository 패턴의 역할**:
```dart
// Repository는 데이터 소스를 추상화
// - Remote API
// - Local DB
// - In-memory cache
// → 단일 인터페이스로 제공

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<Product> getProduct(String id);
  Future<void> saveProduct(Product product);
}
```

**기본 구현**:
```dart
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;

  @override
  Future<List<Product>> getProducts() async {
    try {
      // 1. Remote에서 가져오기
      final products = await remoteDataSource.getProducts();

      // 2. Local에 캐싱
      await localDataSource.cacheProducts(products);

      return products;
    } on ServerException {
      // 3. 실패 시 Local에서 가져오기
      return await localDataSource.getProducts();
    }
  }

  @override
  Future<Product> getProduct(String id) async {
    // Local 우선 확인
    final cachedProduct = await localDataSource.getProduct(id);
    if (cachedProduct != null && !_isExpired(cachedProduct)) {
      return cachedProduct;
    }

    // Remote에서 가져오기
    final product = await remoteDataSource.getProduct(id);
    await localDataSource.cacheProduct(product);

    return product;
  }

  bool _isExpired(Product product) {
    final now = DateTime.now();
    return now.difference(product.cachedAt) > Duration(hours: 1);
  }
}
```

**캐싱 전략**:
```dart
// 1. Cache-First (오프라인 우선)
@override
Future<List<Product>> getProducts() async {
  // Local에 있으면 즉시 반환
  final cachedProducts = await localDataSource.getProducts();
  if (cachedProducts.isNotEmpty) {
    // Background에서 업데이트
    _refreshInBackground();
    return cachedProducts;
  }

  // 없으면 Remote에서 가져오기
  final products = await remoteDataSource.getProducts();
  await localDataSource.cacheProducts(products);
  return products;
}

void _refreshInBackground() {
  remoteDataSource.getProducts().then((products) {
    localDataSource.cacheProducts(products);
  });
}

// 2. Network-First (최신 데이터 우선)
@override
Future<List<Product>> getProducts() async {
  try {
    final products = await remoteDataSource.getProducts();
    await localDataSource.cacheProducts(products);
    return products;
  } catch (e) {
    // Fallback to cache
    return await localDataSource.getProducts();
  }
}

// 3. Stale-While-Revalidate
@override
Stream<List<Product>> watchProducts() async* {
  // 1. 캐시된 데이터 즉시 방출
  final cachedProducts = await localDataSource.getProducts();
  if (cachedProducts.isNotEmpty) {
    yield cachedProducts;
  }

  // 2. 네트워크에서 최신 데이터 가져와 방출
  try {
    final products = await remoteDataSource.getProducts();
    await localDataSource.cacheProducts(products);
    yield products;
  } catch (e) {
    // 네트워크 실패 시 캐시만 사용
    if (cachedProducts.isEmpty) rethrow;
  }
}
```

**에러 처리**:
```dart
// Either 패턴
@override
Future<Either<Failure, List<Product>>> getProducts() async {
  try {
    final products = await remoteDataSource.getProducts();
    await localDataSource.cacheProducts(products);
    return Right(products);
  } on ServerException catch (e) {
    // Remote 실패 → Local 시도
    try {
      final cachedProducts = await localDataSource.getProducts();
      if (cachedProducts.isEmpty) {
        return Left(CacheFailure());
      }
      return Right(cachedProducts);
    } catch (_) {
      return Left(CacheFailure());
    }
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(UnknownFailure(e.toString()));
  }
}

// Bloc에서 사용
Future<void> _onLoadProducts(
  LoadProducts event,
  Emitter<ProductState> emit,
) async {
  emit(ProductLoading());

  final result = await repository.getProducts();

  result.fold(
    (failure) => emit(ProductError(failure.message)),
    (products) => emit(ProductLoaded(products)),
  );
}
```

**실시간 동기화**:
```dart
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  }) {
    // Remote 변경 감지 → Local 동기화
    _syncSubscription = remoteDataSource.watchProducts().listen((products) {
      localDataSource.cacheProducts(products);
    });
  }

  StreamSubscription? _syncSubscription;

  @override
  Stream<List<Product>> watchProducts() {
    // Local DB 변경사항 스트리밍
    return localDataSource.watchProducts();
  }

  void dispose() {
    _syncSubscription?.cancel();
  }
}
```

**페이지네이션 지원**:
```dart
abstract class ProductRepository {
  Future<PagedResult<Product>> getProducts({
    required int page,
    required int pageSize,
  });
}

class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<PagedResult<Product>> getProducts({
    required int page,
    required int pageSize,
  }) async {
    try {
      final result = await remoteDataSource.getProducts(
        page: page,
        pageSize: pageSize,
      );

      // 첫 페이지면 캐시 초기화, 아니면 추가
      if (page == 1) {
        await localDataSource.clearProducts();
      }
      await localDataSource.cacheProducts(result.items);

      return result;
    } catch (e) {
      // Offline: Local에서 페이지네이션
      final allCached = await localDataSource.getProducts();
      final start = (page - 1) * pageSize;
      final end = start + pageSize;

      return PagedResult(
        items: allCached.sublist(
          start,
          end > allCached.length ? allCached.length : end,
        ),
        page: page,
        totalPages: (allCached.length / pageSize).ceil(),
      );
    }
  }
}
```

**테스트**:
```dart
void main() {
  late ProductRepositoryImpl repository;
  late MockRemoteDataSource mockRemote;
  late MockLocalDataSource mockLocal;

  setUp(() {
    mockRemote = MockRemoteDataSource();
    mockLocal = MockLocalDataSource();
    repository = ProductRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
    );
  });

  test('returns remote data and caches it', () async {
    when(() => mockRemote.getProducts())
        .thenAnswer((_) async => testProducts);
    when(() => mockLocal.cacheProducts(any()))
        .thenAnswer((_) async {});

    final result = await repository.getProducts();

    expect(result, testProducts);
    verify(() => mockLocal.cacheProducts(testProducts)).called(1);
  });

  test('returns cached data when remote fails', () async {
    when(() => mockRemote.getProducts())
        .thenThrow(ServerException());
    when(() => mockLocal.getProducts())
        .thenAnswer((_) async => cachedProducts);

    final result = await repository.getProducts();

    expect(result, cachedProducts);
  });
}
```

**평가 기준**:
- ✅ 좋은 답변: 캐싱 전략, Remote/Local 통합, 에러 처리
- ❌ 나쁜 답변: "API 호출을 감춘다" 수준

**꼬리 질문**:
1. Repository vs DataSource의 차이는?
2. Repository에서 비즈니스 로직을 넣으면 안 되는 이유는?

**참고 문서**: [../architecture/02_repository_pattern.md](../architecture/02_repository_pattern.md)

---

### Q21. UseCase 패턴이 필요한 이유와 구현 방법을 설명하세요.

**핵심 키워드**: Single Responsibility, Reusability, Testability, Business logic encapsulation

**모범 답변**:

**UseCase의 역할**:
```dart
// UseCase = 하나의 비즈니스 유스케이스
// - 단일 책임 원칙
// - Repository 조합
// - 유효성 검증
// - 비즈니스 규칙 적용

abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

class NoParams {}
```

**기본 구현**:
```dart
// usecases/get_user.dart
class GetUser implements UseCase<User, String> {
  const GetUser(this._repository);

  final UserRepository _repository;

  @override
  Future<User> call(String userId) async {
    // 유효성 검증
    if (userId.isEmpty) {
      throw InvalidParameterException('User ID is required');
    }

    // Repository 호출
    return await _repository.getUser(userId);
  }
}

// 사용
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc(this._getUser) : super(UserInitial());

  final GetUser _getUser;

  Future<void> _onLoadUser(LoadUser event, Emitter emit) async {
    final user = await _getUser(event.userId);  // UseCase 호출
    emit(UserLoaded(user));
  }
}
```

**복잡한 UseCase**:
```dart
// usecases/create_order.dart
class CreateOrder implements UseCase<Order, CreateOrderParams> {
  const CreateOrder({
    required this.orderRepository,
    required this.cartRepository,
    required this.userRepository,
  });

  final OrderRepository orderRepository;
  final CartRepository cartRepository;
  final UserRepository userRepository;

  @override
  Future<Order> call(CreateOrderParams params) async {
    // 1. 사용자 인증 확인
    final user = await userRepository.getCurrentUser();
    if (user == null) {
      throw UnauthenticatedException();
    }

    // 2. 장바구니 가져오기
    final cart = await cartRepository.getCart();
    if (cart.items.isEmpty) {
      throw EmptyCartException();
    }

    // 3. 재고 확인
    for (final item in cart.items) {
      final available = await orderRepository.checkStock(item.productId);
      if (available < item.quantity) {
        throw InsufficientStockException(item.productId);
      }
    }

    // 4. 주문 생성
    final order = Order(
      userId: user.id,
      items: cart.items,
      shippingAddress: params.shippingAddress,
      paymentMethod: params.paymentMethod,
      totalAmount: cart.total,
    );

    final createdOrder = await orderRepository.createOrder(order);

    // 5. 장바구니 비우기
    await cartRepository.clearCart();

    return createdOrder;
  }
}

@freezed
class CreateOrderParams with _$CreateOrderParams {
  const factory CreateOrderParams({
    required String shippingAddress,
    required PaymentMethod paymentMethod,
  }) = _CreateOrderParams;
}
```

**UseCase 조합**:
```dart
// usecases/login_user.dart
class LoginUser implements UseCase<User, LoginParams> {
  const LoginUser({
    required this.authRepository,
    required this.userRepository,
    required this.tokenStorage,
  });

  final AuthRepository authRepository;
  final UserRepository userRepository;
  final TokenStorage tokenStorage;

  @override
  Future<User> call(LoginParams params) async {
    // 1. 이메일 형식 검증
    if (!_isValidEmail(params.email)) {
      throw InvalidEmailException();
    }

    // 2. 비밀번호 길이 검증
    if (params.password.length < 8) {
      throw WeakPasswordException();
    }

    // 3. 인증 요청
    final authResult = await authRepository.login(
      email: params.email,
      password: params.password,
    );

    // 4. 토큰 저장
    await tokenStorage.saveToken(authResult.token);

    // 5. 사용자 정보 가져오기
    final user = await userRepository.getUser(authResult.userId);

    return user;
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

@freezed
class LoginParams with _$LoginParams {
  const factory LoginParams({
    required String email,
    required String password,
  }) = _LoginParams;
}
```

**Either 패턴 UseCase**:
```dart
// Either<Failure, Success> 반환
class GetUserProfile implements UseCase<Either<Failure, UserProfile>, String> {
  const GetUserProfile(this._repository);

  final UserRepository _repository;

  @override
  Future<Either<Failure, UserProfile>> call(String userId) async {
    if (userId.isEmpty) {
      return Left(ValidationFailure('User ID is required'));
    }

    try {
      final user = await _repository.getUser(userId);
      final profile = UserProfile.fromUser(user);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return Left(NetworkFailure());
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
```

**Stream 기반 UseCase**:
```dart
// Stream 반환
class WatchNotifications implements UseCase<Stream<List<Notification>>, String> {
  const WatchNotifications(this._repository);

  final NotificationRepository _repository;

  @override
  Stream<List<Notification>> call(String userId) {
    return _repository.watchNotifications(userId)
        .map((notifications) {
          // 읽지 않은 것만 필터링
          return notifications.where((n) => !n.isRead).toList();
        });
  }
}

// Bloc에서 사용
Future<void> _onWatchNotifications(
  WatchNotifications event,
  Emitter<NotificationState> emit,
) async {
  await emit.forEach(
    _watchNotifications(event.userId),
    onData: (notifications) => NotificationLoaded(notifications),
  );
}
```

**테스트**:
```dart
void main() {
  late GetUser getUser;
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
    getUser = GetUser(mockRepository);
  });

  test('returns user when repository succeeds', () async {
    when(() => mockRepository.getUser('1'))
        .thenAnswer((_) async => testUser);

    final result = await getUser('1');

    expect(result, testUser);
    verify(() => mockRepository.getUser('1')).called(1);
  });

  test('throws exception when userId is empty', () async {
    expect(
      () => getUser(''),
      throwsA(isA<InvalidParameterException>()),
    );

    verifyNever(() => mockRepository.getUser(any()));
  });

  test('throws exception when repository fails', () async {
    when(() => mockRepository.getUser('1'))
        .thenThrow(ServerException());

    expect(
      () => getUser('1'),
      throwsA(isA<ServerException>()),
    );
  });
}
```

**UseCase가 필요한 이유**:
```dart
// ❌ UseCase 없이 Bloc에서 직접 처리
class UserBloc extends Bloc<UserEvent, UserState> {
  Future<void> _onLoadUser(LoadUser event, Emitter emit) async {
    // 유효성 검증, Repository 호출, 에러 처리 모두 Bloc에 있음
    if (event.userId.isEmpty) throw ...;
    final user = await repository.getUser(event.userId);
    // ...
  }
}

// ✅ UseCase 사용
class UserBloc extends Bloc<UserEvent, UserState> {
  Future<void> _onLoadUser(LoadUser event, Emitter emit) async {
    final user = await _getUser(event.userId);  // 비즈니스 로직 캡슐화
    emit(UserLoaded(user));
  }
}

// 장점:
// 1. Bloc은 UI 로직에만 집중
// 2. UseCase 재사용 (다른 Bloc, CLI 도구 등)
// 3. 비즈니스 로직 테스트 용이
```

**평가 기준**:
- ✅ 좋은 답변: SRP, Repository 조합, 유효성 검증, 테스트 용이성
- ❌ 나쁜 답변: "Repository를 감싸는 레이어" 수준

**꼬리 질문**:
1. UseCase가 1줄이어도 만들어야 하나요?
2. UseCase 간 의존 관계는 어떻게 처리하나요?

**참고 문서**: [../architecture/03_usecase_pattern.md](../architecture/03_usecase_pattern.md)

---

### Q22. GetIt/Injectable을 사용한 의존성 주입 패턴을 설명하세요.

**핵심 키워드**: Service Locator, Lazy singleton, Factory, Injectable annotation, Code generation

**모범 답변**:

**GetIt 기본**:
```dart
// core/injection.dart
final getIt = GetIt.instance;

void setupDependencies() {
  // Singleton: 앱 전체에서 하나의 인스턴스
  getIt.registerLazySingleton<Dio>(() => Dio(
    BaseOptions(baseUrl: 'https://api.example.com'),
  ));

  // Lazy Singleton: 첫 접근 시 생성
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
    ),
  );

  // Factory: 매번 새 인스턴스 생성
  getIt.registerFactory<UserBloc>(
    () => UserBloc(getIt()),
  );
}

// main.dart
void main() {
  setupDependencies();
  runApp(MyApp());
}

// 사용
final userBloc = getIt<UserBloc>();
```

**Injectable 자동 생성**:
```dart
// core/injection.dart
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => getIt.init();

// data/repositories/user_repository_impl.dart
@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;

  // ...
}

// domain/usecases/get_user.dart
@lazySingleton
class GetUser {
  GetUser(this._repository);

  final UserRepository _repository;

  Future<User> call(String userId) async {
    return await _repository.getUser(userId);
  }
}

// presentation/bloc/user_bloc.dart
@injectable
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc(this._getUser) : super(UserInitial());

  final GetUser _getUser;
}
```

**Injectable 어노테이션**:
```dart
// @injectable: Factory (매번 새 인스턴스)
@injectable
class LoginBloc { }

// @singleton: 앱 전체 단일 인스턴스
@singleton
class AppDatabase { }

// @lazySingleton: 첫 접근 시 생성 후 재사용
@lazySingleton
class ApiClient { }

// @LazySingleton(as: Interface): 인터페이스로 등록
@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository { }
```

**환경별 설정**:
```dart
// dev, prod 환경 분리
abstract class Environment {
  static const dev = 'dev';
  static const prod = 'prod';
}

@module
abstract class AppModule {
  @dev
  @lazySingleton
  Dio devDio() => Dio(BaseOptions(baseUrl: 'https://dev.api.example.com'));

  @prod
  @lazySingleton
  Dio prodDio() => Dio(BaseOptions(baseUrl: 'https://api.example.com'));
}

// main.dart
void main() {
  configureDependencies(environment: Environment.prod);
  runApp(MyApp());
}
```

**Named 의존성**:
```dart
@module
abstract class StorageModule {
  @Named('secure')
  @lazySingleton
  Storage secureStorage() => SecureStorage();

  @Named('local')
  @lazySingleton
  Storage localStorage() => LocalStorage();
}

@lazySingleton
class TokenRepository {
  TokenRepository(@Named('secure') this._storage);

  final Storage _storage;
}
```

**실무 패턴: Feature별 의존성**:
```dart
// features/auth/injection.dart
@module
abstract class AuthModule {
  @lazySingleton
  AuthRemoteDataSource authRemoteDataSource(Dio dio) =>
      AuthRemoteDataSourceImpl(dio);

  @LazySingleton(as: AuthRepository)
  AuthRepository authRepository(
    AuthRemoteDataSource remoteDataSource,
    @Named('secure') Storage storage,
  ) => AuthRepositoryImpl(remoteDataSource, storage);
}

@lazySingleton
class LoginUser {
  LoginUser(this._repository);
  final AuthRepository _repository;
}

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._loginUser, this._logoutUser) : super(AuthInitial());

  final LoginUser _loginUser;
  final LogoutUser _logoutUser;
}
```

**테스트용 Mock 주입**:
```dart
// test/helpers/injection_test.dart
void setupTestDependencies() {
  getIt.reset();

  // Mock 등록
  getIt.registerLazySingleton<UserRepository>(
    () => MockUserRepository(),
  );

  getIt.registerFactory<UserBloc>(
    () => UserBloc(getIt()),
  );
}

// test/user_bloc_test.dart
void main() {
  setUp(() {
    setupTestDependencies();
  });

  tearDown(() {
    getIt.reset();
  });

  blocTest<UserBloc, UserState>(
    'emits [UserLoading, UserLoaded] when LoadUser is added',
    build: () {
      final mockRepo = getIt<UserRepository>() as MockUserRepository;
      when(() => mockRepo.getUser(any()))
          .thenAnswer((_) async => testUser);

      return getIt<UserBloc>();
    },
    act: (bloc) => bloc.add(LoadUser('1')),
    expect: () => [UserLoading(), UserLoaded(testUser)],
  );
}
```

**Dispose 처리**:
```dart
@singleton
class DatabaseService {
  late Database _db;

  Future<void> init() async {
    _db = await openDatabase('app.db');
  }

  @disposeMethod
  void dispose() {
    _db.close();
  }
}

// 앱 종료 시
await getIt.reset(dispose: true);  // disposeMethod 자동 호출
```

**GetIt vs Provider vs Riverpod**:
```
| 항목              | GetIt           | Provider         | Riverpod       |
|-------------------|-----------------|------------------|----------------|
| 타입              | Service Locator | InheritedWidget  | Provider       |
| BuildContext      | 불필요          | 필수             | 불필요         |
| Code generation   | Injectable      | 없음             | 있음           |
| Scope             | Global          | Widget tree      | Global         |
| 테스트            | getIt.reset()   | ProviderScope    | ProviderScope  |
| 적합한 용도       | Repository/UseCase | UI 상태       | 모든 상태      |
```

**평가 기준**:
- ✅ 좋은 답변: Lazy singleton, Factory 차이, Injectable, 환경별 설정
- ❌ 나쁜 답변: "의존성을 주입한다" 수준

**꼬리 질문**:
1. GetIt의 Service Locator 패턴이 안티패턴인 이유는?
2. @preResolve는 언제 사용하나요?

**참고 문서**: [../architecture/04_dependency_injection.md](../architecture/04_dependency_injection.md)

---

### Q23. Feature-based 프로젝트 구조의 장점과 구현 방법을 설명하세요.

**핵심 키워드**: Feature module, Scalability, Team collaboration, Bounded context

**모범 답변**:

**Feature-based 구조**:
```
lib/
├── core/                    # 공용 유틸리티
│   ├── network/
│   ├── storage/
│   ├── error/
│   └── injection/
├── features/
│   ├── auth/                # 인증 기능
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── datasources/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── widgets/
│   │       └── bloc/
│   ├── product/             # 상품 기능
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── cart/                # 장바구니 기능
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```

**Feature 모듈 예제**:
```dart
// features/auth/domain/entities/user.dart
class User {
  const User({required this.id, required this.name});
  final String id;
  final String name;
}

// features/auth/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<void> logout();
}

// features/auth/domain/usecases/login_user.dart
@lazySingleton
class LoginUser {
  LoginUser(this._repository);
  final AuthRepository _repository;

  Future<User> call(String email, String password) async {
    return await _repository.login(email, password);
  }
}

// features/auth/data/repositories/auth_repository_impl.dart
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);
  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<User> login(String email, String password) async {
    // ...
  }
}

// features/auth/presentation/bloc/auth_bloc.dart
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._loginUser) : super(AuthInitial());
  final LoginUser _loginUser;
}

// features/auth/presentation/pages/login_page.dart
class LoginPage extends StatelessWidget {
  static const route = '/login';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: LoginView(),
    );
  }
}
```

**Feature 간 의존성 관리**:
```dart
// ✅ 올바른 의존성: Domain 레이어를 통한 통신
// features/cart/domain/usecases/add_to_cart.dart
@lazySingleton
class AddToCart {
  AddToCart(this._cartRepository, this._authRepository);

  final CartRepository _cartRepository;
  final AuthRepository _authRepository;  // auth feature의 domain

  Future<void> call(Product product) async {
    final user = await _authRepository.getCurrentUser();
    if (user == null) throw UnauthenticatedException();

    await _cartRepository.addItem(CartItem.fromProduct(product));
  }
}

// ❌ 잘못된 의존성: Presentation 레이어 직접 참조
// features/cart/presentation/bloc/cart_bloc.dart
class CartBloc {
  CartBloc(this._authBloc);  // ❌ 다른 feature의 Bloc 직접 의존
  final AuthBloc _authBloc;
}
```

**공용 코드 관리**:
```dart
// core/network/dio_client.dart
@lazySingleton
class DioClient {
  DioClient() {
    _dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    _dio.interceptors.add(AuthInterceptor());
  }

  late final Dio _dio;
  Dio get dio => _dio;
}

// core/error/failures.dart
abstract class Failure {
  const Failure(this.message);
  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

// core/injection/injection.dart
@InjectableInit()
void configureDependencies() => getIt.init();
```

**라우팅**:
```dart
// core/routing/app_router.dart
@AutoRouterConfig()
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: AuthRoute.page, path: '/auth', children: [
      AutoRoute(page: LoginRoute.page, path: 'login'),
      AutoRoute(page: SignupRoute.page, path: 'signup'),
    ]),
    AutoRoute(page: ProductRoute.page, path: '/products'),
    AutoRoute(page: CartRoute.page, path: '/cart'),
  ];
}

// features/auth/presentation/pages/login_page.dart
@RoutePage()
class LoginPage extends StatelessWidget {
  // ...
}
```

**장점**:
```dart
// 1. 확장성
// 새 기능 추가 시 다른 feature에 영향 없음
lib/features/payment/  // 새 feature 추가

// 2. 팀 협업
// - Team A: auth feature 담당
// - Team B: product feature 담당
// - 독립적으로 작업 가능

// 3. 테스트 격리
// features/auth/test/
// features/product/test/
// feature별로 독립적 테스트

// 4. 코드 재사용
// features/auth/domain/usecases/login_user.dart
// → CLI 도구, Admin 앱에서도 재사용 가능

// 5. 명확한 경계
// feature 내부 구현은 외부에 노출하지 않음
// 오직 domain 레이어만 공개
```

**실무 팁**:
```dart
// 1. Feature 내부 임포트는 상대 경로
import '../../../domain/entities/user.dart';  // ✅

// 2. Feature 외부 임포트는 절대 경로
import 'package:my_app/features/auth/domain/repositories/auth_repository.dart';  // ✅

// 3. Barrel exports로 public API 정의
// features/auth/auth.dart
export 'domain/entities/user.dart';
export 'domain/repositories/auth_repository.dart';
export 'domain/usecases/login_user.dart';

// 사용
import 'package:my_app/features/auth/auth.dart';

// 4. Feature 플래그
@dev
@lazySingleton
class PaymentFeature {
  bool get isEnabled => true;  // dev에서만 활성화
}
```

**평가 기준**:
- ✅ 좋은 답변: Feature 독립성, Domain 레이어 의존, 확장성, 팀 협업
- ❌ 나쁜 답변: "폴더를 기능별로 나눈다" 수준

**꼬리 질문**:
1. Feature 간 순환 의존을 방지하려면?
2. Feature-based vs Layer-based 구조의 tradeoff는?

**참고 문서**: [../architecture/05_project_structure.md](../architecture/05_project_structure.md)

---

## 5. 네트워킹

### Q24. Dio Interceptor의 활용 사례와 구현 방법을 설명하세요.

**핵심 키워드**: onRequest/onResponse/onError, 토큰 주입, 로깅, 재시도, QueuedInterceptor

**모범 답변**:

**Interceptor 기본**:
```dart
class AppInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('Request: ${options.method} ${options.path}');
    handler.next(options);  // 다음 Interceptor로 전달
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('Response: ${response.statusCode}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('Error: ${err.message}');
    handler.next(err);
  }
}

// 등록
final dio = Dio();
dio.interceptors.add(AppInterceptor());
```

**1. 인증 토큰 주입**:
```dart
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }
}
```

**2. 토큰 갱신 (QueuedInterceptor)**:
```dart
class TokenRefreshInterceptor extends QueuedInterceptor {
  TokenRefreshInterceptor(this._tokenStorage, this._authApi);

  final TokenStorage _tokenStorage;
  final AuthApi _authApi;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        // 1. Refresh token으로 새 토큰 받기
        final refreshToken = await _tokenStorage.getRefreshToken();
        final newTokens = await _authApi.refreshToken(refreshToken);

        // 2. 새 토큰 저장
        await _tokenStorage.saveToken(newTokens.accessToken);

        // 3. 실패한 요청 재시도
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer ${newTokens.accessToken}';

        final response = await Dio().fetch(options);
        return handler.resolve(response);
      } catch (e) {
        // Refresh 실패 → 로그아웃
        await _tokenStorage.clearTokens();
        return handler.reject(err);
      }
    }

    handler.next(err);
  }
}
```

**3. 로깅 Interceptor**:
```dart
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.info('''
    ┌────────────────────────────────────────────────────────
    │ Request
    ├────────────────────────────────────────────────────────
    │ ${options.method} ${options.uri}
    │ Headers: ${options.headers}
    │ Body: ${options.data}
    └────────────────────────────────────────────────────────
    ''');

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.info('''
    ┌────────────────────────────────────────────────────────
    │ Response
    ├────────────────────────────────────────────────────────
    │ ${response.statusCode} ${response.requestOptions.uri}
    │ Body: ${response.data}
    └────────────────────────────────────────────────────────
    ''');

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.error('''
    ┌────────────────────────────────────────────────────────
    │ Error
    ├────────────────────────────────────────────────────────
    │ ${err.requestOptions.method} ${err.requestOptions.uri}
    │ ${err.message}
    │ ${err.response?.data}
    └────────────────────────────────────────────────────────
    ''');

    handler.next(err);
  }
}
```

**4. 재시도 Interceptor**:
```dart
class RetryInterceptor extends Interceptor {
  RetryInterceptor({this.maxRetries = 3, this.retryDelay = const Duration(seconds: 1)});

  final int maxRetries;
  final Duration retryDelay;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retryCount'] ?? 0;

    // 재시도 조건
    if (retryCount < maxRetries && _shouldRetry(err)) {
      await Future.delayed(retryDelay * (retryCount + 1));  // 지수 백오프

      final options = err.requestOptions;
      options.extra['retryCount'] = retryCount + 1;

      try {
        final response = await Dio().fetch(options);
        return handler.resolve(response);
      } catch (e) {
        // 재시도 실패 → 다음 Interceptor로
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // 네트워크 오류 또는 5xx 에러만 재시도
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           (err.response?.statusCode ?? 0) >= 500;
  }
}
```

**5. 캐싱 Interceptor**:
```dart
class CacheInterceptor extends Interceptor {
  CacheInterceptor(this._cacheManager);

  final CacheManager _cacheManager;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // GET 요청만 캐싱
    if (options.method == 'GET') {
      final cacheKey = _getCacheKey(options);
      final cachedResponse = await _cacheManager.get(cacheKey);

      if (cachedResponse != null) {
        return handler.resolve(cachedResponse);
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.requestOptions.method == 'GET') {
      final cacheKey = _getCacheKey(response.requestOptions);
      await _cacheManager.put(cacheKey, response);
    }

    handler.next(response);
  }

  String _getCacheKey(RequestOptions options) {
    return '${options.uri}_${options.queryParameters}';
  }
}
```

**6. 에러 변환 Interceptor**:
```dart
class ErrorTransformInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ServerException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        exception = TimeoutException();
      case DioExceptionType.connectionError:
        exception = NetworkException();
      default:
        final statusCode = err.response?.statusCode;
        exception = switch (statusCode) {
          400 => BadRequestException(err.response?.data['message']),
          401 => UnauthorizedException(),
          403 => ForbiddenException(),
          404 => NotFoundException(),
          500 => ServerException('Internal server error'),
          _ => UnknownException(err.message),
        };
    }

    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: exception,
    ));
  }
}
```

**Interceptor 순서**:
```dart
final dio = Dio();

dio.interceptors.addAll([
  LoggingInterceptor(),       // 1. 로깅 (먼저)
  AuthInterceptor(),          // 2. 토큰 주입
  CacheInterceptor(),         // 3. 캐시 확인
  RetryInterceptor(),         // 4. 재시도
  TokenRefreshInterceptor(),  // 5. 토큰 갱신
  ErrorTransformInterceptor(), // 6. 에러 변환 (마지막)
]);

// 실행 순서:
// Request: 1 → 2 → 3 → 4 → 5 → 6 → 서버
// Response: 서버 → 6 → 5 → 4 → 3 → 2 → 1
```

**평가 기준**:
- ✅ 좋은 답변: 토큰 갱신, QueuedInterceptor, 재시도, 캐싱
- ❌ 나쁜 답변: "헤더 추가하는 것" 수준

**꼬리 질문**:
1. Interceptor vs Transformer의 차이는?
2. QueuedInterceptor를 사용하는 이유는?

**참고 문서**: [../networking/01_dio_basics.md](../networking/01_dio_basics.md)

---

### Q25. JWT Refresh Token 갱신 메커니즘을 어떻게 구현하나요?
**핵심 키워드**: `QueuedInterceptor`, Token Refresh, 401 Handling

**모범 답변**:
`QueuedInterceptor`를 사용해 토큰 갱신 시 동시 요청을 대기열로 관리합니다.

```dart
class AuthInterceptor extends QueuedInterceptor {
  final TokenRepository _tokenRepo;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final newToken = await _tokenRepo.refresh();
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final retry = await _dio.fetch(err.requestOptions);
        return handler.resolve(retry);
      } catch (e) {
        return handler.reject(err);
      }
    }
    handler.next(err);
  }
}
```

**평가 기준**:
- ✅ 좋은 답변: QueuedInterceptor로 동시 요청 직렬화, 재시도 로직 구현
- ❌ 나쁜 답변: 일반 Interceptor로 race condition 발생

**꼬리 질문**: Refresh Token도 만료되면 어떻게 처리하나요?

**참고 문서**: [Networking 가이드](../networking/01_dio_setup.md)

---

### Q26. Either<Failure, T> 패턴을 왜 사용하나요?
**핵심 키워드**: `fpdart`, Railway-Oriented Programming, Type Safety

**모범 답변**:
예외를 타입으로 명시해 안전한 에러 처리를 강제합니다.

```dart
abstract class Failure {
  final String message;
  Failure(this.message);
}

class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}

class UserRepository {
  Future<Either<Failure, User>> getUser(String id) async {
    try {
      final user = await _api.fetchUser(id);
      return Right(user);
    } on DioException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Unknown error'));
    }
  }
}

// Usage
final result = await userRepo.getUser('123');
result.fold(
  (failure) => emit(ErrorState(failure.message)),
  (user) => emit(LoadedState(user)),
);
```

**평가 기준**:
- ✅ 좋은 답변: fold/match로 모든 케이스 처리, 타입 안전성 강조
- ❌ 나쁜 답변: try-catch로 예외 숨김, null 반환

**꼬리 질문**: Result 타입과 Either의 차이점은?

**참고 문서**: [에러 처리 가이드](../networking/02_error_handling.md)

---

### Q27. REST API와 GraphQL 중 어떤 것을 선택하나요?
**핵심 키워드**: Over-fetching, Schema, Query Flexibility

**모범 답변**:
데이터 요구사항과 네트워크 효율성을 기준으로 선택합니다.

**REST 선택 시**:
- 단순 CRUD, 캐싱 전략 명확, RESTful 표준 준수 팀
- 예: 관리자 대시보드, 정적 데이터 중심

**GraphQL 선택 시**:
- 복잡한 관계형 데이터, over-fetching 회피, 클라이언트 주도 쿼리
- 예: SNS 피드, 실시간 협업 도구

```dart
// GraphQL with graphql_flutter
final query = gql('''
  query GetUser(\$id: ID!) {
    user(id: \$id) {
      name
      posts(limit: 5) { title createdAt }
    }
  }
''');
final result = await client.query(QueryOptions(document: query));
```

**평가 기준**:
- ✅ 좋은 답변: 트레이드오프 비교, 구체적 사용 사례 제시
- ❌ 나쁜 답변: "GraphQL이 최신 기술이라서"

**꼬리 질문**: GraphQL N+1 문제를 어떻게 해결하나요?

**참고 문서**: [API 설계 가이드](../networking/03_api_design.md)

---

### Q28. 로컬 캐싱 전략을 설계한다면?
**핵심 키워드**: Memory Cache, Disk Cache, TTL, Cache Invalidation

**모범 답변**:
3-tier 캐싱으로 성능과 신선도를 균형있게 관리합니다.

```dart
class CacheManager {
  final Map<String, CacheEntry> _memoryCache = {};
  final HiveBox _diskCache;

  Future<T?> get<T>(String key, {Duration ttl = const Duration(minutes: 5)}) async {
    // 1. Memory cache
    final memEntry = _memoryCache[key];
    if (memEntry != null && !memEntry.isExpired(ttl)) {
      return memEntry.data as T;
    }

    // 2. Disk cache
    final diskEntry = await _diskCache.get(key);
    if (diskEntry != null && !diskEntry.isExpired(ttl)) {
      _memoryCache[key] = diskEntry; // Promote
      return diskEntry.data as T;
    }

    return null;
  }

  void invalidatePrefix(String prefix) {
    _memoryCache.removeWhere((k, _) => k.startsWith(prefix));
  }
}
```

**평가 기준**:
- ✅ 좋은 답변: TTL 관리, LRU 정책, 무효화 전략 명시
- ❌ 나쁜 답변: SharedPreferences만 사용, TTL 없음

**꼬리 질문**: 오프라인 시나리오에서 캐시 동기화는?

**참고 문서**: [캐싱 전략](../networking/04_caching.md)

---

## 섹션 5: 테스트 전략 (Q29-Q32)

### Q29. 테스트 피라미드를 Flutter에 적용하면?
**핵심 키워드**: Unit Test, Widget Test, Integration Test

**모범 답변**:
비율은 70% Unit / 20% Widget / 10% Integration으로 구성합니다.

```dart
// Unit Test (가장 빠름, 가장 많이)
test('AuthBloc emits authenticated on login success', () {
  whenListen(authBloc, Stream.fromIterable([AuthLoading(), Authenticated()]));
  expect(authBloc.stream, emitsInOrder([AuthLoading(), Authenticated()]));
});

// Widget Test (UI 로직)
testWidgets('LoginPage shows error on invalid input', (tester) async {
  await tester.pumpWidget(MaterialApp(home: LoginPage()));
  await tester.enterText(find.byType(TextField), 'short');
  await tester.tap(find.text('Login'));
  await tester.pump();
  expect(find.text('Password too short'), findsOneWidget);
});

// Integration Test (E2E 플로우)
testWidgets('Full login flow', (tester) async {
  app.main();
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(Key('email')), 'test@example.com');
  // ...
});
```

**평가 기준**:
- ✅ 좋은 답변: 각 레이어 목적과 비율 제시, 속도 고려
- ❌ 나쁜 답변: Integration Test만 작성

**꼬리 질문**: CI/CD에서 테스트 실행 순서는?

**참고 문서**: [테스트 전략](../testing/01_test_strategy.md)

---

### Q30. blocTest를 사용한 테스트 패턴은?
**핵심 키워드**: `blocTest`, `whenListen`, State Verification

**모범 답변**:
`blocTest`로 이벤트-상태 전환을 명확히 검증합니다.

```dart
blocTest<CounterCubit, int>(
  'emits [1, 2] when increment is called twice',
  build: () => CounterCubit(),
  act: (cubit) {
    cubit.increment();
    cubit.increment();
  },
  expect: () => [1, 2],
);

// 비동기 로직
blocTest<UserBloc, UserState>(
  'emits [loading, loaded] on fetch success',
  build: () {
    when(() => mockRepo.getUser()).thenAnswer((_) async => mockUser);
    return UserBloc(mockRepo);
  },
  act: (bloc) => bloc.add(FetchUser()),
  expect: () => [UserLoading(), UserLoaded(mockUser)],
  verify: (_) {
    verify(() => mockRepo.getUser()).called(1);
  },
);
```

**평가 기준**:
- ✅ 좋은 답변: expect로 상태 순서 검증, verify로 의존성 호출 확인
- ❌ 나쁜 답변: emit을 직접 호출해 테스트

**꼬리 질문**: skip과 wait의 차이점은?

**참고 문서**: [Bloc 테스트](../testing/02_bloc_test.md)

---

### Q31. Widget Test에서 MockBloc을 어떻게 활용하나요?
**핵심 키워드**: `MockBloc`, `whenListen`, UI Isolation

**모범 답변**:
`MockBloc`으로 UI를 비즈니스 로직과 분리해 테스트합니다.

```dart
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  testWidgets('shows spinner when loading', (tester) async {
    whenListen(mockAuthBloc, Stream.value(AuthLoading()));

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: MaterialApp(home: LoginPage()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('navigates on authenticated', (tester) async {
    whenListen(mockAuthBloc, Stream.value(Authenticated(mockUser)));
    // ...
    expect(find.byType(HomePage), findsOneWidget);
  });
}
```

**평가 기준**:
- ✅ 좋은 답변: whenListen으로 상태 주입, UI만 검증
- ❌ 나쁜 답변: 실제 Bloc 인스턴스 사용

**꼬리 질문**: BlocProvider.value와 BlocProvider의 차이는?

**참고 문서**: [Widget 테스트](../testing/03_widget_test.md)

---

### Q32. Golden Test의 개념과 활용법은?
**핵심 키워드**: `matchesGoldenFile`, Visual Regression, Pixel-Perfect

**모범 답변**:
스크린샷 비교로 UI 변경을 자동 감지합니다.

```dart
testWidgets('ProductCard golden test', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProductCard(
          product: Product(name: 'Test', price: 1000),
        ),
      ),
    ),
  );

  await expectLater(
    find.byType(ProductCard),
    matchesGoldenFile('goldens/product_card.png'),
  );
});

// 다크모드 테스트
testWidgets('ProductCard dark mode', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: ProductCard(...),
    ),
  );

  await expectLater(
    find.byType(ProductCard),
    matchesGoldenFile('goldens/product_card_dark.png'),
  );
});
```

**사용 시나리오**:
- 디자인 시스템 컴포넌트 검증
- 다국어 레이아웃 확인
- 다크모드/라이트모드 일관성

**평가 기준**:
- ✅ 좋은 답변: CI 통합 방법, 플랫폼별 차이 인지
- ❌ 나쁜 답변: 로컬에서만 실행, 버전 관리 안 함

**꼬리 질문**: CI에서 Golden 테스트 실패 시 어떻게 처리하나요?

**참고 문서**: [Golden 테스트](../testing/04_golden_test.md)

---

## 섹션 6: 모바일 실무 (Q33-Q37)

### Q33. AppLifecycleState를 어떻게 활용하나요?
**핵심 키워드**: `WidgetsBindingObserver`, Background/Foreground, State Preservation

**모범 답변**:
앱 생명주기를 감지해 리소스와 상태를 관리합니다.

```dart
class MyApp extends StatefulWidget with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _pauseVideoPlayer();
        _saveCurrentState();
        break;
      case AppLifecycleState.resumed:
        _refreshTokenIfNeeded();
        _resumeVideoPlayer();
        break;
      case AppLifecycleState.detached:
        _cleanup();
        break;
    }
  }
}
```

**활용 사례**:
- 백그라운드 시 WebSocket 연결 해제
- 포그라운드 복귀 시 토큰 갱신
- 비디오 재생 일시정지

**평가 기준**:
- ✅ 좋은 답변: 리소스 절약과 UX 개선 사례 제시
- ❌ 나쁜 답변: 생명주기 무시, 메모리 누수

**꼬리 질문**: inactive와 paused의 차이는?

**참고 문서**: [라이프사이클 관리](../advanced/01_lifecycle.md)

---

### Q34. Permission 요청 플로우를 어떻게 설계하나요?
**핵심 키워드**: `permission_handler`, Rationale, Graceful Degradation

**모범 답변**:
권한 상태별 분기로 UX를 보장합니다.

```dart
class PermissionManager {
  Future<bool> requestCamera() async {
    final status = await Permission.camera.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      // 첫 요청 시 설명 표시
      final shouldRequest = await _showRationaleDialog();
      if (!shouldRequest) return false;

      final result = await Permission.camera.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // 설정으로 이동
      await _showSettingsDialog();
      return false;
    }

    return false;
  }

  Future<void> _showRationaleDialog() async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('카메라 권한 필요'),
        content: Text('QR 코드 스캔을 위해 카메라 권한이 필요합니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('허용')),
        ],
      ),
    );
  }
}
```

**평가 기준**:
- ✅ 좋은 답변: Rationale 제공, permanentlyDenied 처리
- ❌ 나쁜 답변: 무조건 request만 호출

**꼬리 질문**: iOS와 Android의 권한 정책 차이는?

**참고 문서**: [권한 관리](../advanced/02_permissions.md)

---

### Q35. Push Notification 처리 아키텍처는?
**핵심 키워드**: `firebase_messaging`, Background Handler, Deep Link

**모범 답변**:
포그라운드/백그라운드/종료 상태별 처리를 구분합니다.

```dart
class NotificationService {
  Future<void> initialize() async {
    // 백그라운드 핸들러 (최상위 함수)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 포그라운드 핸들러
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // 알림 탭 핸들러
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 종료 상태에서 앱 실행 시
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage);
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    final id = message.data['id'];

    switch (type) {
      case 'order':
        router.go('/orders/$id');
        break;
      case 'chat':
        router.go('/chat/$id');
        break;
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // 백그라운드 로직 (DB 저장 등)
}
```

**평가 기준**:
- ✅ 좋은 답변: 3가지 상태 모두 처리, Deep Link 연동
- ❌ 나쁜 답변: onMessage만 처리

**꼬리 질문**: Data message와 Notification message의 차이는?

**참고 문서**: [푸시 알림](../advanced/03_push_notification.md)

---

### Q36. GoRouter에서 인증 가드를 구현하려면?
**핵심 키워드**: `redirect`, `refreshListenable`, Auth State

**모범 답변**:
`redirect`와 `refreshListenable`로 인증 상태 기반 라우팅을 제어합니다.

```dart
final router = GoRouter(
  refreshListenable: authBloc, // Bloc이 Listenable 구현
  redirect: (context, state) {
    final isAuthenticated = authBloc.state is Authenticated;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isAuthenticated && !isLoginRoute) {
      return '/login';
    }

    if (isAuthenticated && isLoginRoute) {
      return '/home';
    }

    return null; // 변경 없음
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => LoginPage()),
    GoRoute(
      path: '/home',
      builder: (_, __) => HomePage(),
      routes: [
        GoRoute(path: 'profile', builder: (_, __) => ProfilePage()),
      ],
    ),
  ],
);

// Bloc을 Listenable로 변환
class AuthBlocListenable extends ChangeNotifier {
  final AuthBloc _bloc;
  StreamSubscription? _subscription;

  AuthBlocListenable(this._bloc) {
    _subscription = _bloc.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

**평가 기준**:
- ✅ 좋은 답변: refreshListenable로 자동 갱신, 순환 리다이렉트 방지
- ❌ 나쁜 답변: 매 화면마다 수동 체크

**꼬리 질문**: 인증 토큰 만료 시 현재 페이지를 어떻게 보존하나요?

**참고 문서**: [라우팅 가이드](../navigation/02_gorouter.md)

---

### Q37. 다국어(i18n) 아키텍처를 어떻게 설계하나요?
**핵심 키워드**: `intl`, `easy_localization`, ARB, Context Extension

**모범 답변**:
ARB 파일 기반으로 타입 안전한 다국어를 구현합니다.

```dart
// pubspec.yaml
flutter:
  generate: true

// l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart

// lib/l10n/app_en.arb
{
  "welcomeMessage": "Welcome, {name}!",
  "@welcomeMessage": {
    "description": "환영 메시지",
    "placeholders": {
      "name": {"type": "String"}
    }
  },
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "placeholders": {
      "count": {"type": "int"}
    }
  }
}

// Usage
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomePage(),
    );
  }
}

// Extension for convenience
extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

// Widget
Text(context.l10n.welcomeMessage('John'));
Text(context.l10n.itemCount(5)); // "5 items"
```

**고려사항**:
- RTL 언어 지원 (Directionality)
- 폰트 교체 (Noto Sans CJK 등)
- 날짜/숫자 포맷 (`intl` 패키지)

**평가 기준**:
- ✅ 좋은 답변: ARB 사용, Plural 처리, 타입 안전성
- ❌ 나쁜 답변: Map<String, String>으로 하드코딩

**꼬리 질문**: 런타임 언어 변경은 어떻게 처리하나요?

**참고 문서**: [다국어 가이드](../advanced/04_localization.md)

---

## 메타데이터

**작성일**: 2026-02-08
**Flutter 버전**: 3.38
**Dart 버전**: 3.10
**총 문항**: 37개
**예상 소요 시간**: 면접 60-90분

---

## 관련 문서

- [Flutter 면접 Q&A — L3 Junior](./QnA_L3_Junior.md)
- [Flutter 면접 Q&A — L5 Senior](./QnA_L5_Senior.md)
- [Flutter 면접 Q&A — L6 Staff](./QnA_L6_Staff.md)
- [Flutter 아키텍처 가이드](../architecture/01_clean_architecture.md)
- [Bloc 상태 관리](../state-management/02_bloc_cubit.md)
- [CheatSheet 모음](../cheatsheets/)