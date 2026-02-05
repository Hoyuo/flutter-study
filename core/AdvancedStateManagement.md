# Flutter 고급 상태 관리 가이드 (시니어)

> 대규모 엔터프라이즈 애플리케이션을 위한 고급 상태 관리 패턴 및 아키텍처

## 목차

1. [상태 관리 개요](#1-상태-관리-개요)
2. [Bloc vs Riverpod 심층 비교](#2-bloc-vs-riverpod-심층-비교)
3. [대규모 앱 상태 설계 전략](#3-대규모-앱-상태-설계-전략)
4. [Event Sourcing 패턴](#4-event-sourcing-패턴)
5. [CQRS 패턴](#5-cqrs-패턴)
6. [Optimistic UI Update](#6-optimistic-ui-update)
7. [State Synchronization](#7-state-synchronization)
8. [Undo/Redo 패턴](#8-undoredo-패턴)
9. [Time-travel Debugging](#9-time-travel-debugging)
10. [상태 직렬화/역직렬화](#10-상태-직렬화역직렬화)

---

## 1. 상태 관리 개요

### 상태의 분류

```dart
// 1. Local State (Widget State)
// - 단일 위젯 내에서만 사용
// - 다른 위젯과 공유 불필요
class CounterWidget extends StatefulWidget {
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0; // Local State

  @override
  Widget build(BuildContext context) {
    return Text('$_counter');
  }
}

// 2. Feature-scoped State
// - 특정 Feature 내에서만 공유
// - Feature 외부로 노출되지 않음
class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  // Feature 내부 상태
}

// 3. Global State
// - 앱 전체에서 공유
// - 여러 Feature에서 접근
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // 전역 상태 (현재 사용자)
}

// 4. Ephemeral State (일회성 상태)
// - UI 애니메이션, 폼 입력 등
// - 영속성 불필요
class AnimationControllerWrapper {
  final AnimationController controller;
  // 일회성 상태
}
```

### 상태 관리 솔루션 선택 기준

| 기준 | Bloc | Riverpod | GetX | Provider |
|------|------|----------|------|----------|
| 학습 곡선 | 높음 | 중간 | 낮음 | 낮음 |
| 타입 안전성 | 높음 | 높음 | 낮음 | 중간 |
| 테스트 용이성 | 매우 높음 | 높음 | 중간 | 높음 |
| DevTools 지원 | 우수 | 우수 | 보통 | 우수 |
| 보일러플레이트 | 많음 | 적음 | 매우 적음 | 중간 |
| 성능 | 우수 | 우수 | 우수 | 좋음 |
| 커뮤니티 | 크다 | 성장 중 | 크다 | 크다 |
| 엔터프라이즈 적합성 | ★★★★★ | ★★★★☆ | ★★☆☆☆ | ★★★☆☆ |

---

## 2. Bloc vs Riverpod 심층 비교

### 2.1 아키텍처 비교

```dart
// ============= Bloc =============
// Event-driven 아키텍처

// Event
@freezed
class UserEvent with _$UserEvent {
  const factory UserEvent.loadProfile() = _LoadProfile;
  const factory UserEvent.updateName(String name) = _UpdateName;
}

// State
@freezed
class UserState with _$UserState {
  const factory UserState.initial() = _Initial;
  const factory UserState.loading() = _Loading;
  const factory UserState.loaded(User user) = _Loaded;
  const factory UserState.error(String message) = _Error;
}

// Bloc
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserProfileUseCase _getUserProfile;
  final UpdateUserNameUseCase _updateUserName;

  UserBloc(this._getUserProfile, this._updateUserName)
      : super(const UserState.initial()) {
    on<UserEvent>(_onEvent);
  }

  Future<void> _onEvent(UserEvent event, Emitter<UserState> emit) async {
    await event.when(
      loadProfile: () => _onLoadProfile(emit),
      updateName: (name) => _onUpdateName(name, emit),
    );
  }

  Future<void> _onLoadProfile(Emitter<UserState> emit) async {
    emit(const UserState.loading());
    final result = await _getUserProfile();
    result.fold(
      (failure) => emit(UserState.error(failure.message)),
      (user) => emit(UserState.loaded(user)),
    );
  }
}

// UI
BlocBuilder<UserBloc, UserState>(
  builder: (context, state) {
    return state.when(
      initial: () => const SizedBox(),
      loading: () => const CircularProgressIndicator(),
      loaded: (user) => Text(user.name),
      error: (message) => Text(message),
    );
  },
)

// ============= Riverpod =============
// Reactive 아키텍처

// Provider
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  FutureOr<User> build() async {
    // 초기 로드
    return _loadProfile();
  }

  Future<User> _loadProfile() async {
    final useCase = ref.read(getUserProfileUseCaseProvider);
    final result = await useCase();
    return result.fold(
      (failure) => throw failure,
      (user) => user,
    );
  }

  Future<void> updateName(String name) async {
    state = const AsyncValue.loading();

    final useCase = ref.read(updateUserNameUseCaseProvider);
    final result = await useCase(name);

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }
}

// UI
Consumer(
  builder: (context, ref, child) {
    final userAsync = ref.watch(userNotifierProvider);

    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  },
)
```

### 2.2 성능 비교

```dart
// ============= Bloc 성능 특성 =============

// 장점:
// 1. Selective rebuild with BlocSelector
BlocSelector<UserBloc, UserState, String>(
  selector: (state) => state.maybeWhen(
    loaded: (user) => user.name,
    orElse: () => '',
  ),
  builder: (context, name) {
    return Text(name); // name 변경 시에만 rebuild
  },
)

// 2. Transformer로 이벤트 제어
on<SearchQueryChanged>(
  _onQueryChanged,
  transformer: restartable(), // 이전 요청 취소
)

on<SearchQueryChanged>(
  _onQueryChanged,
  transformer: debounce(const Duration(milliseconds: 300)),
)

// 3. Stream 기반으로 배압(backpressure) 자동 처리
await emit.forEach<Data>(
  repository.dataStream,
  onData: (data) => state.copyWith(data: data),
);

// 단점:
// 1. Event 생성 오버헤드
// 매번 Event 객체 생성 필요

// ============= Riverpod 성능 특성 =============

// 장점:
// 1. 자동 의존성 추적 및 최소 rebuild
final nameProvider = Provider((ref) {
  final user = ref.watch(userProvider);
  return user.name; // name 변경 시에만 rebuild
});

// 2. Provider 자동 dispose
// 사용되지 않는 Provider 자동 정리

// 3. 계산 결과 캐싱
@riverpod
Future<List<Product>> filteredProducts(
  FilteredProductsRef ref,
  {required String category},
) async {
  // category가 같으면 캐시된 결과 반환
  final products = await ref.watch(productsProvider.future);
  return products.where((p) => p.category == category).toList();
}

// 4. 세밀한 rebuild 제어
ref.listen(userProvider, (prev, next) {
  // 상태 변경 감지, UI rebuild 없음
});

// 단점:
// 1. 복잡한 의존성 그래프에서 디버깅 어려움
```

### 2.3 테스트 용이성

```dart
// ============= Bloc 테스트 =============
// bloc_test 패키지로 강력한 테스트 지원

blocTest<UserBloc, UserState>(
  'loadProfile 성공 시 loaded 상태로 전환',
  build: () {
    when(() => mockGetUserProfile()).thenAnswer(
      (_) async => Right(testUser),
    );
    return UserBloc(mockGetUserProfile, mockUpdateUserName);
  },
  act: (bloc) => bloc.add(const UserEvent.loadProfile()),
  expect: () => [
    const UserState.loading(),
    UserState.loaded(testUser),
  ],
  verify: (_) {
    verify(() => mockGetUserProfile()).called(1);
  },
);

// ============= Riverpod 테스트 =============
// ProviderContainer로 테스트

test('loadProfile 성공 시 User 반환', () async {
  final container = ProviderContainer(
    overrides: [
      getUserProfileUseCaseProvider.overrideWithValue(
        mockGetUserProfile,
      ),
    ],
  );

  when(() => mockGetUserProfile()).thenAnswer(
    (_) async => Right(testUser),
  );

  final user = await container.read(userNotifierProvider.future);

  expect(user, testUser);
  verify(() => mockGetUserProfile()).called(1);
});

// Widget 테스트
testWidgets('UserProfile 위젯 테스트', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userNotifierProvider.overrideWith(() => MockUserNotifier()),
      ],
      child: const MaterialApp(home: UserProfilePage()),
    ),
  );

  expect(find.text(testUser.name), findsOneWidget);
});
```

### 2.4 DevTools 지원

```dart
// ============= Bloc DevTools =============
// - Bloc Observer로 모든 이벤트/상태 변화 추적
// - Transition 히스토리
// - Time-travel debugging 지원

class AppBlocObserver extends BlocObserver {
  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    // DevTools에 전송
    // Event -> State 전환 추적
  }
}

// ============= Riverpod DevTools =============
// - Riverpod Inspector (Flutter 3.7+)
// - Provider 의존성 그래프 시각화
// - Provider 상태 실시간 확인
// - Provider rebuild 추적

final userProvider = Provider((ref) {
  // DevTools에서 의존성 자동 추적
  final auth = ref.watch(authProvider);
  return User(auth.userId);
});
```

### 2.5 권장 사용 시나리오

```dart
// ============= Bloc 권장 =============
// ✅ 복잡한 비즈니스 로직
// ✅ Event-driven 아키텍처
// ✅ 명시적인 상태 전환 추적
// ✅ 엄격한 타입 안전성
// ✅ 대규모 엔터프라이즈 앱

// 예: 금융 앱, ERP 시스템, 의료 시스템

// ============= Riverpod 권장 =============
// ✅ 빠른 프로토타이핑
// ✅ 반응형 UI
// ✅ 간단한 상태 공유
// ✅ 함수형 프로그래밍 선호
// ✅ 적은 보일러플레이트

// 예: 소셜 미디어 앱, 콘텐츠 앱, 대시보드
```

---

## 3. 대규모 앱 상태 설계 전략

### 3.1 상태 스코프 전략

```dart
// ============= Global State =============
// 앱 전역에서 접근 필요한 상태

// ⚠️ Bloc은 GetIt에 등록하지 않음 - BlocProvider에서 직접 생성
// Bloc의 의존성(Repository 등)만 GetIt에 등록하고, Bloc은 BlocProvider가 관리

// 1. Authentication State
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository; // GetIt에서 주입받음

  AuthBloc(this._authRepository) : super(AuthInitial());
  // 모든 Feature에서 접근
}

// 2. Theme State
class ThemeBloc extends Cubit<ThemeMode> {
  ThemeBloc() : super(ThemeMode.system);
  // 앱 전체 테마
}

// 3. Locale State
class LocaleBloc extends Cubit<Locale> {
  LocaleBloc() : super(const Locale('ko', 'KR'));
  // 앱 전체 언어 설정
}

// 4. Connectivity State
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final ConnectivityRepository _repository; // GetIt에서 주입받음

  ConnectivityBloc(this._repository) : super(ConnectivityInitial());
  // 네트워크 연결 상태
}

// App에서 제공
MultiBlocProvider(
  providers: [
    BlocProvider<AuthBloc>(create: (_) => GetIt.I<AuthBloc>()),
    BlocProvider<ThemeBloc>(create: (_) => GetIt.I<ThemeBloc>()),
    BlocProvider<LocaleBloc>(create: (_) => GetIt.I<LocaleBloc>()),
    BlocProvider<ConnectivityBloc>(create: (_) => GetIt.I<ConnectivityBloc>()),
  ],
  child: const MyApp(),
)

// ============= Feature-scoped State =============
// 특정 Feature 내에서만 사용

class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductListBloc(
        GetIt.I<GetProductsUseCase>(),
      )..add(const ProductListEvent.started()),
      child: const _ProductListView(),
    );
  }
}

// ============= Page-scoped State =============
// 단일 페이지 내에서만 사용

class CheckoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CheckoutBloc(
        cartBloc: context.read<CartBloc>(),
        paymentService: GetIt.I<PaymentService>(),
      ),
      child: const _CheckoutView(),
    );
  }
}

// ============= Component-scoped State =============
// 단일 컴포넌트(위젯) 내에서만 사용

class SearchBar extends StatefulWidget {
  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final _controller = TextEditingController();
  // 컴포넌트 내부 상태
}
```

### 3.2 상태 정규화 (Normalization)

```dart
// ❌ 비정규화된 상태 (중복 데이터)
@freezed
class AppState with _$AppState {
  const factory AppState({
    required List<Order> orders,
    required List<Product> products,
    required User user,
  }) = _AppState;
}

class Order {
  final String id;
  final Product product; // 중복!
  final User customer;   // 중복!
}

// ✅ 정규화된 상태 (참조로 관리)
@freezed
class AppState with _$AppState {
  const factory AppState({
    @Default({}) Map<String, Order> ordersById,
    @Default({}) Map<String, Product> productsById,
    @Default({}) Map<String, User> usersById,
  }) = _AppState;
}

class Order {
  final String id;
  final String productId; // 참조
  final String customerId; // 참조
}

// 상태 접근 헬퍼
extension AppStateX on AppState {
  Order? getOrder(String id) => ordersById[id];

  Product? getProduct(String id) => productsById[id];

  User? getUser(String id) => usersById[id];

  // 주문과 관련 데이터를 함께 가져오기
  OrderDetail? getOrderDetail(String orderId) {
    final order = getOrder(orderId);
    if (order == null) return null;

    return OrderDetail(
      order: order,
      product: getProduct(order.productId),
      customer: getUser(order.customerId),
    );
  }
}

// Bloc에서 정규화된 상태 업데이트
class OrderBloc extends Bloc<OrderEvent, AppState> {
  Future<void> _onOrderLoaded(
    OrderLoaded event,
    Emitter<AppState> emit,
  ) async {
    final result = await _getOrdersUseCase();

    result.fold(
      (failure) => emit(state.copyWith(error: failure)),
      (orders) {
        // 정규화하여 저장
        final ordersById = {for (var order in orders) order.id: order};
        final productsById = {
          for (var order in orders)
            if (order.product != null) order.product!.id: order.product!
        };
        final usersById = {
          for (var order in orders)
            if (order.customer != null) order.customer!.id: order.customer!
        };

        emit(state.copyWith(
          ordersById: ordersById,
          productsById: {...state.productsById, ...productsById},
          usersById: {...state.usersById, ...usersById},
        ));
      },
    );
  }
}
```

### 3.3 상태 분할 (State Slicing)

```dart
// 거대한 단일 상태 대신 여러 Bloc으로 분할

// ❌ 모든 것이 하나의 Bloc에
class AppBloc extends Bloc<AppEvent, AppState> {
  // 너무 많은 책임
  // - 사용자 관리
  // - 상품 관리
  // - 주문 관리
  // - 카트 관리
  // - 결제 관리
}

// ✅ 도메인별 Bloc 분리
class UserBloc extends Bloc<UserEvent, UserState> {
  // 사용자 관련 로직만
}

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  // 상품 관련 로직만
}

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  // 주문 관련 로직만
}

class CartBloc extends Bloc<CartEvent, CartState> {
  // 카트 관련 로직만
}

// Bloc 간 통신은 Event Bus 또는 Stream 구독
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final CartBloc _cartBloc;
  late StreamSubscription _cartSubscription;

  OrderBloc(this._cartBloc) : super(OrderState.initial()) {
    _cartSubscription = _cartBloc.stream.listen((cartState) {
      if (cartState is CartCheckedOut) {
        add(OrderEvent.createFromCart(cartState.items));
      }
    });

    on<OrderEvent>(_onEvent);
  }

  @override
  Future<void> close() {
    _cartSubscription.cancel();
    return super.close();
  }
}
```

### 3.4 Derived State (파생 상태)

```dart
// 기본 상태에서 계산된 상태

@freezed
class ProductListState with _$ProductListState {
  const factory ProductListState({
    @Default([]) List<Product> products,
    @Default('') String searchQuery,
    @Default(ProductFilter.all) ProductFilter filter,
    @Default(ProductSort.name) ProductSort sortBy,
  }) = _ProductListState;

  const ProductListState._();

  // Derived state: 필터링되고 정렬된 상품 목록
  List<Product> get filteredProducts {
    var result = products;

    // 검색
    if (searchQuery.isNotEmpty) {
      result = result
          .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    // 필터
    result = switch (filter) {
      ProductFilter.all => result,
      ProductFilter.inStock => result.where((p) => p.stock > 0).toList(),
      ProductFilter.onSale => result.where((p) => p.isOnSale).toList(),
    };

    // 정렬
    result = switch (sortBy) {
      ProductSort.name => result..sort((a, b) => a.name.compareTo(b.name)),
      ProductSort.price => result..sort((a, b) => a.price.compareTo(b.price)),
      ProductSort.rating => result..sort((a, b) => b.rating.compareTo(a.rating)),
    };

    return result;
  }

  // Derived state: 통계
  int get totalProducts => products.length;
  int get inStockProducts => products.where((p) => p.stock > 0).length;
  double get averagePrice =>
      products.isEmpty ? 0 : products.map((p) => p.price).reduce((a, b) => a + b) / products.length;
}

// UI에서 사용
BlocBuilder<ProductListBloc, ProductListState>(
  builder: (context, state) {
    // filteredProducts는 캐싱되지 않으므로 매번 계산됨
    // 성능이 중요하면 Equatable로 캐싱 또는 별도 상태로 관리
    final products = state.filteredProducts;
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    );
  },
)

// 성능 최적화: Memoization
// ⚠️ Freezed 2.x는 클래스 상속을 지원하지 않으므로 composition 패턴 사용
class MemoizedProductListState {
  final ProductListState state;
  final Map<String, List<Product>> _cache = {};

  MemoizedProductListState(this.state);

  List<Product> get filteredProducts {
    // 캐시 키 생성
    final cacheKey = '${state.searchQuery}_${state.filter}_${state.sortBy}';

    // 캐시에서 조회
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // 캐시 갱신
    final filtered = state.filteredProducts;
    _cache[cacheKey] = filtered;

    return filtered;
  }

  // state의 다른 속성들을 위임
  List<Product> get products => state.products;
  String get searchQuery => state.searchQuery;
  ProductFilter get filter => state.filter;
  ProductSort get sortBy => state.sortBy;
}
```

---

## 4. Event Sourcing 패턴

Event Sourcing은 상태를 직접 저장하지 않고, 상태를 변경하는 이벤트 시퀀스를 저장합니다.

### 4.1 기본 개념

```dart
// ============= Event Store =============
abstract class DomainEvent {
  String get id;
  DateTime get timestamp;
  String get aggregateId;
  int get version;
}

class OrderCreated extends DomainEvent {
  @override
  final String id;
  @override
  final DateTime timestamp;
  @override
  final String aggregateId;
  @override
  final int version;

  final String customerId;
  final List<OrderItem> items;

  OrderCreated({
    required this.id,
    required this.timestamp,
    required this.aggregateId,
    required this.version,
    required this.customerId,
    required this.items,
  });
}

class OrderItemAdded extends DomainEvent {
  @override
  final String id;
  @override
  final DateTime timestamp;
  @override
  final String aggregateId;
  @override
  final int version;

  final OrderItem item;

  OrderItemAdded({
    required this.id,
    required this.timestamp,
    required this.aggregateId,
    required this.version,
    required this.item,
  });
}

class OrderPaid extends DomainEvent {
  @override
  final String id;
  @override
  final DateTime timestamp;
  @override
  final String aggregateId;
  @override
  final int version;

  final String paymentId;
  final double amount;

  OrderPaid({
    required this.id,
    required this.timestamp,
    required this.aggregateId,
    required this.version,
    required this.paymentId,
    required this.amount,
  });
}

// ============= Event Store 구현 =============
abstract class EventStore {
  Future<void> save(String aggregateId, List<DomainEvent> events);
  Future<List<DomainEvent>> load(String aggregateId);
  Stream<DomainEvent> stream(String aggregateId);
}

@LazySingleton(as: EventStore)
class SqliteEventStore implements EventStore {
  final Database _db;

  SqliteEventStore(this._db);

  @override
  Future<void> save(String aggregateId, List<DomainEvent> events) async {
    final batch = _db.batch();

    for (final event in events) {
      batch.insert('events', {
        'id': event.id,
        'aggregate_id': event.aggregateId,
        'version': event.version,
        'type': event.runtimeType.toString(),
        'data': jsonEncode(_eventToJson(event)),
        'timestamp': event.timestamp.toIso8601String(),
      });
    }

    await batch.commit();
  }

  @override
  Future<List<DomainEvent>> load(String aggregateId) async {
    final results = await _db.query(
      'events',
      where: 'aggregate_id = ?',
      whereArgs: [aggregateId],
      orderBy: 'version ASC',
    );

    return results.map((row) => _jsonToEvent(row)).toList();
  }

  @override
  Stream<DomainEvent> stream(String aggregateId) {
    // SQLite는 네이티브 스트림 지원 안 함
    // Polling 또는 외부 pub/sub 시스템 사용
    return Stream.periodic(const Duration(seconds: 1))
        .asyncMap((_) => load(aggregateId))
        .expand((events) => events);
  }

  Map<String, dynamic> _eventToJson(DomainEvent event) {
    // Event를 JSON으로 직렬화
    return {}; // 구현 생략
  }

  DomainEvent _jsonToEvent(Map<String, dynamic> json) {
    // JSON을 Event로 역직렬화
    return OrderCreated(
      id: '',
      timestamp: DateTime.now(),
      aggregateId: '',
      version: 0,
      customerId: '',
      items: [],
    ); // 구현 생략
  }
}
```

### 4.2 Aggregate 패턴

```dart
// Aggregate: 이벤트로부터 현재 상태 재구성
class OrderAggregate {
  String id;
  String customerId;
  List<OrderItem> items;
  OrderStatus status;
  int version;

  OrderAggregate({
    required this.id,
    required this.customerId,
    this.items = const [],
    this.status = OrderStatus.created,
    this.version = 0,
  });

  // 이벤트 적용하여 상태 재구성
  void apply(DomainEvent event) {
    switch (event) {
      case OrderCreated(:final customerId, :final items):
        this.customerId = customerId;
        this.items = items;
        status = OrderStatus.created;
      case OrderItemAdded(:final item):
        items = [...items, item];
      case OrderPaid():
        status = OrderStatus.paid;
    }
    version = event.version;
  }

  // 이벤트 시퀀스로부터 Aggregate 재구성
  static OrderAggregate fromEvents(List<DomainEvent> events) {
    if (events.isEmpty) {
      throw Exception('No events to reconstruct aggregate');
    }

    final firstEvent = events.first as OrderCreated;
    final aggregate = OrderAggregate(
      id: firstEvent.aggregateId,
      customerId: firstEvent.customerId,
    );

    for (final event in events) {
      aggregate.apply(event);
    }

    return aggregate;
  }

  // 비즈니스 로직: 새 이벤트 생성
  List<DomainEvent> addItem(OrderItem item) {
    if (status != OrderStatus.created) {
      throw Exception('Cannot add item to non-created order');
    }

    return [
      OrderItemAdded(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        aggregateId: id,
        version: version + 1,
        item: item,
      ),
    ];
  }

  List<DomainEvent> pay(String paymentId) {
    if (status != OrderStatus.created) {
      throw Exception('Order already paid or cancelled');
    }

    final total = items.fold<double>(
      0,
      (sum, item) => sum + item.price * item.quantity,
    );

    return [
      OrderPaid(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        aggregateId: id,
        version: version + 1,
        paymentId: paymentId,
        amount: total,
      ),
    ];
  }
}
```

### 4.3 Event Sourcing Bloc

```dart
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final EventStore _eventStore;
  final String _orderId;

  OrderBloc(this._eventStore, this._orderId)
      : super(const OrderState.loading()) {
    on<OrderEvent>(_onEvent);

    // 초기 로드
    add(OrderEvent.load());

    // 이벤트 스트림 구독
    _eventStore.stream(_orderId).listen((domainEvent) {
      add(OrderEvent.eventReceived(domainEvent));
    });
  }

  Future<void> _onEvent(OrderEvent event, Emitter<OrderState> emit) async {
    await event.when(
      load: () => _onLoad(emit),
      addItem: (item) => _onAddItem(item, emit),
      pay: (paymentId) => _onPay(paymentId, emit),
      eventReceived: (domainEvent) => _onEventReceived(domainEvent, emit),
    );
  }

  Future<void> _onLoad(Emitter<OrderState> emit) async {
    emit(const OrderState.loading());

    try {
      final events = await _eventStore.load(_orderId);
      final aggregate = OrderAggregate.fromEvents(events);

      emit(OrderState.loaded(aggregate));
    } catch (e) {
      emit(OrderState.error(e.toString()));
    }
  }

  Future<void> _onAddItem(OrderItem item, Emitter<OrderState> emit) async {
    await state.maybeWhen(
      loaded: (aggregate) async {
        try {
          // 새 이벤트 생성
          final newEvents = aggregate.addItem(item);

          // 이벤트 저장
          await _eventStore.save(_orderId, newEvents);

          // 상태 업데이트
          final updatedAggregate = OrderAggregate.fromEvents([
            ...await _eventStore.load(_orderId),
          ]);

          emit(OrderState.loaded(updatedAggregate));
        } catch (e) {
          emit(OrderState.error(e.toString()));
        }
      },
      orElse: () {},
    );
  }

  Future<void> _onPay(String paymentId, Emitter<OrderState> emit) async {
    await state.maybeWhen(
      loaded: (aggregate) async {
        try {
          final newEvents = aggregate.pay(paymentId);
          await _eventStore.save(_orderId, newEvents);

          final updatedAggregate = OrderAggregate.fromEvents([
            ...await _eventStore.load(_orderId),
          ]);

          emit(OrderState.loaded(updatedAggregate));
        } catch (e) {
          emit(OrderState.error(e.toString()));
        }
      },
      orElse: () {},
    );
  }

  Future<void> _onEventReceived(
    DomainEvent domainEvent,
    Emitter<OrderState> emit,
  ) async {
    // 다른 소스(다른 기기, 백엔드)에서 이벤트 수신
    await state.maybeWhen(
      loaded: (aggregate) {
        aggregate.apply(domainEvent);
        emit(OrderState.loaded(aggregate));
      },
      orElse: () {},
    );
  }
}
```

### 4.4 Event Sourcing 장점

```dart
// 1. 완전한 감사 추적 (Audit Trail)
// 모든 변경 사항이 이벤트로 기록됨

Future<List<DomainEvent>> getOrderHistory(String orderId) async {
  return eventStore.load(orderId);
}

// 2. 시점 복원 (Point-in-Time Recovery)
// 특정 시점의 상태 재구성

Future<OrderAggregate> getOrderAtTime(String orderId, DateTime timestamp) async {
  final events = await eventStore.load(orderId);
  final eventsUntil = events.where((e) => e.timestamp.isBefore(timestamp)).toList();
  return OrderAggregate.fromEvents(eventsUntil);
}

// 3. 이벤트 재생 (Event Replay)
// 버그 수정 후 이벤트 재생으로 상태 재구성

Future<void> rebuildProjections() async {
  // 모든 이벤트 재생하여 Read Model 재구성
}

// 4. 여러 Read Model 지원
// 같은 이벤트로 다양한 뷰 생성

class OrderListProjection {
  Future<void> project(DomainEvent event) async {
    // 주문 목록용 Read Model 업데이트
  }
}

class OrderStatisticsProjection {
  Future<void> project(DomainEvent event) async {
    // 통계용 Read Model 업데이트
  }
}
```

---

## 5. CQRS 패턴

CQRS (Command Query Responsibility Segregation)는 읽기와 쓰기를 분리합니다.

### 5.1 기본 구조

```dart
// ============= Command (쓰기) =============
abstract class Command {
  String get id;
}

class CreateOrderCommand extends Command {
  @override
  final String id;
  final String customerId;
  final List<OrderItem> items;

  CreateOrderCommand({
    required this.id,
    required this.customerId,
    required this.items,
  });
}

class AddOrderItemCommand extends Command {
  @override
  final String id; // Order ID
  final OrderItem item;

  AddOrderItemCommand({
    required this.id,
    required this.item,
  });
}

// ============= Query (읽기) =============
abstract class Query<T> {}

class GetOrderQuery extends Query<Order> {
  final String orderId;

  GetOrderQuery(this.orderId);
}

class GetOrderListQuery extends Query<List<OrderSummary>> {
  final String customerId;
  final int page;
  final int pageSize;

  GetOrderListQuery({
    required this.customerId,
    required this.page,
    required this.pageSize,
  });
}

// ============= Command Handler =============
abstract class CommandHandler<T extends Command> {
  Future<void> handle(T command);
}

@injectable
class CreateOrderCommandHandler extends CommandHandler<CreateOrderCommand> {
  final OrderRepository _repository;
  final EventStore _eventStore;

  CreateOrderCommandHandler(this._repository, this._eventStore);

  @override
  Future<void> handle(CreateOrderCommand command) async {
    // 1. 도메인 로직 실행
    final order = Order.create(
      id: command.id,
      customerId: command.customerId,
      items: command.items,
    );

    // 2. 이벤트 생성
    final events = order.getUncommittedEvents();

    // 3. 이벤트 저장
    await _eventStore.save(order.id, events);

    // 4. Write Model 업데이트 (선택적)
    await _repository.save(order);
  }
}

// ============= Query Handler =============
abstract class QueryHandler<Q extends Query<T>, T> {
  Future<T> handle(Q query);
}

@injectable
class GetOrderQueryHandler extends QueryHandler<GetOrderQuery, Order> {
  final OrderReadRepository _readRepository;

  GetOrderQueryHandler(this._readRepository);

  @override
  Future<Order> handle(GetOrderQuery query) async {
    // Read Model에서 직접 조회
    return _readRepository.getById(query.orderId);
  }
}

@injectable
class GetOrderListQueryHandler
    extends QueryHandler<GetOrderListQuery, List<OrderSummary>> {
  final OrderReadRepository _readRepository;

  GetOrderListQueryHandler(this._readRepository);

  @override
  Future<List<OrderSummary>> handle(GetOrderListQuery query) async {
    // 최적화된 Read Model 조회
    return _readRepository.getOrderSummaries(
      customerId: query.customerId,
      page: query.page,
      pageSize: query.pageSize,
    );
  }
}
```

### 5.2 Command Bus & Query Bus

```dart
// ============= Command Bus =============
@injectable
class CommandBus {
  final Map<Type, CommandHandler> _handlers = {};

  void register<T extends Command>(CommandHandler<T> handler) {
    _handlers[T] = handler;
  }

  Future<void> execute<T extends Command>(T command) async {
    final handler = _handlers[T] as CommandHandler<T>?;

    if (handler == null) {
      throw Exception('No handler registered for ${T.toString()}');
    }

    await handler.handle(command);
  }
}

// ============= Query Bus =============
@injectable
class QueryBus {
  final Map<Type, QueryHandler> _handlers = {};

  void register<Q extends Query<T>, T>(QueryHandler<Q, T> handler) {
    _handlers[Q] = handler;
  }

  Future<T> execute<Q extends Query<T>, T>(Q query) async {
    final handler = _handlers[Q] as QueryHandler<Q, T>?;

    if (handler == null) {
      throw Exception('No handler registered for ${Q.toString()}');
    }

    return handler.handle(query);
  }
}

// ============= DI 설정 =============
@module
abstract class CQRSModule {
  @singleton
  CommandBus provideCommandBus(
    CreateOrderCommandHandler createOrderHandler,
    AddOrderItemCommandHandler addItemHandler,
  ) {
    final bus = CommandBus();
    bus.register(createOrderHandler);
    bus.register(addItemHandler);
    return bus;
  }

  @singleton
  QueryBus provideQueryBus(
    GetOrderQueryHandler getOrderHandler,
    GetOrderListQueryHandler getOrderListHandler,
  ) {
    final bus = QueryBus();
    bus.register(getOrderHandler);
    bus.register(getOrderListHandler);
    return bus;
  }
}
```

### 5.3 CQRS Bloc

```dart
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final CommandBus _commandBus;
  final QueryBus _queryBus;

  OrderBloc(this._commandBus, this._queryBus)
      : super(const OrderState.initial()) {
    on<OrderEvent>(_onEvent);
  }

  Future<void> _onEvent(OrderEvent event, Emitter<OrderState> emit) async {
    await event.when(
      load: (orderId) => _onLoad(orderId, emit),
      create: (customerId, items) => _onCreate(customerId, items, emit),
      addItem: (orderId, item) => _onAddItem(orderId, item, emit),
    );
  }

  // Query 실행
  Future<void> _onLoad(String orderId, Emitter<OrderState> emit) async {
    emit(const OrderState.loading());

    try {
      final order = await _queryBus.execute<GetOrderQuery, Order>(
        GetOrderQuery(orderId),
      );

      emit(OrderState.loaded(order));
    } catch (e) {
      emit(OrderState.error(e.toString()));
    }
  }

  // Command 실행
  Future<void> _onCreate(
    String customerId,
    List<OrderItem> items,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderState.loading());

    try {
      final orderId = const Uuid().v4();

      await _commandBus.execute(
        CreateOrderCommand(
          id: orderId,
          customerId: customerId,
          items: items,
        ),
      );

      // Command 성공 후 Query로 최신 상태 조회
      final order = await _queryBus.execute<GetOrderQuery, Order>(
        GetOrderQuery(orderId),
      );

      emit(OrderState.loaded(order));
    } catch (e) {
      emit(OrderState.error(e.toString()));
    }
  }

  Future<void> _onAddItem(
    String orderId,
    OrderItem item,
    Emitter<OrderState> emit,
  ) async {
    await state.maybeWhen(
      loaded: (order) async {
        emit(OrderState.loading());

        try {
          await _commandBus.execute(
            AddOrderItemCommand(id: orderId, item: item),
          );

          final updatedOrder = await _queryBus.execute<GetOrderQuery, Order>(
            GetOrderQuery(orderId),
          );

          emit(OrderState.loaded(updatedOrder));
        } catch (e) {
          emit(OrderState.error(e.toString()));
        }
      },
      orElse: () {},
    );
  }
}
```

### 5.4 Read Model Projection

```dart
// Write Model (Domain Model)
class Order {
  final String id;
  final String customerId;
  final List<OrderItem> items;
  final OrderStatus status;

  // 복잡한 도메인 로직
}

// Read Model (최적화된 조회용)
class OrderSummary {
  final String id;
  final String customerName;
  final int itemCount;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;

  // 조회에 최적화된 평탄한 구조
}

// Projection: Write Model → Read Model
@injectable
class OrderProjection {
  final OrderReadRepository _readRepository;

  OrderProjection(this._readRepository);

  Future<void> project(DomainEvent event) async {
    switch (event) {
      case OrderCreated(:final aggregateId, :final customerId, :final items):
        await _createOrderSummary(aggregateId, customerId, items);
      case OrderItemAdded(:final aggregateId, :final item):
        await _addItemToSummary(aggregateId, item);
      case OrderPaid(:final aggregateId):
        await _updateOrderStatus(aggregateId, OrderStatus.paid);
    }
  }

  Future<void> _createOrderSummary(
    String orderId,
    String customerId,
    List<OrderItem> items,
  ) async {
    // 고객 정보 조회 (denormalization)
    final customer = await _readRepository.getCustomer(customerId);

    final summary = OrderSummary(
      id: orderId,
      customerName: customer.name,
      itemCount: items.length,
      totalAmount: items.fold(0, (sum, item) => sum + item.price * item.quantity),
      status: OrderStatus.created,
      createdAt: DateTime.now(),
    );

    await _readRepository.saveOrderSummary(summary);
  }

  Future<void> _addItemToSummary(String orderId, OrderItem item) async {
    final summary = await _readRepository.getOrderSummary(orderId);

    final updated = summary.copyWith(
      itemCount: summary.itemCount + 1,
      totalAmount: summary.totalAmount + item.price * item.quantity,
    );

    await _readRepository.saveOrderSummary(updated);
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus status) async {
    final summary = await _readRepository.getOrderSummary(orderId);

    final updated = summary.copyWith(status: status);

    await _readRepository.saveOrderSummary(updated);
  }
}

// Event Handler에서 Projection 실행
class OrderEventHandler {
  final OrderProjection _projection;

  OrderEventHandler(this._projection);

  Future<void> handleEvent(DomainEvent event) async {
    await _projection.project(event);
  }
}
```

---

## 6. Optimistic UI Update

사용자 경험 향상을 위해 서버 응답 전에 UI를 먼저 업데이트합니다.

### 6.1 기본 패턴

```dart
@freezed
class TodoState with _$TodoState {
  const factory TodoState({
    @Default([]) List<Todo> todos,
    @Default({}) Map<String, PendingOperation> pendingOperations,
  }) = _TodoState;
}

class PendingOperation {
  final String operationId;
  final OperationType type;
  final dynamic data;

  PendingOperation({
    required this.operationId,
    required this.type,
    required this.data,
  });
}

enum OperationType { create, update, delete }

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository _repository;

  TodoBloc(this._repository) : super(const TodoState()) {
    on<TodoEvent>(_onEvent);
  }

  Future<void> _onEvent(TodoEvent event, Emitter<TodoState> emit) async {
    await event.when(
      add: (title) => _onAdd(title, emit),
      toggle: (id) => _onToggle(id, emit),
      delete: (id) => _onDelete(id, emit),
    );
  }

  Future<void> _onAdd(String title, Emitter<TodoState> emit) async {
    // 1. Optimistic Update: 즉시 UI 업데이트
    final optimisticTodo = Todo(
      id: const Uuid().v4(),
      title: title,
      completed: false,
    );

    final operationId = const Uuid().v4();

    emit(state.copyWith(
      todos: [...state.todos, optimisticTodo],
      pendingOperations: {
        ...state.pendingOperations,
        operationId: PendingOperation(
          operationId: operationId,
          type: OperationType.create,
          data: optimisticTodo,
        ),
      },
    ));

    // 2. 서버 요청
    try {
      final createdTodo = await _repository.create(title);

      // 3. 성공: optimistic todo를 실제 todo로 교체
      emit(state.copyWith(
        todos: state.todos
            .map((todo) => todo.id == optimisticTodo.id ? createdTodo : todo)
            .toList(),
        pendingOperations: Map.from(state.pendingOperations)..remove(operationId),
      ));
    } catch (e) {
      // 4. 실패: Rollback
      emit(state.copyWith(
        todos: state.todos.where((todo) => todo.id != optimisticTodo.id).toList(),
        pendingOperations: Map.from(state.pendingOperations)..remove(operationId),
      ));

      // 에러 알림
      emit(state.copyWith(error: 'Failed to add todo: ${e.toString()}'));
    }
  }

  Future<void> _onToggle(String id, Emitter<TodoState> emit) async {
    // 1. 현재 상태 저장 (롤백용)
    final originalTodos = List<Todo>.from(state.todos);

    // 2. Optimistic Update
    final operationId = const Uuid().v4();

    emit(state.copyWith(
      todos: state.todos.map((todo) {
        return todo.id == id ? todo.copyWith(completed: !todo.completed) : todo;
      }).toList(),
      pendingOperations: {
        ...state.pendingOperations,
        operationId: PendingOperation(
          operationId: operationId,
          type: OperationType.update,
          data: id,
        ),
      },
    ));

    // 3. 서버 요청
    try {
      await _repository.toggle(id);

      // 4. 성공: pending 제거
      emit(state.copyWith(
        pendingOperations: Map.from(state.pendingOperations)..remove(operationId),
      ));
    } catch (e) {
      // 5. 실패: Rollback
      emit(state.copyWith(
        todos: originalTodos,
        pendingOperations: Map.from(state.pendingOperations)..remove(operationId),
        error: 'Failed to toggle todo: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDelete(String id, Emitter<TodoState> emit) async {
    // 1. 현재 상태 저장
    final originalTodos = List<Todo>.from(state.todos);
    final deletedTodo = originalTodos.firstWhere((todo) => todo.id == id);

    // 2. Optimistic Update: 즉시 삭제
    final operationId = const Uuid().v4();

    emit(state.copyWith(
      todos: state.todos.where((todo) => todo.id != id).toList(),
      pendingOperations: {
        ...state.pendingOperations,
        operationId: PendingOperation(
          operationId: operationId,
          type: OperationType.delete,
          data: deletedTodo,
        ),
      },
    ));

    // 3. 서버 요청
    try {
      await _repository.delete(id);

      // 4. 성공
      emit(state.copyWith(
        pendingOperations: Map.from(state.pendingOperations)..remove(operationId),
      ));
    } catch (e) {
      // 5. 실패: Rollback (삭제된 항목 복원)
      emit(state.copyWith(
        todos: [...state.todos, deletedTodo],
        pendingOperations: Map.from(state.pendingOperations)..remove(operationId),
        error: 'Failed to delete todo: ${e.toString()}',
      ));
    }
  }
}
```

### 6.2 UI에서 Pending 상태 표시

```dart
class TodoListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        return ListView.builder(
          itemCount: state.todos.length,
          itemBuilder: (context, index) {
            final todo = state.todos[index];

            // Pending 상태 확인
            final isPending = state.pendingOperations.values.any(
              (op) => op.data == todo || op.data == todo.id,
            );

            return TodoTile(
              todo: todo,
              isPending: isPending, // 로딩 표시
              onToggle: () {
                context.read<TodoBloc>().add(TodoEvent.toggle(todo.id));
              },
              onDelete: () {
                context.read<TodoBloc>().add(TodoEvent.delete(todo.id));
              },
            );
          },
        );
      },
    );
  }
}

class TodoTile extends StatelessWidget {
  final Todo todo;
  final bool isPending;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoTile({
    super.key,
    required this.todo,
    required this.isPending,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isPending ? 0.5 : 1.0, // Pending 시 반투명
      child: ListTile(
        leading: isPending
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Checkbox(
                value: todo.completed,
                onChanged: (_) => onToggle(),
              ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: isPending ? null : onDelete, // Pending 시 비활성화
        ),
      ),
    );
  }
}
```

### 6.3 고급 패턴: Operation Queue

```dart
// 오프라인 지원을 위한 Operation Queue
class OperationQueue {
  final List<PendingOperation> _queue = [];
  final ConnectivityService _connectivity;

  OperationQueue(this._connectivity) {
    // 온라인 상태 복구 시 큐 처리
    _connectivity.onOnline.listen((_) => _processQueue());
  }

  void enqueue(PendingOperation operation) {
    _queue.add(operation);
    if (_connectivity.isOnline) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    while (_queue.isNotEmpty && _connectivity.isOnline) {
      final operation = _queue.first;

      try {
        await _executeOperation(operation);
        _queue.removeAt(0);
      } catch (e) {
        // 실패 시 재시도 또는 큐에 유지
        break;
      }
    }
  }

  Future<void> _executeOperation(PendingOperation operation) async {
    // Operation 실행
  }
}
```

---

## 7. State Synchronization

여러 Bloc 간 상태를 동기화하는 패턴입니다.

### 7.1 Stream 기반 동기화

```dart
// ============= Master-Slave 패턴 =============
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Master: 인증 상태 관리
}

class UserBloc extends Bloc<UserEvent, UserState> {
  final AuthBloc _authBloc;
  late StreamSubscription _authSubscription;

  UserBloc(this._authBloc) : super(const UserState.initial()) {
    // Slave: AuthBloc 상태를 구독
    _authSubscription = _authBloc.stream.listen((authState) {
      authState.whenOrNull(
        authenticated: (user) => add(UserEvent.loadProfile(user.id)),
        unauthenticated: () => add(const UserEvent.clear()),
      );
    });

    on<UserEvent>(_onEvent);
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}

// ============= Bidirectional Sync =============
class CartBloc extends Bloc<CartEvent, CartState> {
  final ProductBloc _productBloc;
  late StreamSubscription _productSubscription;

  CartBloc(this._productBloc) : super(const CartState()) {
    // 상품 정보 변경 시 카트 업데이트
    _productSubscription = _productBloc.stream.listen((productState) {
      productState.whenOrNull(
        loaded: (products) {
          // 카트에 있는 상품 정보 동기화
          add(CartEvent.syncProducts(products));
        },
      );
    });

    on<CartEvent>(_onEvent);
  }

  Future<void> _onSyncProducts(
    CartSyncProducts event,
    Emitter<CartState> emit,
  ) async {
    // 카트의 각 항목 가격 업데이트
    final updatedItems = state.items.map((item) {
      final updatedProduct = event.products.firstWhereOrNull(
        (p) => p.id == item.productId,
      );

      if (updatedProduct != null && updatedProduct.price != item.price) {
        return item.copyWith(
          price: updatedProduct.price,
          name: updatedProduct.name,
        );
      }

      return item;
    }).toList();

    emit(state.copyWith(items: updatedItems));
  }

  @override
  Future<void> close() {
    _productSubscription.cancel();
    return super.close();
  }
}
```

### 7.2 Shared State Repository 패턴

```dart
// 공유 상태 저장소
@injectable
class SharedStateRepository {
  final _stateController = BehaviorSubject<AppSharedState>();

  Stream<AppSharedState> get stateStream => _stateController.stream;
  AppSharedState get currentState => _stateController.value;

  void updateCart(CartState cart) {
    _stateController.add(
      currentState.copyWith(cart: cart),
    );
  }

  void updateUser(UserState user) {
    _stateController.add(
      currentState.copyWith(user: user),
    );
  }

  void dispose() {
    _stateController.close();
  }
}

@freezed
class AppSharedState with _$AppSharedState {
  const factory AppSharedState({
    UserState? user,
    CartState? cart,
    SettingsState? settings,
  }) = _AppSharedState;
}

// Bloc에서 사용
class CartBloc extends Bloc<CartEvent, CartState> {
  final SharedStateRepository _sharedState;

  CartBloc(this._sharedState) : super(const CartState()) {
    on<CartEvent>(_onEvent);

    // 상태 변경 시 공유 저장소 업데이트
    stream.listen((state) {
      _sharedState.updateCart(state);
    });
  }
}
```

### 7.3 State Reconciliation (상태 조정)

```dart
// 서버와 로컬 상태 동기화
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final LocalRepository _local;
  final RemoteRepository _remote;

  SyncBloc(this._local, this._remote) : super(const SyncState.idle()) {
    on<SyncEvent>(_onEvent);
  }

  Future<void> _onSync(Emitter<SyncState> emit) async {
    emit(const SyncState.syncing());

    try {
      // 1. 로컬과 서버 데이터 가져오기
      final localData = await _local.getAll();
      final remoteData = await _remote.getAll();

      // 2. 충돌 감지 및 해결
      final conflicts = _detectConflicts(localData, remoteData);
      final resolved = await _resolveConflicts(conflicts);

      // 3. 병합
      final merged = _mergeData(localData, remoteData, resolved);

      // 4. 로컬 및 서버 업데이트
      await _local.saveAll(merged);
      await _remote.saveAll(merged);

      emit(SyncState.completed(mergedCount: merged.length));
    } catch (e) {
      emit(SyncState.failed(e.toString()));
    }
  }

  List<DataConflict> _detectConflicts(
    List<Data> local,
    List<Data> remote,
  ) {
    final conflicts = <DataConflict>[];

    for (final localItem in local) {
      final remoteItem = remote.firstWhereOrNull(
        (r) => r.id == localItem.id,
      );

      if (remoteItem != null &&
          localItem.updatedAt != remoteItem.updatedAt &&
          localItem != remoteItem) {
        conflicts.add(DataConflict(
          id: localItem.id,
          local: localItem,
          remote: remoteItem,
        ));
      }
    }

    return conflicts;
  }

  Future<Map<String, Data>> _resolveConflicts(
    List<DataConflict> conflicts,
  ) async {
    final resolved = <String, Data>{};

    for (final conflict in conflicts) {
      // 해결 전략: Last Write Wins (LWW)
      final winner = conflict.local.updatedAt.isAfter(conflict.remote.updatedAt)
          ? conflict.local
          : conflict.remote;

      resolved[conflict.id] = winner;
    }

    return resolved;
  }

  List<Data> _mergeData(
    List<Data> local,
    List<Data> remote,
    Map<String, Data> resolved,
  ) {
    final merged = <String, Data>{};

    // 로컬 데이터
    for (final item in local) {
      merged[item.id] = resolved[item.id] ?? item;
    }

    // 서버 데이터 (로컬에 없는 것)
    for (final item in remote) {
      if (!merged.containsKey(item.id)) {
        merged[item.id] = resolved[item.id] ?? item;
      }
    }

    return merged.values.toList();
  }
}
```

---

## 8. Undo/Redo 패턴

사용자 액션의 취소/재실행 기능을 구현합니다.

### 8.1 Command 패턴 기반 Undo/Redo

```dart
// ============= Command 인터페이스 =============
abstract class Command {
  Future<void> execute();
  Future<void> undo();
  String get description;
}

// ============= 구체적인 Command =============
class AddTodoCommand implements Command {
  final TodoRepository _repository;
  final String title;
  late String _todoId;

  AddTodoCommand(this._repository, this.title);

  @override
  Future<void> execute() async {
    final todo = await _repository.create(title);
    _todoId = todo.id;
  }

  @override
  Future<void> undo() async {
    await _repository.delete(_todoId);
  }

  @override
  String get description => 'Add: $title';
}

class ToggleTodoCommand implements Command {
  final TodoRepository _repository;
  final String todoId;
  late bool _previousState;

  ToggleTodoCommand(this._repository, this.todoId);

  @override
  Future<void> execute() async {
    final todo = await _repository.getById(todoId);
    _previousState = todo.completed;
    await _repository.toggle(todoId);
  }

  @override
  Future<void> undo() async {
    await _repository.toggle(todoId); // Toggle back
  }

  @override
  String get description => 'Toggle: $todoId';
}

class DeleteTodoCommand implements Command {
  final TodoRepository _repository;
  final String todoId;
  late Todo _deletedTodo;

  DeleteTodoCommand(this._repository, this.todoId);

  @override
  Future<void> execute() async {
    _deletedTodo = await _repository.getById(todoId);
    await _repository.delete(todoId);
  }

  @override
  Future<void> undo() async {
    await _repository.restore(_deletedTodo);
  }

  @override
  String get description => 'Delete: ${_deletedTodo.title}';
}

// ============= Command Manager =============
class CommandManager {
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];
  final int maxHistorySize;

  CommandManager({this.maxHistorySize = 50});

  Future<void> execute(Command command) async {
    await command.execute();

    _undoStack.add(command);
    _redoStack.clear(); // 새 명령 실행 시 redo 스택 초기화

    // 히스토리 크기 제한
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }
  }

  Future<bool> undo() async {
    if (_undoStack.isEmpty) return false;

    final command = _undoStack.removeLast();
    await command.undo();
    _redoStack.add(command);

    return true;
  }

  Future<bool> redo() async {
    if (_redoStack.isEmpty) return false;

    final command = _redoStack.removeLast();
    await command.execute();
    _undoStack.add(command);

    return true;
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  List<String> get undoHistory =>
      _undoStack.map((c) => c.description).toList();

  List<String> get redoHistory =>
      _redoStack.map((c) => c.description).toList();

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
```

### 8.2 Undo/Redo Bloc

```dart
@freezed
class TodoState with _$TodoState {
  const factory TodoState({
    @Default([]) List<Todo> todos,
    @Default(false) bool canUndo,
    @Default(false) bool canRedo,
    @Default([]) List<String> undoHistory,
    @Default([]) List<String> redoHistory,
  }) = _TodoState;
}

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository _repository;
  final CommandManager _commandManager;

  TodoBloc(this._repository, this._commandManager)
      : super(const TodoState()) {
    on<TodoEvent>(_onEvent);
  }

  Future<void> _onEvent(TodoEvent event, Emitter<TodoState> emit) async {
    await event.when(
      load: () => _onLoad(emit),
      add: (title) => _onAdd(title, emit),
      toggle: (id) => _onToggle(id, emit),
      delete: (id) => _onDelete(id, emit),
      undo: () => _onUndo(emit),
      redo: () => _onRedo(emit),
    );
  }

  Future<void> _onLoad(Emitter<TodoState> emit) async {
    final todos = await _repository.getAll();
    emit(state.copyWith(
      todos: todos,
      canUndo: _commandManager.canUndo,
      canRedo: _commandManager.canRedo,
      undoHistory: _commandManager.undoHistory,
      redoHistory: _commandManager.redoHistory,
    ));
  }

  Future<void> _onAdd(String title, Emitter<TodoState> emit) async {
    final command = AddTodoCommand(_repository, title);
    await _commandManager.execute(command);

    // 상태 업데이트
    final todos = await _repository.getAll();
    emit(state.copyWith(
      todos: todos,
      canUndo: _commandManager.canUndo,
      canRedo: _commandManager.canRedo,
      undoHistory: _commandManager.undoHistory,
      redoHistory: _commandManager.redoHistory,
    ));
  }

  Future<void> _onToggle(String id, Emitter<TodoState> emit) async {
    final command = ToggleTodoCommand(_repository, id);
    await _commandManager.execute(command);

    final todos = await _repository.getAll();
    emit(state.copyWith(
      todos: todos,
      canUndo: _commandManager.canUndo,
      canRedo: _commandManager.canRedo,
      undoHistory: _commandManager.undoHistory,
      redoHistory: _commandManager.redoHistory,
    ));
  }

  Future<void> _onDelete(String id, Emitter<TodoState> emit) async {
    final command = DeleteTodoCommand(_repository, id);
    await _commandManager.execute(command);

    final todos = await _repository.getAll();
    emit(state.copyWith(
      todos: todos,
      canUndo: _commandManager.canUndo,
      canRedo: _commandManager.canRedo,
      undoHistory: _commandManager.undoHistory,
      redoHistory: _commandManager.redoHistory,
    ));
  }

  Future<void> _onUndo(Emitter<TodoState> emit) async {
    final success = await _commandManager.undo();

    if (success) {
      final todos = await _repository.getAll();
      emit(state.copyWith(
        todos: todos,
        canUndo: _commandManager.canUndo,
        canRedo: _commandManager.canRedo,
        undoHistory: _commandManager.undoHistory,
        redoHistory: _commandManager.redoHistory,
      ));
    }
  }

  Future<void> _onRedo(Emitter<TodoState> emit) async {
    final success = await _commandManager.redo();

    if (success) {
      final todos = await _repository.getAll();
      emit(state.copyWith(
        todos: todos,
        canUndo: _commandManager.canUndo,
        canRedo: _commandManager.canRedo,
        undoHistory: _commandManager.undoHistory,
        redoHistory: _commandManager.redoHistory,
      ));
    }
  }
}
```

### 8.3 UI 통합

```dart
class TodoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        actions: [
          BlocBuilder<TodoBloc, TodoState>(
            buildWhen: (prev, curr) => prev.canUndo != curr.canUndo,
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.undo),
                onPressed: state.canUndo
                    ? () => context.read<TodoBloc>().add(const TodoEvent.undo())
                    : null,
              );
            },
          ),
          BlocBuilder<TodoBloc, TodoState>(
            buildWhen: (prev, curr) => prev.canRedo != curr.canRedo,
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.redo),
                onPressed: state.canRedo
                    ? () => context.read<TodoBloc>().add(const TodoEvent.redo())
                    : null,
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) {
          return ListView.builder(
            itemCount: state.todos.length,
            itemBuilder: (context, index) {
              return TodoTile(todo: state.todos[index]);
            },
          );
        },
      ),
    );
  }
}

// Keyboard Shortcuts
class TodoPageWithShortcuts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
            const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
            const RedoIntent(),
      },
      child: Actions(
        actions: {
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (_) {
              context.read<TodoBloc>().add(const TodoEvent.undo());
              return null;
            },
          ),
          RedoIntent: CallbackAction<RedoIntent>(
            onInvoke: (_) {
              context.read<TodoBloc>().add(const TodoEvent.redo());
              return null;
            },
          ),
        },
        child: const TodoPage(),
      ),
    );
  }
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}
```

---

## 9. Time-travel Debugging

상태 히스토리를 추적하고 이전 상태로 되돌릴 수 있는 디버깅 기능입니다.

### 9.1 State History Tracker

```dart
class StateHistoryTracker<S> {
  final List<StateSnapshot<S>> _history = [];
  final int maxHistorySize;
  int _currentIndex = -1;

  StateHistoryTracker({this.maxHistorySize = 100});

  void record(S state, {String? eventName}) {
    // 현재 위치 이후의 히스토리 제거 (time travel 후 새 이벤트 발생 시)
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    final snapshot = StateSnapshot(
      state: state,
      timestamp: DateTime.now(),
      eventName: eventName,
      index: _history.length,
    );

    _history.add(snapshot);
    _currentIndex = _history.length - 1;

    // 히스토리 크기 제한
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
      _currentIndex--;
    }
  }

  S? get currentState => _history.isEmpty ? null : _history[_currentIndex].state;

  bool canGoBack() => _currentIndex > 0;
  bool canGoForward() => _currentIndex < _history.length - 1;

  S? goBack() {
    if (!canGoBack()) return null;
    _currentIndex--;
    return _history[_currentIndex].state;
  }

  S? goForward() {
    if (!canGoForward()) return null;
    _currentIndex++;
    return _history[_currentIndex].state;
  }

  S? jumpTo(int index) {
    if (index < 0 || index >= _history.length) return null;
    _currentIndex = index;
    return _history[_currentIndex].state;
  }

  List<StateSnapshot<S>> get history => List.unmodifiable(_history);
  int get currentIndex => _currentIndex;

  void clear() {
    _history.clear();
    _currentIndex = -1;
  }
}

class StateSnapshot<S> {
  final S state;
  final DateTime timestamp;
  final String? eventName;
  final int index;

  StateSnapshot({
    required this.state,
    required this.timestamp,
    this.eventName,
    required this.index,
  });
}
```

### 9.2 Time-travel Bloc

```dart
// Time travel events
abstract class TimeTravelEvent {}
class TimeTravelBack extends TimeTravelEvent {}
class TimeTravelForward extends TimeTravelEvent {}
class TimeTravelJumpTo extends TimeTravelEvent {
  final int index;
  TimeTravelJumpTo(this.index);
}

class TimeTravelBloc<E, S> extends Bloc<E, S> {
  final StateHistoryTracker<S> _historyTracker;
  bool _isTimeTraveling = false;

  TimeTravelBloc(
    S initialState, {
    int maxHistorySize = 100,
  })  : _historyTracker = StateHistoryTracker(maxHistorySize: maxHistorySize),
        super(initialState) {
    // 초기 상태 기록
    _historyTracker.record(initialState);

    // 모든 상태 변화 추적
    stream.listen((state) {
      if (!_isTimeTraveling) {
        _historyTracker.record(state);
      }
    });

    // ⚠️ Bloc 8.x+: emit()은 on<Event> 핸들러 내부에서만 호출 가능
    on<TimeTravelBack>((event, emit) {
      final previousState = _historyTracker.goBack();
      if (previousState != null) {
        _isTimeTraveling = true;
        emit(previousState);
        _isTimeTraveling = false;
      }
    });

    on<TimeTravelForward>((event, emit) {
      final nextState = _historyTracker.goForward();
      if (nextState != null) {
        _isTimeTraveling = true;
        emit(nextState);
        _isTimeTraveling = false;
      }
    });

    on<TimeTravelJumpTo>((event, emit) {
      final targetState = _historyTracker.jumpTo(event.index);
      if (targetState != null) {
        _isTimeTraveling = true;
        emit(targetState);
        _isTimeTraveling = false;
      }
    });
  }

  // Time travel 메서드 - 이제 이벤트를 dispatch함
  void goBack() => add(TimeTravelBack() as E);
  void goForward() => add(TimeTravelForward() as E);
  void jumpToState(int index) => add(TimeTravelJumpTo(index) as E);

  bool get canGoBack => _historyTracker.canGoBack();
  bool get canGoForward => _historyTracker.canGoForward();

  List<StateSnapshot<S>> get stateHistory => _historyTracker.history;
  int get currentHistoryIndex => _historyTracker.currentIndex;
}

// 사용 예
class CounterBloc extends TimeTravelBloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
    on<Decrement>((event, emit) => emit(state - 1));
  }
}
```

### 9.3 Time-travel DevTools UI

```dart
class TimeTravelDebugger extends StatelessWidget {
  final TimeTravelBloc bloc;

  const TimeTravelDebugger({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: bloc.stream,
      builder: (context, snapshot) {
        final history = bloc.stateHistory;
        final currentIndex = bloc.currentHistoryIndex;

        return Column(
          children: [
            // Timeline Slider
            Slider(
              value: currentIndex.toDouble(),
              min: 0,
              max: (history.length - 1).toDouble(),
              divisions: history.length - 1,
              label: 'State ${currentIndex + 1}',
              onChanged: (value) {
                bloc.jumpToState(value.toInt());
              },
            ),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: bloc.canGoBack ? bloc.goBack : null,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: bloc.canGoForward ? bloc.goForward : null,
                ),
              ],
            ),

            // State History List
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final snapshot = history[index];
                  final isActive = index == currentIndex;

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                      backgroundColor: isActive ? Colors.blue : Colors.grey,
                    ),
                    title: Text(
                      snapshot.eventName ?? 'State ${index + 1}',
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      _formatTimestamp(snapshot.timestamp),
                    ),
                    trailing: Text(
                      snapshot.state.toString(),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    onTap: () => bloc.jumpToState(index),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute}:${timestamp.second}.${timestamp.millisecond}';
  }
}
```

### 9.4 Redux DevTools 통합

```dart
// Redux DevTools Extension과 통합
class ReduxDevToolsObserver extends BlocObserver {
  final devtools = DevToolsExtension();

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);

    // DevTools에 이벤트 전송
    devtools.send(
      event.toString(),
      bloc.state,
      timestamp: DateTime.now(),
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);

    // DevTools에 상태 전환 전송
    devtools.send(
      transition.event.toString(),
      transition.nextState,
      previousState: transition.currentState,
    );
  }
}

// main.dart
void main() {
  if (kDebugMode) {
    Bloc.observer = ReduxDevToolsObserver();
  }

  runApp(const MyApp());
}
```

---

## 10. 상태 직렬화/역직렬화

상태를 영속화하고 복원하는 전략입니다.

### 10.1 HydratedBloc 활용

```dart
// 자동 상태 저장/복원
class SettingsBloc extends HydratedBloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsState.initial()) {
    on<SettingsEvent>(_onEvent);
  }

  @override
  SettingsState? fromJson(Map<String, dynamic> json) {
    try {
      return SettingsState.fromJson(json);
    } catch (e) {
      // 역직렬화 실패 시 null 반환 (기본 상태 사용)
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(SettingsState state) {
    try {
      return state.toJson();
    } catch (e) {
      // 직렬화 실패 시 null 반환
      return null;
    }
  }
}

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(false) bool darkMode,
    @Default('en') String language,
    @Default(true) bool notificationsEnabled,
    @Default(14.0) double fontSize,
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);
}
```

### 10.2 복잡한 상태 직렬화

```dart
// 중첩된 객체 직렬화
@freezed
class AppState with _$AppState {
  const factory AppState({
    required User? user,
    required List<Product> cart,
    required Map<String, Order> orders,
    required DateTime lastSynced,
  }) = _AppState;

  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      cart: (json['cart'] as List<dynamic>)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList(),
      orders: (json['orders'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          Order.fromJson(value as Map<String, dynamic>),
        ),
      ),
      lastSynced: DateTime.parse(json['lastSynced'] as String),
    );
  }

  Map<String, dynamic> toJson(AppState state) {
    return {
      'user': state.user?.toJson(),
      'cart': state.cart.map((item) => item.toJson()).toList(),
      'orders': state.orders.map((key, value) => MapEntry(key, value.toJson())),
      'lastSynced': state.lastSynced.toIso8601String(),
    };
  }
}
```

### 10.3 선택적 직렬화

```dart
// 민감한 정보는 제외하고 직렬화
class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState.initial()) {
    on<AuthEvent>(_onEvent);
  }

  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    return AuthState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(AuthState state) {
    return state.when(
      initial: () => {'type': 'initial'},
      loading: () => {'type': 'loading'},
      authenticated: (user, token) => {
        'type': 'authenticated',
        'user': user.toJson(),
        // ⚠️ 토큰은 저장하지 않음 (보안)
      },
      error: (message) => {'type': 'error'},
    );
  }

  // 토큰은 SecureStorage에 별도 저장
  Future<void> _saveTokenSecurely(String token) async {
    final storage = FlutterSecureStorage();
    await storage.write(key: 'auth_token', value: token);
  }

  Future<String?> _loadTokenSecurely() async {
    final storage = FlutterSecureStorage();
    return storage.read(key: 'auth_token');
  }
}
```

### 10.4 마이그레이션 전략

```dart
// 버전 관리 및 마이그레이션
class VersionedBloc extends HydratedBloc<MyEvent, MyState> {
  static const int currentVersion = 3;

  VersionedBloc() : super(MyState.initial()) {
    on<MyEvent>(_onEvent);
  }

  @override
  MyState? fromJson(Map<String, dynamic> json) {
    try {
      final version = json['version'] as int? ?? 1;

      // 버전별 마이그레이션
      Map<String, dynamic> migratedJson = json;

      if (version < 2) {
        migratedJson = _migrateV1ToV2(migratedJson);
      }

      if (version < 3) {
        migratedJson = _migrateV2ToV3(migratedJson);
      }

      return MyState.fromJson(migratedJson);
    } catch (e) {
      print('Migration failed: $e');
      return null; // 기본 상태 사용
    }
  }

  @override
  Map<String, dynamic>? toJson(MyState state) {
    final json = state.toJson();
    json['version'] = currentVersion;
    return json;
  }

  // V1 -> V2 마이그레이션
  Map<String, dynamic> _migrateV1ToV2(Map<String, dynamic> json) {
    // V1에서는 'userName'이었지만 V2에서는 'user.name'으로 변경
    final userName = json['userName'] as String?;
    json.remove('userName');

    json['user'] = {
      'name': userName ?? '',
      'email': '', // 새로 추가된 필드
    };

    json['version'] = 2;
    return json;
  }

  // V2 -> V3 마이그레이션
  Map<String, dynamic> _migrateV2ToV3(Map<String, dynamic> json) {
    // V2에서는 'items'가 List였지만 V3에서는 Map으로 변경
    final items = json['items'] as List<dynamic>?;
    if (items != null) {
      json['itemsById'] = {
        for (var item in items) (item as Map<String, dynamic>)['id']: item
      };
      json.remove('items');
    }

    json['version'] = 3;
    return json;
  }
}
```

### 10.5 압축 및 암호화

```dart
// 큰 상태를 압축하여 저장
class CompressedBloc extends HydratedBloc<MyEvent, MyState> {
  CompressedBloc() : super(MyState.initial()) {
    on<MyEvent>(_onEvent);
  }

  @override
  MyState? fromJson(Map<String, dynamic> json) {
    try {
      // 압축된 데이터 확인
      if (json.containsKey('compressed')) {
        final compressedBytes = base64Decode(json['compressed'] as String);
        final decompressedBytes = gzip.decode(compressedBytes);
        final decompressedJson = utf8.decode(decompressedBytes);
        json = jsonDecode(decompressedJson) as Map<String, dynamic>;
      }

      return MyState.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(MyState state) {
    try {
      final json = state.toJson();
      final jsonString = jsonEncode(json);

      // 큰 데이터만 압축 (10KB 이상)
      if (jsonString.length > 10240) {
        final bytes = utf8.encode(jsonString);
        final compressed = gzip.encode(bytes);
        final encoded = base64Encode(compressed);

        return {'compressed': encoded};
      }

      return json;
    } catch (e) {
      return null;
    }
  }
}

// 암호화된 저장소
class EncryptedStorage implements Storage {
  final Encrypter _encrypter;
  final Storage _storage;

  EncryptedStorage(this._encrypter, this._storage);

  @override
  Future<void> write(String key, dynamic value) async {
    final encrypted = _encrypter.encrypt(jsonEncode(value));
    await _storage.write(key, encrypted.base64);
  }

  @override
  Future<dynamic> read(String key) async {
    final encrypted = await _storage.read(key);
    if (encrypted == null) return null;

    final decrypted = _encrypter.decrypt64(encrypted);
    return jsonDecode(decrypted);
  }

  @override
  Future<void> delete(String key) => _storage.delete(key);

  @override
  Future<void> clear() => _storage.clear();
}
```

---

## 결론

대규모 Flutter 애플리케이션에서 고급 상태 관리는 필수입니다:

1. **Bloc vs Riverpod**: 프로젝트 특성에 따라 선택
   - Bloc: 엄격한 타입 안전성, Event-driven, 엔터프라이즈
   - Riverpod: 적은 보일러플레이트, Reactive, 빠른 개발

2. **상태 설계**: Global/Feature/Page 스코프 분리
   - 정규화된 상태로 중복 제거
   - Derived state로 성능 최적화

3. **Event Sourcing & CQRS**: 감사 추적 및 읽기/쓰기 최적화

4. **Optimistic UI**: 사용자 경험 향상

5. **State Sync**: 여러 Bloc 간 일관성 유지

6. **Undo/Redo**: 사용자 실수 복구

7. **Time-travel Debugging**: 개발 생산성 향상

8. **직렬화**: 상태 영속화 및 마이그레이션

이러한 패턴들을 적절히 조합하여 복잡한 비즈니스 로직을 효과적으로 관리할 수 있습니다.

## 참고 자료

- [Bloc Library](https://bloclibrary.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Event Sourcing Pattern](https://martinfowler.com/eaaDev/EventSourcing.html)
- [CQRS Pattern](https://martinfowler.com/bliki/CQRS.html)
- [Redux DevTools](https://github.com/reduxjs/redux-devtools)
