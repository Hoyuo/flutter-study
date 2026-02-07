# Flutter Local Storage Guide

> 이 문서는 SharedPreferences, Isar Plus, SecureStorage를 사용한 로컬 저장소 패턴을 설명합니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - SharedPreferences로 간단한 키-값 데이터를 저장할 수 있다
> - SecureStorage로 민감한 데이터를 안전하게 관리할 수 있다
> - 용도에 맞는 로컬 저장소 솔루션을 선택하고 구현할 수 있다

## 1. 개요

### 1.1 저장소 종류 비교

| 저장소 | 용도 | 데이터 유형 | 보안 | 상태 |
|--------|------|------------|------|------|
| **SharedPreferences** | 간단한 설정값 | Key-Value (primitive) | 낮음 | ✅ 활발 (새 async API) |
| **Isar Plus** | 복잡한 구조화 데이터 | 객체/컬렉션 | 중간 | ✅ 커뮤니티 포크 (원본 Isar 대체) |
| **SecureStorage** | 민감한 정보 | Key-Value | 높음 (암호화) | ✅ 활발 (v10+) |

### 1.2 사용 시나리오

```
SharedPreferences
├── 앱 설정 (테마, 언어)
├── 온보딩 완료 여부
├── 마지막 로그인 시간
└── 캐시 만료 시간

Isar
├── 오프라인 캐시 데이터
├── 검색 히스토리
├── 로컬 사용자 데이터
└── 장바구니/위시리스트

SecureStorage
├── 액세스/리프레시 토큰
├── API 키
├── 사용자 인증 정보
└── 암호화 키
```

### 1.3 프로젝트 구조

```
core/
└── core_storage/
    └── lib/
        ├── core_storage.dart
        └── src/
            ├── preferences/
            │   ├── app_preferences.dart
            │   └── preference_keys.dart
            ├── database/
            │   ├── isar_database.dart
            │   └── collections/
            ├── secure/
            │   └── secure_storage.dart
            └── injection.dart
```

## 2. 프로젝트 설정

### 2.1 의존성 추가

```yaml
# core/core_storage/pubspec.yaml
dependencies:
  # SharedPreferences - 최신 async API 지원
  shared_preferences: ^2.5.4

  # SecureStorage - v10+ 새로운 초기화 API
  flutter_secure_storage: ^10.0.0

  # ⚠️ 경고: Isar Plus는 커뮤니티 포크로 장기 유지보수 불확실
  # 새 프로젝트는 Drift 사용 권장 (섹션 4.0.3 참조)
  # isar_plus: ^1.2.1  # 개발 중단된 Isar의 포크

  # 권장 대안: Drift (타입 안전, 활발한 개발)
  drift: ^2.14.0

  injectable: ^2.5.0
  path_provider: ^2.1.2

dev_dependencies:
  isar_plus_generator: ^1.2.1
  build_runner: ^2.4.15
  injectable_generator: ^2.7.0
```

## 3. SharedPreferences

> **⚠️ 중요 (2025년 업데이트)**: 기존 동기(synchronous) API(`SharedPreferences.getInstance()`)는 deprecated 되었습니다.
> 새 프로젝트는 **SharedPreferencesAsync** 또는 **SharedPreferencesWithCache**를 사용하세요.

### 3.0 새로운 Async API (권장)

#### 3.0.1 SharedPreferencesAsync - 완전 비동기 API

모든 읽기/쓰기가 비동기로 동작하며, 초기화 불필요.

```dart
// core/core_storage/lib/src/preferences/app_preferences_async.dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AppPreferencesAsync {
  Future<void> setThemeMode(String mode);
  Future<String?> getThemeMode();
  Future<void> setLanguageCode(String code);
  Future<String?> getLanguageCode();
  Future<void> clear();
}

@LazySingleton(as: AppPreferencesAsync)
class AppPreferencesAsyncImpl implements AppPreferencesAsync {
  // 초기화 불필요! 인스턴스 직접 사용
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(PreferenceKeys.themeMode, mode);
  }

  @override
  Future<String?> getThemeMode() async {
    return await _prefs.getString(PreferenceKeys.themeMode);
  }

  @override
  Future<void> setLanguageCode(String code) async {
    await _prefs.setString(PreferenceKeys.languageCode, code);
  }

  @override
  Future<String?> getLanguageCode() async {
    return await _prefs.getString(PreferenceKeys.languageCode);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}
```

**장점:**
- ✅ 초기화 단계 불필요
- ✅ 진짜 비동기, 메인 스레드 블로킹 없음
- ✅ 동시성 안전 (concurrent-safe)

**단점:**
- ❌ 모든 읽기가 비동기 (UI 렌더링 시 약간의 지연)

#### 3.0.2 SharedPreferencesWithCache - 하이브리드 API

초기화 후 동기 읽기 + 비동기 쓰기. 성능과 편의성의 균형.

```dart
// core/core_storage/lib/src/preferences/app_preferences_cached.dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AppPreferencesCached {
  // 읽기: 동기 (캐시에서)
  String? getThemeMode();
  bool isOnboardingCompleted();

  // 쓰기: 비동기 (디스크에)
  Future<void> setThemeMode(String mode);
  Future<void> setOnboardingCompleted(bool completed);
  Future<void> clear();
}

@LazySingleton(as: AppPreferencesCached)
class AppPreferencesCachedImpl implements AppPreferencesCached {
  final SharedPreferencesWithCache _prefs;

  AppPreferencesCachedImpl(this._prefs);

  // 읽기 - 동기 (빠름)
  @override
  String? getThemeMode() {
    return _prefs.getString(PreferenceKeys.themeMode);
  }

  @override
  bool isOnboardingCompleted() {
    return _prefs.getBool(PreferenceKeys.onboardingCompleted) ?? false;
  }

  // 쓰기 - 비동기
  @override
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(PreferenceKeys.themeMode, mode);
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(PreferenceKeys.onboardingCompleted, completed);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}
```

**DI 설정:**

```dart
// core/core_storage/lib/src/modules/preferences_module.dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class PreferencesModule {
  // WithCache 사용 시 초기화 필요
  @preResolve
  Future<SharedPreferencesWithCache> get prefsWithCache async {
    return await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        // 캐시할 키 명시 (선택사항)
        allowList: <String>{
          PreferenceKeys.themeMode,
          PreferenceKeys.languageCode,
          PreferenceKeys.onboardingCompleted,
        },
      ),
    );
  }
}
```

**장점:**
- ✅ 읽기는 동기 (UI 렌더링 시 빠름)
- ✅ 쓰기는 비동기 (메인 스레드 안전)
- ✅ 선택적 캐싱 (allowList로 메모리 절약)

**단점:**
- ❌ 초기화 필요 (앱 시작 시)

#### 3.0.3 API 선택 가이드

| 시나리오 | 권장 API |
|---------|---------|
| 새 프로젝트, 단순한 설정 | **SharedPreferencesAsync** |
| 앱 시작 시 많은 설정 읽기 (테마, 언어 등) | **SharedPreferencesWithCache** |
| 기존 프로젝트 (마이그레이션 전) | Legacy API (아래 3.1-3.3) |

#### 3.0.4 마이그레이션 가이드

**Legacy → SharedPreferencesAsync**

```dart
// ❌ Before (Legacy)
class AppPreferencesImpl {
  final SharedPreferences _prefs;
  AppPreferencesImpl(this._prefs);

  String? getThemeMode() => _prefs.getString('theme_mode');
  Future<void> setThemeMode(String mode) => _prefs.setString('theme_mode', mode);
}

// ✅ After (Async)
class AppPreferencesAsyncImpl {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<String?> getThemeMode() => _prefs.getString('theme_mode');
  Future<void> setThemeMode(String mode) => _prefs.setString('theme_mode', mode);
}
```

**Legacy → SharedPreferencesWithCache**

```dart
// ❌ Before (Legacy)
@module
abstract class PreferencesModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}

// ✅ After (WithCache)
@module
abstract class PreferencesModule {
  @preResolve
  Future<SharedPreferencesWithCache> get prefs async {
    return await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
  }
}
```

**주요 변경사항:**
1. `getInstance()` → `SharedPreferencesAsync()` 또는 `SharedPreferencesWithCache.create()`
2. 읽기 메서드가 `Future<T?>` 반환 (Async API만)
3. DI에서 타입 변경 필요

---

### 3.1 Preference Keys 정의 (모든 API 공통)

```dart
// core/core_storage/lib/src/preferences/preference_keys.dart
abstract class PreferenceKeys {
  // App Settings
  static const String themeMode = 'theme_mode';
  static const String languageCode = 'language_code';
  static const String countryCode = 'country_code';

  // User State
  static const String onboardingCompleted = 'onboarding_completed';
  static const String lastLoginAt = 'last_login_at';
  static const String userId = 'user_id';

  // Cache
  static const String cacheExpiry = 'cache_expiry';
  static const String lastSyncAt = 'last_sync_at';

  // Feature Flags
  static const String pushNotificationEnabled = 'push_notification_enabled';
  static const String analyticsEnabled = 'analytics_enabled';

  // Migration
  static const String storageVersion = 'storage_version';
}
```

### 3.2 Legacy AppPreferences 클래스 (기존 프로젝트용)

> **⚠️ 주의**: 아래는 deprecated된 synchronous API 예제입니다.
> 새 프로젝트는 위의 3.0 섹션의 새 API를 사용하세요.

```dart
// core/core_storage/lib/src/preferences/app_preferences.dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AppPreferences {
  // Theme
  Future<void> setThemeMode(String mode);
  String? getThemeMode();

  // Language
  Future<void> setLanguageCode(String code);
  String? getLanguageCode();

  // Country
  Future<void> setCountryCode(String code);
  String? getCountryCode();

  // Onboarding
  Future<void> setOnboardingCompleted(bool completed);
  bool isOnboardingCompleted();

  // User
  Future<void> setUserId(String? userId);
  String? getUserId();
  Future<void> setLastLoginAt(DateTime dateTime);
  DateTime? getLastLoginAt();

  // Notifications
  Future<void> setPushNotificationEnabled(bool enabled);
  bool isPushNotificationEnabled();

  // Storage Version (for migrations)
  Future<void> setStorageVersion(int version);
  int? getStorageVersion();

  // Clear
  Future<void> clear();
}

@LazySingleton(as: AppPreferences)
class AppPreferencesImpl implements AppPreferences {
  final SharedPreferences _prefs;

  AppPreferencesImpl(this._prefs);

  // Theme
  @override
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(PreferenceKeys.themeMode, mode);
  }

  @override
  String? getThemeMode() {
    return _prefs.getString(PreferenceKeys.themeMode);
  }

  // Language
  @override
  Future<void> setLanguageCode(String code) async {
    await _prefs.setString(PreferenceKeys.languageCode, code);
  }

  @override
  String? getLanguageCode() {
    return _prefs.getString(PreferenceKeys.languageCode);
  }

  // Country
  @override
  Future<void> setCountryCode(String code) async {
    await _prefs.setString(PreferenceKeys.countryCode, code);
  }

  @override
  String? getCountryCode() {
    return _prefs.getString(PreferenceKeys.countryCode);
  }

  // Onboarding
  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(PreferenceKeys.onboardingCompleted, completed);
  }

  @override
  bool isOnboardingCompleted() {
    return _prefs.getBool(PreferenceKeys.onboardingCompleted) ?? false;
  }

  // User
  @override
  Future<void> setUserId(String? userId) async {
    if (userId != null) {
      await _prefs.setString(PreferenceKeys.userId, userId);
    } else {
      await _prefs.remove(PreferenceKeys.userId);
    }
  }

  @override
  String? getUserId() {
    return _prefs.getString(PreferenceKeys.userId);
  }

  @override
  Future<void> setLastLoginAt(DateTime dateTime) async {
    await _prefs.setString(
      PreferenceKeys.lastLoginAt,
      dateTime.toIso8601String(),
    );
  }

  @override
  DateTime? getLastLoginAt() {
    final value = _prefs.getString(PreferenceKeys.lastLoginAt);
    if (value == null) return null;

    // DateTime.tryParse 사용 (안전한 파싱)
    return DateTime.tryParse(value);

    // 또는 try-catch 사용:
    // try {
    //   return DateTime.parse(value);
    // } catch (e) {
    //   return null;
    // }
  }

  // Notifications
  @override
  Future<void> setPushNotificationEnabled(bool enabled) async {
    await _prefs.setBool(PreferenceKeys.pushNotificationEnabled, enabled);
  }

  @override
  bool isPushNotificationEnabled() {
    return _prefs.getBool(PreferenceKeys.pushNotificationEnabled) ?? true;
  }

  // Storage Version (for migrations)
  @override
  Future<void> setStorageVersion(int version) async {
    await _prefs.setInt(PreferenceKeys.storageVersion, version);
  }

  @override
  int? getStorageVersion() {
    return _prefs.getInt(PreferenceKeys.storageVersion);
  }

  // Clear
  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}
```

### 3.3 Legacy DI 설정 (기존 프로젝트용)

> **⚠️ 주의**: 아래는 deprecated된 synchronous API의 DI 설정입니다.

```dart
// core/core_storage/lib/src/modules/preferences_module.dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class PreferencesModule {
  @preResolve
  @Deprecated('Use SharedPreferencesAsync or SharedPreferencesWithCache')
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
```

## 4. Isar Plus Database

### 4.0 Isar Plus 소개

> **ℹ️ Isar Plus (2026년 1월 기준)**:
> - 원본 Isar가 2024년 이후 개발 중단됨에 따라 커뮤니티에서 **Isar Plus**를 포크하여 유지보수하고 있습니다.
> - `isar_plus: ^1.2.1` 사용을 권장합니다.
> - 기존 Isar API와 호환되며, 버그 수정 및 Flutter 최신 버전 지원이 이루어지고 있습니다.

#### 4.0.1 권장 대안

| 대안 | 유형 | 장점 | 단점 | 마이그레이션 난이도 |
|------|------|------|------|-----------------|
| **Drift** | SQL | ✅ 활발한 개발<br>✅ 타입 안전<br>✅ 관계형 쿼리 강력<br>✅ 마이그레이션 시스템 | ❌ SQL 지식 필요<br>❌ 코드 생성 필수 | 중간 |
| **ObjectBox** | NoSQL | ✅ 매우 빠름 (Isar급)<br>✅ 상업적 지원<br>✅ 관계 지원<br>✅ 쿼리 언어 유사 | ❌ 일부 상업 기능 유료<br>❌ 생태계 작음 | 낮음 (Isar 유사) |
| **Hive** | Key-Value | ✅ 가볍고 빠름<br>✅ 간단한 API<br>✅ 코드 생성 선택적 | ❌ 관계형 쿼리 약함<br>❌ 인덱싱 제한적 | 높음 (구조 단순화) |
| **SQFlite** | SQL | ✅ 성숙한 생태계<br>✅ Raw SQL 지원<br>✅ 가볍고 안정적 | ❌ 타입 안전 없음<br>❌ 수동 쿼리 작성 | 중간 |

#### 4.0.2 대안 선택 가이드

```
새 프로젝트 선택 기준:

복잡한 관계형 데이터 + SQL 가능
  → Drift (추천!)

Isar 같은 NoSQL + 고성능 필수
  → ObjectBox

간단한 로컬 캐싱만
  → Hive

Raw SQL 제어 원함
  → SQFlite
```

#### 4.0.3 Drift 예제 (Isar 대체)

```dart
// drift_database.dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'drift_database.g.dart';

// 테이블 정의 (Isar Collection 대신)
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().unique()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();
}

class SearchHistories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get query => text()();
  DateTimeColumn get searchedAt => dateTime()();
  IntColumn get searchCount => integer().withDefault(const Constant(1))();
}

// Database 클래스
@DriftDatabase(tables: [Users, SearchHistories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'app_database');
  }

  // 쿼리 예시 (Isar와 유사하지만 타입 안전)
  Future<List<SearchHistory>> getSearchHistory({int limit = 10}) {
    return (select(searchHistories)
          ..orderBy([(t) => OrderingTerm.desc(t.searchedAt)])
          ..limit(limit))
        .get();
  }

  Future<void> saveSearchQuery(String query) async {
    final existing = await (select(searchHistories)
          ..where((tbl) => tbl.query.equals(query)))
        .getSingleOrNull();

    if (existing != null) {
      await (update(searchHistories)..where((t) => t.id.equals(existing.id)))
          .write(SearchHistoriesCompanion(
        searchCount: Value(existing.searchCount + 1),
        searchedAt: Value(DateTime.now()),
      ));
    } else {
      await into(searchHistories).insert(SearchHistoriesCompanion.insert(
        query: query,
        searchedAt: DateTime.now(),
      ));
    }
  }
}
```

**왜 Drift를 추천하나?**
- ✅ 타입 안전한 쿼리 빌더
- ✅ 마이그레이션 시스템 내장
- ✅ 스트림 지원 (watch)
- ✅ 활발한 커뮤니티와 업데이트
- ✅ SQLite 기반이라 안정적

---

> **아래 섹션 (4.1-4.4)은 기존 Isar 프로젝트 유지보수용입니다.**
> 새 프로젝트는 위의 대안을 사용하세요.

### 4.1 Collection 정의

```dart
// core/core_storage/lib/src/database/collections/cached_user.dart
// 참고: isar_plus 사용 시
// import 'package:isar_plus/isar_plus.dart';
import 'package:isar/isar.dart';  // 또는 isar_plus 사용

part 'cached_user.g.dart';

@collection
class CachedUser {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String odId;

  late String name;
  String? email;
  String? avatarUrl;

  @Index()
  late DateTime cachedAt;

  late DateTime? lastLoginAt;
}
```

```dart
// core/core_storage/lib/src/database/collections/search_history.dart
import 'package:isar/isar.dart';

part 'search_history.g.dart';

@collection
class SearchHistory {
  Id id = Isar.autoIncrement;

  @Index()
  late String query;

  @Index()
  late DateTime searchedAt;

  int searchCount = 1;
}
```

```dart
// core/core_storage/lib/src/database/collections/cart_item.dart
import 'package:isar/isar.dart';

part 'cart_item.g.dart';

@collection
class CartItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String productId;

  late String productName;
  late double price;
  late int quantity;
  String? imageUrl;

  @Index()
  late DateTime addedAt;
}
```

### 4.2 Isar Database 설정

```dart
// core/core_storage/lib/src/database/isar_database.dart
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'collections/cached_user.dart';
import 'collections/search_history.dart';
import 'collections/cart_item.dart';

abstract class IsarDatabase {
  Isar get instance;
  Future<void> close();
  Future<void> clear();
}

@LazySingleton(as: IsarDatabase)
class IsarDatabaseImpl implements IsarDatabase {
  Isar? _isar;

  @override
  Isar get instance {
    if (_isar == null || !_isar!.isOpen) {
      throw StateError('Isar database not initialized. Call init() first.');
    }
    return _isar!;
  }

  @factoryMethod
  static Future<IsarDatabaseImpl> create() async {
    final impl = IsarDatabaseImpl();
    await impl._init();
    return impl;
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        CachedUserSchema,
        SearchHistorySchema,
        CartItemSchema,
      ],
      directory: dir.path,
      name: 'app_database',
    );
  }

  @override
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  @override
  Future<void> clear() async {
    await _isar?.writeTxn(() async {
      await _isar!.clear();
    });
  }
}
```

### 4.3 Repository 패턴으로 Isar 사용

```dart
// features/search/lib/data/datasources/search_local_datasource.dart
import 'package:isar/isar.dart';
import 'package:injectable/injectable.dart';
import 'package:core_storage/core_storage.dart';

abstract class SearchLocalDataSource {
  Future<List<SearchHistory>> getSearchHistory({int limit = 10});
  Future<void> saveSearchQuery(String query);
  Future<void> deleteSearchHistory(int id);
  Future<void> clearSearchHistory();
}

@LazySingleton(as: SearchLocalDataSource)
class SearchLocalDataSourceImpl implements SearchLocalDataSource {
  final IsarDatabase _database;

  SearchLocalDataSourceImpl(this._database);

  Isar get _isar => _database.instance;

  @override
  Future<List<SearchHistory>> getSearchHistory({int limit = 10}) async {
    return await _isar.searchHistorys
        .where()
        .sortBySearchedAtDesc()
        .limit(limit)
        .findAll();
  }

  @override
  Future<void> saveSearchQuery(String query) async {
    await _isar.writeTxn(() async {
      // 기존 검색어 확인
      final existing = await _isar.searchHistorys
          .where()
          .queryEqualTo(query)
          .findFirst();

      if (existing != null) {
        // 검색 횟수 증가
        existing.searchCount++;
        existing.searchedAt = DateTime.now();
        await _isar.searchHistorys.put(existing);
      } else {
        // 새 검색어 저장
        final history = SearchHistory()
          ..query = query
          ..searchedAt = DateTime.now();
        await _isar.searchHistorys.put(history);
      }
    });
  }

  @override
  Future<void> deleteSearchHistory(int id) async {
    await _isar.writeTxn(() async {
      await _isar.searchHistorys.delete(id);
    });
  }

  @override
  Future<void> clearSearchHistory() async {
    await _isar.writeTxn(() async {
      await _isar.searchHistorys.clear();
    });
  }
}
```

### 4.4 Cart DataSource 예시

```dart
// features/cart/lib/data/datasources/cart_local_datasource.dart
import 'package:isar/isar.dart';
import 'package:injectable/injectable.dart';
import 'package:core_storage/core_storage.dart';

abstract class CartLocalDataSource {
  Future<List<CartItem>> getCartItems();
  Future<void> addToCart(CartItem item);
  Future<void> updateQuantity(String productId, int quantity);
  Future<void> removeFromCart(String productId);
  Future<void> clearCart();
  Stream<List<CartItem>> watchCartItems();
}

@LazySingleton(as: CartLocalDataSource)
class CartLocalDataSourceImpl implements CartLocalDataSource {
  final IsarDatabase _database;

  CartLocalDataSourceImpl(this._database);

  Isar get _isar => _database.instance;

  @override
  Future<List<CartItem>> getCartItems() async {
    return await _isar.cartItems.where().findAll();
  }

  @override
  Future<void> addToCart(CartItem item) async {
    await _isar.writeTxn(() async {
      // 이미 장바구니에 있는지 확인
      final existing = await _isar.cartItems
          .where()
          .productIdEqualTo(item.productId)
          .findFirst();

      if (existing != null) {
        // 수량 증가
        existing.quantity += item.quantity;
        await _isar.cartItems.put(existing);
      } else {
        // 새로 추가
        item.addedAt = DateTime.now();
        await _isar.cartItems.put(item);
      }
    });
  }

  @override
  Future<void> updateQuantity(String productId, int quantity) async {
    await _isar.writeTxn(() async {
      final item = await _isar.cartItems
          .where()
          .productIdEqualTo(productId)
          .findFirst();

      if (item != null) {
        if (quantity <= 0) {
          await _isar.cartItems.delete(item.id);
        } else {
          item.quantity = quantity;
          await _isar.cartItems.put(item);
        }
      }
    });
  }

  @override
  Future<void> removeFromCart(String productId) async {
    await _isar.writeTxn(() async {
      await _isar.cartItems
          .where()
          .productIdEqualTo(productId)
          .deleteFirst();
    });
  }

  @override
  Future<void> clearCart() async {
    await _isar.writeTxn(() async {
      await _isar.cartItems.clear();
    });
  }

  @override
  Stream<List<CartItem>> watchCartItems() {
    return _isar.cartItems.where().watch(fireImmediately: true);
  }
}
```

## 5. Secure Storage

> **✅ 업데이트 (2026년 1월)**: flutter_secure_storage v10.0.0 새로운 API 적용

### 5.0 v10.0.0 Breaking Changes

flutter_secure_storage v10.0.0에서 초기화 API가 변경되었습니다.

**주요 변경사항:**
- `const FlutterSecureStorage(aOptions: ..., iOptions: ...)` → `FlutterSecureStorage.standard(androidOptions: ..., iosOptions: ...)`
- Android/iOS 옵션 객체 변경
- 더 명확한 네이밍과 타입 안전성

### 5.1 SecureStorage 클래스 (v10.0.0)

```dart
// core/core_storage/lib/src/secure/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

abstract class SecureStorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'secure_user_id';
  static const String encryptionKey = 'encryption_key';
  static const String biometricEnabled = 'biometric_enabled';
}

abstract class TokenStorage {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> deleteTokens();
  Future<bool> hasValidTokens();
}

@LazySingleton(as: TokenStorage)
class TokenStorageImpl implements TokenStorage {
  final FlutterSecureStorage _storage;

  TokenStorageImpl(this._storage);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(
        key: SecureStorageKeys.accessToken,
        value: accessToken,
      ),
      _storage.write(
        key: SecureStorageKeys.refreshToken,
        value: refreshToken,
      ),
    ]);
  }

  @override
  Future<String?> getAccessToken() async {
    return await _storage.read(key: SecureStorageKeys.accessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: SecureStorageKeys.refreshToken);
  }

  @override
  Future<void> deleteTokens() async {
    await Future.wait([
      _storage.delete(key: SecureStorageKeys.accessToken),
      _storage.delete(key: SecureStorageKeys.refreshToken),
    ]);
  }

  @override
  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
```

### 5.2 SecureStorage DI 설정 (v10.0.0)

```dart
// core/core_storage/lib/src/modules/secure_storage_module.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@module
abstract class SecureStorageModule {
  // ⚠️ 주의: flutter_secure_storage v10.0.0은 아직 beta 버전입니다.
  // Production에서는 v9.x stable 버전 사용을 권장합니다.
  // v10 API는 변경될 수 있습니다.
  @lazySingleton
  FlutterSecureStorage get secureStorage {
    return FlutterSecureStorage.standard(
      // Android 옵션 (v10+ 새 API)
      androidOptions: const AndroidSecureStorageOptions(
        encryptedSharedPreferences: true,
        sharedPreferencesName: 'secure_prefs',
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),

      // iOS 옵션 (v10+ 새 API)
      iosOptions: const IOSSecureStorageOptions(
        accessibility: IOSAccessibility.first_unlock_this_device,
        accountName: 'app_secure_storage',
      ),

      // Linux 옵션 (v10+ 추가)
      linuxOptions: const LinuxSecureStorageOptions(),

      // macOS 옵션 (v10+ 추가)
      macOSOptions: const MacOSSecureStorageOptions(
        accessibility: MacOSAccessibility.first_unlock_this_device,
        accountName: 'app_secure_storage',
      ),

      // Web 옵션 (v10+ 추가)
      webOptions: const WebSecureStorageOptions(),

      // Windows 옵션 (v10+ 추가)
      windowsOptions: const WindowsSecureStorageOptions(),
    );
  }
}
```

#### 5.2.1 v9 → v10 마이그레이션

**Before (v9.x):**
```dart
// ❌ Old API (v9)
const androidOptions = AndroidOptions(
  encryptedSharedPreferences: true,
);

const iosOptions = IOSOptions(
  accessibility: KeychainAccessibility.first_unlock_this_device,
);

final storage = const FlutterSecureStorage(
  aOptions: androidOptions,
  iOptions: iosOptions,
);
```

**After (v10+):**
```dart
// ✅ New API (v10)
final storage = FlutterSecureStorage.standard(
  androidOptions: const AndroidSecureStorageOptions(
    encryptedSharedPreferences: true,
  ),
  iosOptions: const IOSSecureStorageOptions(
    accessibility: IOSAccessibility.first_unlock_this_device,
  ),
);
```

**주요 차이점:**
1. `FlutterSecureStorage()` → `FlutterSecureStorage.standard()`
2. `aOptions`/`iOptions` → `androidOptions`/`iosOptions`
3. `AndroidOptions` → `AndroidSecureStorageOptions`
4. `IOSOptions` → `IOSSecureStorageOptions`
5. `KeychainAccessibility` → `IOSAccessibility`
6. 더 세밀한 암호화 알고리즘 제어 가능
7. Linux, macOS, Web, Windows 옵션 추가

#### 5.2.2 Android 암호화 알고리즘 선택 (v10+)

```dart
// 강력한 보안 (API 23+)
androidOptions: const AndroidSecureStorageOptions(
  encryptedSharedPreferences: true,
  keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
  storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
),

// 호환성 우선 (API 18+)
androidOptions: const AndroidSecureStorageOptions(
  encryptedSharedPreferences: false,  // EncryptedSharedPreferences는 API 23+
  keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
  storageCipherAlgorithm: StorageCipherAlgorithm.AES_CBC_PKCS7Padding,
),
```

### 5.3 플랫폼별 설정

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
    <application
        android:allowBackup="false"
        ...>
        <!-- SecureStorage 자동 백업 제외 -->
    </application>
</manifest>
```

## 6. 통합 Storage Service

### 6.1 통합 인터페이스

```dart
// core/core_storage/lib/src/storage_service.dart
import 'package:injectable/injectable.dart';

abstract class StorageService {
  // Preferences
  AppPreferences get preferences;

  // Token
  TokenStorage get tokenStorage;

  // Database
  IsarDatabase get database;

  // 전체 초기화 (로그아웃 시)
  Future<void> clearAll();

  // 캐시만 초기화
  Future<void> clearCache();
}

@LazySingleton(as: StorageService)
class StorageServiceImpl implements StorageService {
  @override
  final AppPreferences preferences;

  @override
  final TokenStorage tokenStorage;

  @override
  final IsarDatabase database;

  StorageServiceImpl(
    this.preferences,
    this.tokenStorage,
    this.database,
  );

  @override
  Future<void> clearAll() async {
    await Future.wait([
      preferences.clear(),
      tokenStorage.deleteTokens(),
      database.clear(),
    ]);
  }

  @override
  Future<void> clearCache() async {
    // 캐시 관련 데이터만 초기화
    await database.clear();
  }
}
```

## 7. Feature에서 사용

### 7.1 Auth Feature - 토큰 저장

```dart
// features/auth/lib/data/repositories/auth_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:core_storage/core_storage.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;
  final AppPreferences _preferences;

  AuthRepositoryImpl(
    this._remoteDataSource,
    this._tokenStorage,
    this._preferences,
  );

  @override
  Future<Either<AuthFailure, User>> login(String email, String password) async {
    try {
      final response = await _remoteDataSource.login(email, password);

      // 토큰 저장 (SecureStorage)
      await _tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      // 사용자 ID 저장 (Preferences)
      await _preferences.setUserId(response.user.id);
      await _preferences.setLastLoginAt(DateTime.now());

      return Right(response.user.toEntity());
    // import 'package:dio/dio.dart';
    } on DioException catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> logout() async {
    try {
      await _remoteDataSource.logout();

      // 토큰 삭제
      await _tokenStorage.deleteTokens();
      await _preferences.setUserId(null);

      return const Right(unit);
    } catch (e) {
      // 로컬 데이터는 삭제
      await _tokenStorage.deleteTokens();
      await _preferences.setUserId(null);

      return const Right(unit);
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return await _tokenStorage.hasValidTokens();
  }
}
```

### 7.2 Settings Feature - 설정 관리

```dart
// features/settings/lib/data/repositories/settings_repository_impl.dart
import 'package:injectable/injectable.dart';
import 'package:core_storage/core_storage.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  final AppPreferences _preferences;

  SettingsRepositoryImpl(this._preferences);

  @override
  ThemeMode getThemeMode() {
    final value = _preferences.getThemeMode();
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _preferences.setThemeMode(value);
  }

  @override
  String getLanguageCode() {
    return _preferences.getLanguageCode() ?? 'ko';
  }

  @override
  Future<void> setLanguageCode(String code) async {
    await _preferences.setLanguageCode(code);
  }

  @override
  String getCountryCode() {
    return _preferences.getCountryCode() ?? 'KR';
  }

  @override
  Future<void> setCountryCode(String code) async {
    await _preferences.setCountryCode(code);
  }

  @override
  bool isPushNotificationEnabled() {
    return _preferences.isPushNotificationEnabled();
  }

  @override
  Future<void> setPushNotificationEnabled(bool enabled) async {
    await _preferences.setPushNotificationEnabled(enabled);
  }
}
```

## 8. 캐시 전략

### 8.1 캐시 만료 처리

```dart
// core/core_storage/lib/src/cache/cache_manager.dart
import 'package:injectable/injectable.dart';

abstract class CacheManager {
  Future<T?> get<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration expiry = const Duration(hours: 1),
  });
  Future<void> invalidate(String key);
  Future<void> invalidateAll();
}

@LazySingleton(as: CacheManager)
class CacheManagerImpl implements CacheManager {
  final IsarDatabase _database;  // TODO: 디스크 캐싱에 사용 예정
  final Map<String, CacheEntry> _memoryCache = {};

  CacheManagerImpl(this._database);

  @override
  Future<T?> get<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration expiry = const Duration(hours: 1),
  }) async {
    // 1. 메모리 캐시 확인
    final memoryCached = _memoryCache[key];
    if (memoryCached != null && !memoryCached.isExpired) {
      return memoryCached.data as T;
    }

    // 2. 네트워크에서 가져오기
    try {
      final data = await fetcher();

      // 3. 캐시에 저장
      _memoryCache[key] = CacheEntry(
        data: data,
        expiry: DateTime.now().add(expiry),
      );

      return data;
    } catch (e) {
      // 네트워크 실패 시 만료된 캐시라도 반환
      if (memoryCached != null) {
        return memoryCached.data as T;
      }
      rethrow;
    }
  }

  @override
  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
  }

  @override
  Future<void> invalidateAll() async {
    _memoryCache.clear();
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiry;

  CacheEntry({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}
```

## 9. 테스트

### 9.1 SharedPreferences Mock

```dart
// test/mocks/mock_shared_preferences.dart
import 'package:shared_preferences/shared_preferences.dart';

Future<void> setupMockPreferences([Map<String, Object>? values]) async {
  SharedPreferences.setMockInitialValues(values ?? {});
}

// 테스트에서 사용
void main() {
  setUp(() async {
    await setupMockPreferences({
      'theme_mode': 'dark',
      'language_code': 'ko',
    });
  });

  test('테마 모드 가져오기', () async {
    final prefs = await SharedPreferences.getInstance();
    final appPrefs = AppPreferencesImpl(prefs);

    expect(appPrefs.getThemeMode(), 'dark');
  });
}
```

### 9.2 SecureStorage Mock

```dart
// test/mocks/mock_secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'mock_secure_storage.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  late MockFlutterSecureStorage mockStorage;
  late TokenStorageImpl tokenStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    tokenStorage = TokenStorageImpl(mockStorage);
  });

  test('토큰 저장 및 조회', () async {
    // Arrange
    when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
        .thenAnswer((_) async {});
    when(mockStorage.read(key: SecureStorageKeys.accessToken))
        .thenAnswer((_) async => 'test_token');

    // Act
    await tokenStorage.saveTokens(
      accessToken: 'test_token',
      refreshToken: 'refresh_token',
    );
    final token = await tokenStorage.getAccessToken();

    // Assert
    expect(token, 'test_token');
  });
}
```

## 10. 데이터베이스 암호화

### 10.1 SQLCipher (Drift 암호화)

```yaml
# pubspec.yaml
dependencies:
  drift: ^2.15.0
  sqlite3_flutter_libs: ^0.5.0
  sqlcipher_flutter_libs: ^0.6.0  # SQLCipher 지원
```

```dart
// lib/core/database/encrypted_database.dart
// import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:path/path.dart' as p;

LazyDatabase openEncryptedDatabase(String name, String password) {
  return LazyDatabase(() async {
    // SQLCipher 라이브러리 로드
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, '$name.db'));

    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        // 암호화 키 설정
        db.execute("PRAGMA key = '$password';");
        // 암호화 검증
        db.execute('SELECT count(*) FROM sqlite_master;');
      },
    );
  });
}
```

### 10.2 암호화 키 관리

```dart
// import 'dart:math';
// import 'dart:convert';
class DatabaseKeyManager {
  final FlutterSecureStorage _secureStorage;

  DatabaseKeyManager(this._secureStorage);

  /// 암호화 키 생성 또는 로드
  Future<String> getOrCreateKey() async {
    const keyName = 'database_encryption_key';

    var key = await _secureStorage.read(key: keyName);
    if (key == null) {
      // 256비트 랜덤 키 생성
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      key = base64Encode(bytes);
      await _secureStorage.write(key: keyName, value: key);
    }

    return key;
  }

  /// 키 마이그레이션 (비밀번호 변경)
  Future<void> rotateKey(String oldKey, String newKey) async {
    final db = await openEncryptedDatabase('app', oldKey);
    await db.customStatement("PRAGMA rekey = '$newKey';");
    await _secureStorage.write(key: 'database_encryption_key', value: newKey);
  }
}
```

### 10.3 ObjectBox 암호화

```dart
// ObjectBox 암호화 설정
final store = await openStore(
  directory: dbPath,
  // 256비트 암호화 키
  encryptionKey: await _getEncryptionKey(),
);

Future<Uint8List> _getEncryptionKey() async {
  final keyString = await _keyManager.getOrCreateKey();
  return base64Decode(keyString);
}
```

### 10.4 마이그레이션 시 암호화 유지

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async {
    await m.createAll();
  },
  onUpgrade: (m, from, to) async {
    // 암호화된 상태에서 마이그레이션 수행
    if (from < 2) {
      await m.addColumn(users, users.profileImage);
    }
  },
  beforeOpen: (details) async {
    // 암호화 상태 검증
    await customStatement('SELECT count(*) FROM sqlite_master;');
  },
);
```

### 10.5 주의사항

| 항목 | 설명 |
|-----|------|
| 성능 | 암호화는 약 5-15% 성능 오버헤드 발생 |
| 키 분실 | 암호화 키 분실 시 데이터 복구 불가 |
| 백업 | 암호화된 DB 백업 시 키도 함께 관리 필요 |
| 디버깅 | DB Browser에서 암호화된 DB 열람 불가 |

## 11. Best Practices

### 11.1 저장소 선택 가이드 (2026년 기준)

| 데이터 유형 | 저장소 | 이유 |
|------------|--------|------|
| 앱 설정 | SharedPreferencesAsync/WithCache | 간단한 Key-Value (새 async API) |
| 토큰/비밀번호 | SecureStorage v10+ | 암호화 필요 (플랫폼별 강화) |
| 복잡한 객체 | Drift 또는 ObjectBox | 쿼리/관계 필요 (⚠️ Isar 개발 중단) |
| 임시 캐시 | 메모리 + Drift/ObjectBox | 빠른 접근 + 영속성 |

### 11.2 DO (이렇게 하세요) - 2026 업데이트

| 항목 | 설명 | 예시 |
|------|------|------|
| **새 API 사용** | SharedPreferencesAsync 또는 WithCache 사용 | ✅ `SharedPreferencesAsync()` |
| **SecureStorage v10** | 새로운 초기화 API 사용 | ✅ `FlutterSecureStorage.standard()` |
| **Isar 피하기** | 새 프로젝트는 Drift/ObjectBox | ✅ Drift로 시작 |
| **Key 상수화** | PreferenceKeys 클래스로 관리 | ✅ `PreferenceKeys.themeMode` |
| **인터페이스 분리** | TokenStorage, AppPreferences 등 | ✅ 단일 책임 원칙 |
| **비동기 초기화** | WithCache는 앱 시작 시 초기화 | ✅ `@preResolve` 사용 |
| **타입 안전성** | Generic이 아닌 명시적 메서드 | ✅ `Future<String?>` 반환 |

### 11.3 DON'T (하지 마세요) - 2026 업데이트

```dart
// ❌ Legacy SharedPreferences API 사용
final prefs = await SharedPreferences.getInstance();  // Deprecated!
// ✅ SharedPreferencesAsync 또는 WithCache 사용

// ❌ 구 SecureStorage 초기화 (v9)
final storage = FlutterSecureStorage(aOptions: ...);  // v10에서 제거됨
// ✅ FlutterSecureStorage.standard() 사용

// ❌ Isar를 새 프로젝트에 사용
dependencies:
  isar: ^3.1.0  // 개발 중단!
// ✅ Drift 또는 ObjectBox 사용

// ❌ Key 하드코딩
await prefs.setString('user_token', token);
// ✅ PreferenceKeys.userToken 상수 사용

// ❌ 토큰을 SharedPreferences에 저장
await prefs.setString('token', accessToken);
// ✅ SecureStorage 사용

// ❌ 대용량 데이터를 SharedPreferences에
await prefs.setString('users', jsonEncode(userList));
// ✅ Drift/ObjectBox 사용

// ❌ 동기 호출 가정 (SharedPreferencesAsync 사용 시)
final theme = prefs.getString('theme');  // await 필요!
// ✅ await prefs.getString('theme');
```

## 12. 마이그레이션

### 12.1 Isar 스키마 변경

```dart
// 버전 관리가 필요한 경우
@collection
class CachedUser {
  Id id = Isar.autoIncrement;

  late String odId;
  late String name;

  // 새 필드 추가 시 nullable 또는 기본값 필요
  String? newField;  // nullable로 추가
}
```

### 12.2 데이터 마이그레이션

```dart
// app/lib/src/migration/storage_migration.dart
class StorageMigration {
  final AppPreferences _preferences;
  final IsarDatabase _database;

  StorageMigration(this._preferences, this._database);

  Future<void> migrate() async {
    final currentVersion = _preferences.getStorageVersion() ?? 0;

    if (currentVersion < 1) {
      await _migrateV0ToV1();
    }

    if (currentVersion < 2) {
      await _migrateV1ToV2();
    }

    await _preferences.setStorageVersion(2);
  }

  Future<void> _migrateV0ToV1() async {
    // V1 마이그레이션 로직
  }

  Future<void> _migrateV1ToV2() async {
    // V2 마이그레이션 로직
  }
}
```

## 13. 2026년 1월 업데이트 요약

이 문서는 2026년 1월 기준 최신 Flutter 로컬 저장소 베스트 프랙티스를 반영합니다.

### 주요 변경사항

#### 1. SharedPreferences - 새로운 Async API
- **Legacy API Deprecated**: `SharedPreferences.getInstance()` 사용 중단
- **새 API 2가지**:
  - `SharedPreferencesAsync`: 완전 비동기, 초기화 불필요
  - `SharedPreferencesWithCache`: 하이브리드 (동기 읽기 + 비동기 쓰기)
- **마이그레이션 필수**: 기존 코드 업데이트 권장

#### 2. flutter_secure_storage v10.0.0 - Breaking Changes
- **초기화 API 변경**: `FlutterSecureStorage()` → `FlutterSecureStorage.standard()`
- **옵션 객체 변경**:
  - `AndroidOptions` → `AndroidSecureStorageOptions`
  - `IOSOptions` → `IOSSecureStorageOptions`
- **새 플랫폼 지원**: Linux, macOS, Web, Windows 옵션 추가
- **향상된 암호화**: 더 세밀한 알고리즘 제어

#### 3. Isar 개발 중단 - 대안 필수
- **⚠️ 개발 중단**: 2024년 이후 업데이트 없음
- **권장 대안**:
  - **Drift** (SQL): 타입 안전, 마이그레이션 시스템, 활발한 개발
  - **ObjectBox** (NoSQL): Isar 유사, 고성능, 상업적 지원
- **기존 프로젝트**: 동작은 하지만 장기적으로 마이그레이션 고려

### 새 프로젝트 권장 스택 (2026)

```yaml
dependencies:
  # Key-Value 설정
  shared_preferences: ^2.5.4  # Async API 사용

  # 보안 저장소
  flutter_secure_storage: ^10.0.0  # v10 새 API

  # 데이터베이스 (택 1)
  drift: ^2.14.0  # SQL, 권장!
  # objectbox: ^2.4.0  # NoSQL 대안

  injectable: ^2.5.0
  path_provider: ^2.1.2

dev_dependencies:
  drift_dev: ^2.14.0  # Drift 사용 시
  build_runner: ^2.4.15
```

### 마이그레이션 체크리스트

- [ ] SharedPreferences → SharedPreferencesAsync 또는 WithCache
- [ ] SecureStorage v9 → v10 (초기화 API 변경)
- [ ] Isar 의존성 확인 (새 프로젝트면 Drift로 변경)
- [ ] DI 설정 업데이트 (PreferencesModule, SecureStorageModule)
- [ ] 테스트 코드 업데이트

## 14. 참고

- [SharedPreferences 공식 문서](https://pub.dev/packages/shared_preferences)
- [Flutter Secure Storage 공식 문서](https://pub.dev/packages/flutter_secure_storage)
- [Drift 공식 문서](https://drift.simonbinder.eu/)
- [ObjectBox 공식 문서](https://docs.objectbox.io/getting-started)
- [Isar 공식 문서 (레거시)](https://isar.dev/)

---

## 실습 과제

### 과제 1: 사용자 설정 저장
SharedPreferences로 테마 모드(라이트/다크), 언어 설정, 알림 On/Off를 저장하고 앱 재시작 시 복원하세요.

### 과제 2: 보안 데이터 관리
SecureStorage로 JWT 토큰과 리프레시 토큰을 저장하고, 토큰 만료 시 자동 갱신 로직을 구현하세요.

### 과제 3: 로컬 캐시 전략
API 응답 데이터를 로컬에 캐시하고, 네트워크 연결이 없을 때 캐시 데이터를 반환하는 Repository를 구현하세요.

## Self-Check

- [ ] SharedPreferences와 SecureStorage의 용도 차이를 설명할 수 있는가?
- [ ] 민감한 데이터(토큰, 비밀번호)를 SecureStorage에 저장하고 있는가?
- [ ] 로컬 저장소 접근을 Repository 패턴으로 추상화할 수 있는가?
- [ ] 캐시 만료 전략(TTL)을 구현할 수 있는가?
