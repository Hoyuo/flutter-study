# Advanced Design Patterns - Flutter 고급 설계 패턴

> 이 문서는 10년 이상 경력의 시니어 개발자를 대상으로 작성된 Flutter 고급 설계 패턴 가이드입니다.

## 목차 (Table of Contents)

1. [DDD (Domain-Driven Design)](#1-ddd-domain-driven-design)
2. [Hexagonal Architecture](#2-hexagonal-architecture)
3. [Saga Pattern](#3-saga-pattern)
4. [Specification Pattern](#4-specification-pattern)
5. [CQRS Pattern](#5-cqrs-pattern)
6. [Event Sourcing](#6-event-sourcing)
7. [패턴 비교 및 선택 가이드](#7-패턴-비교-및-선택-가이드)
8. [관련 문서](#8-관련-문서)

---

## 1. DDD (Domain-Driven Design)

### 1.1 핵심 개념

DDD는 복잡한 비즈니스 로직을 체계적으로 관리하는 설계 방법론입니다.

```
전략적 설계 (Strategic Design)
├── Bounded Context
├── Context Mapping
└── Ubiquitous Language

전술적 패턴 (Tactical Patterns)
├── Entity
├── Value Object
├── Aggregate
├── Repository
├── Domain Service
└── Domain Event
```

### 1.2 Aggregate Root 예제

```dart
// Value Object
class Money {
  final double amount;
  final String currency;
  
  const Money(this.amount, this.currency);
  
  Money operator +(Money other) {
    if (currency != other.currency) throw ArgumentError('Currency mismatch');
    return Money(amount + other.amount, currency);
  }
}

// Aggregate Root
class Order {
  final String id;
  final String customerId;
  final List<OrderLine> _lines;
  OrderStatus _status;
  
  Order(this.id, this.customerId, this._lines, this._status);
  
  List<OrderLine> get lines => List.unmodifiable(_lines);
  OrderStatus get status => _status;
  
  Money calculateTotal() {
    return _lines.fold(Money(0, 'USD'), (sum, line) => sum + line.total);
  }
  
  void confirm() {
    if (_status != OrderStatus.pending) {
      throw StateError('Can only confirm pending orders');
    }
    _status = OrderStatus.confirmed;
  }
}

enum OrderStatus { pending, confirmed, shipped, completed }
```

### 1.3 Repository Pattern

```dart
abstract class OrderRepository {
  Future<Order?> findById(String id);
  Future<List<Order>> findByCustomer(String customerId);
  Future<void> save(Order order);
}

class OrderRepositoryImpl implements OrderRepository {
  final Database db;
  
  OrderRepositoryImpl(this.db);
  
  @override
  Future<Order?> findById(String id) async {
    // Implementation
  }
  
  @override
  Future<void> save(Order order) async {
    await db.transaction((txn) async {
      await txn.insert('orders', orderToMap(order));
      for (final line in order.lines) {
        await txn.insert('order_lines', lineToMap(line));
      }
    });
  }
}
```

### 1.4 DDD 안티패턴

| 안티패턴 | 설명 | 해결책 |
|---------|------|--------|
| Anemic Domain Model | Entity에 로직 없음 | 비즈니스 로직을 Entity로 이동 |
| God Aggregate | 너무 큰 Aggregate | 작게 분리 |
| Repository 남용 | 모든 쿼리를 Repository에 | Specification 사용 |

---

## 2. Hexagonal Architecture

### 2.1 개념

Ports & Adapters 패턴으로 도메인을 외부 기술로부터 격리합니다.

```
     Primary Adapters           Domain Core         Secondary Adapters
     (Driving Side)                                   (Driven Side)
    ┌──────────────┐          ┌──────────┐          ┌──────────────┐
    │ REST API     │          │          │          │  Database    │
    │ Flutter UI   │──────────│  Domain  │──────────│  External API│
    │ CLI          │          │          │          │  Message Q   │
    └──────────────┘          └──────────┘          └──────────────┘
```

### 2.2 Port 정의

```dart
// Primary Port (Use Case Interface)
abstract class CreateOrderUseCase {
  Future<Either<Failure, String>> execute(CreateOrderRequest request);
}

// Secondary Port (Repository Interface)
abstract class OrderRepository {
  Future<Either<Failure, Order>> findById(String id);
  Future<Either<Failure, void>> save(Order order);
}

// Secondary Port (Payment Gateway Interface)
abstract class PaymentGateway {
  Future<Either<Failure, PaymentResult>> processPayment(Money amount);
}
```

### 2.3 Adapter 구현

```dart
// Primary Adapter (Flutter UI)
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final CreateOrderUseCase _createOrder;
  
  OrderBloc(this._createOrder) : super(OrderInitial()) {
    on<CreateOrderRequested>((event, emit) async {
      emit(OrderCreating());
      final result = await _createOrder.execute(event.request);
      result.fold(
        (failure) => emit(OrderError(failure.message)),
        (orderId) => emit(OrderCreated(orderId)),
      );
    });
  }
}

// Secondary Adapter (SQLite)
class SqliteOrderRepository implements OrderRepository {
  final Database db;
  
  SqliteOrderRepository(this.db);
  
  @override
  Future<Either<Failure, Order>> findById(String id) async {
    try {
      final results = await db.query('orders', where: 'id = ?', whereArgs: [id]);
      if (results.isEmpty) return Left(NotFoundFailure());
      return Right(_mapToOrder(results.first));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
```

### 2.4 테스트 용이성

```dart
// Mock을 사용한 테스트
class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  test('should create order successfully', () async {
    final mockRepo = MockOrderRepository();
    final useCase = CreateOrderUseCaseImpl(mockRepo);
    
    when(() => mockRepo.save(any())).thenAnswer((_) async => Right(null));
    
    final result = await useCase.execute(createOrderRequest);
    
    expect(result.isRight(), true);
    verify(() => mockRepo.save(any())).called(1);
  });
}
```

---

## 3. Saga Pattern

### 3.1 개념

분산 트랜잭션을 관리하는 패턴입니다.

```
정상 흐름
Step 1 ──> Step 2 ──> Step 3 ──> Step 4
  │          │          │ ✗
  │          │          └─────> Compensation
  │          └────────────────> Compensation  
  └───────────────────────────> Compensation
```

### 3.2 Saga 구현

```dart
abstract class SagaStep {
  String get name;
  Future<Either<Failure, void>> execute();
  Future<void> compensate();
}

class CreateOrderStep implements SagaStep {
  final OrderRepository repository;
  Order? createdOrder;
  
  CreateOrderStep(this.repository);
  
  @override
  String get name => 'CreateOrder';
  
  @override
  Future<Either<Failure, void>> execute() async {
    createdOrder = Order.create(/* ... */);
    return repository.save(createdOrder!);
  }
  
  @override
  Future<void> compensate() async {
    if (createdOrder != null) {
      await repository.delete(createdOrder!.id);
    }
  }
}

class SagaOrchestrator {
  final List<SagaStep> steps = [];
  final List<SagaStep> executedSteps = [];
  
  void addStep(SagaStep step) => steps.add(step);
  
  Future<Either<Failure, void>> execute() async {
    for (final step in steps) {
      debugPrint('Executing: ${step.name}');
      final result = await step.execute();

      if (result.isLeft()) {
        debugPrint('Failed at: ${step.name}. Starting compensation...');
        await _compensate();
        return result;
      }
      
      executedSteps.add(step);
    }
    return Right(null);
  }
  
  Future<void> _compensate() async {
    for (final step in executedSteps.reversed) {
      print('Compensating: ${step.name}');
      await step.compensate();
    }
  }
}
```

### 3.3 Saga 사용 예제

```dart
class OrderSaga {
  Future<Either<Failure, String>> createOrder(OrderRequest request) async {
    final saga = SagaOrchestrator();
    
    saga.addStep(CreateOrderStep(orderRepo));
    saga.addStep(ReserveInventoryStep(inventoryService));
    saga.addStep(ProcessPaymentStep(paymentService));
    saga.addStep(SendNotificationStep(notificationService));
    
    final result = await saga.execute();
    return result.fold(
      (failure) => Left(failure),
      (_) => Right(order.id),
    );
  }
}
```

---

## 4. Specification Pattern

### 4.1 개념

비즈니스 규칙을 재사용 가능한 객체로 캡슐화합니다.

```dart
abstract class Specification<T> {
  bool isSatisfiedBy(T candidate);
  
  Specification<T> and(Specification<T> other) => AndSpecification(this, other);
  Specification<T> or(Specification<T> other) => OrSpecification(this, other);
  Specification<T> not() => NotSpecification(this);
}

class AndSpecification<T> extends Specification<T> {
  final Specification<T> left, right;
  
  AndSpecification(this.left, this.right);
  
  @override
  bool isSatisfiedBy(T candidate) {
    return left.isSatisfiedBy(candidate) && right.isSatisfiedBy(candidate);
  }
}
```

### 4.2 구체적인 Specification

```dart
class OrderIsPendingSpec extends Specification<Order> {
  @override
  bool isSatisfiedBy(Order order) => order.status == OrderStatus.pending;
}

class OrderTotalAboveSpec extends Specification<Order> {
  final Money threshold;
  
  OrderTotalAboveSpec(this.threshold);
  
  @override
  bool isSatisfiedBy(Order order) {
    return order.calculateTotal().amount > threshold.amount;
  }
}

// 조합 사용
void main() {
  final order = Order(/* ... */);
  
  final eligibleForDiscount = OrderIsPendingSpec()
    .and(OrderTotalAboveSpec(Money(100, 'USD')));
  
  if (eligibleForDiscount.isSatisfiedBy(order)) {
    print('Discount can be applied!');
  }
}
```

### 4.3 Repository와 통합

```dart
abstract class OrderRepository {
  Future<List<Order>> findBySpecification(Specification<Order> spec);
}

class OrderRepositoryImpl implements OrderRepository {
  @override
  Future<List<Order>> findBySpecification(Specification<Order> spec) async {
    final allOrders = await findAll();
    return allOrders.where(spec.isSatisfiedBy).toList();
  }
}
```

---

## 5. CQRS Pattern

### 5.1 개념

Command(쓰기)와 Query(읽기)를 분리합니다.

```
Command Side                  Query Side
┌──────────────┐            ┌──────────────┐
│  Command     │            │   Query      │
│  Handler     │            │   Handler    │
│      ↓       │            │      ↓       │
│ Write Model  │──Events──→ │  Read Model  │
│ (Normalized) │            │(Denormalized)│
└──────────────┘            └──────────────┘
```

### 5.2 Command 구현

```dart
abstract class Command {}

class CreateOrderCommand extends Command {
  final String customerId;
  final List<OrderItem> items;
  
  CreateOrderCommand(this.customerId, this.items);
}

abstract class CommandHandler<T extends Command, R> {
  Future<Either<Failure, R>> handle(T command);
}

class CreateOrderCommandHandler 
    implements CommandHandler<CreateOrderCommand, String> {
  final OrderRepository repository;
  final EventPublisher eventPublisher;
  
  CreateOrderCommandHandler(this.repository, this.eventPublisher);
  
  @override
  Future<Either<Failure, String>> handle(CreateOrderCommand cmd) async {
    final order = Order.create(cmd.customerId, cmd.items);
    
    await repository.save(order);
    
    await eventPublisher.publish(OrderCreatedEvent(order.id));
    
    return Right(order.id);
  }
}
```

### 5.3 Query 구현

```dart
abstract class Query<R> {}

class GetOrderDetailsQuery extends Query<OrderDetailsDto> {
  final String orderId;
  GetOrderDetailsQuery(this.orderId);
}

abstract class QueryHandler<T extends Query<R>, R> {
  Future<Either<Failure, R>> handle(T query);
}

class GetOrderDetailsQueryHandler 
    implements QueryHandler<GetOrderDetailsQuery, OrderDetailsDto> {
  final OrderReadRepository readRepo;
  
  GetOrderDetailsQueryHandler(this.readRepo);
  
  @override
  Future<Either<Failure, OrderDetailsDto>> handle(
    GetOrderDetailsQuery query,
  ) async {
    final dto = await readRepo.getOrderDetails(query.orderId);
    return dto != null ? Right(dto) : Left(NotFoundFailure());
  }
}
```

### 5.4 CQRS Bus

```dart
class CQRSBus {
  final Map<Type, CommandHandler> _commandHandlers = {};
  final Map<Type, QueryHandler> _queryHandlers = {};
  
  void registerCommand<T extends Command, R>(CommandHandler<T, R> handler) {
    _commandHandlers[T] = handler;
  }
  
  void registerQuery<T extends Query<R>, R>(QueryHandler<T, R> handler) {
    _queryHandlers[T] = handler;
  }
  
  Future<Either<Failure, R>> send<T extends Command, R>(T command) async {
    final handler = _commandHandlers[T] as CommandHandler<T, R>?;
    if (handler == null) throw StateError('No handler for $T');
    return handler.handle(command);
  }
  
  Future<Either<Failure, R>> query<T extends Query<R>, R>(T query) async {
    final handler = _queryHandlers[T] as QueryHandler<T, R>?;
    if (handler == null) throw StateError('No handler for $T');
    return handler.handle(query);
  }
}
```

---

## 6. Event Sourcing

### 6.1 개념

상태 대신 이벤트를 저장합니다.

```
Traditional                Event Sourcing
┌─────────┐               ┌───────────────┐
│ Current │               │ Event Stream  │
│  State  │               │ 1. Created    │
│ status: │               │ 2. Confirmed  │
│ SHIPPED │               │ 3. Shipped    │
└─────────┘               └───────────────┘
                                 ↓ Replay
                          ┌─────────────┐
                          │   Current   │
                          │    State    │
                          └─────────────┘
```

### 6.2 Event Store

```dart
abstract class DomainEvent {
  final String aggregateId;
  final int version;
  final DateTime occurredAt;
  
  DomainEvent(this.aggregateId, this.version, this.occurredAt);
  
  Map<String, dynamic> toJson();
  String get eventType;
}

class OrderCreatedEvent extends DomainEvent {
  final String customerId;
  final List<OrderItem> items;
  
  OrderCreatedEvent(String aggregateId, int version, this.customerId, this.items)
    : super(aggregateId, version, DateTime.now());
  
  @override
  String get eventType => 'OrderCreated';
  
  @override
  Map<String, dynamic> toJson() => {
    'aggregateId': aggregateId,
    'version': version,
    'customerId': customerId,
    'items': items.map((i) => i.toJson()).toList(),
  };
}

abstract class EventStore {
  Future<void> saveEvents(String aggregateId, List<DomainEvent> events, int expectedVersion);
  Future<List<DomainEvent>> getEvents(String aggregateId);
}
```

### 6.3 Event Sourced Aggregate

```dart
class EventSourcedOrder {
  final String id;
  int version = 0;
  final List<DomainEvent> uncommittedEvents = [];
  
  String? customerId;
  List<OrderItem> items = [];
  OrderStatus status = OrderStatus.pending;
  
  EventSourcedOrder(this.id);
  
  factory EventSourcedOrder.create(String id, String customerId, List<OrderItem> items) {
    final order = EventSourcedOrder(id);
    final event = OrderCreatedEvent(id, 1, customerId, items);
    order._applyEvent(event, isNew: true);
    return order;
  }
  
  void confirm() {
    if (status != OrderStatus.pending) {
      throw StateError('Can only confirm pending orders');
    }
    final event = OrderConfirmedEvent(id, version + 1);
    _applyEvent(event, isNew: true);
  }
  
  void _applyEvent(DomainEvent event, {bool isNew = false}) {
    if (event is OrderCreatedEvent) {
      customerId = event.customerId;
      items = event.items;
      status = OrderStatus.pending;
    } else if (event is OrderConfirmedEvent) {
      status = OrderStatus.confirmed;
    }
    
    version = event.version;
    if (isNew) uncommittedEvents.add(event);
  }
  
  void loadFromHistory(List<DomainEvent> history) {
    for (final event in history) {
      _applyEvent(event);
    }
  }
}
```

### 6.4 Snapshot 최적화

```dart
class Snapshot {
  final String aggregateId;
  final int version;
  final Map<String, dynamic> state;
  
  Snapshot(this.aggregateId, this.version, this.state);
}

class SnapshotStore {
  Future<Snapshot?> getLatest(String aggregateId) async {
    // Load latest snapshot from DB
  }
  
  Future<void> save(Snapshot snapshot) async {
    // Save snapshot to DB
  }
}

class OptimizedEventSourcedRepository {
  final EventStore eventStore;
  final SnapshotStore snapshotStore;
  
  OptimizedEventSourcedRepository(this.eventStore, this.snapshotStore);
  
  Future<EventSourcedOrder?> load(String orderId) async {
    // 1. Load latest snapshot
    final snapshot = await snapshotStore.getLatest(orderId);
    
    EventSourcedOrder order;
    int fromVersion;
    
    if (snapshot != null) {
      order = EventSourcedOrder(orderId);
      _restoreFromSnapshot(order, snapshot);
      fromVersion = snapshot.version;
    } else {
      order = EventSourcedOrder(orderId);
      fromVersion = 0;
    }
    
    // 2. Load events since snapshot
    final events = await eventStore.getEventsSince(orderId, fromVersion);
    order.loadFromHistory(events);
    
    return order;
  }
}
```

---

## 7. 패턴 비교 및 선택 가이드

### 7.1 복잡도 비교

| 패턴 | 복잡도 | 학습 곡선 | 적용 시기 |
|------|--------|----------|----------|
| **DDD** | 높음 | 높음 | 복잡한 비즈니스 로직 |
| **Hexagonal** | 중간 | 중간 | 외부 의존성 많을 때 |
| **Saga** | 높음 | 높음 | 분산 트랜잭션 필요 |
| **Specification** | 낮음 | 낮음 | 복잡한 필터링/검증 |
| **CQRS** | 중간 | 중간 | 읽기/쓰기 비율 차이 |
| **Event Sourcing** | 매우 높음 | 매우 높음 | 감사 로그 필수 |

### 7.2 시나리오별 선택

| 시나리오 | 추천 패턴 |
|---------|----------|
| 금융 거래 앱 | DDD + Event Sourcing + CQRS |
| E-Commerce | DDD + Hexagonal + Saga |
| 소셜 미디어 | CQRS + Specification |
| IoT 데이터 | Event Sourcing + CQRS |
| 간단한 CRUD | Repository + Clean Architecture |

### 7.3 성능 영향

| 패턴 | 읽기 성능 | 쓰기 성능 | 메모리 사용 |
|------|----------|----------|------------|
| DDD | 보통 | 보통 | 보통 |
| Hexagonal | 보통 | 보통 | 보통 |
| Saga | 낮음 | 낮음 | 높음 |
| Specification | 높음 | - | 낮음 |
| CQRS | 매우 높음 | 보통 | 높음 |
| Event Sourcing | 낮음* | 높음 | 매우 높음 |

*Snapshot 사용 시 개선

### 7.4 조합 패턴

**권장 조합:**
- DDD + Hexagonal (기본)
- DDD + Hexagonal + CQRS (확장성)
- DDD + Hexagonal + Event Sourcing + CQRS (금융/의료)
- Specification + Repository (어디든 적용 가능)

**피해야 할 조합:**
- Event Sourcing 단독 (너무 복잡)
- Saga + Event Sourcing (오버엔지니어링)

---

## 8. 관련 문서

### 8.1 크로스 레퍼런스

| 문서 | 관련 패턴 | 설명 |
|------|----------|------|
| Architecture.md | DDD, Hexagonal | Clean Architecture 기본 |
| Bloc.md | CQRS, Event Sourcing | 상태 관리 통합 |
| Fpdart.md | 모든 패턴 | Either, Option 활용 |
| DI.md | Hexagonal | Port/Adapter 설정 |
| Testing.md | 모든 패턴 | 패턴별 테스트 전략 |

### 8.2 학습 경로

**초급 (0-2년):**
1. Clean Architecture
2. Repository Pattern
3. Specification Pattern

**중급 (2-5년):**
1. DDD (Entity, Value Object, Aggregate)
2. Hexagonal Architecture
3. CQRS (간단한 분리)

**고급 (5-10년):**
1. DDD (Bounded Context, Context Mapping)
2. Event Sourcing
3. Saga Pattern

**시니어 (10년+):**
1. 패턴 조합 및 트레이드오프
2. 팀 역량 고려한 패턴 선택
3. 성능과 유지보수성 균형

---

## 마치며

고급 패턴은 강력하지만 **과도한 적용은 복잡도를 증가**시킵니다.

**핵심 원칙:**
- YAGNI: 필요할 때 추가
- Evolutionary Architecture: 점진적 도입
- Team Skill: 팀 역량 고려
- Business Value: 가치 중심

대부분의 Flutter 앱은 **DDD + Hexagonal + Bloc**으로 충분합니다.

Happy Coding! 🚀
