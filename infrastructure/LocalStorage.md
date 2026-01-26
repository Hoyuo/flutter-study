# Flutter Local Storage Guide

> 이 문서는 SharedPreferences, Isar, SecureStorage를 사용한 로컬 저장소 패턴을 설명합니다.

## 1. 개요

### 1.1 저장소 종류 비교

| 저장소 | 용도 | 데이터 유형 | 보안 |
|--------|------|------------|------|
| **SharedPreferences** | 간단한 설정값 | Key-Value (primitive) | 낮음 |
| **Isar** | 복잡한 구조화 데이터 | 객체/컬렉션 | 중간 |
| **SecureStorage** | 민감한 정보 | Key-Value | 높음 (암호화) |

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
  shared_preferences: ^2.2.0
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  flutter_secure_storage: ^9.0.0
  injectable: ^2.3.0
  path_provider: ^2.1.0

dev_dependencies:
  isar_generator: ^3.1.0
  build_runner: ^2.4.0
  injectable_generator: ^2.4.0
```

## 3. SharedPreferences

### 3.1 Preference Keys 정의

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
}
```

### 3.2 AppPreferences 클래스

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
    return value != null ? DateTime.parse(value) : null;
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

  // Clear
  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}
```

### 3.3 DI 설정

```dart
// core/core_storage/lib/src/modules/preferences_module.dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class PreferencesModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
```

## 4. Isar Database

### 4.1 Collection 정의

```dart
// core/core_storage/lib/src/database/collections/cached_user.dart
import 'package:isar/isar.dart';

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

### 5.1 SecureStorage 클래스

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

### 5.2 SecureStorage DI 설정

```dart
// core/core_storage/lib/src/modules/secure_storage_module.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@module
abstract class SecureStorageModule {
  @lazySingleton
  FlutterSecureStorage get secureStorage {
    // Android 옵션 설정
    const androidOptions = AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'secure_prefs',
      preferencesKeyPrefix: 'app_',
    );

    // iOS 옵션 설정
    const iosOptions = IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    );

    return const FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iosOptions,
    );
  }
}
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
  final IsarDatabase _database;
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
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late TokenStorageImpl tokenStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    tokenStorage = TokenStorageImpl(mockStorage);
  });

  test('토큰 저장 및 조회', () async {
    // Arrange
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => mockStorage.read(key: SecureStorageKeys.accessToken))
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

## 10. Best Practices

### 10.1 저장소 선택 가이드

| 데이터 유형 | 저장소 | 이유 |
|------------|--------|------|
| 앱 설정 | SharedPreferences | 간단한 Key-Value |
| 토큰/비밀번호 | SecureStorage | 암호화 필요 |
| 복잡한 객체 | Isar | 쿼리/관계 필요 |
| 임시 캐시 | 메모리 + Isar | 빠른 접근 + 영속성 |

### 10.2 DO (이렇게 하세요)

| 항목 | 설명 |
|------|------|
| Key 상수화 | PreferenceKeys 클래스로 관리 |
| 인터페이스 분리 | TokenStorage, AppPreferences 등 |
| 비동기 초기화 | Isar, SharedPreferences는 async |
| 타입 안전성 | Generic이 아닌 명시적 메서드 |

### 10.3 DON'T (하지 마세요)

```dart
// ❌ Key 하드코딩
await prefs.setString('user_token', token);  // Key 상수 사용

// ❌ 토큰을 SharedPreferences에 저장
await prefs.setString('token', accessToken);  // SecureStorage 사용

// ❌ 대용량 데이터를 SharedPreferences에
await prefs.setString('users', jsonEncode(userList));  // Isar 사용

// ❌ 동기 호출 가정
final token = secureStorage.read(key: 'token');  // await 필요
```

## 11. 마이그레이션

### 11.1 Isar 스키마 변경

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

### 11.2 데이터 마이그레이션

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

## 12. 참고

- [SharedPreferences 공식 문서](https://pub.dev/packages/shared_preferences)
- [Isar 공식 문서](https://isar.dev/)
- [Flutter Secure Storage 공식 문서](https://pub.dev/packages/flutter_secure_storage)
