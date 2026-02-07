# Flutter 로컬 데이터베이스 심화 가이드

> Drift(SQLite)를 활용한 고급 데이터베이스 패턴과 성능 최적화 전략을 학습합니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Drift를 사용하여 복잡한 쿼리(JOIN, 서브쿼리, 집계)를 작성하고 실시간 Stream으로 UI를 갱신할 수 있습니다
> - 스키마 마이그레이션과 인덱싱 전략으로 프로덕션급 데이터베이스를 안전하게 관리할 수 있습니다
> - FTS(Full-Text Search), 암호화, 대용량 데이터 처리 등 실전 시나리오를 구현할 수 있습니다

---

## 목차

1. [Drift 개요 및 설정](#1-drift-개요-및-설정)
2. [테이블 정의와 DAO 패턴](#2-테이블-정의와-dao-패턴)
3. [기본 CRUD 연산](#3-기본-crud-연산)
4. [복잡한 쿼리 작성](#4-복잡한-쿼리-작성)
5. [JOIN과 관계형 데이터](#5-join과-관계형-데이터)
6. [트랜잭션 관리](#6-트랜잭션-관리)
7. [실시간 쿼리와 Stream](#7-실시간-쿼리와-stream)
8. [마이그레이션 전략](#8-마이그레이션-전략)
9. [인덱싱과 성능 최적화](#9-인덱싱과-성능-최적화)
10. [Full-Text Search (FTS)](#10-full-text-search-fts)
11. [데이터베이스 암호화](#11-데이터베이스-암호화)
12. [대용량 데이터 처리](#12-대용량-데이터-처리)
13. [Clean Architecture 통합](#13-clean-architecture-통합)
14. [테스트 전략](#14-테스트-전략)

---

## 1. Drift 개요 및 설정

### 1.1 Drift란?

Drift는 타입 안전한 SQL 쿼리를 제공하는 Flutter용 데이터베이스 라이브러리입니다.

**장점:**
- ✅ 컴파일 타임 타입 체크
- ✅ 자동 완성과 리팩토링 지원
- ✅ 강력한 마이그레이션 시스템
- ✅ Stream 기반 실시간 업데이트
- ✅ 복잡한 SQL 쿼리 지원

### 1.2 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.2
  path: ^1.9.0

dev_dependencies:
  drift_dev: ^2.14.0
  build_runner: ^2.4.15
```

### 1.3 Database 클래스 생성

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

### 1.4 코드 생성

```bash
# 코드 생성
dart run build_runner build --delete-conflicting-outputs

# Watch 모드 (파일 변경 시 자동 생성)
dart run build_runner watch
```

---

## 2. 테이블 정의와 DAO 패턴

### 2.1 기본 테이블 정의

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

### 2.2 복합 테이블 예시

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

### 2.3 DAO (Data Access Object) 패턴

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

### 2.4 Database에 DAO 등록

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

---

## 3. 기본 CRUD 연산

### 3.1 Create (삽입)

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

print('Created user with ID: ${user.id}');
```

### 3.2 Read (조회)

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
  print('User not found');
}

// Limit, Offset
final firstTen = await (select(users)..limit(10)).get();
final nextTen = await (select(users)
      ..limit(10)
      ..offset(10))
    .get();

// 정렬
final sortedUsers = await (select(users)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
    .get();
```

### 3.3 Update (수정)

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

### 3.4 Delete (삭제)

```dart
// ID로 삭제
final deletedCount = await (delete(users)..where((tbl) => tbl.id.equals(1))).go();

// 조건부 삭제
await (delete(users)..where((tbl) => tbl.isActive.equals(false))).go();

// 전체 삭제 (주의!)
await delete(users).go();

// 삭제 후 확인
if (deletedCount > 0) {
  print('$deletedCount users deleted');
}
```

---

## 4. 복잡한 쿼리 작성

### 4.1 WHERE 조건

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

// Custom Expression
final results5 = await (select(users)
      ..where((tbl) =>
          Expression<bool>.and([
            tbl.isActive.equals(true),
            tbl.createdAt.isBiggerOrEqualValue(DateTime(2024)),
            tbl.email.like('%@gmail.com'),
          ])))
    .get();
```

### 4.2 집계 함수

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

### 4.3 GROUP BY와 HAVING

```dart
// GROUP BY (예: 작성자별 게시글 수)
final postCountByAuthor = await (selectOnly(posts)
      ..addColumns([posts.authorId, posts.id.count()])
      ..groupBy([posts.authorId]))
    .get();

for (final row in postCountByAuthor) {
  final authorId = row.read(posts.authorId);
  final count = row.read(posts.id.count());
  print('Author $authorId has $count posts');
}

// HAVING (게시글 10개 이상인 작성자만)
final prolificAuthors = await (selectOnly(posts)
      ..addColumns([posts.authorId, posts.id.count()])
      ..groupBy([posts.authorId])
      ..having(posts.id.count().isBiggerOrEqualValue(10)))
    .get();
```

### 4.4 서브쿼리

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

---

## 5. JOIN과 관계형 데이터

### 5.1 INNER JOIN

```dart
// 사용자와 게시글 JOIN
final query = select(users).join([
  innerJoin(posts, posts.authorId.equalsExp(users.id)),
]);

final results = await query.get();

for (final row in results) {
  final user = row.readTable(users);
  final post = row.readTable(posts);

  print('${user.name} wrote: ${post.title}');
}
```

### 5.2 LEFT OUTER JOIN

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
    print('${user.name}: ${post.title}');
  } else {
    print('${user.name}: No posts');
  }
}
```

### 5.3 다중 JOIN

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

### 5.4 JOIN 결과를 DTO로 매핑

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

---

## 6. 트랜잭션 관리

### 6.1 기본 트랜잭션

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

### 6.2 예외 처리와 롤백

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

  print('Transaction committed');
} catch (e) {
  print('Transaction rolled back: $e');
}
```

### 6.3 중첩 트랜잭션 (Savepoint)

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
    print('Inner transaction failed: $e');
  }

  // user1은 여전히 커밋됨
});
```

---

## 7. 실시간 쿼리와 Stream

### 7.1 watch() - 실시간 데이터 감지

```dart
// 전체 사용자 감지
Stream<List<User>> watchUsers() {
  return select(users).watch();
}

// UI에서 사용
class UserListScreen extends StatelessWidget {
  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<User>>(
      stream: db.userDao.watchAllUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
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

### 7.2 조건부 Stream

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

### 7.3 JOIN Stream

```dart
Stream<List<TypedResult>> watchUsersWithPostCount() {
  final query = select(users).join([
    leftOuterJoin(posts, posts.authorId.equalsExp(users.id)),
  ]);

  return query.watch();
}
```

### 7.4 Stream 변환

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

---

## 8. 마이그레이션 전략

### 8.1 스키마 버전 관리

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

### 8.2 컬럼 추가/삭제

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

### 8.3 테이블 이름 변경

```dart
await m.renameTable(users, 'app_users');
```

### 8.4 데이터 마이그레이션

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

### 8.5 마이그레이션 검증

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

---

## 9. 인덱싱과 성능 최적화

### 9.1 인덱스 정의

```dart
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

// 복합 인덱스 (Custom Index)
@override
List<Index> get indexes => [
  Index('user_email_name_idx', [email, name]),
  Index('user_created_idx', [createdAt]),
];
```

### 9.2 쿼리 성능 분석 (EXPLAIN)

```dart
Future<void> analyzeQuery() async {
  final query = select(users)..where((tbl) => tbl.email.equals('test@test.com'));

  // EXPLAIN QUERY PLAN
  final explanation = await customSelect(
    'EXPLAIN QUERY PLAN ${query.constructQuery().sql}',
    readsFrom: {users},
  ).get();

  for (final row in explanation) {
    print(row.data);
  }
}

// 결과 예시:
// SCAN TABLE users  ← 인덱스 없음 (느림)
// SEARCH TABLE users USING INDEX users_email_idx  ← 인덱스 사용 (빠름)
```

### 9.3 인덱스 전략

| 시나리오 | 인덱스 타입 | 예시 |
|---------|-----------|------|
| **Primary Key** | 자동 인덱스 | `autoIncrement()` |
| **Unique 컬럼** | Unique 인덱스 | `unique()` |
| **WHERE 절** | 단일 인덱스 | `Index('idx_email', [email])` |
| **WHERE + ORDER BY** | 복합 인덱스 | `Index('idx_email_created', [email, createdAt])` |
| **Foreign Key** | 인덱스 권장 | `Index('idx_author', [authorId])` |

### 9.4 성능 최적화 팁

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

---

## 10. Full-Text Search (FTS)

### 10.1 FTS5 테이블 생성

```dart
// FTS 전용 가상 테이블
@UseDriftFts(tokenizer: TokenizerType.porter)
class ArticlesFts extends Table {
  TextColumn get title => text()();
  TextColumn get content => text()();
}

@DriftDatabase(tables: [Articles, ArticlesFts])
class AppDatabase extends _$AppDatabase {
  // ...
}
```

### 10.2 데이터 동기화

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

### 10.3 전문 검색 쿼리

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

---

## 11. 데이터베이스 암호화

### 11.1 SQLCipher 설정

```yaml
# pubspec.yaml
dependencies:
  sqlcipher_flutter_libs: ^0.6.0
  sqlite3_flutter_libs: ^0.5.0
```

### 11.2 암호화된 데이터베이스 열기

```dart
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

LazyDatabase _openEncryptedConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'encrypted_app.db'));

    // SQLCipher 라이브러리 로드
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        // 암호화 키 설정
        db.execute("PRAGMA key = 'your-secret-key';");
      },
    );
  });
}
```

### 11.3 키 관리 (SecureStorage)

```dart
import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseKeyManager {
  final _storage = const FlutterSecureStorage();
  static const _keyName = 'database_encryption_key';

  Future<String> getOrCreateKey() async {
    var key = await _storage.read(key: _keyName);

    if (key == null) {
      // 256비트 랜덤 키 생성
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      key = base64Encode(bytes);
      await _storage.write(key: _keyName, value: key);
    }

    return key;
  }
}
```

---

## 12. 대용량 데이터 처리

### 12.1 배치 삽입

```dart
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

### 12.2 페이지네이션

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

### 12.3 백그라운드 처리

```dart
import 'dart:isolate';

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

  print(result);
}
```

---

## 13. Clean Architecture 통합

### 13.1 DataSource Layer

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

### 13.2 Repository Layer

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

### 13.3 Dependency Injection

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

---

## 14. 테스트 전략

### 14.1 Database Mock

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

### 14.2 In-Memory Database 테스트

```dart
// test/database/user_dao_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
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

---

## 참고 자료

- [Drift 공식 문서](https://drift.simonbinder.eu/)
- [Drift GitHub](https://github.com/simolus3/drift)
- [SQLite 공식 문서](https://www.sqlite.org/docs.html)
- [SQL Tutorial](https://www.sqltutorial.org/)

---

## 실습 과제

### 과제 1: Todo 앱 데이터베이스 구현

Drift로 Todo 앱의 데이터베이스를 구현하세요.

요구사항:
1. `Todos` 테이블 생성 (id, title, description, completed, dueDate, createdAt)
2. `TodoDao` 작성 (CRUD + watch 메서드)
3. 완료된 할 일 필터링 쿼리
4. 기한이 오늘인 할 일 조회
5. Stream으로 실시간 할 일 목록 제공

### 과제 2: 블로그 앱 관계형 데이터

사용자, 게시글, 댓글 관계를 구현하세요.

요구사항:
1. `Users`, `Posts`, `Comments` 테이블 정의 (Foreign Key 설정)
2. JOIN 쿼리로 사용자와 게시글 함께 조회
3. 게시글별 댓글 수 집계 쿼리
4. 트랜잭션으로 게시글과 댓글 함께 삭제
5. 사용자별 게시글 수를 Stream으로 제공

### 과제 3: 대용량 데이터 처리

1,000개 이상의 데이터를 효율적으로 처리하는 로직을 구현하세요.

요구사항:
1. Batch Insert로 1,000개 데이터 삽입
2. 페이지네이션 (페이지당 50개)
3. 인덱스 추가 후 성능 비교 (EXPLAIN 사용)
4. FTS로 전문 검색 구현
5. 백그라운드 Isolate에서 대량 데이터 처리

---

## Self-Check

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
