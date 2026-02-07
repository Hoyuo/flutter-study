# Flutter 캐싱 전략 가이드

> 이 문서는 Flutter 애플리케이션에서 HTTP 캐시, 로컬 DB 캐시, 메모리 캐시를 통합하여 3계층 캐싱 시스템을 설계하고 구현하는 방법을 다룹니다. Cache-First, Network-First, Stale-While-Revalidate 전략을 활용하여 네트워크 요청을 최소화하고, 오프라인 환경에서도 최적의 사용자 경험을 제공하는 방법을 학습합니다.

> **학습 목표**:
> 1. 메모리 캐시, 디스크 캐시, 네트워크의 3계층 캐싱 아키텍처를 이해하고, LRU Cache와 TTL 기반 캐시를 구현할 수 있다
> 2. HTTP Cache-Control, ETag, dio_cache_interceptor를 활용하여 HTTP 캐싱을 구현하고, Repository 패턴과 통합할 수 있다
> 3. Cache-First, Network-First, Stale-While-Revalidate 전략을 이해하고, Bloc 패턴과 통합하여 오프라인 지원을 구현할 수 있다

---

## 목차

1. [캐싱 계층 구조](#1-캐싱-계층-구조)
2. [메모리 캐시 구현](#2-메모리-캐시-구현)
3. [HTTP 캐시](#3-http-캐시)
4. [로컬 DB 캐시](#4-로컬-db-캐시)
5. [Repository 패턴과 캐싱](#5-repository-패턴과-캐싱)
6. [이미지 캐싱](#6-이미지-캐싱)
7. [캐시 무효화 패턴](#7-캐시-무효화-패턴)
8. [Bloc과 캐시 통합](#8-bloc과-캐시-통합)
9. [오프라인 캐시](#9-오프라인-캐시)
10. [캐시 모니터링](#10-캐시-모니터링)

---

## 1. 캐싱 계층 구조

### 1.1 3-Tier 캐싱 아키텍처

```dart
/// 3계층 캐싱 시스템
///
/// Layer 1: Memory Cache (가장 빠름, 휘발성)
///   - LRU Cache
///   - 앱 재시작 시 소멸
///   - 수십 MB ~ 수백 MB
///
/// Layer 2: Disk Cache (중간 속도, 영구)
///   - Hive, SharedPreferences, SQLite
///   - 디바이스에 저장
///   - 수백 MB ~ 수 GB
///
/// Layer 3: Network (가장 느림)
///   - HTTP 요청
///   - 서버에서 데이터 가져오기

class CacheLayer {
  final MemoryCache memoryCache;
  final DiskCache diskCache;
  final NetworkClient networkClient;

  CacheLayer({
    required this.memoryCache,
    required this.diskCache,
    required this.networkClient,
  });

  /// 3계층 캐시 조회
  Future<T> get<T>(
    String key, {
    required Future<T> Function() fetchFromNetwork,
    Duration ttl = const Duration(hours: 1),
  }) async {
    // Layer 1: Memory Cache 확인
    final memoryResult = memoryCache.get<T>(key);
    if (memoryResult != null) {
      return memoryResult;
    }

    // Layer 2: Disk Cache 확인
    final diskResult = await diskCache.get<T>(key);
    if (diskResult != null) {
      // 메모리 캐시에 저장
      memoryCache.set(key, diskResult, ttl: ttl);
      return diskResult;
    }

    // Layer 3: Network 요청
    final networkResult = await fetchFromNetwork();

    // 하위 계층에 저장
    await diskCache.set(key, networkResult, ttl: ttl);
    memoryCache.set(key, networkResult, ttl: ttl);

    return networkResult;
  }

  /// 캐시 무효화
  Future<void> invalidate(String key) async {
    memoryCache.remove(key);
    await diskCache.remove(key);
  }

  /// 전체 캐시 초기화
  Future<void> clearAll() async {
    memoryCache.clear();
    await diskCache.clear();
  }
}
```

### 1.2 캐싱 전략

```dart
import 'dart:async';

enum CachingStrategy {
  /// 캐시 우선: 캐시가 있으면 즉시 반환, 없으면 네트워크 요청
  /// 사용 사례: 거의 변하지 않는 데이터 (국가 목록, 카테고리)
  cacheFirst,

  /// 네트워크 우선: 항상 네트워크 요청, 실패 시 캐시 반환
  /// 사용 사례: 실시간 데이터 (주식 가격, 날씨)
  networkFirst,

  /// 캐시만 사용: 네트워크 요청 안 함
  /// 사용 사례: 완전 오프라인 모드
  cacheOnly,

  /// 네트워크만 사용: 캐시 무시
  /// 사용 사례: 민감한 데이터 (계좌 잔액)
  networkOnly,

  /// Stale-While-Revalidate: 캐시 즉시 반환 + 백그라운드 갱신
  /// 사용 사례: 빠른 응답이 중요한 데이터 (뉴스 피드, 상품 목록)
  staleWhileRevalidate,
}

class CacheStrategyExecutor {
  final CacheLayer cacheLayer;

  CacheStrategyExecutor(this.cacheLayer);

  Future<T> execute<T>({
    required String key,
    required CachingStrategy strategy,
    required Future<T> Function() fetchFromNetwork,
    Duration ttl = const Duration(hours: 1),
  }) async {
    switch (strategy) {
      case CachingStrategy.cacheFirst:
        return _cacheFirst(key, fetchFromNetwork, ttl);
      case CachingStrategy.networkFirst:
        return _networkFirst(key, fetchFromNetwork, ttl);
      case CachingStrategy.cacheOnly:
        return _cacheOnly(key);
      case CachingStrategy.networkOnly:
        return _networkOnly(fetchFromNetwork);
      case CachingStrategy.staleWhileRevalidate:
        return _staleWhileRevalidate(key, fetchFromNetwork, ttl);
    }
  }

  Future<T> _cacheFirst<T>(
    String key,
    Future<T> Function() fetch,
    Duration ttl,
  ) async {
    try {
      return await cacheLayer.get<T>(key, fetchFromNetwork: fetch, ttl: ttl);
    } catch (e) {
      // 네트워크 실패 시에도 캐시가 있으면 반환
      final cached = await cacheLayer.diskCache.get<T>(key);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<T> _networkFirst<T>(
    String key,
    Future<T> Function() fetch,
    Duration ttl,
  ) async {
    try {
      final result = await fetch();
      await cacheLayer.diskCache.set(key, result, ttl: ttl);
      cacheLayer.memoryCache.set(key, result, ttl: ttl);
      return result;
    } catch (e) {
      // 네트워크 실패 시 캐시 반환
      final cached = await cacheLayer.diskCache.get<T>(key);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<T> _cacheOnly<T>(String key) async {
    final cached = cacheLayer.memoryCache.get<T>(key) ??
        await cacheLayer.diskCache.get<T>(key);
    if (cached == null) {
      throw CacheNotFoundException('No cache found for key: $key');
    }
    return cached;
  }

  Future<T> _networkOnly<T>(Future<T> Function() fetch) async {
    return fetch();
  }

  Future<T> _staleWhileRevalidate<T>(
    String key,
    Future<T> Function() fetch,
    Duration ttl,
  ) async {
    // 캐시가 있으면 즉시 반환
    final cached = cacheLayer.memoryCache.get<T>(key) ??
        await cacheLayer.diskCache.get<T>(key);

    if (cached != null) {
      // 백그라운드에서 갱신 (await 안 함)
      unawaited(_refreshCache(key, fetch, ttl));
      return cached;
    }

    // 캐시가 없으면 네트워크 요청 대기
    return fetch();
  }

  Future<void> _refreshCache<T>(
    String key,
    Future<T> Function() fetch,
    Duration ttl,
  ) async {
    try {
      final result = await fetch();
      await cacheLayer.diskCache.set(key, result, ttl: ttl);
      cacheLayer.memoryCache.set(key, result, ttl: ttl);
    } catch (e) {
      // 백그라운드 갱신 실패는 무시
    }
  }
}

class CacheNotFoundException implements Exception {
  final String message;
  CacheNotFoundException(this.message);
}
```

---

## 2. 메모리 캐시 구현

### 2.1 LRU Cache

```dart
import 'dart:collection';

/// LRU (Least Recently Used) 캐시
///
/// 가장 오래 사용하지 않은 항목을 제거하는 캐시
class LruCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();

  LruCache({required this.maxSize}) : assert(maxSize > 0);

  V? get(K key) {
    final entry = _cache.remove(key);
    if (entry == null) return null;

    // TTL 확인
    if (entry.isExpired) {
      return null;
    }

    // 최근 사용 항목으로 이동
    _cache[key] = entry;
    return entry.value;
  }

  void set(K key, V value, {Duration? ttl}) {
    // 기존 항목 제거 (최근 사용으로 이동하기 위해)
    _cache.remove(key);

    // 용량 초과 시 가장 오래된 항목 제거
    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }

    final expiresAt = ttl != null ? DateTime.now().add(ttl) : null;
    _cache[key] = _CacheEntry(value, expiresAt);
  }

  void remove(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  int get length => _cache.length;

  bool containsKey(K key) => _cache.containsKey(key);

  /// 만료된 항목 제거
  void evictExpired() {
    final keysToRemove = <K>[];
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime? expiresAt;

  _CacheEntry(this.value, this.expiresAt);

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}
```

### 2.2 TTL 기반 메모리 캐시

```dart
class MemoryCache {
  final LruCache<String, dynamic> _cache;
  Timer? _cleanupTimer;

  MemoryCache({int maxSize = 100})
      : _cache = LruCache(maxSize: maxSize) {
    // 주기적으로 만료된 항목 제거
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cache.evictExpired(),
    );
  }

  T? get<T>(String key) {
    return _cache.get(key) as T?;
  }

  void set<T>(String key, T value, {Duration? ttl}) {
    _cache.set(key, value, ttl: ttl);
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }

  // 캐시 통계
  CacheStats get stats {
    return CacheStats(
      size: _cache.length,
      maxSize: _cache.maxSize,
    );
  }
}

class CacheStats {
  final int size;
  final int maxSize;

  const CacheStats({
    required this.size,
    required this.maxSize,
  });

  double get usagePercentage => (size / maxSize) * 100;
}
```

---

## 3. HTTP 캐시

### 3.1 dio_cache_interceptor 설정

```dart
// pubspec.yaml
/*
dependencies:
  dio: ^5.9.0
  dio_cache_interceptor: ^3.5.0
  dio_cache_interceptor_hive_store: ^3.2.2
  hive: ^2.2.3
  path_provider: ^2.1.1
*/

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';

class HttpClientFactory {
  static Future<Dio> create() async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // 캐시 설정
    final cacheDir = await getTemporaryDirectory();
    final cacheStore = HiveCacheStore(
      cacheDir.path,
      hiveBoxName: 'http_cache',
    );

    final cacheOptions = CacheOptions(
      store: cacheStore,
      policy: CachePolicy.forceCache, // 기본 정책
      maxStale: const Duration(days: 7), // 최대 7일 동안 stale 데이터 사용 가능
      priority: CachePriority.high,
      hitCacheOnErrorExcept: [401, 403], // 인증 오류는 캐시 사용 안 함
      keyBuilder: (request) {
        // 커스텀 캐시 키 생성
        return '${request.method}_${request.uri.toString()}';
      },
    );

    dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

    return dio;
  }
}
```

### 3.2 HTTP Cache-Control

```dart
class ApiClient {
  final Dio dio;

  ApiClient(this.dio);

  /// Cache-First: 캐시 우선
  Future<Response<T>> getCached<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Duration maxAge = const Duration(hours: 1),
  }) async {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
        extra: {
          'dio_cache_interceptor_options': CacheOptions(
            policy: CachePolicy.forceCache,
            maxStale: maxAge,
          ),
        },
      ),
    );
  }

  /// Network-First: 네트워크 우선
  Future<Response<T>> getRefreshed<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
        extra: {
          'dio_cache_interceptor_options': const CacheOptions(
            policy: CachePolicy.refresh,
          ),
        },
      ),
    );
  }

  /// Stale-While-Revalidate
  Future<Response<T>> getStaleWhileRevalidate<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
        extra: {
          'dio_cache_interceptor_options': const CacheOptions(
            policy: CachePolicy.request,
          ),
        },
        headers: {
          'Cache-Control': 'max-age=300, stale-while-revalidate=3600',
        },
      ),
    );
  }

  /// ETag 활용
  Future<Response<T>> getWithETag<T>(
    String path, {
    String? etag,
    Map<String, dynamic>? queryParameters,
  }) async {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          if (etag != null) 'If-None-Match': etag,
        },
      ),
    );
  }
}
```

### 3.3 커스텀 캐시 Interceptor

```dart
class CustomCacheInterceptor extends Interceptor {
  final MemoryCache memoryCache;

  CustomCacheInterceptor(this.memoryCache);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // GET 요청만 캐싱
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    final cacheKey = _getCacheKey(options);
    final cached = memoryCache.get<Response>(cacheKey);

    if (cached != null) {
      // 캐시 히트
      return handler.resolve(cached);
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    // 성공한 GET 요청만 캐싱
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode == 200) {
      final cacheKey = _getCacheKey(response.requestOptions);

      // Cache-Control 헤더에서 TTL 추출
      final ttl = _extractTtl(response.headers);

      memoryCache.set(cacheKey, response, ttl: ttl);
    }

    handler.next(response);
  }

  String _getCacheKey(RequestOptions options) {
    final uri = options.uri.toString();
    return 'http_cache_$uri';
  }

  Duration? _extractTtl(Headers headers) {
    final cacheControl = headers.value('cache-control');
    if (cacheControl == null) return null;

    final maxAgeMatch = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
    if (maxAgeMatch == null) return null;

    final seconds = int.tryParse(maxAgeMatch.group(1)!);
    return seconds != null ? Duration(seconds: seconds) : null;
  }
}
```

---

## 4. 로컬 DB 캐시

### 4.1 Hive를 활용한 디스크 캐시

```dart
// pubspec.yaml
/*
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
*/

import 'package:hive_flutter/hive_flutter.dart';

class DiskCache {
  static const String _boxName = 'disk_cache';
  Box? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  Future<T?> get<T>(String key) async {
    final entry = _box?.get(key);
    if (entry == null) return null;

    if (entry is Map) {
      final expiresAt = entry['expiresAt'] as int?;
      if (expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAt) {
        // 만료됨
        await remove(key);
        return null;
      }

      return entry['value'] as T?;
    }

    return entry as T?;
  }

  Future<void> set<T>(
    String key,
    T value, {
    Duration? ttl,
  }) async {
    final expiresAt = ttl != null
        ? DateTime.now().add(ttl).millisecondsSinceEpoch
        : null;

    await _box?.put(key, {
      'value': value,
      'expiresAt': expiresAt,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> remove(String key) async {
    await _box?.delete(key);
  }

  Future<void> clear() async {
    await _box?.clear();
  }

  Future<void> evictExpired() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final keysToRemove = <String>[];

    for (final key in _box?.keys ?? []) {
      final entry = _box?.get(key);
      if (entry is Map) {
        final expiresAt = entry['expiresAt'] as int?;
        if (expiresAt != null && now > expiresAt) {
          keysToRemove.add(key as String);
        }
      }
    }

    for (final key in keysToRemove) {
      await remove(key);
    }
  }

  int get size => _box?.length ?? 0;

  Future<void> close() async {
    await _box?.close();
  }
}
```

### 4.2 캐시 엔티티 정의

```dart
// pubspec.yaml
/*
dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.15
*/

import 'package:hive/hive.dart';

part 'cache_entity.g.dart';

// ⚠️ 주의: 실제 프로젝트에서는 generic 클래스에 @HiveType을 사용할 수 없습니다.
// hive_generator가 T 타입을 직렬화할 수 없으므로, 구체적인 타입별 어댑터를 작성하거나
// dynamic/String(JSON) 방식을 사용해야 합니다.
@HiveType(typeId: 0)
class CacheEntity<T> {
  @HiveField(0)
  final T value;

  @HiveField(1)
  final int? expiresAt;

  @HiveField(2)
  final int createdAt;

  @HiveField(3)
  final String? etag;

  CacheEntity({
    required this.value,
    this.expiresAt,
    required this.createdAt,
    this.etag,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch > expiresAt!;
  }

  bool isStale(Duration staleDuration) {
    final staleAt = createdAt + staleDuration.inMilliseconds;
    return DateTime.now().millisecondsSinceEpoch > staleAt;
  }
}

// 사용 예제
class TypedDiskCache<T> {
  final Box<CacheEntity<T>> box;

  TypedDiskCache(this.box);

  static Future<TypedDiskCache<T>> open<T>(String boxName) async {
    final box = await Hive.openBox<CacheEntity<T>>(boxName);
    return TypedDiskCache(box);
  }

  CacheEntity<T>? get(String key) {
    final entry = box.get(key);
    if (entry == null || entry.isExpired) {
      return null;
    }
    return entry;
  }

  Future<void> set(
    String key,
    T value, {
    Duration? ttl,
    String? etag,
  }) async {
    final expiresAt = ttl != null
        ? DateTime.now().add(ttl).millisecondsSinceEpoch
        : null;

    await box.put(
      key,
      CacheEntity(
        value: value,
        expiresAt: expiresAt,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        etag: etag,
      ),
    );
  }
}
```

---

## 5. Repository 패턴과 캐싱

### 5.1 캐시를 통합한 Repository

```dart
import 'dart:async';

abstract class CachedRepository<T> {
  final ApiClient apiClient;
  final DiskCache diskCache;
  final MemoryCache memoryCache;

  CachedRepository({
    required this.apiClient,
    required this.diskCache,
    required this.memoryCache,
  });

  /// 캐시 키 생성
  String getCacheKey(String id);

  /// 네트워크에서 데이터 가져오기
  Future<T> fetchFromNetwork(String id);

  /// 캐시 우선 전략
  Future<T> getCacheFirst(
    String id, {
    Duration ttl = const Duration(hours: 1),
  }) async {
    final cacheKey = getCacheKey(id);

    // 메모리 캐시 확인
    final memCached = memoryCache.get<T>(cacheKey);
    if (memCached != null) return memCached;

    // 디스크 캐시 확인
    final diskCached = await diskCache.get<T>(cacheKey);
    if (diskCached != null) {
      memoryCache.set(cacheKey, diskCached, ttl: ttl);
      return diskCached;
    }

    // 네트워크 요청
    final networkData = await fetchFromNetwork(id);

    // 캐시 저장
    await diskCache.set(cacheKey, networkData, ttl: ttl);
    memoryCache.set(cacheKey, networkData, ttl: ttl);

    return networkData;
  }

  /// 네트워크 우선 전략
  Future<T> getNetworkFirst(String id) async {
    final cacheKey = getCacheKey(id);

    try {
      final networkData = await fetchFromNetwork(id);

      // 캐시 갱신
      await diskCache.set(cacheKey, networkData);
      memoryCache.set(cacheKey, networkData);

      return networkData;
    } catch (e) {
      // 네트워크 실패 시 캐시 반환
      final diskCached = await diskCache.get<T>(cacheKey);
      if (diskCached != null) return diskCached;

      rethrow;
    }
  }

  /// Stale-While-Revalidate 전략
  Future<T> getStaleWhileRevalidate(String id) async {
    final cacheKey = getCacheKey(id);

    // 캐시 즉시 반환
    final cached = memoryCache.get<T>(cacheKey) ??
        await diskCache.get<T>(cacheKey);

    // 백그라운드 갱신
    unawaited(_refreshCache(id));

    if (cached != null) return cached;

    // 캐시 없으면 네트워크 대기
    return fetchFromNetwork(id);
  }

  Future<void> _refreshCache(String id) async {
    try {
      final cacheKey = getCacheKey(id);
      final networkData = await fetchFromNetwork(id);

      await diskCache.set(cacheKey, networkData);
      memoryCache.set(cacheKey, networkData);
    } catch (e) {
      // 백그라운드 갱신 실패는 무시
    }
  }

  /// 캐시 무효화
  Future<void> invalidateCache(String id) async {
    final cacheKey = getCacheKey(id);
    memoryCache.remove(cacheKey);
    await diskCache.remove(cacheKey);
  }
}

// 실제 구현 예제
class ProductRepository extends CachedRepository<Product> {
  ProductRepository({
    required super.apiClient,
    required super.diskCache,
    required super.memoryCache,
  });

  @override
  String getCacheKey(String id) => 'product_$id';

  @override
  Future<Product> fetchFromNetwork(String id) async {
    final response = await apiClient.dio.get<Map<String, dynamic>>('/products/$id');
    return Product.fromJson(response.data!);
  }

  // 비즈니스 로직 메서드
  Future<Product> getProduct(String id) async {
    return getCacheFirst(id, ttl: const Duration(hours: 24));
  }

  Future<List<Product>> getProducts() async {
    // 목록은 짧은 TTL
    return getCacheFirst('product_list', ttl: const Duration(minutes: 5));
  }

  Future<void> updateProduct(String id, Product product) async {
    await apiClient.dio.put('/products/$id', data: product.toJson());

    // 캐시 무효화
    await invalidateCache(id);
    await invalidateCache('product_list');
  }
}
```

### 5.2 Result 타입과 캐싱

```dart
import 'package:fpdart/fpdart.dart';

typedef Result<T> = Either<Failure, T>;

class CachedResult<T> {
  final T data;
  final bool isFromCache;
  final DateTime? cachedAt;

  const CachedResult({
    required this.data,
    required this.isFromCache,
    this.cachedAt,
  });

  bool isStale(Duration staleDuration) {
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt!) > staleDuration;
  }
}

abstract class CachedRepositoryWithResult<T> {
  final ApiClient apiClient;
  final DiskCache diskCache;
  final MemoryCache memoryCache;

  CachedRepositoryWithResult({
    required this.apiClient,
    required this.diskCache,
    required this.memoryCache,
  });

  String getCacheKey(String id);

  Future<Result<T>> fetchFromNetwork(String id);

  Future<Result<CachedResult<T>>> getCacheFirst(
    String id, {
    Duration ttl = const Duration(hours: 1),
  }) async {
    final cacheKey = getCacheKey(id);

    // 캐시 확인
    final cached = memoryCache.get<T>(cacheKey) ??
        await diskCache.get<T>(cacheKey);

    if (cached != null) {
      return right(CachedResult(
        data: cached,
        isFromCache: true,
        cachedAt: DateTime.now(),
      ));
    }

    // 네트워크 요청
    final result = await fetchFromNetwork(id);

    return result.map((data) {
      // 캐시 저장
      diskCache.set(cacheKey, data, ttl: ttl);
      memoryCache.set(cacheKey, data, ttl: ttl);

      return CachedResult(
        data: data,
        isFromCache: false,
        cachedAt: null,
      );
    });
  }
}
```

---

## 6. 이미지 캐싱

### 6.1 cached_network_image

```dart
// pubspec.yaml
/*
dependencies:
  cached_network_image: ^3.3.0
*/

import 'package:cached_network_image/cached_network_image.dart';

class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.error),
      ),
      // 메모리 캐시 설정
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      // 디스크 캐시 설정
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );
  }
}
```

### 6.2 이미지 캐시 관리

```dart
import 'package:cached_network_image/cached_network_image.dart';

class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  /// 이미지 프리로드
  Future<void> precacheImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    await Future.wait(
      imageUrls.map((url) => precacheImage(
        CachedNetworkImageProvider(url),
        context,
      )),
    );
  }

  /// 이미지 캐시 삭제
  Future<void> clearImageCache() async {
    await CachedNetworkImage.evictFromCache('https://example.com/image.jpg');
  }

  /// 전체 이미지 캐시 삭제
  Future<void> clearAllImageCache() async {
    final cacheManager = DefaultCacheManager();
    await cacheManager.emptyCache();
  }

  /// 이미지 캐시 크기 확인
  Future<int> getImageCacheSize() async {
    final cacheManager = DefaultCacheManager();
    // ⚠️ 주의: retrieveCacheData()는 flutter_cache_manager의 공식 API가 아닙니다.
    // 실제 캐시 크기 확인은 getFileFromCache() 또는 store의 다른 메서드를 사용해야 합니다.
    final files = await cacheManager.store.retrieveCacheData();
    return files.fold<int>(0, (sum, file) => sum + (file.length ?? 0));
  }
}
```

---

## 7. 캐시 무효화 패턴

### 7.1 수동 무효화

```dart
class CacheInvalidator {
  final MemoryCache memoryCache;
  final DiskCache diskCache;

  CacheInvalidator({
    required this.memoryCache,
    required this.diskCache,
  });

  /// 단일 키 무효화
  Future<void> invalidate(String key) async {
    memoryCache.remove(key);
    await diskCache.remove(key);
  }

  /// 패턴 매칭 무효화
  Future<void> invalidatePattern(String pattern) async {
    final regex = RegExp(pattern);

    // 메모리 캐시
    // (LruCache에 키 목록 메서드 추가 필요)

    // 디스크 캐시 (Hive)
    final box = Hive.box('disk_cache');
    final keysToRemove = box.keys
        .where((key) => regex.hasMatch(key.toString()))
        .toList();

    for (final key in keysToRemove) {
      await diskCache.remove(key.toString());
    }
  }

  /// 전체 무효화
  Future<void> invalidateAll() async {
    memoryCache.clear();
    await diskCache.clear();
  }
}

// 사용 예제
class UserRepository {
  final CacheInvalidator cacheInvalidator;

  UserRepository(this.cacheInvalidator);

  Future<void> updateUser(String userId, User user) async {
    // API 호출
    // ...

    // 관련 캐시 무효화
    await cacheInvalidator.invalidate('user_$userId');
    await cacheInvalidator.invalidatePattern(r'user_list_.*');
  }
}
```

### 7.2 이벤트 기반 무효화

```dart
import 'dart:async';

enum CacheEvent {
  userUpdated,
  productUpdated,
  orderCreated,
}

class CacheEventBus {
  static final CacheEventBus _instance = CacheEventBus._internal();
  factory CacheEventBus() => _instance;
  CacheEventBus._internal();

  final _controller = StreamController<CacheEvent>.broadcast();

  Stream<CacheEvent> get stream => _controller.stream;

  void fire(CacheEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

class EventBasedCacheInvalidator {
  final CacheInvalidator cacheInvalidator;
  StreamSubscription? _subscription;

  EventBasedCacheInvalidator(this.cacheInvalidator);

  void start() {
    _subscription = CacheEventBus().stream.listen((event) {
      switch (event) {
        case CacheEvent.userUpdated:
          cacheInvalidator.invalidatePattern(r'user_.*');
          break;
        case CacheEvent.productUpdated:
          cacheInvalidator.invalidatePattern(r'product_.*');
          break;
        case CacheEvent.orderCreated:
          cacheInvalidator.invalidatePattern(r'order_.*');
          break;
      }
    });
  }

  void stop() {
    _subscription?.cancel();
  }
}

// 사용 예제
class UserService {
  Future<void> updateUser(String userId, User user) async {
    // API 호출
    // ...

    // 이벤트 발행
    CacheEventBus().fire(CacheEvent.userUpdated);
  }
}
```

### 7.3 TTL 기반 자동 무효화

```dart
class AutoEvictionScheduler {
  final MemoryCache memoryCache;
  final DiskCache diskCache;
  Timer? _timer;

  AutoEvictionScheduler({
    required this.memoryCache,
    required this.diskCache,
  });

  void start({Duration interval = const Duration(minutes: 5)}) {
    _timer = Timer.periodic(interval, (_) async {
      await _evict();
    });
  }

  Future<void> _evict() async {
    // 메모리 캐시 만료 항목 제거
    memoryCache.evictExpired();

    // 디스크 캐시 만료 항목 제거
    await diskCache.evictExpired();
  }

  void stop() {
    _timer?.cancel();
  }
}
```

---

## 8. Bloc과 캐시 통합

### 8.1 캐시를 활용한 Bloc

```dart
// Events
sealed class ProductEvent {}

class ProductLoadRequested extends ProductEvent {
  final String productId;
  final bool forceRefresh;

  ProductLoadRequested(this.productId, {this.forceRefresh = false});
}

class ProductRefreshRequested extends ProductEvent {
  final String productId;

  ProductRefreshRequested(this.productId);
}

// States
sealed class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {
  final Product? cachedProduct;

  ProductLoading({this.cachedProduct});
}

class ProductLoaded extends ProductState {
  final Product product;
  final bool isFromCache;

  ProductLoaded(this.product, {this.isFromCache = false});
}

class ProductError extends ProductState {
  final String message;
  final Product? cachedProduct;

  ProductError(this.message, {this.cachedProduct});
}

// Bloc
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;

  ProductBloc({required this.repository}) : super(ProductInitial()) {
    on<ProductLoadRequested>(_onLoadRequested);
    on<ProductRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    ProductLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      if (event.forceRefresh) {
        // 강제 새로고침: 네트워크 우선
        emit(ProductLoading());
        final product = await repository.getNetworkFirst(event.productId);
        emit(ProductLoaded(product, isFromCache: false));
      } else {
        // 일반 로드: 캐시 우선
        final cachedResult = await repository.getCacheFirst(event.productId);

        cachedResult.fold(
          (failure) => emit(ProductError(failure.message)),
          (result) {
            if (result.isFromCache && result.isStale(const Duration(hours: 1))) {
              // Stale 캐시: 캐시 표시 + 백그라운드 갱신
              emit(ProductLoaded(result.data, isFromCache: true));
              add(ProductRefreshRequested(event.productId));
            } else {
              emit(ProductLoaded(result.data, isFromCache: result.isFromCache));
            }
          },
        );
      }
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    ProductRefreshRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      // 백그라운드 갱신
      final product = await repository.fetchFromNetwork(event.productId);

      // 캐시 갱신
      await repository.diskCache.set('product_${event.productId}', product);
      repository.memoryCache.set('product_${event.productId}', product);

      // 상태 업데이트
      if (state is ProductLoaded) {
        emit(ProductLoaded(product, isFromCache: false));
      }
    } catch (e) {
      // 백그라운드 갱신 실패는 무시 (기존 캐시 유지)
    }
  }
}
```

### 8.2 Optimistic Update with Cache

```dart
// Events
class ProductUpdateRequested extends ProductEvent {
  final String productId;
  final Product updatedProduct;

  ProductUpdateRequested(this.productId, this.updatedProduct);
}

// Bloc
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  // ...

  Future<void> _onUpdateRequested(
    ProductUpdateRequested event,
    Emitter<ProductState> emit,
  ) async {
    final previousState = state;

    try {
      // Optimistic Update: 즉시 UI 업데이트
      emit(ProductLoaded(event.updatedProduct, isFromCache: false));

      // 캐시 업데이트
      repository.memoryCache.set('product_${event.productId}', event.updatedProduct);
      await repository.diskCache.set('product_${event.productId}', event.updatedProduct);

      // 서버에 업데이트 요청
      await repository.apiClient.dio.put(
        '/products/${event.productId}',
        data: event.updatedProduct.toJson(),
      );

      // 캐시 무효화 (목록 등)
      await repository.invalidateCache('product_list');
    } catch (e) {
      // 실패 시 이전 상태로 롤백
      if (previousState is ProductLoaded) {
        emit(previousState);

        // 캐시도 롤백
        repository.memoryCache.set('product_${event.productId}', previousState.product);
        await repository.diskCache.set('product_${event.productId}', previousState.product);
      }

      emit(ProductError(e.toString()));
    }
  }
}
```

---

## 9. 오프라인 캐시

### 9.1 오프라인 감지

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _subscription;

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onlineStream => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    _isOnline = !results.contains(ConnectivityResult.none);
    _controller.add(_isOnline);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
```

### 9.2 오프라인 우선 Repository

```dart
import 'dart:async';

class OfflineFirstRepository extends CachedRepository<Product> {
  final ConnectivityService connectivityService;

  OfflineFirstRepository({
    required super.apiClient,
    required super.diskCache,
    required super.memoryCache,
    required this.connectivityService,
  });

  @override
  String getCacheKey(String id) => 'product_$id';

  @override
  Future<Product> fetchFromNetwork(String id) async {
    final response = await apiClient.dio.get<Map<String, dynamic>>('/products/$id');
    return Product.fromJson(response.data!);
  }

  Future<Product> getProduct(String id) async {
    final cacheKey = getCacheKey(id);

    // 캐시 확인
    final cached = memoryCache.get<Product>(cacheKey) ??
        await diskCache.get<Product>(cacheKey);

    if (!connectivityService.isOnline) {
      // 오프라인: 캐시 반환 (없으면 오류)
      if (cached == null) {
        throw OfflineException('No cached data available');
      }
      return cached;
    }

    // 온라인: Stale-While-Revalidate
    if (cached != null) {
      // 캐시 즉시 반환
      unawaited(_refreshCache(id));
      return cached;
    }

    // 캐시 없음: 네트워크 요청
    return getNetworkFirst(id);
  }
}

class OfflineException implements Exception {
  final String message;
  OfflineException(this.message);
}
```

### 9.3 오프라인 큐

```dart
import 'dart:collection';

class OfflineQueue {
  final DiskCache diskCache;
  final Queue<PendingAction> _queue = Queue();
  static const String _queueKey = 'offline_queue';

  OfflineQueue(this.diskCache);

  Future<void> init() async {
    final saved = await diskCache.get<List>(_queueKey);
    if (saved != null) {
      _queue.addAll(saved.map((e) => PendingAction.fromJson(e)));
    }
  }

  Future<void> enqueue(PendingAction action) async {
    _queue.add(action);
    await _save();
  }

  Future<void> processQueue(ApiClient apiClient) async {
    while (_queue.isNotEmpty) {
      final action = _queue.first;

      try {
        await _executeAction(apiClient, action);
        _queue.removeFirst();
        await _save();
      } catch (e) {
        // 실패 시 큐 유지
        break;
      }
    }
  }

  Future<void> _executeAction(ApiClient apiClient, PendingAction action) async {
    switch (action.method) {
      case 'POST':
        await apiClient.dio.post(action.path, data: action.data);
        break;
      case 'PUT':
        await apiClient.dio.put(action.path, data: action.data);
        break;
      case 'DELETE':
        await apiClient.dio.delete(action.path);
        break;
    }
  }

  Future<void> _save() async {
    await diskCache.set(
      _queueKey,
      _queue.map((e) => e.toJson()).toList(),
    );
  }

  int get length => _queue.length;
}

class PendingAction {
  final String method;
  final String path;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  PendingAction({
    required this.method,
    required this.path,
    this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'method': method,
    'path': path,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      method: json['method'],
      path: json['path'],
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

---

## 10. 캐시 모니터링

### 10.1 캐시 통계

```dart
class CacheStatistics {
  int _hits = 0;
  int _misses = 0;
  int _totalSize = 0;

  void recordHit() => _hits++;
  void recordMiss() => _misses++;
  void updateSize(int size) => _totalSize = size;

  double get hitRate {
    final total = _hits + _misses;
    return total == 0 ? 0 : _hits / total;
  }

  int get totalRequests => _hits + _misses;
  int get totalSize => _totalSize;

  void reset() {
    _hits = 0;
    _misses = 0;
    _totalSize = 0;
  }

  Map<String, dynamic> toJson() => {
    'hits': _hits,
    'misses': _misses,
    'hitRate': hitRate,
    'totalRequests': totalRequests,
    'totalSize': _totalSize,
  };
}

class MonitoredCache {
  final MemoryCache memoryCache;
  final CacheStatistics statistics = CacheStatistics();

  MonitoredCache(this.memoryCache);

  T? get<T>(String key) {
    final result = memoryCache.get<T>(key);

    if (result != null) {
      statistics.recordHit();
    } else {
      statistics.recordMiss();
    }

    return result;
  }

  void set<T>(String key, T value, {Duration? ttl}) {
    memoryCache.set(key, value, ttl: ttl);
    statistics.updateSize(memoryCache.stats.size);
  }
}
```

### 10.2 캐시 대시보드

```dart
class CacheDashboard extends StatelessWidget {
  final MonitoredCache cache;

  const CacheDashboard({super.key, required this.cache});

  @override
  Widget build(BuildContext context) {
    final stats = cache.statistics;

    return Scaffold(
      appBar: AppBar(title: const Text('Cache Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCard(
              '캐시 히트율',
              '${(stats.hitRate * 100).toStringAsFixed(1)}%',
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              '총 요청 수',
              '${stats.totalRequests}',
              Icons.analytics,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              '캐시 크기',
              '${stats.totalSize} items',
              Icons.storage,
              Colors.orange,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                cache.memoryCache.clear();
                stats.reset();
              },
              child: const Text('캐시 초기화'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 실습 과제

### 과제 1: 3계층 캐싱 시스템 구현

다음 요구사항을 만족하는 캐싱 시스템을 구현하세요:

1. **메모리 캐시**
   - LRU Cache (최대 100개 항목)
   - TTL 지원 (기본 1시간)
   - 주기적 만료 항목 제거 (5분마다)

2. **디스크 캐시**
   - Hive 활용
   - TTL 지원
   - 캐시 크기 제한 (최대 50MB)

3. **Repository 통합**
   - Cache-First 전략
   - Network-First 전략
   - Stale-While-Revalidate 전략

**추가 요구사항**:
- 캐시 히트율 측정
- 캐시 무효화 API
- 단위 테스트 작성

### 과제 2: 오프라인 지원 구현

다음 요구사항을 만족하는 오프라인 기능을 구현하세요:

1. **오프라인 감지**
   - connectivity_plus 활용
   - 실시간 연결 상태 모니터링

2. **오프라인 큐**
   - POST/PUT/DELETE 작업 큐잉
   - 온라인 복귀 시 자동 처리
   - 재시도 로직 (최대 3회)

3. **Bloc 통합**
   - 오프라인 상태 표시
   - 캐시된 데이터 표시
   - 동기화 상태 표시

**추가 요구사항**:
- 오프라인 배너 UI
- 동기화 진행 상황 표시
- 충돌 해결 전략 (Last-Write-Wins)

### 과제 3: 이미지 캐싱과 프리로딩

다음 요구사항을 만족하는 이미지 캐싱 시스템을 구현하세요:

1. **이미지 캐싱**
   - cached_network_image 활용
   - 메모리/디스크 캐시 최적화
   - 해상도별 캐싱

2. **프리로딩**
   - 다음 화면 이미지 사전 로드
   - 백그라운드 다운로드
   - 우선순위 큐

3. **캐시 관리**
   - 캐시 크기 모니터링
   - 자동 정리 (7일 이상 미사용)
   - 수동 캐시 삭제 UI

**추가 요구사항**:
- 프로그레시브 이미지 로딩
- 저화질 → 고화질 전환
- 캐시 통계 대시보드

---

## Self-Check

다음 항목을 모두 이해하고 구현할 수 있는지 확인하세요:

- [ ] 메모리 캐시, 디스크 캐시, 네트워크의 3계층 캐싱 아키텍처를 이해하고, 각 계층의 역할과 특성을 설명할 수 있다
- [ ] LRU Cache 알고리즘을 이해하고, TTL 기반 만료 처리를 구현할 수 있다
- [ ] dio_cache_interceptor를 활용하여 HTTP 캐싱을 구현하고, Cache-Control 헤더를 이해할 수 있다
- [ ] Hive를 활용하여 디스크 캐시를 구현하고, 캐시 엔티티와 TTL을 관리할 수 있다
- [ ] Cache-First, Network-First, Stale-While-Revalidate 전략의 차이를 이해하고, 적절한 상황에 사용할 수 있다
- [ ] Repository 패턴과 캐싱을 통합하고, Clean Architecture 계층에서 캐시를 올바르게 사용할 수 있다
- [ ] cached_network_image를 활용하여 이미지 캐싱을 구현하고, 메모리/디스크 캐시 설정을 최적화할 수 있다
- [ ] 수동, TTL 기반, 이벤트 기반 캐시 무효화 전략을 구현할 수 있다
- [ ] Bloc 패턴과 캐시를 통합하고, Optimistic Update와 Stale-While-Revalidate를 구현할 수 있다
- [ ] connectivity_plus를 활용하여 오프라인을 감지하고, 오프라인 큐를 구현하여 온라인 복귀 시 동기화할 수 있다
- [ ] 캐시 히트율, 미스율, 크기를 모니터링하고, 캐시 대시보드를 구현할 수 있다

---

**Package Versions**
- flutter_bloc: ^9.1.1
- freezed: ^3.2.4
- fpdart: ^1.2.0
- go_router: ^17.0.1
- dio: ^5.9.0
- dio_cache_interceptor: ^3.5.0
- hive: ^2.2.3
- cached_network_image: ^3.3.0
- connectivity_plus: ^5.0.2
