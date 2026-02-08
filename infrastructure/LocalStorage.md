# Flutter Local Storage Guide

> **난이도**: 중급 | **카테고리**: infrastructure
> **선행 학습**: [Architecture](../core/Architecture.md)
> **예상 학습 시간**: 2h

> 이 문서는 SharedPreferences, Drift, Isar Plus, SecureStorage를 사용한 로컬 저장소 패턴을 설명합니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - SharedPreferences로 간단한 키-값 데이터를 저장할 수 있다
> - Drift를 사용하여 복잡한 쿼리(JOIN, 서브쿼리, 집계)를 작성하고 실시간 Stream으로 UI를 갱신할 수 있다
> - 스키마 마이그레이션과 인덱싱 전략으로 프로덕션급 데이터베이스를 안전하게 관리할 수 있다
> - FTS(Full-Text Search), 암호화, 대용량 데이터 처리 등 실전 시나리오를 구현할 수 있다
> - SecureStorage로 민감한 데이터를 안전하게 관리할 수 있다
> - 용도에 맞는 로컬 저장소 솔루션을 선택하고 구현할 수 있다

## 1. 개요

### 1.1 저장소 종류 비교

| 저장소 | 용도 | 데이터 유형 | 보안 | 상태 |
|--------|------|------------|------|------|
| **SharedPreferences** | 간단한 설정값 | Key-Value (primitive) | 낮음 | ✅ 활발 (새 async API) |
| **Drift** | 복잡한 관계형 데이터 | SQL (테이블/관계) | 중간 (SQLCipher 지원) | ✅ 활발 (권장) |
| **Isar Plus** | 복잡한 구조화 데이터 | 객체/컬렉션 | 중간 | ✅ 커뮤니티 포크 (원본 Isar 대체) |
| **SecureStorage** | 민감한 정보 | Key-Value | 높음 (암호화) | ✅ 활발 (v10+) |

### 1.2 사용 시나리오

```
SharedPreferences
├── 앱 설정 (테마, 언어)
├── 온보딩 완료 여부
├── 마지막 로그인 시간
└── 캐시 만료 시간

Drift (SQLite)
├── 복잡한 관계형 데이터 (사용자-게시글-댓글)
├── 오프라인 캐시 데이터
├── 전문 검색 (FTS)
├── 대용량 데이터 처리
└── 실시간 쿼리 (Stream)

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

> 📖 **오프라인 동기화 패턴**:
> 로컬 저장소를 사용한 **오프라인 우선 아키텍처, 동기화 전략, 충돌 해결**은 [OfflineSupport.md](../advanced/OfflineSupport.md) 참조

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
            │   ├── app_database.dart          # Drift Database
            │   ├── app_database.g.dart        # Drift 코드 생성
            │   ├── tables/
            │   │   ├── users.dart
            │   │   └── posts.dart
            │   ├── daos/
            │   │   ├── user_dao.dart
            │   │   └── post_dao.dart
            │   ├── isar_database.dart          # Isar (레거시)
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

  # Drift - 타입 안전한 SQL 데이터베이스 (권장)
  drift: ^2.31.0
  drift_flutter: ^0.2.8            # 간편한 DB 연결
  sqlite3_flutter_libs: ^0.5.41     # SQLite 네이티브 라이브러리
  path: ^1.9.1

  # ⚠️ 경고: Isar Plus는 커뮤니티 포크로 장기 유지보수 불확실
  # 새 프로젝트는 Drift 사용 권장 (섹션 4 참조)
  # isar_plus: ^1.2.1  # 개발 중단된 Isar의 포크

  injectable: ^2.7.1
  path_provider: ^2.1.5

dev_dependencies:
  drift_dev: ^2.31.0               # Drift 코드 생성기
  isar_generator: ^3.1.0+1
  build_runner: ^2.11.0
  injectable_generator: ^2.12.0
```

## 3. SharedPreferences

> **⚠️ 중요 (2026년 2월 기준)**: 기존 동기(synchronous) API(`SharedPreferences.getInstance()`)는 deprecated 되었습니다.
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

## 4. Drift (SQLite)

Drift는 타입 안전한 SQL 쿼리를 제공하는 Flutter용 데이터베이스 라이브러리입니다. 복잡한 관계형 데이터, 실시간 Stream, 마이그레이션 등 프로덕션급 데이터베이스 기능을 지원합니다.

### 4.1 Drift 개요

**장점:**
- ✅ 컴파일 타임 타입 체크
- ✅ 자동 완성과 리팩토링 지원
- ✅ 강력한 마이그레이션 시스템
- ✅ Stream 기반 실시간 업데이트
- ✅ 복잡한 SQL 쿼리 지원

### 4.2 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  drift: ^2.31.0
  sqlite3_flutter_libs: ^0.5.41
  path_provider: ^2.1.5
  path: ^1.9.0

dev_dependencies:
  drift_dev: ^2.31.0
  build_runner: ^2.11.0
```

### 4.3 Database 클래스 생성 / 코드 생성

#### 4.3.1 Database 클래스 생성

```dart
// lib/data/local/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'app.db'));
      return NativeDatabase(file);
    });
  }
}
```

#### 4.3.2 코드 생성

```bash
# 코드 생성
dart run build_runner build --delete-conflicting-outputs

# Watch 모드 (파일 변경 시 자동 생성)
dart run build_runner watch
```

### 4.4 테이블 정의와 DAO 패턴

#### 4.4.1 기본 테이블 정의

```dart
// lib/data/local/tables/users.dart
import 'dart:convert';

import 'package:drift/drift.dart';

class Users extends Table {
  // Primary Key (자동 증가)
  IntColumn get id => integer().autoIncrement()();

  // Not Null 컬럼
  TextColumn get userId => text().unique()();
  TextColumn get name => text()();
  TextColumn get email => text()();

  // Nullable 컬럼
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get bio => text().nullable()();

  // DateTime 컬럼
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // Boolean 컬럼 (SQLite는 정수로 저장)
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  // JSON 컬럼 (TEXT로 저장)
  TextColumn get metadata => text().map(const JsonConverter()).nullable()();
}

// JSON Converter
class JsonConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    return jsonDecode(fromDb) as Map<String, dynamic>;
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return jsonEncode(value);
  }
}
```

#### 4.4.2 복합 테이블 예시

```dart
// lib/data/local/tables/posts.dart
class Posts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get postId => text().unique()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get content => text()();

  // Foreign Key
  IntColumn get authorId => integer().references(Users, #id)();

  // Enum 컬럼
  IntColumn get status => intEnum<PostStatus>()();

  DateTimeColumn get publishedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  // Computed Column (가상 컬럼)
  TextColumn get searchText => text().generatedAs(
    title + const Constant(' ') + content,
  )();
}

enum PostStatus {
  draft,
  published,
  archived,
}
```

#### 4.4.3 DAO (Data Access Object) 패턴

```dart
// lib/data/local/daos/user_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/users.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(AppDatabase db) : super(db);

  // 전체 조회
  Future<List<User>> getAllUsers() => select(users).get();

  // ID로 조회
  Future<User?> getUserById(int id) {
    return (select(users)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  // userId로 조회
  Future<User?> getUserByUserId(String userId) {
    return (select(users)..where((tbl) => tbl.userId.equals(userId)))
        .getSingleOrNull();
  }

  // 생성
  Future<int> createUser(UsersCompanion user) {
    return into(users).insert(user);
  }

  // 업데이트
  Future<bool> updateUser(User user) {
    return update(users).replace(user);
  }

  // 삭제
  Future<int> deleteUser(int id) {
    return (delete(users)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Stream으로 실시간 조회
  Stream<List<User>> watchAllUsers() => select(users).watch();

  Stream<User?> watchUserById(int id) {
    return (select(users)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }
}
```

#### 4.4.4 Database에 DAO 등록

```dart
// lib/data/local/app_database.dart
@DriftDatabase(
  tables: [Users, Posts],
  daos: [UserDao, PostDao],
)
class AppDatabase extends _$AppDatabase {
  // ...
}
```

### 4.5 기본 CRUD 연산

#### 4.5.1 Create (삽입)

```dart
// 단일 삽입
final userId = await db.userDao.createUser(
  UsersCompanion.insert(
    userId: 'user123',
    name: '홍길동',
    email: 'hong@example.com',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
);

// Companion을 사용한 삽입 (일부 필드만)
await into(users).insert(
  UsersCompanion(
    userId: const Value('user456'),
    name: const Value('김철수'),
    email: const Value('kim@example.com'),
    createdAt: Value(DateTime.now()),
    updatedAt: Value(DateTime.now()),
  ),
);

// insertReturning: 삽입 후 생성된 행 반환
final user = await into(users).insertReturning(
  UsersCompanion.insert(
    userId: 'user789',
    name: '이영희',
    email: 'lee@example.com',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
);

debugPrint('Created user with ID: ${user.id}');
```

#### 4.5.2 Read (조회)

```dart
// 전체 조회
final allUsers = await select(users).get();

// 조건부 조회
final activeUsers = await (select(users)
      ..where((tbl) => tbl.isActive.equals(true)))
    .get();

// 단일 조회 (없으면 null)
final user = await (select(users)
      ..where((tbl) => tbl.userId.equals('user123')))
    .getSingleOrNull();

// 단일 조회 (없으면 예외)
try {
  final user = await (select(users)
        ..where((tbl) => tbl.userId.equals('user123')))
      .getSingle();
} on StateError {
  debugPrint('User not found');
}

// Limit, Offset
final firstTen = await (select(users)..limit(10)).get();
final nextTen = await (select(users)
      ..limit(10, offset: 10))
    .get();

// 정렬
final sortedUsers = await (select(users)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
    .get();
```

#### 4.5.3 Update (수정)

```dart
// 객체로 업데이트 (모든 필드)
final user = await db.userDao.getUserById(1);
if (user != null) {
  await update(users).replace(
    user.copyWith(
      name: '수정된 이름',
      updatedAt: DateTime.now(),
    ),
  );
}

// Companion으로 부분 업데이트
await (update(users)..where((tbl) => tbl.id.equals(1))).write(
  UsersCompanion(
    name: const Value('새 이름'),
    updatedAt: Value(DateTime.now()),
  ),
);

// 조건부 일괄 업데이트
await (update(users)..where((tbl) => tbl.isActive.equals(false))).write(
  const UsersCompanion(
    isActive: Value(true),
  ),
);

// Custom Expression 사용
await (update(users)..where((tbl) => tbl.id.equals(1))).write(
  UsersCompanion(
    // 값 증가
    // loginCount: Value(users.loginCount + const Constant(1)),
  ),
);
```

#### 4.5.4 Delete (삭제)

```dart
// ID로 삭제
final deletedCount = await (delete(users)..where((tbl) => tbl.id.equals(1))).go();

// 조건부 삭제
await (delete(users)..where((tbl) => tbl.isActive.equals(false))).go();

// 전체 삭제 (주의!)
await delete(users).go();

// 삭제 후 확인
if (deletedCount > 0) {
  debugPrint('$deletedCount users deleted');
}
```

### 4.6 복잡한 쿼리 작성

#### 4.6.1 WHERE 조건

```dart
// AND 조건
final results = await (select(users)
      ..where((tbl) =>
          tbl.isActive.equals(true) & tbl.email.isNotNull()))
    .get();

// OR 조건
final results2 = await (select(users)
      ..where((tbl) =>
          tbl.name.like('%김%') | tbl.email.like('%kim%')))
    .get();

// BETWEEN
final results3 = await (select(users)
      ..where((tbl) =>
          tbl.createdAt.isBetweenValues(
            DateTime(2024, 1, 1),
            DateTime(2024, 12, 31),
          )))
    .get();

// IN
final userIds = ['user1', 'user2', 'user3'];
final results4 = await (select(users)
      ..where((tbl) => tbl.userId.isIn(userIds)))
    .get();

// IS NULL / IS NOT NULL
final usersWithoutAvatar = await (select(users)
      ..where((tbl) => tbl.avatarUrl.isNull()))
    .get();

// LIKE
final usersNamedKim = await (select(users)
      ..where((tbl) => tbl.name.like('김%')))
    .get();

// 올바른 방법: & 연산자로 조건 결합
final results5 = await (select(users)
      ..where((tbl) =>
          (tbl.isActive.equals(true)) &
          (tbl.createdAt.isBiggerOrEqualValue(DateTime(2024))) &
          (tbl.email.like('%@gmail.com'))))
    .get();
```

#### 4.6.2 집계 함수

```dart
// COUNT
final userCount = await (selectOnly(users)
      ..addColumns([users.id.count()]))
    .getSingle()
    .then((row) => row.read(users.id.count()));

// COUNT with condition
final activeUserCount = await (selectOnly(users)
      ..addColumns([users.id.count()])
      ..where(users.isActive.equals(true)))
    .getSingle()
    .then((row) => row.read(users.id.count()));

// SUM, AVG, MIN, MAX (예: Posts 테이블에 viewCount가 있다고 가정)
// final stats = await (selectOnly(posts)
//       ..addColumns([
//         posts.viewCount.sum(),
//         posts.viewCount.avg(),
//         posts.viewCount.min(),
//         posts.viewCount.max(),
//       ]))
//     .getSingle();
```

#### 4.6.3 GROUP BY와 HAVING

```dart
// GROUP BY (예: 작성자별 게시글 수)
final postCountByAuthor = await (selectOnly(posts)
      ..addColumns([posts.authorId, posts.id.count()])
      ..groupBy([posts.authorId]))
    .get();

for (final row in postCountByAuthor) {
  final authorId = row.read(posts.authorId);
  final count = row.read(posts.id.count());
  debugPrint('Author $authorId has $count posts');
}

// HAVING (게시글 10개 이상인 작성자만)
final prolificAuthors = await (selectOnly(posts)
      ..addColumns([posts.authorId, posts.id.count()])
      ..groupBy([posts.authorId])
      ..having(posts.id.count().isBiggerOrEqualValue(10)))
    .get();
```

#### 4.6.4 서브쿼리

```dart
// EXISTS 서브쿼리 (게시글이 있는 사용자만)
final usersWithPosts = await (select(users)
      ..where((u) =>
          existsQuery(
            select(posts)..where((p) => p.authorId.equalsExp(u.id)),
          )))
    .get();

// IN 서브쿼리
final activeAuthorIds = selectOnly(posts)
  ..addColumns([posts.authorId])
  ..where(posts.status.equalsValue(PostStatus.published))
  ..groupBy([posts.authorId]);

final activeAuthors = await (select(users)
      ..where((u) => u.id.isInQuery(activeAuthorIds)))
    .get();
```

### 4.7 JOIN과 관계형 데이터

#### 4.7.1 INNER JOIN

```dart
// 사용자와 게시글 JOIN
final query = select(users).join([
  innerJoin(posts, posts.authorId.equalsExp(users.id)),
]);

final results = await query.get();

for (final row in results) {
  final user = row.readTable(users);
  final post = row.readTable(posts);

  debugPrint('${user.name} wrote: ${post.title}');
}
```

#### 4.7.2 LEFT OUTER JOIN

```dart
// 모든 사용자와 그들의 게시글 (게시글 없어도 포함)
final query = select(users).join([
  leftOuterJoin(posts, posts.authorId.equalsExp(users.id)),
]);

final results = await query.get();

for (final row in results) {
  final user = row.readTable(users);
  final post = row.readTableOrNull(posts);  // null 가능

  if (post != null) {
    debugPrint('${user.name}: ${post.title}');
  } else {
    debugPrint('${user.name}: No posts');
  }
}
```

#### 4.7.3 다중 JOIN

```dart
// Comments 테이블이 있다고 가정
// class Comments extends Table {
//   IntColumn get id => integer().autoIncrement()();
//   IntColumn get postId => integer().references(Posts, #id)();
//   IntColumn get authorId => integer().references(Users, #id)();
//   TextColumn get content => text()();
// }

// 사용자 -> 게시글 -> 댓글
final query = select(users).join([
  innerJoin(posts, posts.authorId.equalsExp(users.id)),
  // innerJoin(comments, comments.postId.equalsExp(posts.id)),
]);
```

#### 4.7.4 JOIN 결과를 DTO로 매핑

```dart
class UserWithPosts {
  final User user;
  final List<Post> posts;

  UserWithPosts(this.user, this.posts);
}

Future<List<UserWithPosts>> getUsersWithPosts() async {
  final query = select(users).join([
    leftOuterJoin(posts, posts.authorId.equalsExp(users.id)),
  ]);

  final results = await query.get();

  // 사용자별로 게시글 그룹화
  final Map<int, UserWithPosts> userMap = {};

  for (final row in results) {
    final user = row.readTable(users);
    final post = row.readTableOrNull(posts);

    if (!userMap.containsKey(user.id)) {
      userMap[user.id] = UserWithPosts(user, []);
    }

    if (post != null) {
      userMap[user.id]!.posts.add(post);
    }
  }

  return userMap.values.toList();
}
```

### 4.8 트랜잭션 관리

#### 4.8.1 기본 트랜잭션

```dart
// 트랜잭션: 모두 성공하거나 모두 실패
await db.transaction(() async {
  // 사용자 생성
  final userId = await into(users).insert(
    UsersCompanion.insert(
      userId: 'user123',
      name: '홍길동',
      email: 'hong@example.com',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );

  // 게시글 생성
  await into(posts).insert(
    PostsCompanion.insert(
      postId: 'post123',
      title: '첫 게시글',
      content: '내용',
      authorId: userId,
      status: PostStatus.published,
      createdAt: DateTime.now(),
    ),
  );

  // 하나라도 실패하면 모두 롤백
});
```

#### 4.8.2 예외 처리와 롤백

```dart
try {
  await db.transaction(() async {
    // 작업 1
    await into(users).insert(user1);

    // 작업 2 (실패 가능)
    await into(users).insert(user2);

    // 의도적으로 롤백하려면 예외 throw
    if (someCondition) {
      throw Exception('Transaction aborted');
    }
  });

  debugPrint('Transaction committed');
} catch (e) {
  debugPrint('Transaction rolled back: $e');
}
```

#### 4.8.3 중첩 트랜잭션 (Savepoint)

```dart
await db.transaction(() async {
  // 외부 트랜잭션
  await into(users).insert(user1);

  try {
    await db.transaction(() async {
      // 내부 트랜잭션 (Savepoint)
      await into(posts).insert(post1);
      await into(posts).insert(post2);
    });
  } catch (e) {
    // 내부 트랜잭션만 롤백, 외부는 계속
    debugPrint('Inner transaction failed: $e');
  }

  // user1은 여전히 커밋됨
});
```

### 4.9 실시간 쿼리와 Stream

#### 4.9.1 watch() - 실시간 데이터 감지

```dart
// 전체 사용자 감지
Stream<List<User>> watchUsers() {
  return select(users).watch();
}

// UI에서 사용
class UserListScreen extends StatelessWidget {
  final AppDatabase db;

  const UserListScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<User>>(
      stream: db.userDao.watchAllUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(users[index].name),
              subtitle: Text(users[index].email),
            );
          },
        );
      },
    );
  }
}
```

#### 4.9.2 조건부 Stream

```dart
// 활성 사용자만 감지
Stream<List<User>> watchActiveUsers() {
  return (select(users)..where((tbl) => tbl.isActive.equals(true))).watch();
}

// 특정 사용자 감지
Stream<User?> watchUserById(int id) {
  return (select(users)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
}
```

#### 4.9.3 JOIN Stream

```dart
Stream<List<TypedResult>> watchUsersWithPostCount() {
  final query = select(users).join([
    leftOuterJoin(posts, posts.authorId.equalsExp(users.id)),
  ]);

  return query.watch();
}
```

#### 4.9.4 Stream 변환

```dart
// Stream 매핑
Stream<List<String>> watchUserNames() {
  return select(users)
      .watch()
      .map((users) => users.map((u) => u.name).toList());
}

// Stream 필터링
Stream<List<User>> watchUsersCreatedToday() {
  return select(users).watch().map((users) {
    final today = DateTime.now();
    return users.where((u) =>
        u.createdAt.year == today.year &&
        u.createdAt.month == today.month &&
        u.createdAt.day == today.day).toList();
  });
}
```

### 4.10 마이그레이션 전략

#### 4.10.1 스키마 버전 관리

```dart
@DriftDatabase(tables: [Users, Posts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // 현재 스키마 버전
  @override
  int get schemaVersion => 3;  // 버전 변경 시 증가

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // 앱 최초 설치 시 모든 테이블 생성
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 버전별 마이그레이션
        if (from < 2) {
          await _migrateV1ToV2(m);
        }
        if (from < 3) {
          await _migrateV2ToV3(m);
        }
      },
    );
  }

  Future<void> _migrateV1ToV2(Migrator m) async {
    // 컬럼 추가
    await m.addColumn(users, users.bio);
    await m.addColumn(users, users.avatarUrl);
  }

  Future<void> _migrateV2ToV3(Migrator m) async {
    // 테이블 생성
    await m.createTable(posts);
  }
}
```

#### 4.10.2 컬럼 추가/삭제

```dart
// 컬럼 추가 (nullable 또는 default 필요)
await m.addColumn(users, users.phoneNumber);

// 컬럼 삭제 (SQLite는 직접 지원 안 함 → 재생성)
await m.deleteTable('users');
await m.createTable(users);

// 데이터 보존하며 컬럼 삭제
await customStatement('ALTER TABLE users RENAME TO users_old');
await m.createTable(users);
await customStatement('''
  INSERT INTO users (id, name, email)
  SELECT id, name, email FROM users_old
''');
await customStatement('DROP TABLE users_old');
```

#### 4.10.3 테이블 이름 변경

```dart
await m.renameTable(users, 'app_users');
```

#### 4.10.4 데이터 마이그레이션

```dart
Future<void> _migrateV2ToV3(Migrator m) async {
  // 1. 새 테이블 생성
  await m.createTable(posts);

  // 2. 데이터 변환
  final oldUsers = await customSelect('SELECT * FROM legacy_users').get();

  for (final row in oldUsers) {
    await into(users).insert(
      UsersCompanion.insert(
        userId: row.read<String>('user_id'),
        name: row.read<String>('full_name'),
        email: row.read<String>('email_address'),
        createdAt: DateTime.parse(row.read<String>('created')),
        updatedAt: DateTime.now(),
      ),
    );
  }

  // 3. 구 테이블 삭제
  await customStatement('DROP TABLE legacy_users');
}
```

#### 4.10.5 마이그레이션 검증

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    beforeOpen: (details) async {
      // 마이그레이션 후 검증
      if (details.hadUpgrade) {
        // Foreign Key 체크 활성화
        await customStatement('PRAGMA foreign_keys = ON');

        // 데이터 무결성 검증
        final result = await customSelect('PRAGMA integrity_check').getSingle();
        if (result.read<String>('integrity_check') != 'ok') {
          throw Exception('Database integrity check failed');
        }
      }
    },
  );
}
```

### 4.11 인덱싱과 성능 최적화

#### 4.11.1 인덱스 정의

```dart
// 올바른 인덱스 정의 - @TableIndex 어노테이션 사용
@TableIndex(name: 'idx_users_email_name', columns: {#email, #name})
@TableIndex(name: 'idx_users_created', columns: {#createdAt})
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().unique()();  // 자동으로 인덱스 생성
  TextColumn get email => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {email},  // email에 UNIQUE 인덱스
  ];
}
```

#### 4.11.2 쿼리 성능 분석 (EXPLAIN)

```dart
Future<void> analyzeQuery() async {
  // EXPLAIN QUERY PLAN - customSelect()로 직접 SQL 실행
  final explanation = await customSelect(
    "EXPLAIN QUERY PLAN SELECT * FROM users WHERE email = ?",
    variables: [Variable.withString('test@test.com')],
    readsFrom: {users},
  ).get();

  for (final row in explanation) {
    debugPrint(row.data);
  }
}

// 결과 예시:
// SCAN TABLE users  ← 인덱스 없음 (느림)
// SEARCH TABLE users USING INDEX users_email_idx  ← 인덱스 사용 (빠름)
```

#### 4.11.3 인덱스 전략

| 시나리오 | 인덱스 타입 | 예시 |
|---------|-----------|------|
| **Primary Key** | 자동 인덱스 | `autoIncrement()` |
| **Unique 컬럼** | Unique 인덱스 | `unique()` |
| **WHERE 절** | 단일 인덱스 | `Index('idx_email', [email])` |
| **WHERE + ORDER BY** | 복합 인덱스 | `Index('idx_email_created', [email, createdAt])` |
| **Foreign Key** | 인덱스 권장 | `Index('idx_author', [authorId])` |

#### 4.11.4 성능 최적화 팁

```dart
// ❌ N+1 쿼리 (느림)
final users = await select(users).get();
for (final user in users) {
  final posts = await (select(posts)
        ..where((tbl) => tbl.authorId.equals(user.id)))
      .get();
}

// ✅ JOIN 사용 (빠름)
final query = select(users).join([
  leftOuterJoin(posts, posts.authorId.equalsExp(users.id)),
]);
final results = await query.get();

// ✅ Batch 삽입
await batch((batch) {
  for (final user in userList) {
    batch.insert(users, user);
  }
});

// ✅ 페이지네이션
Future<List<User>> getUsers({int page = 0, int pageSize = 20}) {
  return (select(users)
        ..limit(pageSize, offset: page * pageSize))
      .get();
}
```

### 4.12 Full-Text Search (FTS)

#### 4.12.1 FTS5 테이블 생성

```dart
// FTS5 전문 검색 - customStatement()를 사용하여 가상 테이블 생성
// Drift에서는 FTS 전용 어노테이션이 없으며,
// 반드시 SQL로 직접 FTS5 가상 테이블을 생성해야 합니다.

@DriftDatabase(tables: [Articles])
class AppDatabase extends _$AppDatabase {
  // ...

  /// FTS5 가상 테이블 생성 (마이그레이션에서 호출)
  Future<void> createFtsTable() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS articles_fts
      USING fts5(title, content, content='articles', content_rowid='id')
    ''');
  }

  /// FTS5를 활용한 전문 검색
  Future<List<Article>> searchArticles(String query) async {
    final results = await customSelect(
      'SELECT a.* FROM articles a '
      'INNER JOIN articles_fts fts ON a.id = fts.rowid '
      'WHERE articles_fts MATCH ?',
      variables: [Variable.withString(query)],
      readsFrom: {articles},
    ).get();
    return results.map((row) => Article.fromData(row.data)).toList();
  }
}
```

#### 4.12.2 데이터 동기화

```dart
// 원본 테이블에 데이터 삽입 시 FTS 테이블에도 삽입
Future<void> createArticle(ArticlesCompanion article) async {
  await transaction(() async {
    final id = await into(articles).insert(article);

    // FTS 테이블에 동기화
    await into(articlesFts).insert(
      ArticlesFtsCompanion.insert(
        rowid: Value(id),
        title: article.title.value,
        content: article.content.value,
      ),
    );
  });
}
```

#### 4.12.3 전문 검색 쿼리

```dart
// MATCH 쿼리
Future<List<Article>> searchArticles(String query) async {
  final ftsResults = await (select(articlesFts)
        ..where((tbl) => tbl.match(query)))
      .get();

  final ids = ftsResults.map((row) => row.rowid).toList();

  return (select(articles)..where((tbl) => tbl.id.isIn(ids))).get();
}

// 검색어 하이라이팅
Future<List<Map<String, String>>> searchWithHighlight(String query) async {
  final results = await customSelect(
    '''
    SELECT
      snippet(articles_fts, 0, '<mark>', '</mark>', '...', 20) as title_snippet,
      snippet(articles_fts, 1, '<mark>', '</mark>', '...', 40) as content_snippet
    FROM articles_fts
    WHERE articles_fts MATCH ?
    ''',
    variables: [Variable(query)],
  ).get();

  return results.map((row) => {
    'title': row.read<String>('title_snippet'),
    'content': row.read<String>('content_snippet'),
  }).toList();
}
```

### 4.13 대용량 데이터 처리

#### 4.13.1 배치 삽입

```dart
import 'dart:math'; // min() 사용을 위해 필요

// ❌ 비효율적 (각 삽입마다 트랜잭션)
for (final user in users) {
  await into(users).insert(user);
}

// ✅ 효율적 (단일 트랜잭션)
await batch((batch) {
  for (final user in users) {
    batch.insert(users, user, mode: InsertMode.insertOrReplace);
  }
});

// 대용량 데이터 청크 처리
Future<void> insertLargeDataset(List<UsersCompanion> users) async {
  const chunkSize = 500;

  for (var i = 0; i < users.length; i += chunkSize) {
    final chunk = users.sublist(
      i,
      min(i + chunkSize, users.length),
    );

    await batch((batch) {
      for (final user in chunk) {
        batch.insert(users, user);
      }
    });

    // UI 업데이트를 위한 작은 딜레이
    await Future.delayed(const Duration(milliseconds: 10));
  }
}
```

#### 4.13.2 페이지네이션

```dart
class PaginatedQuery<T> {
  final int pageSize;
  int _currentPage = 0;
  bool _hasMore = true;

  PaginatedQuery({this.pageSize = 20});

  Future<List<T>> loadNextPage(
    SimpleSelectStatement<$Table, T> Function() queryBuilder,
  ) async {
    if (!_hasMore) return [];

    final query = queryBuilder()
      ..limit(pageSize, offset: _currentPage * pageSize);

    final results = await query.get();

    if (results.length < pageSize) {
      _hasMore = false;
    }

    _currentPage++;
    return results;
  }

  void reset() {
    _currentPage = 0;
    _hasMore = true;
  }
}

// 사용
final pagination = PaginatedQuery<User>(pageSize: 50);

final firstPage = await pagination.loadNextPage(() => select(users));
final secondPage = await pagination.loadNextPage(() => select(users));
```

#### 4.13.3 백그라운드 처리

```dart
import 'dart:isolate';

// ⚠️ 주의: background isolate에서는 path_provider (Flutter 플러그인)를 사용할 수 없습니다.
// 메인 isolate에서 먼저 경로를 해석한 후, String path를 background isolate에 전달하세요.
Future<void> processLargeDataInBackground(List<Map<String, dynamic>> data) async {
  final result = await Isolate.run(() async {
    // Isolate 내에서 새 데이터베이스 연결 필요
    final db = AppDatabase();

    await db.batch((batch) {
      for (final item in data) {
        batch.insert(
          db.users,
          UsersCompanion.insert(
            userId: item['userId'],
            name: item['name'],
            email: item['email'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
    });

    await db.close();
    return 'Success';
  });

  debugPrint(result);
}
```

### 4.14 Clean Architecture 통합

#### 4.14.1 DataSource Layer

```dart
// lib/features/user/data/datasources/user_local_datasource.dart
abstract class UserLocalDataSource {
  Future<UserDto?> getUserById(String userId);
  Future<void> saveUser(UserDto user);
  Future<void> deleteUser(String userId);
  Stream<List<UserDto>> watchUsers();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final AppDatabase _db;

  UserLocalDataSourceImpl(this._db);

  @override
  Future<UserDto?> getUserById(String userId) async {
    final user = await _db.userDao.getUserByUserId(userId);
    return user != null ? _mapToDto(user) : null;
  }

  @override
  Future<void> saveUser(UserDto dto) async {
    await _db.userDao.createUser(
      UsersCompanion.insert(
        userId: dto.userId,
        name: dto.name,
        email: dto.email,
        avatarUrl: Value(dto.avatarUrl),
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
      ),
    );
  }

  @override
  Stream<List<UserDto>> watchUsers() {
    return _db.userDao
        .watchAllUsers()
        .map((users) => users.map(_mapToDto).toList());
  }

  UserDto _mapToDto(User user) {
    return UserDto(
      id: user.id.toString(),
      userId: user.userId,
      name: user.name,
      email: user.email,
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }
}
```

#### 4.14.2 Repository Layer

```dart
// lib/features/user/data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;

  UserRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<Either<Failure, User>> getUser(String userId) async {
    try {
      // 1. 로컬 캐시 확인
      final cached = await _localDataSource.getUserById(userId);
      if (cached != null && !_isCacheExpired(cached)) {
        return Right(cached.toEntity());
      }

      // 2. 네트워크에서 가져오기
      final dto = await _remoteDataSource.getUser(userId);

      // 3. 로컬에 저장
      await _localDataSource.saveUser(dto);

      return Right(dto.toEntity());
    } on DioException catch (e) {
      // 4. 네트워크 실패 시 만료된 캐시라도 반환
      final cached = await _localDataSource.getUserById(userId);
      if (cached != null) {
        return Right(cached.toEntity());
      }

      return Left(NetworkFailure(e.message));
    }
  }

  bool _isCacheExpired(UserDto dto) {
    final now = DateTime.now();
    final age = now.difference(dto.updatedAt);
    return age.inHours > 1;  // 1시간 캐시
  }
}
```

#### 4.14.3 Dependency Injection

```dart
// lib/core/di/injection.dart
@module
abstract class DatabaseModule {
  @lazySingleton
  AppDatabase get database => AppDatabase();

  @lazySingleton
  UserDao userDao(AppDatabase db) => db.userDao;

  @lazySingleton
  PostDao postDao(AppDatabase db) => db.postDao;
}

@injectable
class UserLocalDataSourceImpl implements UserLocalDataSource {
  final AppDatabase _db;

  UserLocalDataSourceImpl(this._db);
  // ...
}
```

### 4.15 Drift 테스트 전략

#### 4.15.1 Database Mock

```dart
// test/mocks/mock_database.dart
class MockAppDatabase extends Mock implements AppDatabase {}
class MockUserDao extends Mock implements UserDao {}

void main() {
  late MockUserDao mockDao;
  late UserLocalDataSourceImpl dataSource;

  setUp(() {
    mockDao = MockUserDao();
    final mockDb = MockAppDatabase();
    when(() => mockDb.userDao).thenReturn(mockDao);

    dataSource = UserLocalDataSourceImpl(mockDb);
  });

  test('getUserById returns user when found', () async {
    // Arrange
    final user = User(
      id: 1,
      userId: 'user123',
      name: 'Test User',
      email: 'test@test.com',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
    );

    when(() => mockDao.getUserByUserId('user123'))
        .thenAnswer((_) async => user);

    // Act
    final result = await dataSource.getUserById('user123');

    // Assert
    expect(result, isNotNull);
    expect(result!.userId, 'user123');
  });
}
```

#### 4.15.2 In-Memory Database 테스트

```dart
// test/database/user_dao_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // ⚠️ 주의: 아래 .connect() 생성자를 사용하려면 AppDatabase 클래스에
    // AppDatabase.connect(DatabaseConnection connection) : super(connection)
    // 명명된 생성자를 추가해야 합니다.
    // 메모리 데이터베이스 생성
    database = AppDatabase.connect(
      DatabaseConnection(NativeDatabase.memory()),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('UserDao', () {
    test('createUser inserts user', () async {
      // Arrange
      final user = UsersCompanion.insert(
        userId: 'user123',
        name: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final id = await database.userDao.createUser(user);

      // Assert
      expect(id, greaterThan(0));

      final inserted = await database.userDao.getUserById(id);
      expect(inserted, isNotNull);
      expect(inserted!.userId, 'user123');
    });

    test('updateUser modifies existing user', () async {
      // Create
      final id = await database.userDao.createUser(
        UsersCompanion.insert(
          userId: 'user123',
          name: 'Original Name',
          email: 'test@test.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Update
      final user = (await database.userDao.getUserById(id))!;
      await database.userDao.updateUser(
        user.copyWith(name: 'Updated Name'),
      );

      // Verify
      final updated = await database.userDao.getUserById(id);
      expect(updated!.name, 'Updated Name');
    });

    test('deleteUser removes user', () async {
      // Create
      final id = await database.userDao.createUser(
        UsersCompanion.insert(
          userId: 'user123',
          name: 'Test',
          email: 'test@test.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Delete
      await database.userDao.deleteUser(id);

      // Verify
      final deleted = await database.userDao.getUserById(id);
      expect(deleted, isNull);
    });
  });
}
```

## 5. Isar Plus Database

### 5.0 Isar Plus 소개

> **ℹ️ Isar Plus (2026년 2월 기준)**:
> - 원본 Isar가 2024년 이후 개발 중단됨에 따라 커뮤니티에서 **Isar Plus**를 포크하여 유지보수하고 있습니다.
> - `isar_plus: ^1.2.1` 사용을 권장합니다.
> - 기존 Isar API와 호환되며, 버그 수정 및 Flutter 최신 버전 지원이 이루어지고 있습니다.

#### 5.0.1 권장 대안

| 대안 | 유형 | 장점 | 단점 | 마이그레이션 난이도 |
|------|------|------|------|-----------------|
| **Drift** | SQL | ✅ 활발한 개발<br>✅ 타입 안전<br>✅ 관계형 쿼리 강력<br>✅ 마이그레이션 시스템 | ❌ SQL 지식 필요<br>❌ 코드 생성 필수 | 중간 |
| **ObjectBox** | NoSQL | ✅ 매우 빠름 (Isar급)<br>✅ 상업적 지원<br>✅ 관계 지원<br>✅ 쿼리 언어 유사 | ❌ 일부 상업 기능 유료<br>❌ 생태계 작음 | 낮음 (Isar 유사) |
| **Hive** | Key-Value | ✅ 가볍고 빠름<br>✅ 간단한 API<br>✅ 코드 생성 선택적 | ❌ 관계형 쿼리 약함<br>❌ 인덱싱 제한적 | 높음 (구조 단순화) |
| **SQFlite** | SQL | ✅ 성숙한 생태계<br>✅ Raw SQL 지원<br>✅ 가볍고 안정적 | ❌ 타입 안전 없음<br>❌ 수동 쿼리 작성 | 중간 |

#### 5.0.2 대안 선택 가이드

```
새 프로젝트 선택 기준:

복잡한 관계형 데이터 + SQL 가능
  → Drift (추천!) → 섹션 4 참조

Isar 같은 NoSQL + 고성능 필수
  → ObjectBox

간단한 로컬 캐싱만
  → Hive

Raw SQL 제어 원함
  → SQFlite
```

#### 5.0.3 Drift 마이그레이션 안내

> Drift에 대한 상세한 가이드는 **섹션 4. Drift (SQLite)**를 참조하세요.
> 테이블 정의, DAO 패턴, 복잡한 쿼리, JOIN, Stream, 마이그레이션 등을 포괄적으로 다루고 있습니다.

**왜 Drift를 추천하나?**
- ✅ 타입 안전한 쿼리 빌더
- ✅ 마이그레이션 시스템 내장
- ✅ 스트림 지원 (watch)
- ✅ 활발한 커뮤니티와 업데이트
- ✅ SQLite 기반이라 안정적

---

> **아래 섹션 (5.1-5.4)은 기존 Isar 프로젝트 유지보수용입니다.**
> 새 프로젝트는 섹션 4의 Drift를 사용하세요.

### 5.1 Collection 정의

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

### 5.2 Isar Database 설정

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

### 5.3 Repository 패턴으로 Isar 사용

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

### 5.4 Cart DataSource 예시

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

## 6. Secure Storage

> **✅ 업데이트 (2026년 2월)**: flutter_secure_storage v10.0.0 새로운 API 적용

### 6.0 v10.0.0 Breaking Changes

flutter_secure_storage v10.0.0에서 초기화 API가 변경되었습니다.

**주요 변경사항:**
- `const FlutterSecureStorage(aOptions: ..., iOptions: ...)` → `FlutterSecureStorage.standard(androidOptions: ..., iosOptions: ...)`
- Android/iOS 옵션 객체 변경
- 더 명확한 네이밍과 타입 안전성

### 6.1 SecureStorage 클래스 (v10.0.0)

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

### 6.2 SecureStorage DI 설정 (v10.0.0)

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

#### 6.2.1 v9 → v10 마이그레이션

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

#### 6.2.2 Android 암호화 알고리즘 선택 (v10+)

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

### 6.3 플랫폼별 설정

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

## 7. 통합 Storage Service

### 7.1 통합 인터페이스

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

## 8. Feature에서 사용

### 8.1 Auth Feature - 토큰 저장

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

### 8.2 Settings Feature - 설정 관리

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

## 9. 캐시 전략

### 9.1 캐시 만료 처리

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

## 10. 테스트

### 10.1 SharedPreferences Mock

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

### 10.2 SecureStorage Mock

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

## 11. 데이터베이스 암호화

### 11.1 SQLCipher (Drift 암호화)

```yaml
# pubspec.yaml
dependencies:
  drift: ^2.31.0
  sqlite3_flutter_libs: ^0.5.41
  sqlcipher_flutter_libs: ^0.6.8  # SQLCipher 지원
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

### 11.2 암호화 키 관리

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

### 11.3 ObjectBox 암호화

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

### 11.4 마이그레이션 시 암호화 유지

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

### 11.5 주의사항

| 항목 | 설명 |
|-----|------|
| 성능 | 암호화는 약 5-15% 성능 오버헤드 발생 |
| 키 분실 | 암호화 키 분실 시 데이터 복구 불가 |
| 백업 | 암호화된 DB 백업 시 키도 함께 관리 필요 |
| 디버깅 | DB Browser에서 암호화된 DB 열람 불가 |

## 12. Best Practices

### 12.1 저장소 선택 가이드 (2026년 기준)

| 데이터 유형 | 저장소 | 이유 |
|------------|--------|------|
| 앱 설정 | SharedPreferencesAsync/WithCache | 간단한 Key-Value (새 async API) |
| 토큰/비밀번호 | SecureStorage v10+ | 암호화 필요 (플랫폼별 강화) |
| 복잡한 관계형 데이터 | Drift | 타입 안전 쿼리, JOIN, Stream (권장) |
| 복잡한 객체 (NoSQL) | ObjectBox | 고성능 NoSQL (⚠️ Isar 개발 중단) |
| 임시 캐시 | 메모리 + Drift/ObjectBox | 빠른 접근 + 영속성 |

### 12.2 DO (이렇게 하세요) - 2026 업데이트

| 항목 | 설명 | 예시 |
|------|------|------|
| **새 API 사용** | SharedPreferencesAsync 또는 WithCache 사용 | ✅ `SharedPreferencesAsync()` |
| **SecureStorage v10** | 새로운 초기화 API 사용 | ✅ `FlutterSecureStorage.standard()` |
| **Drift 사용** | 새 프로젝트는 Drift로 시작 | ✅ `@DriftDatabase(tables: [...])` |
| **Key 상수화** | PreferenceKeys 클래스로 관리 | ✅ `PreferenceKeys.themeMode` |
| **인터페이스 분리** | TokenStorage, AppPreferences 등 | ✅ 단일 책임 원칙 |
| **비동기 초기화** | WithCache는 앱 시작 시 초기화 | ✅ `@preResolve` 사용 |
| **타입 안전성** | Generic이 아닌 명시적 메서드 | ✅ `Future<String?>` 반환 |

### 12.3 DON'T (하지 마세요) - 2026 업데이트

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

## 13. 마이그레이션

### 13.1 Isar 스키마 변경

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

### 13.2 데이터 마이그레이션

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

> **참고**: Drift의 마이그레이션 전략에 대해서는 섹션 4.10을 참조하세요.

## 14. 2026년 2월 업데이트 요약

이 문서는 2026년 2월 기준 최신 Flutter 로컬 저장소 베스트 프랙티스를 반영합니다.

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

#### 4. Drift 심화 가이드 통합
- **섹션 4에 Drift 종합 가이드 추가**: 테이블 정의, DAO 패턴, 복잡한 쿼리, JOIN, 트랜잭션, Stream, 마이그레이션, 인덱싱, FTS, 대용량 처리, Clean Architecture 통합, 테스트 전략

### 새 프로젝트 권장 스택 (2026)

```yaml
dependencies:
  # Key-Value 설정
  shared_preferences: ^2.5.4  # Async API 사용

  # 보안 저장소
  flutter_secure_storage: ^10.0.0  # v10 새 API

  # 데이터베이스 (권장: Drift)
  drift: ^2.31.0              # SQL, 권장!
  drift_flutter: ^0.2.8       # 간편한 DB 연결
  sqlite3_flutter_libs: ^0.5.41
  # objectbox: ^2.4.0         # NoSQL 대안

  injectable: ^2.7.1
  path_provider: ^2.1.5

dev_dependencies:
  drift_dev: ^2.31.0  # Drift 사용 시
  build_runner: ^2.11.0
```

### 마이그레이션 체크리스트

- [ ] SharedPreferences → SharedPreferencesAsync 또는 WithCache
- [ ] SecureStorage v9 → v10 (초기화 API 변경)
- [ ] Isar 의존성 확인 (새 프로젝트면 Drift로 변경)
- [ ] DI 설정 업데이트 (PreferencesModule, SecureStorageModule)
- [ ] 테스트 코드 업데이트

## 15. 참고

- [SharedPreferences 공식 문서](https://pub.dev/packages/shared_preferences)
- [Flutter Secure Storage 공식 문서](https://pub.dev/packages/flutter_secure_storage)
- [Drift 공식 문서](https://drift.simonbinder.eu/)
- [Drift GitHub](https://github.com/simolus3/drift)
- [SQLite 공식 문서](https://www.sqlite.org/docs.html)
- [SQL Tutorial](https://www.sqltutorial.org/)
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

### 과제 4: Todo 앱 데이터베이스 구현 (Drift)

Drift로 Todo 앱의 데이터베이스를 구현하세요.

요구사항:
1. `Todos` 테이블 생성 (id, title, description, completed, dueDate, createdAt)
2. `TodoDao` 작성 (CRUD + watch 메서드)
3. 완료된 할 일 필터링 쿼리
4. 기한이 오늘인 할 일 조회
5. Stream으로 실시간 할 일 목록 제공

### 과제 5: 블로그 앱 관계형 데이터 (Drift)

사용자, 게시글, 댓글 관계를 구현하세요.

요구사항:
1. `Users`, `Posts`, `Comments` 테이블 정의 (Foreign Key 설정)
2. JOIN 쿼리로 사용자와 게시글 함께 조회
3. 게시글별 댓글 수 집계 쿼리
4. 트랜잭션으로 게시글과 댓글 함께 삭제
5. 사용자별 게시글 수를 Stream으로 제공

### 과제 6: 대용량 데이터 처리 (Drift)

1,000개 이상의 데이터를 효율적으로 처리하는 로직을 구현하세요.

요구사항:
1. Batch Insert로 1,000개 데이터 삽입
2. 페이지네이션 (페이지당 50개)
3. 인덱스 추가 후 성능 비교 (EXPLAIN 사용)
4. FTS로 전문 검색 구현
5. 백그라운드 Isolate에서 대량 데이터 처리

## Self-Check

- [ ] SharedPreferences와 SecureStorage의 용도 차이를 설명할 수 있는가?
- [ ] 민감한 데이터(토큰, 비밀번호)를 SecureStorage에 저장하고 있는가?
- [ ] 로컬 저장소 접근을 Repository 패턴으로 추상화할 수 있는가?
- [ ] 캐시 만료 전략(TTL)을 구현할 수 있는가?
- [ ] Drift의 테이블 정의와 DAO 패턴을 이해하고 구현할 수 있는가?
- [ ] JOIN, 서브쿼리, 집계 함수를 사용하여 복잡한 쿼리를 작성할 수 있는가?
- [ ] 트랜잭션으로 원자성을 보장하는 데이터 작업을 구현할 수 있는가?
- [ ] watch()를 사용하여 실시간으로 UI를 업데이트하는 Stream을 제공할 수 있는가?
- [ ] 스키마 버전 관리와 마이그레이션 전략을 설명하고 적용할 수 있는가?
- [ ] 인덱스를 추가하고 EXPLAIN으로 쿼리 성능을 분석할 수 있는가?
- [ ] FTS(Full-Text Search)를 구현하고 전문 검색 기능을 제공할 수 있는가?
- [ ] SQLCipher로 데이터베이스를 암호화하고 키를 안전하게 관리할 수 있는가?
- [ ] Batch Insert와 페이지네이션으로 대용량 데이터를 효율적으로 처리할 수 있는가?
- [ ] Clean Architecture의 DataSource와 Repository 계층에 Drift를 통합할 수 있는가?
