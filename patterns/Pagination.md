# Flutter 페이지네이션 가이드

## 개요

무한 스크롤(Infinite Scroll)과 페이지 기반 페이지네이션을 Bloc 패턴으로 구현합니다. 리스트, 그리드, Pull-to-refresh와 함께 사용하는 패턴을 다룹니다.

## 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  rxdart: ^0.28.0  # 디바운싱에 필요 (FormValidation.md와 버전 일치)
```

## 기본 구조

### Pagination 상태 모델

```dart
// lib/core/pagination/pagination_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_state.freezed.dart';

@freezed
class PaginationState<T> with _$PaginationState<T> {
  const factory PaginationState({
    required List<T> items,
    required int currentPage,
    required bool hasNextPage,
    required bool isLoading,
    required bool isLoadingMore,
    required bool isRefreshing,
    String? error,
  }) = _PaginationState<T>;

  factory PaginationState.initial() => PaginationState<T>(
        items: [],
        currentPage: 1,
        hasNextPage: true,
        isLoading: false,
        isLoadingMore: false,
        isRefreshing: false,
      );
}

extension PaginationStateX<T> on PaginationState<T> {
  bool get isEmpty => items.isEmpty && !isLoading;
  bool get canLoadMore => hasNextPage && !isLoadingMore && !isLoading;
  bool get showLoadingIndicator => isLoading && items.isEmpty;
  bool get showEmptyState => isEmpty && !isLoading && error == null;
  bool get showError => error != null && items.isEmpty;
}
```

### Pagination 설정

```dart
// lib/core/pagination/pagination_config.dart
class PaginationConfig {
  final int pageSize;
  final int preloadOffset;  // 스크롤 끝에서 몇 개 전에 로드 시작

  const PaginationConfig({
    this.pageSize = 20,
    this.preloadOffset = 5,
  });

  static const defaultConfig = PaginationConfig();
}
```

### API 응답 모델

```dart
// lib/core/pagination/paginated_response.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated_response.freezed.dart';
part 'paginated_response.g.dart';

@Freezed(genericArgumentFactories: true)
class PaginatedResponse<T> with _$PaginatedResponse<T> {
  const factory PaginatedResponse({
    required List<T> items,
    required int currentPage,
    required int totalPages,
    required int totalItems,
    required bool hasNextPage,
  }) = _PaginatedResponse<T>;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$PaginatedResponseFromJson(json, fromJsonT);
}
```

## Bloc 패턴 구현

### Event 정의

```dart
// lib/features/product/presentation/bloc/product_list_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_list_event.freezed.dart';

@freezed
class ProductListEvent with _$ProductListEvent {
  /// 초기 로드
  const factory ProductListEvent.loaded() = _Loaded;

  /// 다음 페이지 로드
  const factory ProductListEvent.loadedMore() = _LoadedMore;

  /// 새로고침
  const factory ProductListEvent.refreshed() = _Refreshed;

  /// 필터 변경
  const factory ProductListEvent.filterChanged({
    String? category,
    String? sortBy,
  }) = _FilterChanged;
}
```

### State 정의

```dart
// lib/features/product/presentation/bloc/product_list_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/product.dart';

part 'product_list_state.freezed.dart';

@freezed
class ProductListState with _$ProductListState {
  const factory ProductListState({
    required List<Product> products,
    required int currentPage,
    required bool hasNextPage,
    required bool isLoading,
    required bool isLoadingMore,
    required bool isRefreshing,
    String? selectedCategory,
    String? sortBy,
    String? error,
  }) = _ProductListState;

  factory ProductListState.initial() => const ProductListState(
        products: [],
        currentPage: 1,
        hasNextPage: true,
        isLoading: false,
        isLoadingMore: false,
        isRefreshing: false,
      );
}

extension ProductListStateX on ProductListState {
  bool get isEmpty => products.isEmpty && !isLoading;
  bool get canLoadMore => hasNextPage && !isLoadingMore && !isLoading;
  bool get showLoadingIndicator => isLoading && products.isEmpty;
  bool get showEmptyState => isEmpty && !isLoading && error == null;
  bool get showError => error != null && products.isEmpty;
}
```

### Bloc 구현

```dart
// lib/features/product/presentation/bloc/product_list_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/pagination/pagination_config.dart';
import '../../domain/usecases/get_products_usecase.dart';
import 'product_list_event.dart';
import 'product_list_state.dart';

class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  final GetProductsUseCase _getProductsUseCase;
  final PaginationConfig _config;

  ProductListBloc({
    required GetProductsUseCase getProductsUseCase,
    PaginationConfig config = PaginationConfig.defaultConfig,
  })  : _getProductsUseCase = getProductsUseCase,
        _config = config,
        super(ProductListState.initial()) {
    on<ProductListEvent>((event, emit) async {
      await event.when(
        loaded: () => _onLoaded(emit),
        loadedMore: () => _onLoadedMore(emit),
        refreshed: () => _onRefreshed(emit),
        filterChanged: (category, sortBy) =>
            _onFilterChanged(category, sortBy, emit),
      );
    });
  }

  /// 초기 로드
  Future<void> _onLoaded(Emitter<ProductListState> emit) async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true, error: null));

    final result = await _getProductsUseCase(
      page: 1,
      pageSize: _config.pageSize,
      category: state.selectedCategory,
      sortBy: state.sortBy,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (response) => emit(state.copyWith(
        isLoading: false,
        products: response.items,
        currentPage: response.currentPage,
        hasNextPage: response.hasNextPage,
      )),
    );
  }

  /// 다음 페이지 로드
  Future<void> _onLoadedMore(Emitter<ProductListState> emit) async {
    if (!state.canLoadMore) return;

    emit(state.copyWith(isLoadingMore: true));

    final result = await _getProductsUseCase(
      page: state.currentPage + 1,
      pageSize: _config.pageSize,
      category: state.selectedCategory,
      sortBy: state.sortBy,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        // loadMore 실패는 기존 데이터 유지, 에러 메시지만 표시
      )),
      (response) => emit(state.copyWith(
        isLoadingMore: false,
        products: [...state.products, ...response.items],
        currentPage: response.currentPage,
        hasNextPage: response.hasNextPage,
      )),
    );
  }

  /// Pull-to-refresh
  Future<void> _onRefreshed(Emitter<ProductListState> emit) async {
    emit(state.copyWith(isRefreshing: true, error: null));

    final result = await _getProductsUseCase(
      page: 1,
      pageSize: _config.pageSize,
      category: state.selectedCategory,
      sortBy: state.sortBy,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isRefreshing: false,
        error: failure.message,
      )),
      (response) => emit(state.copyWith(
        isRefreshing: false,
        products: response.items,
        currentPage: response.currentPage,
        hasNextPage: response.hasNextPage,
      )),
    );
  }

  /// 필터 변경 시 처음부터 다시 로드
  Future<void> _onFilterChanged(
    String? category,
    String? sortBy,
    Emitter<ProductListState> emit,
  ) async {
    emit(state.copyWith(
      selectedCategory: category,
      sortBy: sortBy,
      products: [],
      currentPage: 1,
      hasNextPage: true,
    ));

    add(const ProductListEvent.loaded());
  }
}
```

### UseCase

```dart
// lib/features/product/domain/usecases/get_products_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/pagination/paginated_response.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

@injectable
class GetProductsUseCase {
  final ProductRepository _repository;

  GetProductsUseCase(this._repository);

  Future<Either<Failure, PaginatedResponse<Product>>> call({
    required int page,
    required int pageSize,
    String? category,
    String? sortBy,
  }) {
    return _repository.getProducts(
      page: page,
      pageSize: pageSize,
      category: category,
      sortBy: sortBy,
    );
  }
}
```

## UI 구현

### 무한 스크롤 리스트

```dart
// lib/features/product/presentation/pages/product_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/product_list_bloc.dart';
import '../bloc/product_list_event.dart';
import '../bloc/product_list_state.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ProductListBloc>().add(const ProductListEvent.loaded());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ProductListBloc>().add(const ProductListEvent.loadedMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // 끝에서 200px 전에 로드 시작
    return currentScroll >= (maxScroll - 200);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('상품 목록')),
      body: BlocBuilder<ProductListBloc, ProductListState>(
        builder: (context, state) {
          // 초기 로딩
          if (state.showLoadingIndicator) {
            return const Center(child: CircularProgressIndicator());
          }

          // 에러 (데이터 없음)
          if (state.showError) {
            return _ErrorView(
              message: state.error!,
              onRetry: () {
                context.read<ProductListBloc>().add(
                      const ProductListEvent.loaded(),
                    );
              },
            );
          }

          // 빈 상태
          if (state.showEmptyState) {
            return const _EmptyView();
          }

          // 리스트
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProductListBloc>().add(
                    const ProductListEvent.refreshed(),
                  );
              // RefreshIndicator가 완료를 알 수 있도록 대기
              await context.read<ProductListBloc>().stream.firstWhere(
                    (s) => !s.isRefreshing,
                  );
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: state.products.length + (state.hasNextPage ? 1 : 0),
              itemBuilder: (context, index) {
                // 마지막 아이템: 로딩 인디케이터
                if (index >= state.products.length) {
                  return const _LoadMoreIndicator();
                }

                // 상품 아이템
                final product = state.products[index];
                return ProductListTile(product: product);
              },
            ),
          );
        },
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('상품이 없습니다'),
        ],
      ),
    );
  }
}
```

### 재사용 가능한 Pagination ListView

```dart
// lib/core/widgets/paginated_list_view.dart
import 'package:flutter/material.dart';

typedef ItemBuilder<T> = Widget Function(BuildContext context, T item, int index);
typedef OnLoadMore = void Function();
typedef OnRefresh = Future<void> Function();

class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasNextPage;
  final String? error;
  final ItemBuilder<T> itemBuilder;
  final OnLoadMore onLoadMore;
  final OnRefresh onRefresh;
  final VoidCallback? onRetry;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? loadMoreWidget;
  final double loadMoreThreshold;
  final EdgeInsets? padding;
  final Widget? separatorWidget;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasNextPage,
    this.error,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.onRefresh,
    this.onRetry,
    this.emptyWidget,
    this.loadingWidget,
    this.loadMoreWidget,
    this.loadMoreThreshold = 200,
    this.padding,
    this.separatorWidget,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_shouldLoadMore) {
      widget.onLoadMore();
    }
  }

  bool get _shouldLoadMore {
    if (!_scrollController.hasClients) return false;
    if (!widget.hasNextPage) return false;
    if (widget.isLoadingMore) return false;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - widget.loadMoreThreshold);
  }

  @override
  Widget build(BuildContext context) {
    // 초기 로딩
    if (widget.isLoading && widget.items.isEmpty) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    // 에러
    if (widget.error != null && widget.items.isEmpty) {
      return _DefaultErrorView(
        message: widget.error!,
        onRetry: widget.onRetry,
      );
    }

    // 빈 상태
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? const _DefaultEmptyView();
    }

    // 리스트
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        itemCount: widget.items.length + (widget.hasNextPage ? 1 : 0),
        separatorBuilder: (context, index) =>
            widget.separatorWidget ?? const SizedBox.shrink(),
        itemBuilder: (context, index) {
          if (index >= widget.items.length) {
            return widget.loadMoreWidget ?? const _DefaultLoadMoreIndicator();
          }
          return widget.itemBuilder(context, widget.items[index], index);
        },
      ),
    );
  }
}

class _DefaultLoadMoreIndicator extends StatelessWidget {
  const _DefaultLoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _DefaultEmptyView extends StatelessWidget {
  const _DefaultEmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('데이터가 없습니다'),
    );
  }
}

class _DefaultErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _DefaultErrorView({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ],
      ),
    );
  }
}
```

### 사용 예시

```dart
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('상품')),
      body: BlocBuilder<ProductListBloc, ProductListState>(
        builder: (context, state) {
          return PaginatedListView<Product>(
            items: state.products,
            isLoading: state.isLoading,
            isLoadingMore: state.isLoadingMore,
            hasNextPage: state.hasNextPage,
            error: state.error,
            itemBuilder: (context, product, index) {
              return ProductListTile(product: product);
            },
            onLoadMore: () {
              context.read<ProductListBloc>().add(
                    const ProductListEvent.loadedMore(),
                  );
            },
            onRefresh: () async {
              context.read<ProductListBloc>().add(
                    const ProductListEvent.refreshed(),
                  );
              await context.read<ProductListBloc>().stream.firstWhere(
                    (s) => !s.isRefreshing,
                  );
            },
            onRetry: () {
              context.read<ProductListBloc>().add(
                    const ProductListEvent.loaded(),
                  );
            },
            emptyWidget: const EmptyProductView(),
            separatorWidget: const Divider(height: 1),
          );
        },
      ),
    );
  }
}
```

## Grid 페이지네이션

### Paginated GridView

```dart
// lib/core/widgets/paginated_grid_view.dart
import 'package:flutter/material.dart';

class PaginatedGridView<T> extends StatefulWidget {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasNextPage;
  final String? error;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final VoidCallback? onRetry;
  final SliverGridDelegate gridDelegate;
  final EdgeInsets? padding;
  final Widget? emptyWidget;
  final double loadMoreThreshold;

  const PaginatedGridView({
    super.key,
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasNextPage,
    this.error,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.onRefresh,
    this.onRetry,
    required this.gridDelegate,
    this.padding,
    this.emptyWidget,
    this.loadMoreThreshold = 200,
  });

  @override
  State<PaginatedGridView<T>> createState() => _PaginatedGridViewState<T>();
}

class _PaginatedGridViewState<T> extends State<PaginatedGridView<T>> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_shouldLoadMore) {
      widget.onLoadMore();
    }
  }

  bool get _shouldLoadMore {
    if (!_scrollController.hasClients) return false;
    if (!widget.hasNextPage || widget.isLoadingMore) return false;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - widget.loadMoreThreshold);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.error != null && widget.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.error!),
            if (widget.onRetry != null)
              ElevatedButton(
                onPressed: widget.onRetry,
                child: const Text('다시 시도'),
              ),
          ],
        ),
      );
    }

    if (widget.items.isEmpty) {
      return widget.emptyWidget ?? const Center(child: Text('데이터가 없습니다'));
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: widget.padding ?? EdgeInsets.zero,
            sliver: SliverGrid(
              gridDelegate: widget.gridDelegate,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return widget.itemBuilder(
                    context,
                    widget.items[index],
                    index,
                  );
                },
                childCount: widget.items.length,
              ),
            ),
          ),
          if (widget.hasNextPage)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

## Cursor 기반 페이지네이션

### Cursor 기반 상태

```dart
// lib/core/pagination/cursor_pagination_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cursor_pagination_state.freezed.dart';

@freezed
class CursorPaginationState<T> with _$CursorPaginationState<T> {
  const factory CursorPaginationState({
    required List<T> items,
    String? nextCursor,
    required bool hasNextPage,
    required bool isLoading,
    required bool isLoadingMore,
    required bool isRefreshing,
    String? error,
  }) = _CursorPaginationState<T>;

  factory CursorPaginationState.initial() => CursorPaginationState<T>(
        items: [],
        hasNextPage: true,
        isLoading: false,
        isLoadingMore: false,
        isRefreshing: false,
      );
}
```

### Cursor 기반 Bloc

```dart
class CursorPaginationBloc extends Bloc<PaginationEvent, CursorPaginationState<Item>> {
  Future<void> _onLoadedMore(Emitter<CursorPaginationState<Item>> emit) async {
    if (!state.hasNextPage || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));

    final result = await _repository.getItems(
      cursor: state.nextCursor,  // 현재 커서 전달
      limit: 20,
    );

    result.fold(
      (failure) => emit(state.copyWith(isLoadingMore: false)),
      (response) => emit(state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...response.items],
        nextCursor: response.nextCursor,  // 다음 커서 저장
        hasNextPage: response.nextCursor != null,
      )),
    );
  }
}
```

## 필터와 검색

### 필터 + 페이지네이션

```dart
// lib/features/product/presentation/bloc/product_filter_state.dart
@freezed
class ProductListState with _$ProductListState {
  const factory ProductListState({
    required List<Product> products,
    required int currentPage,
    required bool hasNextPage,
    required bool isLoading,
    required bool isLoadingMore,
    required bool isRefreshing,
    // 필터 상태
    String? searchQuery,
    String? selectedCategory,
    PriceRange? priceRange,
    SortOption sortOption,
    String? error,
  }) = _ProductListState;
}

enum SortOption {
  newest,
  priceAsc,
  priceDesc,
  popular,
}

@freezed
class PriceRange with _$PriceRange {
  const factory PriceRange({
    required int min,
    required int max,
  }) = _PriceRange;
}
```

### 검색 디바운싱

```dart
class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  ProductListBloc(...) : super(ProductListState.initial()) {
    // 검색어 변경 이벤트에 디바운스 적용
    on<_SearchChanged>(
      _onSearchChanged,
      transformer: debounce(const Duration(milliseconds: 500)),
    );

    on<_FilterChanged>(_onFilterChanged);
    on<_Loaded>(_onLoaded);
    on<_LoadedMore>(_onLoadedMore);
  }

  EventTransformer<E> debounce<E>(Duration duration) {
    return (events, mapper) => events.debounceTime(duration).flatMap(mapper);
  }

  Future<void> _onSearchChanged(
    _SearchChanged event,
    Emitter<ProductListState> emit,
  ) async {
    emit(state.copyWith(
      searchQuery: event.query,
      products: [],
      currentPage: 1,
      hasNextPage: true,
    ));

    add(const ProductListEvent.loaded());
  }
}
```

## 테스트

### Bloc 테스트

```dart
void main() {
  late ProductListBloc bloc;
  late MockGetProductsUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetProductsUseCase();
    bloc = ProductListBloc(getProductsUseCase: mockUseCase);
  });

  blocTest<ProductListBloc, ProductListState>(
    'should load first page',
    build: () {
      when(() => mockUseCase(page: 1, pageSize: 20))
          .thenAnswer((_) async => Right(PaginatedResponse(
                items: [mockProduct],
                currentPage: 1,
                totalPages: 3,
                totalItems: 50,
                hasNextPage: true,
              )));
      return bloc;
    },
    act: (bloc) => bloc.add(const ProductListEvent.loaded()),
    expect: () => [
      ProductListState.initial().copyWith(isLoading: true),
      ProductListState.initial().copyWith(
        isLoading: false,
        products: [mockProduct],
        currentPage: 1,
        hasNextPage: true,
      ),
    ],
  );

  blocTest<ProductListBloc, ProductListState>(
    'should append items on load more',
    seed: () => ProductListState.initial().copyWith(
      products: [mockProduct1],
      currentPage: 1,
      hasNextPage: true,
    ),
    build: () {
      when(() => mockUseCase(page: 2, pageSize: 20))
          .thenAnswer((_) async => Right(PaginatedResponse(
                items: [mockProduct2],
                currentPage: 2,
                totalPages: 3,
                totalItems: 50,
                hasNextPage: true,
              )));
      return bloc;
    },
    act: (bloc) => bloc.add(const ProductListEvent.loadedMore()),
    expect: () => [
      // isLoadingMore: true
      isA<ProductListState>().having((s) => s.isLoadingMore, 'isLoadingMore', true),
      // 아이템 추가됨
      isA<ProductListState>()
          .having((s) => s.products.length, 'products.length', 2)
          .having((s) => s.currentPage, 'currentPage', 2),
    ],
  );
}
```

## 체크리스트

- [ ] PaginationState 모델 정의
- [ ] PaginatedResponse API 응답 모델 정의
- [ ] Pagination Event/State/Bloc 구현
- [ ] ScrollController로 스크롤 감지
- [ ] loadMore 호출 조건 (hasNextPage, !isLoading, threshold)
- [ ] RefreshIndicator로 Pull-to-refresh 구현
- [ ] 로딩/에러/빈 상태 UI 처리
- [ ] 재사용 가능한 PaginatedListView 위젯
- [ ] 필터/검색 + 페이지네이션 통합
- [ ] 검색 디바운싱 처리
- [ ] Bloc 테스트 작성
