# Flutter 실전 프로젝트 가이드 - Todo 앱 처음부터 끝까지

> Clean Architecture + Bloc 패턴으로 프로덕션급 Todo 앱을 단계별로 구축하는 완전한 가이드입니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Flutter 프로젝트를 초기화하고 Clean Architecture 구조를 설정할 수 있습니다
> - Domain → Data → Presentation 계층을 순서대로 구현하여 완전한 기능을 만들 수 있습니다
> - DI, 라우팅, 에러 처리, 테스트, CI/CD까지 프로덕션 배포 전 체크리스트를 완성할 수 있습니다

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [프로젝트 초기화](#2-프로젝트-초기화)
3. [아키텍처 설계](#3-아키텍처-설계)
4. [도메인 레이어 구현](#4-도메인-레이어-구현)
5. [데이터 레이어 구현](#5-데이터-레이어-구현)
6. [프레젠테이션 레이어 구현](#6-프레젠테이션-레이어-구현)
7. [Dependency Injection 설정](#7-dependency-injection-설정)
8. [라우팅과 네비게이션](#8-라우팅과-네비게이션)
9. [에러 처리 전략](#9-에러-처리-전략)
10. [테스트 작성](#10-테스트-작성)
11. [CI/CD 설정](#11-cicd-설정)
12. [프로덕션 체크리스트](#12-프로덕션-체크리스트)

---

## 1. 프로젝트 개요

### 1.1 Todo 앱 요구사항

이 튜토리얼에서는 실전 프로덕션급 Todo 앱을 처음부터 끝까지 구축합니다.

**핵심 기능:**
- ✅ Todo 추가 (제목, 설명, 기한)
- ✅ Todo 목록 조회
- ✅ Todo 완료/미완료 토글
- ✅ Todo 수정 및 삭제
- ✅ 오프라인 지원

**기술 스택:**
- Clean Architecture + Bloc 패턴
- Dio + Retrofit (네트워킹)
- Drift (로컬 DB)
- GetIt + Injectable (DI)
- GoRouter (라우팅)

### 1.2 학습 흐름

이 문서는 기존 문서들을 종합하는 실전 가이드입니다. 각 단계에서 관련 문서를 참조하세요:

| 단계 | 참조 문서 |
|------|----------|
| **아키텍처 설계** | `core/Architecture.md` |
| **Entity 정의** | `core/Freezed.md` |
| **에러 처리** | `core/Fpdart.md` |
| **Bloc 상태 관리** | `core/Bloc.md` |
| **API 통신** | `networking/Networking_Dio.md` |
| **로컬 DB** | `infrastructure/DatabaseAdvanced.md` |
| **DI 설정** | `infrastructure/DI.md` |
| **라우팅** | `features/Navigation.md` |
| **테스트** | `system/Testing.md` |
| **CI/CD** | `infrastructure/CICD.md` |

---

## 2. 프로젝트 초기화

### 2.1 Flutter 프로젝트 생성

```bash
# 프로젝트 생성
flutter create todo_app
cd todo_app

# FVM 설정
fvm use 3.19.0

# Git 초기화
git init
git add .
git commit -m "chore: initial commit"
```

### 2.2 의존성 추가

> 💡 **참고**: 전체 `pubspec.yaml` 설정은 각 기술별 문서를 참조하세요.

**필수 패키지:**
- flutter_bloc ^9.1.1
- freezed ^3.2.4
- fpdart ^1.2.0
- dio ^5.9.0 / retrofit ^4.0.0
- drift ^2.14.0
- get_it ^9.2.0 / injectable ^2.5.0
- go_router ^17.0.1

### 2.3 폴더 구조 생성

```bash
mkdir -p lib/{app,core/{di,errors,network,database},features/todo/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{bloc,pages,widgets}}}
```

---

## 3. 아키텍처 설계

> 💡 **참고 문서**: `core/Architecture.md`

### 3.1 Clean Architecture 3계층

**Domain Layer (비즈니스 로직)**
- Entities: 핵심 비즈니스 객체
- Repository Interfaces: 데이터 접근 추상화
- UseCases: 비즈니스 규칙

**Data Layer (데이터 접근)**
- Models (DTO): API/DB 데이터 구조
- DataSources: Remote/Local 데이터 소스
- Repository Implementations: 인터페이스 구현

**Presentation Layer (UI)**
- Bloc: 상태 관리
- Pages/Widgets: UI 컴포넌트

### 3.2 의존성 규칙

```
Presentation → Domain ← Data
```

Domain 계층은 다른 계층에 의존하지 않습니다.

---

## 4. 도메인 레이어 구현

> 💡 **참고 문서**: `core/Freezed.md`, `core/Fpdart.md`

### 4.1 Entity 정의

```dart
// lib/features/todo/domain/entities/todo.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo.freezed.dart';

@freezed
class Todo with _$Todo {
  const factory Todo({
    required String id,
    required String title,
    required String description,
    required bool isCompleted,
    DateTime? dueDate,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Todo;
}
```

자세한 Freezed 사용법은 `core/Freezed.md`를 참조하세요.

### 4.2 Repository Interface

```dart
// lib/features/todo/domain/repositories/todo_repository.dart
import 'package:fpdart/fpdart.dart';
import '../entities/todo.dart';

abstract class TodoRepository {
  Future<Either<Failure, List<Todo>>> getTodos();
  Future<Either<Failure, Todo>> createTodo({
    required String title,
    required String description,
    DateTime? dueDate,
  });
  Future<Either<Failure, Todo>> toggleTodoStatus(String id);
  Future<Either<Failure, Unit>> deleteTodo(String id);
}
```

Either 패턴에 대한 자세한 설명은 `core/Fpdart.md`를 참조하세요.

### 4.3 UseCase 구현

```dart
// lib/features/todo/domain/usecases/get_todos_usecase.dart
@injectable
class GetTodosUseCase {
  final TodoRepository _repository;

  GetTodosUseCase(this._repository);

  Future<Either<Failure, List<Todo>>> call() {
    return _repository.getTodos();
  }
}
```

UseCase 패턴에 대한 자세한 설명은 `core/Architecture.md`를 참조하세요.

---

## 5. 데이터 레이어 구현

> 💡 **참고 문서**: `networking/Networking_Dio.md`, `infrastructure/DatabaseAdvanced.md`

### 5.1 DTO 정의

```dart
// lib/features/todo/data/models/todo_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_dto.freezed.dart';
part 'todo_dto.g.dart';

@freezed
class TodoDto with _$TodoDto {
  const factory TodoDto({
    required String id,
    required String title,
    // ... 필드 정의
  }) = _TodoDto;

  factory TodoDto.fromJson(Map<String, dynamic> json) =>
      _$TodoDtoFromJson(json);
}

// DTO ↔ Entity 변환
extension TodoDtoX on TodoDto {
  Todo toEntity() => Todo(/* ... */);
}
```

### 5.2 Remote DataSource (Retrofit)

```dart
// lib/features/todo/data/datasources/todo_remote_datasource.dart
@RestApi(baseUrl: 'https://api.example.com/v1')
abstract class TodoRemoteDataSource {
  factory TodoRemoteDataSource(Dio dio) = _TodoRemoteDataSource;

  @GET('/todos')
  Future<List<TodoDto>> getTodos();

  @POST('/todos')
  Future<TodoDto> createTodo(@Body() Map<String, dynamic> body);
}
```

Retrofit 사용법은 `networking/Networking_Dio.md`를 참조하세요.

### 5.3 Local DataSource (Drift)

```dart
// lib/features/todo/data/datasources/todo_local_datasource.dart
class Todos extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean()();
  // ... 필드 정의

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [Todos])
class TodoLocalDataSource extends DatabaseAccessor<AppDatabase> {
  // CRUD 메서드 구현
}
```

Drift 사용법은 `infrastructure/DatabaseAdvanced.md`를 참조하세요.

### 5.4 Repository Implementation

```dart
// lib/features/todo/data/repositories/todo_repository_impl.dart
@LazySingleton(as: TodoRepository)
class TodoRepositoryImpl implements TodoRepository {
  final TodoRemoteDataSource _remote;
  final TodoLocalDataSource _local;

  @override
  Future<Either<Failure, List<Todo>>> getTodos() async {
    try {
      // 1. 원격 데이터 가져오기
      final dtos = await _remote.getTodos();
      
      // 2. 로컬 캐시 업데이트
      // ...

      // 3. Entity로 변환
      return Right(dtos.map((dto) => dto.toEntity()).toList());
    } on DioException catch (e) {
      // 네트워크 실패 시 로컬 캐시 반환
      // ...
      return Left(Failure.network(e.message));
    }
  }
}
```

---

## 6. 프레젠테이션 레이어 구현

> 💡 **참고 문서**: `core/Bloc.md`

### 6.1 Bloc Event/State

```dart
// Event
@freezed
class TodoEvent with _$TodoEvent {
  const factory TodoEvent.started() = TodoStarted;
  const factory TodoEvent.created({
    required String title,
    required String description,
  }) = TodoCreated;
}

// State
@freezed
class TodoState with _$TodoState {
  const factory TodoState.initial() = TodoInitial;
  const factory TodoState.loading() = TodoLoading;
  const factory TodoState.loaded(List<Todo> todos) = TodoLoaded;
  const factory TodoState.error(String message) = TodoError;
}
```

### 6.2 Bloc 구현

```dart
@injectable
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final GetTodosUseCase _getTodosUseCase;

  TodoBloc(this._getTodosUseCase) : super(const TodoState.initial()) {
    on<TodoStarted>(_onStarted);
  }

  Future<void> _onStarted(
    TodoStarted event,
    Emitter<TodoState> emit,
  ) async {
    emit(const TodoState.loading());

    final result = await _getTodosUseCase();

    result.fold(
      (failure) => emit(TodoState.error(failure.message)),
      (todos) => emit(TodoState.loaded(todos)),
    );
  }
}
```

Bloc 패턴과 Transformer에 대한 자세한 내용은 `core/Bloc.md`를 참조하세요.

### 6.3 UI 구현

```dart
class TodoListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TodoBloc>()..add(const TodoEvent.started()),
      child: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text('할 일을 추가하세요')),
            loading: () => const CircularProgressIndicator(),
            loaded: (todos) => ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) => TodoListItem(todo: todos[index]),
            ),
            error: (message) => Center(child: Text(message)),
          );
        },
      ),
    );
  }
}
```

---

## 7. Dependency Injection 설정

> 💡 **참고 문서**: `infrastructure/DI.md`

### 7.1 Injectable 설정

```dart
// lib/core/di/injection.dart
final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();

// main.dart
void main() {
  configureDependencies();
  runApp(const MyApp());
}
```

### 7.2 Module 정의

```dart
// lib/core/di/modules/network_module.dart
@module
abstract class NetworkModule {
  @lazySingleton
  Dio dio() {
    return Dio(BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: const Duration(seconds: 30),
    ));
  }
}
```

자세한 DI 설정은 `infrastructure/DI.md`를 참조하세요.

---

## 8. 라우팅과 네비게이션

> 💡 **참고 문서**: `features/Navigation.md`

### 8.1 GoRouter 설정

```dart
// lib/app/router.dart
final router = GoRouter(
  initialLocation: '/todos',
  routes: [
    GoRoute(
      path: '/todos',
      builder: (context, state) => const TodoListPage(),
    ),
    GoRoute(
      path: '/todos/create',
      builder: (context, state) => const CreateTodoPage(),
    ),
  ],
);

// lib/app/app.dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
    );
  }
}
```

---

## 9. 에러 처리 전략

> 💡 **참고 문서**: `system/ErrorHandling.md`

### 9.1 Failure 타입 정의

```dart
@freezed
class Failure with _$Failure {
  const factory Failure.network([String? message]) = NetworkFailure;
  const factory Failure.server([String? message]) = ServerFailure;
  const factory Failure.cache([String? message]) = CacheFailure;
}
```

### 9.2 UI에서 에러 표시

Bloc의 error 상태에서 사용자 친화적인 메시지를 표시합니다.

---

## 10. 테스트 작성

> 💡 **참고 문서**: `system/Testing.md`

### 10.1 UseCase 테스트

```dart
test('should return list of todos from repository', () async {
  // Arrange
  when(mockRepository.getTodos()).thenAnswer((_) async => Right(todos));

  // Act
  final result = await useCase();

  // Assert
  expect(result, Right(todos));
  verify(mockRepository.getTodos()).called(1);
});
```

### 10.2 Bloc 테스트

```dart
blocTest<TodoBloc, TodoState>(
  'emits [loading, loaded] when started',
  build: () {
    when(mockUseCase()).thenAnswer((_) async => Right([]));
    return bloc;
  },
  act: (bloc) => bloc.add(const TodoEvent.started()),
  expect: () => [
    const TodoState.loading(),
    const TodoState.loaded([]),
  ],
);
```

테스트 전략과 패턴은 `system/Testing.md`를 참조하세요.

---

## 11. CI/CD 설정

> 💡 **참고 문서**: `infrastructure/CICD.md`

### 11.1 GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
```

자세한 CI/CD 설정은 `infrastructure/CICD.md`를 참조하세요.

---

## 12. 프로덕션 체크리스트

### 12.1 코드 품질
- [ ] 린트 규칙 통과 (`flutter analyze`)
- [ ] 테스트 커버리지 70% 이상
- [ ] 모든 TODO 주석 해결

### 12.2 기능 완성도
- [ ] 모든 핵심 기능 구현
- [ ] 에러 처리 완료
- [ ] 오프라인 모드 동작 확인
- [ ] 로딩 상태 표시

### 12.3 성능 최적화
- [ ] 불필요한 rebuild 제거
- [ ] 이미지 최적화
- [ ] 메모리 누수 체크

### 12.4 보안
- [ ] API 키 환경 변수 처리
- [ ] 민감한 정보 로그 제거
- [ ] HTTPS 통신 확인

### 12.5 배포 준비
- [ ] 앱 아이콘 설정
- [ ] 스플래시 스크린 추가
- [ ] 버전 번호 설정
- [ ] README.md 작성

---

## 실습 과제

### 과제 1: Todo 앱 완성
이 문서와 참조 문서들을 따라 Todo 앱을 처음부터 끝까지 구현하세요.

**단계:**
1. 프로젝트 초기화
2. Domain Layer 구현 (Entity, Repository, UseCase)
3. Data Layer 구현 (DTO, DataSource, Repository)
4. Presentation Layer 구현 (Bloc, UI)
5. DI 및 라우팅 설정
6. 테스트 작성
7. CI/CD 설정

### 과제 2: 추가 기능 구현
다음 기능을 추가하여 앱을 확장하세요:
- 카테고리별 Todo 분류
- 우선순위 설정
- 검색 기능
- 다크 모드

### 과제 3: 프로덕션 배포
- Play Store / App Store 배포 준비
- 릴리즈 빌드 생성
- 실제 배포

---

## Self-Check

- [ ] Clean Architecture의 3계층(Domain, Data, Presentation)과 의존성 규칙을 설명할 수 있는가?
- [ ] Freezed로 불변 Entity와 DTO를 정의하고 변환할 수 있는가?
- [ ] Either 패턴으로 에러를 타입 안전하게 처리할 수 있는가?
- [ ] Retrofit으로 API 통신을 구현할 수 있는가?
- [ ] Drift로 로컬 데이터베이스를 구현하고 오프라인 지원을 추가할 수 있는가?
- [ ] Repository에서 Remote/Local 캐싱 전략을 구현할 수 있는가?
- [ ] Bloc으로 상태 관리를 하고 UI와 연동할 수 있는가?
- [ ] GetIt + Injectable로 DI를 설정할 수 있는가?
- [ ] GoRouter로 라우팅을 구현할 수 있는가?
- [ ] 각 계층에 대한 테스트를 작성하고 커버리지를 측정할 수 있는가?
- [ ] CI/CD 파이프라인을 설정하고 자동화된 테스트를 실행할 수 있는가?
- [ ] 프로덕션 배포 전 체크리스트를 완료하고 앱을 배포할 수 있는가?
