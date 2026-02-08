# Flutter 페이지네이션 가이드

> **마지막 업데이트**: 2026-02-08 | **Flutter 3.38** | **Dart 3.10**
> **난이도**: 중급 | **카테고리**: features
> **선행 학습**: [Bloc](../core/Bloc.md)
> **예상 학습 시간**: 1.5h

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - 무한 스크롤과 페이지 기반 페이지네이션을 Bloc으로 구현할 수 있다
> - Pull-to-refresh와 리스트/그리드 뷰를 조합할 수 있다
> - 페이지네이션 상태 관리와 에러/로딩 처리를 구현할 수 있다

## 개요

무한 스크롤(Infinite Scroll)과 페이지 기반 페이지네이션을 Bloc 패턴으로 구현합니다. 리스트, 그리드, Pull-to-refresh와 함께 사용하는 패턴을 다룹니다.

## 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  rxdart: ^0.28.0
  flutter_bloc: ^9.1.1
  freezed_annotation: ^3.1.0
  fpdart: ^1.2.0
  injectable: ^2.7.1
  shimmer: ^3.0.0  # Skeleton Loader 섹션

dev_dependencies:
  bloc_test: ^10.0.0
  mocktail: ^1.0.4
  freezed: ^3.2.5
  build_runner: ^2.11.0
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
      // 📝 참고: Failure에 message getter가 정의되어 있어야 합니다:
      // String get message => when(...);
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
        error: failure.message,  // 에러 메시지 설정
      )),
      (response) => emit(state.copyWith(
        isLoadingMore: false,
        error: null,  // 성공 시 에러 메시지 초기화
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
              try {
                await context.read<ProductListBloc>().stream.firstWhere(
                      (s) => !s.isRefreshing,
                    ).timeout(const Duration(seconds: 10));
              } catch (e) {
                // Timeout 또는 에러 발생 시 무시
              }
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
          const SizedBox(height: 16),
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
  DateTime? _lastLoadMoreTime;

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
      // 중복 호출 방지: 마지막 호출로부터 300ms 이내면 무시
      final now = DateTime.now();
      if (_lastLoadMoreTime != null &&
          now.difference(_lastLoadMoreTime!).inMilliseconds < 300) {
        return;
      }
      _lastLoadMoreTime = now;
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
// 이벤트 정의
sealed class CursorPaginationEvent {
  const CursorPaginationEvent();
}

final class LoadNextPage extends CursorPaginationEvent {
  const LoadNextPage();
}

final class RefreshItems extends CursorPaginationEvent {
  const RefreshItems();
}

// Bloc 구현
class CursorPaginationBloc extends Bloc<CursorPaginationEvent, CursorPaginationState<Item>> {
  final ItemRepository _repository;

  CursorPaginationBloc(this._repository) : super(CursorPaginationState.initial()) {
    on<LoadNextPage>(_onLoadedMore);
    on<RefreshItems>(_onRefreshed);
  }

  Future<void> _onLoadedMore(
    LoadNextPage event,
    Emitter<CursorPaginationState<Item>> emit,
  ) async {
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

  Future<void> _onRefreshed(
    RefreshItems event,
    Emitter<CursorPaginationState<Item>> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));

    final result = await _repository.getItems(
      cursor: null,  // 처음부터 다시
      limit: 20,
    );

    result.fold(
      (failure) => emit(state.copyWith(isRefreshing: false)),
      (response) => emit(state.copyWith(
        isRefreshing: false,
        items: response.items,
        nextCursor: response.nextCursor,
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
    @Default(SortOption.newest) SortOption sortOption,
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
import 'package:rxdart/rxdart.dart';

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
      when(() => mockUseCase(
        page: 1,
        pageSize: 20,
        category: any(named: 'category'),
        sortBy: any(named: 'sortBy'),
      ))
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

## 10. 스크롤 위치 복원

### 10.1 PageStorageKey 활용

```dart
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductListBloc, ProductListState>(
      builder: (context, state) {
        return ListView.builder(
          // 페이지 이동 후 돌아와도 스크롤 위치 유지
          key: const PageStorageKey('product_list'),
          itemCount: state.products.length,
          itemBuilder: (context, index) => ProductCard(state.products[index]),
        );
      },
    );
  }
}
```

### 10.2 ScrollController 기반 복원

```dart
class PaginatedListWithRestore extends StatefulWidget {
  @override
  State<PaginatedListWithRestore> createState() => _State();
}

class _State extends State<PaginatedListWithRestore> {
  late final ScrollController _scrollController;
  static double? _savedPosition;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _savedPosition ?? 0,
    );
  }

  @override
  void dispose() {
    // 화면 떠날 때 위치 저장
    _savedPosition = _scrollController.offset;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) => ItemCard(items[index]),
    );
  }
}
```

### 10.3 Bloc과 함께 스크롤 상태 저장

```dart
@freezed
class ProductListState with _$ProductListState {
  const factory ProductListState({
    @Default([]) List<Product> products,
    @Default(0.0) double scrollOffset,
    @Default(false) bool isLoading,
  }) = _ProductListState;
}

class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  ProductListBloc() : super(const ProductListState()) {
    on<SaveScrollPosition>((event, emit) {
      emit(state.copyWith(scrollOffset: event.offset));
    });
  }
}

// UI에서 사용
class _ProductListPageState extends State<ProductListPage> {
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    final initialOffset = context.read<ProductListBloc>().state.scrollOffset;
    _controller = ScrollController(initialScrollOffset: initialOffset);

    _controller.addListener(() {
      context.read<ProductListBloc>().add(
        SaveScrollPosition(_controller.offset),
      );
    });
  }
}
```

## 11. 오프라인 캐시

### 11.1 캐시 우선 전략

```dart
class CachedPaginationRepository {
  final ApiClient _api;
  final LocalCache _cache;

  Future<Either<Failure, List<Product>>> getProducts({
    required int page,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'products_page_$page';

    // 1. 캐시 먼저 확인 (네트워크 없거나 forceRefresh 아닐 때)
    if (!forceRefresh) {
      final cached = await _cache.get<List<Product>>(cacheKey);
      if (cached != null) {
        // 백그라운드에서 새로고침
        _refreshInBackground(page);
        return Right(cached);
      }
    }

    // 2. 네트워크 요청
    try {
      final products = await _api.getProducts(page: page);
      await _cache.set(cacheKey, products, ttl: Duration(hours: 1));
      return Right(products);
    } on NetworkException {
      // 3. 네트워크 실패 시 캐시 반환
      final cached = await _cache.get<List<Product>>(cacheKey);
      if (cached != null) {
        return Right(cached);
      }
      return Left(NetworkFailure('오프라인 상태입니다'));
    }
  }

  void _refreshInBackground(int page) async {
    try {
      final products = await _api.getProducts(page: page);
      await _cache.set('products_page_$page', products);
    } catch (_) {
      // 백그라운드 새로고침 실패 무시
    }
  }
}
```

### 11.2 Bloc에서 캐시 상태 표시

```dart
@freezed
class PaginationState<T> with _$PaginationState<T> {
  const factory PaginationState({
    @Default([]) List<T> items,
    @Default(false) bool isLoading,
    @Default(false) bool isFromCache, // 캐시 데이터 여부
    DateTime? lastUpdated,
  }) = _PaginationState<T>;
}

// UI에서 캐시 알림 표시
if (state.isFromCache) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.offline_bolt, color: Colors.white),
          const SizedBox(width: 8),
          Text('오프라인 모드 - ${_formatTime(state.lastUpdated)}에 저장됨'),
        ],
      ),
      action: SnackBarAction(
        label: '새로고침',
        onPressed: () => bloc.add(const Refresh()),
      ),
    ),
  );
}
```

### 11.3 Skeleton Loader

```dart
class SkeletonProductCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 100,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// 로딩 중 Skeleton 표시
ListView.builder(
  itemCount: state.isLoading && state.items.isEmpty
      ? 5 // Skeleton 5개 표시
      : state.items.length,
  itemBuilder: (context, index) {
    if (state.isLoading && state.items.isEmpty) {
      return const SkeletonProductCard();
    }
    return ProductCard(state.items[index]);
  },
)
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
- [ ] 스크롤 위치 복원 구현
- [ ] 오프라인 캐시 전략 구현
- [ ] Skeleton Loader 추가
- [ ] Bloc 테스트 작성

---

## 실습 과제

### 과제 1: 무한 스크롤 목록 구현
Bloc 패턴으로 무한 스크롤 페이지네이션을 구현하세요. ScrollController 기반 자동 로딩, 로딩/에러/빈 상태 표시, Pull-to-refresh를 포함해 주세요.

### 과제 2: 커서 기반 페이지네이션
offset 기반이 아닌 cursor(커서) 기반 페이지네이션을 구현하세요. 이전/다음 페이지 네비게이션, 페이지 크기 조절, 정렬 옵션을 지원하도록 설계하세요.

---

## 관련 문서

- [Bloc](../core/Bloc.md) - Pagination Bloc 패턴 및 상태 관리
- [Architecture](../core/Architecture.md) - Repository 패턴과 데이터 레이어 설계
- [Networking_Retrofit](../networking/Networking_Retrofit.md) - 페이지네이션 API 정의

---

## Self-Check

- [ ] ScrollController를 사용한 무한 스크롤 감지를 구현할 수 있다
- [ ] Bloc에서 페이지네이션 상태(로딩, 에러, 더보기 없음)를 관리할 수 있다
- [ ] Pull-to-refresh로 목록을 초기화하고 다시 로드할 수 있다
- [ ] offset 기반과 cursor 기반 페이지네이션의 차이를 설명할 수 있다
