# Flutter 성능 최적화 가이드

## 개요

Flutter 앱의 성능은 사용자 경험을 결정하는 핵심 요소입니다. 렌더링 파이프라인 이해, 메모리 관리, 효율적인 비동기 처리를 통해 부드러운 60fps(또는 120fps) 유지와 배터리 소비 최소화를 달성할 수 있습니다.

### 성능 측정 지표

| 지표 | 목표값 | 설명 |
|------|--------|------|
| **FPS (Frame Per Second)** | 60fps (일반), 120fps (고주사율) | 초당 렌더링 프레임 수 |
| **Jank** | 0개 | 프레임 드롭으로 인한 끊김 현상 |
| **Memory (메모리)** | 150MB 이하 (시작 시) | 앱 메모리 사용량 |
| **UI 응답성** | < 100ms | 사용자 입력에 대한 응답 시간 |
| **앱 시작 시간** | < 3초 | 콜드 스타트 시간 |

### Flutter 렌더링 파이프라인

```
1. Build Phase
   - Widget 빌드 (build() 호출)
   - RenderObject 생성

2. Layout Phase
   - 위젯 크기/위치 계산
   - Constraints 적용

3. Paint Phase
   - 캔버스에 그리기
   - Layer 구성

4. Composite Phase
   - GPU에 최종 이미지 렌더링
   - 화면 디스플레이
```

각 단계에서 병목이 발생하면 프레임이 16ms(60fps) 또는 8ms(120fps) 내에 완료되지 못해 Jank가 발생합니다.

---

## 렌더링 최적화

### 1. const 생성자 활용

const 생성자는 위젯이 동일한 파라미터를 가질 때 메모리에서 재사용되므로 불필요한 rebuild를 방지합니다.

```dart
// ✅ const 생성자 사용 (Dart 2.17+ super parameters 권장)
class ProductCard extends StatelessWidget {
  final String title;
  final String price;

  const ProductCard({
    super.key,  // Dart 2.17+ 권장 패턴
    required this.title,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // const 생성자 사용
          const SizedBox(height: 16),
          Text(title),
          Text(price),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ✅ 사용할 때도 const로
class ProductList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ProductCard(title: '상품1', price: '10,000원'),
        ProductCard(title: '상품2', price: '20,000원'),
      ],
    );
  }
}

// ❌ 잘못된 예 - const 누락
class BadProductList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ProductCard(title: '상품1', price: '10,000원'),  // 매번 rebuild
        ProductCard(title: '상품2', price: '20,000원'),
      ],
    );
  }
}
```

### 2. RepaintBoundary 사용

복잡한 위젯 트리에서 특정 부분만 repainting되도록 격리하여 성능을 향상시킵니다.

```dart
class ComplexListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 1000,
      itemBuilder: (context, index) {
        // 복잡한 위젯을 RepaintBoundary로 감싸기
        return RepaintBoundary(
          key: ValueKey(index),
          child: ComplexListItem(index: index),
        );
      },
    );
  }
}

class ComplexListItem extends StatelessWidget {
  final int index;

  const ComplexListItem({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    // 복잡한 계산 또는 렌더링
    return Card(
      child: Column(
        children: [
          Image.network('https://.../$index'),
          Text('아이템 $index'),
          _buildComplexGradient(),
          _buildCustomPaint(),
        ],
      ),
    );
  }

  Widget _buildComplexGradient() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: List.generate(
            100,
            (i) => Color.lerp(Colors.blue, Colors.red, i / 100)!,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPaint() {
    return CustomPaint(
      painter: ComplexPainter(index),
      size: const Size(200, 100),
    );
  }
}

class ComplexPainter extends CustomPainter {
  final int index;

  ComplexPainter(this.index);

  @override
  void paint(Canvas canvas, Size size) {
    // 복잡한 그리기 작업
    final paint = Paint()..color = Colors.blue;
    for (int i = 0; i < 100; i++) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        10.0 + i,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ComplexPainter oldDelegate) => oldDelegate.index != index;
}
```

### 3. ListView.builder vs ListView

대량의 데이터를 표시할 때 반드시 `ListView.builder` 또는 `ListView.separated`를 사용합니다.

```dart
// ❌ 성능 나쁨 - 모든 위젯을 메모리에 로드
class BadLargeList extends StatelessWidget {
  final List<String> items = List.generate(10000, (i) => '아이템 $i');

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: items.map((item) => ListTile(title: Text(item))).toList(),
    );
  }
}

// ✅ 성능 우수 - 화면에 보이는 아이템만 렌더링
class GoodLargeList extends StatelessWidget {
  final List<String> items = List.generate(10000, (i) => '아이템 $i');

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(items[index]),
          trailing: const Icon(Icons.arrow_forward),
        );
      },
    );
  }
}

// ✅ 더 나은 성능 - 구분선 포함
class BetterLargeList extends StatelessWidget {
  final List<String> items = List.generate(10000, (i) => '아이템 $i');

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(items[index]));
      },
      separatorBuilder: (context, index) {
        return const Divider(height: 1);
      },
    );
  }
}

// ✅ GridView 최적화
class GoodLargeGrid extends StatelessWidget {
  final List<String> items = List.generate(1000, (i) => '아이템 $i');

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          child: Center(child: Text(items[index])),
        );
      },
    );
  }
}
```

### 4. 불필요한 Rebuild 방지

#### Bloc selector와 context.select 활용

```dart
// ❌ 성능 나쁨 - 전체 상태 변경 시 rebuild
class BadProductScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        return Column(
          children: [
            // 가격만 사용하는데 전체 상태 변경 시 rebuild
            Text('가격: ${state.price}'),
            // 재고만 사용
            Text('재고: ${state.inventory}'),
          ],
        );
      },
    );
  }
}

// ✅ 성능 좋음 - 필요한 부분만 선택
class GoodProductScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 가격만 선택하여 변경될 때만 rebuild
        BlocSelector<ProductBloc, ProductState, String>(
          selector: (state) => state.price,
          builder: (context, price) {
            return Text('가격: $price');
          },
        ),
        // 재고만 선택
        BlocSelector<ProductBloc, ProductState, int>(
          selector: (state) => state.inventory,
          builder: (context, inventory) {
            return Text('재고: $inventory');
          },
        ),
      ],
    );
  }
}

// ✅ context.select 사용 (Flutter 3.0+)
class ModernProductScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 간결한 문법
        Text('가격: ${context.select<ProductBloc, String>((bloc) => bloc.state.price)}'),
        Text('재고: ${context.select<ProductBloc, int>((bloc) => bloc.state.inventory)}'),
      ],
    );
  }
}
```

#### 상태 분리

```dart
// ❌ 성능 나쁨 - 한 상태에 여러 속성
@freezed
class ProductState with _$ProductState {
  const factory ProductState({
    required List<Product> products,
    required int selectedIndex,
    required bool isLoading,
    required bool isFavorite,
    required int cartCount,
    required double totalPrice,
  }) = _ProductState;
}

// ✅ 성능 좋음 - 관심사별로 상태 분리
@freezed
class ProductListState with _$ProductListState {
  const factory ProductListState({
    required List<Product> products,
    required bool isLoading,
  }) = _ProductListState;
}

@freezed
class ProductDetailState with _$ProductDetailState {
  const factory ProductDetailState({
    required Product product,
    required bool isFavorite,
    required int cartCount,
  }) = _ProductDetailState;
}

@freezed
class CartState with _$CartState {
  const factory CartState({
    required double totalPrice,
    required int itemCount,
  }) = _CartState;
}
```

---

## 메모리 최적화

### 1. 이미지 캐싱 전략

```dart
// pubspec.yaml
dependencies:
  cached_network_image: ^3.4.1

// ✅ 이미지 캐싱 (URL 기반)
class CachedProductImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;

  const CachedProductImage({
    super.key,
    required this.imageUrl,
    this.width = 200,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      // 로딩 중 표시
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      ),
      // 에러 표시
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.error),
      ),
    );
  }
}

// ✅ 이미지 캐시 관리
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();

  factory ImageCacheManager() {
    return _instance;
  }

  ImageCacheManager._internal();

  /// 메모리에 캐싱된 이미지 개수 확인
  int get cachedImageCount => imageCache.currentSize;

  /// 최대 메모리 크기 설정 (기본 100MB)
  void setMaxCacheSize(int bytes) {
    imageCache.maximumSizeBytes = bytes;  // 바이트 단위
    // maximumSize는 이미지 개수 제한 (예: imageCache.maximumSize = 100)
  }

  /// 특정 이미지 캐시 제거
  void evictImage(String imageUrl) {
    imageCache.evict(NetworkImage(imageUrl));
  }

  /// 모든 이미지 캐시 제거
  void clearCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  /// 백그라운드에서 주기적으로 캐시 정리
  Timer? _cleanupTimer;

  void setupAutoCleanup({Duration interval = const Duration(minutes: 10)}) {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(interval, (_) {
      clearCache();
    });
  }

  void dispose() {
    _cleanupTimer?.cancel();
  }
}

// ✅ 사용
class ProductListPage extends StatefulWidget {
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  @override
  void initState() {
    super.initState();
    // 이미지 캐시 크기 제한 설정
    ImageCacheManager().setMaxCacheSize(50 * 1024 * 1024); // 50MB
  }

  @override
  void dispose() {
    // 필요시 캐시 정리
    ImageCacheManager().clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return CachedProductImage(
          imageUrl: 'https://example.com/product/$index.jpg',
        );
      },
    );
  }
}
```

### 2. 대용량 리스트 처리

```dart
// ✅ 페이지네이션 구현
@freezed
class PaginatedListState with _$PaginatedListState {
  const factory PaginatedListState({
    required List<Product> items,
    required bool isLoading,
    required bool hasMore,
    required int currentPage,
  }) = _PaginatedListState;

  factory PaginatedListState.initial() => const PaginatedListState(
    items: [],
    isLoading: false,
    hasMore: true,
    currentPage: 1,
  );
}

@freezed
class PaginatedListEvent with _$PaginatedListEvent {
  const factory PaginatedListEvent.loadMore() = _LoadMore;
  const factory PaginatedListEvent.refresh() = _Refresh;
}

class PaginatedListBloc extends Bloc<PaginatedListEvent, PaginatedListState> {
  final GetProductsUseCase _getProductsUseCase;
  static const int _pageSize = 20;

  PaginatedListBloc({required GetProductsUseCase getProductsUseCase})
      : _getProductsUseCase = getProductsUseCase,
        super(PaginatedListState.initial()) {
    on<_LoadMore>(_onLoadMore);
    on<_Refresh>(_onRefresh);
  }

  Future<void> _onLoadMore(
    _LoadMore event,
    Emitter<PaginatedListState> emit,
  ) async {
    if (state.isLoading || !state.hasMore) return;

    emit(state.copyWith(isLoading: true));

    final result = await _getProductsUseCase(
      page: state.currentPage + 1,
      pageSize: _pageSize,
    );

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false)),
      (newItems) {
        final hasMore = newItems.length == _pageSize;
        emit(state.copyWith(
          items: [...state.items, ...newItems],
          isLoading: false,
          hasMore: hasMore,
          currentPage: state.currentPage + 1,
        ));
      },
    );
  }

  Future<void> _onRefresh(
    _Refresh event,
    Emitter<PaginatedListState> emit,
  ) async {
    emit(PaginatedListState.initial().copyWith(isLoading: true));

    final result = await _getProductsUseCase(page: 1, pageSize: _pageSize);

    result.fold(
      (failure) => emit(PaginatedListState.initial()),
      (items) {
        final hasMore = items.length == _pageSize;
        emit(PaginatedListState.initial().copyWith(
          items: items,
          hasMore: hasMore,
        ));
      },
    );
  }
}

// ✅ 무한 스크롤 UI
class PaginatedListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaginatedListBloc, PaginatedListState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<PaginatedListBloc>().add(const PaginatedListEvent.refresh());
          },
          child: ListView.builder(
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // 마지막 아이템에 도달했을 때 다음 페이지 로드
              if (index == state.items.length) {
                return _buildLoadMoreButton(context, state);
              }

              return ProductListTile(product: state.items[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreButton(BuildContext context, PaginatedListState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: state.isLoading
          ? const CircularProgressIndicator()
          : ElevatedButton(
              onPressed: () {
                context.read<PaginatedListBloc>().add(const PaginatedListEvent.loadMore());
              },
              child: const Text('더 불러오기'),
            ),
    );
  }
}
```

### 3. Dispose 패턴

```dart
// ✅ StreamSubscription 관리
class DataSyncManager extends ChangeNotifier {
  late StreamSubscription _subscription;

  DataSyncManager(Stream<Data> dataStream) {
    _subscription = dataStream.listen((data) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    // 리소스 정리
    _subscription.cancel();
    super.dispose();
  }
}

// ✅ Timer 관리
class CountdownTimer extends StatefulWidget {
  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer.cancel();  // 중요: Timer 취소
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();  // 위젯 제거 시 Timer 취소
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('남은 시간: $_secondsRemaining초');
  }
}

// ✅ Bloc에서 StreamSubscription 관리
class DataBloc extends Bloc<DataEvent, DataState> {
  final DataRepository _repository;
  StreamSubscription<Data>? _subscription;

  DataBloc({required DataRepository repository})
      : _repository = repository,
        super(DataState.initial()) {
    on<StartListening>(_onStartListening);
  }

  Future<void> _onStartListening(
    StartListening event,
    Emitter<DataState> emit,
  ) async {
    // 기존 구독 취소
    await _subscription?.cancel();

    _subscription = _repository.dataStream.listen((data) {
      emit(DataState.loaded(data));
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();  // Bloc 종료 시 구독 취소
    return super.close();
  }
}
```

### 4. 메모리 누수 방지

```dart
// ❌ 메모리 누수 - 리스너 정리 안 함
class BadLifecycleWidget extends StatefulWidget {
  @override
  State<BadLifecycleWidget> createState() => _BadLifecycleWidgetState();
}

class _BadLifecycleWidgetState extends State<BadLifecycleWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);  // 리스너 추가
    // dispose에서 정리하지 않음! 메모리 누수
  }

  @override
  Widget build(BuildContext context) => Container();
}

// ✅ 올바른 패턴 - 리스너 정리
class GoodLifecycleWidget extends StatefulWidget {
  @override
  State<GoodLifecycleWidget> createState() => _GoodLifecycleWidgetState();
}

class _GoodLifecycleWidgetState extends State<GoodLifecycleWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);  // 필수!
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 처리
  }

  @override
  Widget build(BuildContext context) => Container();
}

// ✅ ValueNotifier 메모리 누수 방지
class SearchWidget extends StatefulWidget {
  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  late final ValueNotifier<String> _searchQuery = ValueNotifier('');

  @override
  void dispose() {
    _searchQuery.dispose();  // 필수!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (value) => _searchQuery.value = value,
    );
  }
}

// ✅ 메모리 누수 감지 도구
class MemoryMonitor {
  static final MemoryMonitor _instance = MemoryMonitor._();

  factory MemoryMonitor() => _instance;

  MemoryMonitor._();

  Future<void> logMemoryUsage() async {
    // DevTools에서 메모리 모니터링 활용
    // import 'package:flutter/foundation.dart';
    if (kDebugMode) {
      print('Memory usage: ${await _getMemoryUsage()}');
    }
  }

  Future<String> _getMemoryUsage() async {
    // Platform-specific 메모리 정보 수집
    return 'Memory info';
  }
}
```

---

## 비동기 작업 최적화

### 1. Isolate 활용 (compute)

```dart
import 'dart:isolate';
import 'package:flutter/foundation.dart';  // compute 함수 포함

// ✅ 오래 걸리는 계산을 Isolate에서 처리
Future<String> _expensiveComputation(int count) async {
  // 무거운 계산 (메인 스레드 블로킹)
  int sum = 0;
  for (int i = 0; i < count; i++) {
    sum += i;
  }
  return 'Result: $sum';
}

// ✅ compute 함수로 Isolate에서 실행
class ComputeExamplePage extends StatefulWidget {
  @override
  State<ComputeExamplePage> createState() => _ComputeExamplePageState();
}

class _ComputeExamplePageState extends State<ComputeExamplePage> {
  String _result = '계산 중...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performComputation();
  }

  Future<void> _performComputation() async {
    try {
      final result = await compute(_expensiveComputation, 1000000000);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = '계산 실패: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Isolate 예제')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Text(_result),
      ),
    );
  }
}

// ✅ 복잡한 JSON 파싱을 Isolate에서 처리
Future<List<Product>> _parseJsonInIsolate(String jsonString) async {
  final json = jsonDecode(jsonString) as List<dynamic>;
  return json
      .map((item) => Product.fromJson(item as Map<String, dynamic>))
      .toList();
}

class JsonParsingExample extends StatefulWidget {
  @override
  State<JsonParsingExample> createState() => _JsonParsingExampleState();
}

class _JsonParsingExampleState extends State<JsonParsingExample> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    try {
      final jsonString = await _loadJsonFile();
      // 큰 JSON 파싱을 별도 Isolate에서 처리
      final products = await compute(_parseJsonInIsolate, jsonString);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('파싱 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<String> _loadJsonFile() async {
    // JSON 파일 로드
    // import 'package:flutter/services.dart';
    final data = await rootBundle.loadString('assets/products.json');
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JSON 파싱')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_products[index].name),
                  subtitle: Text(_products[index].description),
                );
              },
            ),
    );
  }
}
```

### 2. Stream 최적화

```dart
// ❌ 비효율적 - 매번 새로운 Stream 생성
class BadStreamWidget extends StatefulWidget {
  @override
  State<BadStreamWidget> createState() => _BadStreamWidgetState();
}

class _BadStreamWidgetState extends State<BadStreamWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),  // 매번 새로 생성
      builder: (context, snapshot) {
        return Text('Count: ${snapshot.data}');
      },
    );
  }
}

// ✅ 효율적 - Stream 재사용
class GoodStreamWidget extends StatefulWidget {
  @override
  State<GoodStreamWidget> createState() => _GoodStreamWidgetState();
}

class _GoodStreamWidgetState extends State<GoodStreamWidget> {
  late final Stream<int> _countStream;

  @override
  void initState() {
    super.initState();
    // Stream을 한 번만 생성하여 재사용
    _countStream = Stream.periodic(
      const Duration(seconds: 1),
      (i) => i,
    ).asBroadcastStream();  // 여러 listener 지원
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _countStream,
      builder: (context, snapshot) {
        return Text('Count: ${snapshot.data}');
      },
    );
  }
}

// ✅ broadcast Stream 활용
class BroadcastStreamExample {
  final _eventController = StreamController<String>.broadcast();

  Stream<String> get eventStream => _eventController.stream;

  void addEvent(String event) {
    _eventController.add(event);
  }

  void dispose() {
    _eventController.close();
  }
}

// ✅ Stream 변환 최적화
// rxdart 패키지 import 필요
// import 'package:rxdart/rxdart.dart';
// import 'dart:convert';
class StreamTransformExample extends StatelessWidget {
  final _repository = DataRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Data>>(
      stream: _repository.dataStream
          // 중복 데이터 제거
          .distinct((previous, next) =>
              jsonEncode(previous) == jsonEncode(next))
          // 0.5초 단위로 배치 처리
          .throttleTime(const Duration(milliseconds: 500))
          // 최신 10개만 유지
          .scan<List<Data>>(
            (previous, current) => [
              ...previous.take(9),
              current,
            ],
            <Data>[],  // seed (초기값)
          ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return DataTile(data: snapshot.data![index]);
          },
        );
      },
    );
  }
}
```

### 3. 디바운싱 / 쓰로틀링

```dart
// ✅ 검색 입력 디바운싱
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository _repository;

  SearchBloc({required SearchRepository repository})
      : _repository = repository,
        super(SearchState.initial()) {
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      // 입력이 0.5초 동안 없을 때만 처리
      transformer: debounceTime(const Duration(milliseconds: 500)),
    );
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchState.loading(event.query));

    final result = await _repository.search(event.query);

    result.fold(
      (failure) => emit(SearchState.error(failure.message)),
      (results) => emit(SearchState.loaded(results)),
    );
  }
}

// EventTransformer 구현
EventTransformer<T> debounceTime<T>(Duration duration) {
  return (events, mapper) => events
      .debounceTime(duration)
      .flatMap(mapper);
}

// ✅ 스크롤 이벤트 쓰로틀링
class ScrollThrottlingPage extends StatefulWidget {
  @override
  State<ScrollThrottlingPage> createState() => _ScrollThrottlingPageState();
}

class _ScrollThrottlingPageState extends State<ScrollThrottlingPage> {
  late ScrollController _scrollController;
  int _loadCount = 0;
  DateTime _lastLoadTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // 스크롤 이벤트를 250ms 단위로 쓰로틀링
    final now = DateTime.now();
    if (now.difference(_lastLoadTime).inMilliseconds < 250) {
      return;
    }

    _lastLoadTime = now;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      // 더 불러오기
      setState(() => _loadCount++);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _loadCount * 20 + 1,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('아이템 $index'),
        );
      },
    );
  }
}

// ✅ 버튼 클릭 디바운싱
class DebouncedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Duration duration;

  const DebouncedButton({
    required this.onPressed,
    this.duration = const Duration(seconds: 1),
  });

  @override
  State<DebouncedButton> createState() => _DebouncedButtonState();
}

class _DebouncedButtonState extends State<DebouncedButton> {
  bool _canPress = true;

  void _onPressed() {
    if (!_canPress) return;

    widget.onPressed();

    setState(() => _canPress = false);
    Future.delayed(widget.duration, () {
      if (mounted) {
        setState(() => _canPress = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _canPress ? _onPressed : null,
      child: const Text('전송'),
    );
  }
}
```

---

## 프로파일링 도구

### 1. DevTools Performance 탭

```bash
# DevTools 실행
fvm flutter pub global run devtools

# 또는 직접
fvm flutter devtools

# 앱 연결
fvm flutter run
# DevTools URL: http://localhost:9100
```

**Performance 탭에서 확인할 항목:**
- Frame 렌더링 시간 (16ms 이하가 목표)
- 빌드/레이아웃/페인트 시간 분석
- Jank 감지 및 원인 파악

### 2. Performance Overlay

```dart
// ✅ 성능 오버레이 활성화
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: true,  // 상단 FPS 표시
      home: HomePage(),
    );
  }
}

// 혹은 런타임에 활성화
class PerformanceTogglePage extends StatefulWidget {
  @override
  State<PerformanceTogglePage> createState() => _PerformanceTogglePageState();
}

class _PerformanceTogglePageState extends State<PerformanceTogglePage> {
  bool _showOverlay = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: _showOverlay,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('성능 모니터링'),
          actions: [
            IconButton(
              icon: const Icon(Icons.speed),
              onPressed: () => setState(() => _showOverlay = !_showOverlay),
            ),
          ],
        ),
        body: Center(
          child: Text('Overlay: $_showOverlay'),
        ),
      ),
    );
  }
}
```

성능 오버레이의 색상 의미:
- **녹색**: 프레임이 16ms 이내에 완료 (60fps)
- **빨강**: 프레임이 16ms 이상 소요 (Jank 발생)

### 3. 릴리즈 모드에서 테스트

```bash
# 릴리즈 모드로 실행 (최적화된 성능)
fvm flutter run --release

# 프로파일 모드 (릴리즈 최적화 + 디버깅 정보)
fvm flutter run --profile

# APK/IPA 빌드
fvm flutter build apk --release
fvm flutter build ios --release
```

릴리즈 모드에서의 성능:
- 디버그 모드보다 3-10배 빠름
- 모든 최적화 활성화
- Dart AOT 컴파일

---

## Bloc 성능 최적화

### 1. buildWhen 활용

```dart
// ❌ 성능 나쁨 - 모든 상태 변경 시 rebuild
class BadProductCounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        return Text('총 ${state.items.length}개');  // items 변경할 때만 필요한데...
      },
    );
  }
}

// ✅ 성능 좋음 - 특정 속성 변경할 때만 rebuild
class GoodProductCounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (previous, current) {
        // items 길이가 변경되었을 때만 rebuild
        return previous.items.length != current.items.length;
      },
      builder: (context, state) {
        return Text('총 ${state.items.length}개');
      },
    );
  }
}

// ✅ 더 나은 패턴 - items와 isLoading만 감시
class OptimizedProductListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (previous, current) {
        // items 또는 isLoading이 변경되었을 때만
        return previous.items != current.items ||
            previous.isLoading != current.isLoading;
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const CircularProgressIndicator();
        }
        return ListView.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            return ProductTile(product: state.items[index]);
          },
        );
      },
    );
  }
}
```

### 2. Equatable 올바른 사용

```dart
// ❌ 성능 나쁨 - 비교 불가능한 리스트
@freezed
class BadProductState with _$BadProductState {
  const factory BadProductState({
    required List<Product> items,  // List 참조 비교만 가능
  }) = _BadProductState;
}

// ✅ 성능 좋음 - Equatable 활용
import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final double price;

  const Product({
    required this.id,
    required this.name,
    required this.price,
  });

  @override
  List<Object?> get props => [id, name, price];
}

@freezed
class GoodProductState with _$GoodProductState {
  const factory GoodProductState({
    required List<Product> items,
    required bool isLoading,
  }) = _GoodProductState;
}

// ✅ Freezed의 자동 Equatable (권장)
@freezed
class ProductStateFreezed with _$ProductStateFreezed {
  const factory ProductStateFreezed({
    required List<Product> items,
    required bool isLoading,
  }) = _ProductStateFreezed;
}

// 비교 최적화
final state1 = GoodProductState(
  items: [const Product(id: '1', name: '상품1', price: 10000)],
  isLoading: false,
);

final state2 = GoodProductState(
  items: [const Product(id: '1', name: '상품1', price: 10000)],
  isLoading: false,
);

print(state1 == state2);  // true (내용 기반 비교)
```

### 3. 상태 정규화

```dart
// ❌ 비정규화된 상태 - 중복 데이터
@freezed
class BadCatalogState with _$BadCatalogState {
  const factory BadCatalogState({
    required List<Category> categories,
    required List<Product> products,  // Category 정보 중복
    required List<Product> favoriteProducts,  // 다시 중복
  }) = _BadCatalogState;
}

// ✅ 정규화된 상태 - ID만 저장
@freezed
class GoodCatalogState with _$GoodCatalogState {
  const factory GoodCatalogState({
    required Map<String, Category> categoriesById,  // ID 기반 맵
    required Map<String, Product> productsById,    // ID 기반 맵
    required List<String> selectedProductIds,      // ID 리스트
    required List<String> favoriteProductIds,      // ID 리스트
  }) = _GoodCatalogState;

  factory GoodCatalogState.initial() => const GoodCatalogState(
    categoriesById: {},
    productsById: {},
    selectedProductIds: [],
    favoriteProductIds: [],
  );
}

extension GoodCatalogStateX on GoodCatalogState {
  /// ID로 상품 조회
  Product? getProduct(String id) => productsById[id];

  /// 선택된 상품 리스트
  List<Product> get selectedProducts =>
      selectedProductIds.map((id) => productsById[id]!).toList();

  /// 즐겨찾기 상품
  List<Product> get favoriteProducts =>
      favoriteProductIds.map((id) => productsById[id]!).toList();
}

// Bloc에서 활용
class CatalogBloc extends Bloc<CatalogEvent, GoodCatalogState> {
  final CatalogRepository _repository;

  CatalogBloc({required CatalogRepository repository})
      : _repository = repository,
        super(GoodCatalogState.initial()) {
    on<LoadCatalog>(_onLoadCatalog);
    on<SelectProduct>(_onSelectProduct);
    on<AddToFavorite>(_onAddToFavorite);
  }

  Future<void> _onLoadCatalog(
    LoadCatalog event,
    Emitter<GoodCatalogState> emit,
  ) async {
    final result = await _repository.getCatalog();

    result.fold(
      (failure) => emit(state),
      (catalog) {
        // 데이터 정규화
        final categoriesById = {
          for (var category in catalog.categories) category.id: category,
        };
        final productsById = {
          for (var product in catalog.products) product.id: product,
        };

        emit(state.copyWith(
          categoriesById: categoriesById,
          productsById: productsById,
        ));
      },
    );
  }

  Future<void> _onSelectProduct(
    SelectProduct event,
    Emitter<GoodCatalogState> emit,
  ) async {
    final newSelected = [...state.selectedProductIds, event.productId];
    emit(state.copyWith(selectedProductIds: newSelected));
  }

  Future<void> _onAddToFavorite(
    AddToFavorite event,
    Emitter<GoodCatalogState> emit,
  ) async {
    final newFavorites = {...state.favoriteProductIds, event.productId};
    emit(state.copyWith(favoriteProductIds: newFavorites.toList()));
  }
}

// UI에서 활용
class CatalogPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogBloc, GoodCatalogState>(
      buildWhen: (previous, current) {
        // 선택된 상품 ID만 변경 감시
        return previous.selectedProductIds != current.selectedProductIds;
      },
      builder: (context, state) {
        final selected = state.selectedProducts;
        return ListView.builder(
          itemCount: selected.length,
          itemBuilder: (context, index) {
            return ProductTile(product: selected[index]);
          },
        );
      },
    );
  }
}
```

---

## 13. Shader Compilation Jank 해결

### 13.1 Shader Jank란?

첫 렌더링 시 GPU 셰이더 컴파일로 인해 프레임 드롭이 발생합니다.
사용자에게 "앱이 버벅인다"는 인상을 줍니다.

### 13.2 SkSL Warm-up (Impeller 이전 방식)

```bash
# 1. 셰이더 캡처 모드로 앱 실행
flutter run --profile --cache-sksl

# 2. 앱의 모든 화면/애니메이션 탐색
# 3. 'M' 키로 flutter_01.sksl.json 저장

# 4. 프로덕션 빌드에 번들링
flutter build apk --bundle-sksl-path flutter_01.sksl.json
```

### 13.3 Impeller (Flutter 3.16+)

```dart
// Impeller는 셰이더를 미리 컴파일하여 jank 제거
// iOS: 기본 활성화 (Flutter 3.16+)
// Android: 기본 활성화 (Flutter 3.27+)

// AndroidManifest.xml에서 명시적 활성화
<meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="true" />
```

### 13.4 첫 프레임 최적화

```dart
void main() async {
  // 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 필수 초기화만 동기적으로
  await _initializeCritical();

  // 첫 프레임 렌더링
  runApp(const MyApp());

  // 나머지 초기화는 첫 프레임 이후
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeNonCritical();
  });
}

Future<void> _initializeCritical() async {
  // 로그인 상태, 테마 등 UI 렌더링에 필수적인 것만
  HydratedBloc.storage = await HydratedStorage.build();
}

void _initializeNonCritical() {
  // Analytics, Remote Config, 푸시 알림 등
  FirebaseAnalytics.instance.logAppOpen();
  RemoteConfigService.instance.fetch();
}
```

---

## 14. 앱 시작 시간 최적화

### 14.1 측정 방법

```dart
void main() {
  final stopwatch = Stopwatch()..start();

  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Binding: ${stopwatch.elapsedMilliseconds}ms');

  runApp(MyApp(onFirstFrame: () {
    debugPrint('First Frame: ${stopwatch.elapsedMilliseconds}ms');
  }));
}

class MyApp extends StatefulWidget {
  final VoidCallback? onFirstFrame;

  const MyApp({super.key, this.onFirstFrame});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFirstFrame?.call();
    });
  }
}
```

### 14.2 Lazy Initialization

```dart
// ❌ 잘못된 예: 앱 시작 시 모든 의존성 초기화
void main() async {
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await setupServiceLocator();
  await loadTranslations();
  await fetchRemoteConfig();
  runApp(MyApp()); // 3초+ 지연
}

// ✅ 올바른 예: 필요할 때 초기화
@lazySingleton
class RemoteConfigService {
  Completer<RemoteConfig>? _completer;

  Future<RemoteConfig> get config async {
    _completer ??= Completer()..complete(_initialize());
    return _completer!.future;
  }
}
```

### 14.3 앱 크기 최적화

```bash
# 앱 크기 분석
flutter build apk --analyze-size

# split-debug-info로 디버그 심볼 분리
flutter build apk --split-debug-info=debug-info/

# 미사용 리소스 제거
flutter pub run build_runner build --delete-conflicting-outputs
```

### 14.4 시작 시간 목표

| 등급 | Cold Start | Warm Start |
|-----|-----------|------------|
| 우수 | < 2초 | < 1초 |
| 보통 | 2-4초 | 1-2초 |
| 개선필요 | > 4초 | > 2초 |

---

## 체크리스트

- [ ] const 생성자 사용 확인
- [ ] ListView/GridView에 .builder 패턴 적용
- [ ] RepaintBoundary로 복잡한 위젯 격리
- [ ] BlocSelector 또는 context.select로 불필요한 rebuild 방지
- [ ] 이미지 캐싱 전략 적용
- [ ] 페이지네이션 구현
- [ ] StreamSubscription/Timer dispose 패턴
- [ ] WidgetsBindingObserver 리스너 정리
- [ ] 무거운 계산을 compute 함수로 Isolate 처리
- [ ] Stream 중복 생성 제거
- [ ] 검색/스크롤 이벤트 디바운싱/쓰로틀링
- [ ] DevTools Performance 탭에서 분석
- [ ] Performance Overlay로 FPS 모니터링
- [ ] 릴리즈 모드에서 성능 테스트
- [ ] buildWhen으로 선택적 rebuild 구현
- [ ] 상태 정규화로 메모리 효율성 증대
- [ ] Equatable 올바르게 구현
- [ ] Impeller 활성화 확인 (Flutter 3.16+)
- [ ] 첫 프레임 이후 비필수 초기화 지연
- [ ] 앱 시작 시간 측정 및 최적화
- [ ] Lazy initialization 패턴 적용
