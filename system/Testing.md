# Flutter Testing Guide

> 이 문서는 Flutter 프로젝트에서 테스트를 작성하는 방법을 설명합니다.

## 학습 목표

이 문서를 학습하면 다음을 할 수 있습니다:

1. **Unit Test / Widget Test / Integration Test**의 차이와 테스트 피라미드 전략을 이해할 수 있다
2. **Mockito**(또는 mocktail)를 사용하여 Mock 객체를 생성하고 Stub을 설정할 수 있다
3. **bloc_test** 패키지로 Bloc의 상태 변화를 `blocTest`로 검증할 수 있다
4. **Widget Test**에서 `MockBloc`과 `whenListen`을 사용하여 UI 상태별 렌더링을 테스트할 수 있다
5. **Patrol**을 활용하여 네이티브 권한 처리를 포함한 E2E 테스트를 작성할 수 있다

---

## 1. 테스트 개요

### 1.1 테스트 종류

| 종류 | 범위 | 속도 | 의존성 |
|------|------|------|--------|
| **Unit Test** | 단일 함수/클래스 | 빠름 | 없음 (Mock) |
| **Widget Test** | 단일 위젯 | 중간 | Flutter Framework |
| **Integration Test** | 전체 앱 | 느림 | 실제 디바이스/에뮬레이터 |

### 1.2 테스트 피라미드

```
        /\
       /  \     Integration Test (10%)
      /----\
     /      \   Widget Test (20%)
    /--------\
   /          \ Unit Test (70%)
  --------------
```

- **Unit Test**: 가장 많이 작성 (UseCase, Repository, Bloc, Mapper)
- **Widget Test**: UI 컴포넌트 검증
- **Integration Test**: E2E 시나리오 (선택적)

## 2. 프로젝트 설정

### 2.1 의존성 추가

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
  mockito: ^5.6.3
  build_runner: ^2.4.15  # mockito 코드 생성용

# ⚠️ 주의: 이 문서의 테스트 예제는 mockito를 사용하지만, 이 프로젝트의 표준 모킹 라이브러리는 mocktail입니다.
# mocktail 사용 시: import 'package:mocktail/mocktail.dart';
# Mock 클래스: class MockRepo extends Mock implements Repository {} (코드 생성 불필요)
# when 구문: when(() => mock.method()).thenAnswer(...)
# verify 구문: verify(() => mock.method()).called(1)
```

### 2.2 테스트 폴더 구조

```
features/{feature_name}/
├── lib/
│   ├── data/
│   ├── domain/
│   └── presentation/
└── test/
    ├── data/
    │   ├── datasources/
    │   │   └── home_remote_datasource_test.dart
    │   ├── mappers/
    │   │   └── home_mapper_test.dart
    │   └── repositories/
    │       └── home_repository_impl_test.dart
    ├── domain/
    │   └── usecases/
    │       └── get_home_data_usecase_test.dart
    ├── presentation/
    │   ├── bloc/
    │   │   └── home_bloc_test.dart
    │   └── screens/
    │       └── home_screen_test.dart
    ├── fixtures/
    │   └── home_fixture.dart
    └── mocks/
        └── mocks.dart
```

## 3. Mockito 사용법

> **💡 중요:** bloc_test의 `MockBloc`과 함께 사용 시 mockito의 `when()`이 작동하지 않습니다.
> - `MockBloc`은 mocktail 스타일을 따르므로 `whenListen()` 사용 필요
> - 또는 mockito 대신 **mocktail** 패키지 사용 권장
> - 자세한 내용은 "6.2 Bloc과 함께 Widget Test" 섹션 참조

### 3.1 Mock 클래스 정의

```dart
// test/mocks/mocks.dart
import 'package:mockito/annotations.dart';
import 'package:home/domain/domain.dart';
import 'package:home/data/data.dart';

// Mock 생성 어노테이션
@GenerateMocks([
  HomeRepository,
  HomeRemoteDataSource,
  GetHomeDataUseCase,
])
void main() {}
```

**Mock 파일 생성:**

```bash
# Mock 파일 자동 생성
dart run build_runner build --delete-conflicting-outputs
```

이 명령어를 실행하면 `test/mocks/mocks.mocks.dart` 파일이 자동 생성됩니다.

### 3.2 테스트 파일에서 Mock 사용

```dart
// test/domain/usecases/get_home_data_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../mocks/mocks.mocks.dart';  // 생성된 Mock 파일 import

void main() {
  late MockHomeRepository mockRepository;

  setUp(() {
    mockRepository = MockHomeRepository();
  });
}
```

### 3.3 Stub 설정

```dart
// 성공 케이스
when(mockRepository.getHomeData())
    .thenAnswer((_) async => Right(homeData));

// 실패 케이스
when(mockRepository.getHomeData())
    .thenAnswer((_) async => Left(const HomeFailure.network()));

// Exception 발생
when(mockDataSource.fetchData())
    .thenThrow(DioException(requestOptions: RequestOptions()));

// 여러 번 호출 시 다른 결과를 반환하려면 카운터 변수 사용
// ❌ 잘못된 방법: 체이닝 시 마지막 thenAnswer만 적용됨
// when(mockRepository.getHomeData())
//     .thenAnswer((_) async => Right(homeData1))
//     .thenAnswer((_) async => Right(homeData2));

// ✅ 올바른 방법: 카운터 변수로 순차 반환 구현
var callCount = 0;
when(mockRepository.getHomeData()).thenAnswer((_) async {
  callCount++;
  return callCount == 1 ? Right(homeData1) : Right(homeData2);
});
```

## 4. Unit Test

### 4.1 UseCase 테스트

```dart
// test/domain/usecases/get_home_data_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:home/domain/domain.dart';

import '../../mocks/mocks.mocks.dart';
import '../../fixtures/home_fixture.dart';

void main() {
  late GetHomeDataUseCase useCase;
  late MockHomeRepository mockRepository;

  setUp(() {
    mockRepository = MockHomeRepository();
    useCase = GetHomeDataUseCase(mockRepository);
  });

  group('GetHomeDataUseCase', () {
    test('성공 시 HomeData 반환', () async {
      // Arrange
      final expected = HomeFixture.homeData;
      when(mockRepository.getHomeData())
          .thenAnswer((_) async => Right(expected));

      // Act
      final result = await useCase();

      // Assert
      expect(result, Right(expected));
      verify(mockRepository.getHomeData()).called(1);
    });

    test('실패 시 HomeFailure 반환', () async {
      // Arrange
      when(mockRepository.getHomeData())
          .thenAnswer((_) async => const Left(HomeFailure.network()));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(HomeFailure.network()));
    });
  });
}
```

### 4.2 Repository 테스트

```dart
// test/data/repositories/home_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:home/data/data.dart';
import 'package:home/domain/domain.dart';

import '../../mocks/mocks.mocks.dart';
import '../../fixtures/home_fixture.dart';

void main() {
  late HomeRepositoryImpl repository;
  late MockHomeRemoteDataSource mockDataSource;
  late HomeMapper mapper;

  setUp(() {
    mockDataSource = MockHomeRemoteDataSource();
    mapper = HomeMapper();
    repository = HomeRepositoryImpl(mockDataSource, mapper);
  });

  group('getHomeData', () {
    test('DataSource 성공 시 Entity 반환', () async {
      // Arrange
      final dto = HomeFixture.homeDto;
      when(mockDataSource.getHomeData())
          .thenAnswer((_) async => dto);

      // Act
      final result = await repository.getHomeData();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right, got Left'),
        (data) {
          expect(data.id, dto.id);
          expect(data.title, dto.title);
        },
      );
    });

    test('DioException 발생 시 Failure 반환', () async {
      // Arrange
      when(mockDataSource.getHomeData()).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await repository.getHomeData();

      // Assert
      expect(result, const Left(HomeFailure.network()));
    });

    test('서버 에러(5xx) 시 server Failure 반환', () async {
      // Arrange
      when(mockDataSource.getHomeData()).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      final result = await repository.getHomeData();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<HomeFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
```

### 4.3 Mapper 테스트

```dart
// test/data/mappers/home_mapper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home/data/data.dart';

import '../../fixtures/home_fixture.dart';

void main() {
  late HomeMapper mapper;

  setUp(() {
    mapper = HomeMapper();
  });

  group('HomeMapper', () {
    test('DTO를 Entity로 변환', () {
      // Arrange
      final dto = HomeFixture.homeDto;

      // Act
      final entity = mapper.toEntity(dto);

      // Assert
      expect(entity.id, dto.id);
      expect(entity.title, dto.title);
      expect(entity.createdAt, dto.createdAt);
    });

    test('null 필드 처리', () {
      // Arrange
      final dto = HomeFixture.homeDtoWithNulls;

      // Act
      final entity = mapper.toEntity(dto);

      // Assert
      expect(entity.description, isNull);
    });
  });
}
```

## 5. Bloc Test

### 5.1 bloc_test 패키지 사용

```dart
// test/presentation/bloc/home_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:home/domain/domain.dart';
import 'package:home/presentation/presentation.dart';

import '../../mocks/mocks.mocks.dart';
import '../../fixtures/home_fixture.dart';

void main() {
  late MockGetHomeDataUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetHomeDataUseCase();
  });

  group('HomeBloc', () {
    test('초기 상태는 initial', () {
      final bloc = HomeBloc(mockUseCase);
      expect(bloc.state, const HomeState.initial());
    });

    blocTest<HomeBloc, HomeState>(
      'started 이벤트 시 loading → loaded 상태 변화',
      build: () {
        when(mockUseCase())
            .thenAnswer((_) async => Right(HomeFixture.homeData));
        return HomeBloc(mockUseCase);
      },
      act: (bloc) => bloc.add(const HomeEvent.started()),
      expect: () => [
        const HomeState.loading(),
        HomeState.loaded(HomeFixture.homeData),
      ],
      verify: (_) {
        verify(mockUseCase()).called(1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      '실패 시 loading → error 상태 변화',
      build: () {
        when(mockUseCase())
            .thenAnswer((_) async => const Left(HomeFailure.network()));
        return HomeBloc(mockUseCase);
      },
      act: (bloc) => bloc.add(const HomeEvent.started()),
      expect: () => [
        const HomeState.loading(),
        const HomeState.error('네트워크 오류가 발생했습니다.'),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'refresh 이벤트 시 데이터 다시 로드',
      build: () {
        when(mockUseCase())
            .thenAnswer((_) async => Right(HomeFixture.homeData));
        return HomeBloc(mockUseCase);
      },
      seed: () => HomeState.loaded(HomeFixture.homeData),
      act: (bloc) => bloc.add(const HomeEvent.refresh()),
      expect: () => [
        const HomeState.loading(),
        HomeState.loaded(HomeFixture.homeData),
      ],
    );
  });
}
```

### 5.2 Effect Stream 테스트 (BaseBloc 사용 시)

```dart
// test/presentation/bloc/login_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'login_bloc_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  group('LoginBloc Effect', () {
    test('로그인 성공 시 NavigateToHome Effect 발행', () async {
      // Arrange
      final user = User(id: '1', name: 'Test User', email: 'test@example.com');
      when(mockAuthRepo.login(any, any))
          .thenAnswer((_) async => Right(user));

      final bloc = LoginBloc(authRepository: mockAuthRepo);
      final effects = <LoginEffect>[];

      // Act
      bloc.effectStream.listen(effects.add);
      bloc.add(LoginSubmitted(email: 'test@test.com', password: '1234'));

      await bloc.stream.firstWhere((s) => !s.isLoading);

      // Assert
      expect(effects, contains(isA<NavigateToHome>()));
    });

    test('로그인 실패 시 ShowErrorDialog Effect 발행', () async {
      // Arrange
      when(mockAuthRepo.login(any, any))
          .thenAnswer((_) async => const Left(AuthFailure.invalidCredentials()));

      final bloc = LoginBloc(authRepository: mockAuthRepo);
      final effects = <LoginEffect>[];

      // Act
      bloc.effectStream.listen(effects.add);
      bloc.add(LoginSubmitted(email: 'test@test.com', password: 'wrong'));

      await bloc.stream.firstWhere((s) => !s.isLoading);

      // Assert
      expect(effects, contains(isA<ShowErrorDialog>()));
    });
  });
}
```

## 6. Widget Test

### 6.1 기본 Widget Test

```dart
// test/presentation/widgets/home_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home/presentation/presentation.dart';

import '../../fixtures/home_fixture.dart';

void main() {
  group('HomeCard', () {
    testWidgets('데이터가 올바르게 표시됨', (tester) async {
      // Arrange
      final item = HomeFixture.homeItem;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeCard(item: item),
          ),
        ),
      );

      // Assert
      expect(find.text(item.title), findsOneWidget);
      expect(find.text(item.description), findsOneWidget);
    });

    testWidgets('탭 시 onTap 콜백 호출', (tester) async {
      // Arrange
      var tapped = false;
      final item = HomeFixture.homeItem;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeCard(
              item: item,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(HomeCard));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });
  });
}
```

### 6.2 Bloc과 함께 Widget Test

```dart
// test/presentation/screens/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:home/presentation/presentation.dart';

import '../../mocks/mocks.mocks.dart';
import '../../fixtures/home_fixture.dart';

// 💡 권장: bloc_test의 MockBloc과 함께 사용 시 mockito 대신 mocktail 사용
// - bloc_test의 MockBloc은 mocktail 스타일을 따름
// - mockito의 when()은 작동하지 않음 → whenListen() 사용 필요

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

void main() {
  late MockHomeBloc mockBloc;

  setUp(() {
    mockBloc = MockHomeBloc();
  });

  Widget buildWidget() {
    return MaterialApp(
      home: BlocProvider<HomeBloc>.value(
        value: mockBloc,
        child: const HomeScreen(),
      ),
    );
  }

  group('HomeScreen', () {
    testWidgets('initial 상태에서 빈 화면 표시', (tester) async {
      // Arrange
      whenListen(
        mockBloc,
        Stream<HomeState>.empty(),
        initialState: const HomeState.initial(),
      );

      // Act
      await tester.pumpWidget(buildWidget());

      // Assert
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('loading 상태에서 로딩 인디케이터 표시', (tester) async {
      // Arrange
      whenListen(
        mockBloc,
        Stream<HomeState>.empty(),
        initialState: const HomeState.loading(),
      );

      // Act
      await tester.pumpWidget(buildWidget());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('loaded 상태에서 데이터 표시', (tester) async {
      // Arrange
      whenListen(
        mockBloc,
        Stream<HomeState>.empty(),
        initialState: HomeState.loaded(HomeFixture.homeData),
      );

      // Act
      await tester.pumpWidget(buildWidget());

      // Assert
      expect(find.text(HomeFixture.homeData.title), findsOneWidget);
    });

    testWidgets('error 상태에서 에러 메시지 표시', (tester) async {
      // Arrange
      const errorMessage = '에러가 발생했습니다.';
      whenListen(
        mockBloc,
        Stream<HomeState>.empty(),
        initialState: const HomeState.error(errorMessage),
      );

      // Act
      await tester.pumpWidget(buildWidget());

      // Assert
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('새로고침 버튼 탭 시 refresh 이벤트 발행', (tester) async {
      // Arrange
      whenListen(
        mockBloc,
        Stream<HomeState>.empty(),
        initialState: HomeState.loaded(HomeFixture.homeData),
      );

      // Act
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Assert
      verify(mockBloc.add(const HomeEvent.refresh())).called(1);
    });
  });
}
```

## 7. Fixture 패턴

### 7.1 테스트 데이터 정의

```dart
// test/fixtures/home_fixture.dart
import 'package:home/data/data.dart';
import 'package:home/domain/domain.dart';

class HomeFixture {
  HomeFixture._();

  // DTO Fixtures
  static HomeDto get homeDto => HomeDto(
        id: 'test-id-1',
        title: '테스트 타이틀',
        description: '테스트 설명',
        createdAt: DateTime(2024, 1, 1),
      );

  static HomeDto get homeDtoWithNulls => HomeDto(
        id: 'test-id-2',
        title: '타이틀만 있음',
        description: null,
        createdAt: DateTime(2024, 1, 1),
      );

  // Entity Fixtures
  static HomeData get homeData => HomeData(
        id: 'test-id-1',
        title: '테스트 타이틀',
        description: '테스트 설명',
        createdAt: DateTime(2024, 1, 1),
      );

  static HomeItem get homeItem => const HomeItem(
        id: 'item-1',
        title: '아이템 타이틀',
        description: '아이템 설명',
      );

  // List Fixtures
  static List<HomeItem> get homeItems => [
        const HomeItem(id: '1', title: '아이템 1', description: '설명 1'),
        const HomeItem(id: '2', title: '아이템 2', description: '설명 2'),
        const HomeItem(id: '3', title: '아이템 3', description: '설명 3'),
      ];

  // JSON Fixtures
  static Map<String, dynamic> get homeJson => {
        'id': 'test-id-1',
        'title': '테스트 타이틀',
        'description': '테스트 설명',
        'created_at': '2024-01-01T00:00:00.000Z',
      };
}
```

### 7.2 JSON Fixture 파일 사용

```dart
// test/fixtures/json_reader.dart
import 'dart:convert';
import 'dart:io';

class JsonReader {
  static Map<String, dynamic> read(String fileName) {
    final file = File('test/fixtures/json/$fileName');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  static List<dynamic> readList(String fileName) {
    final file = File('test/fixtures/json/$fileName');
    return jsonDecode(file.readAsStringSync()) as List<dynamic>;
  }
}

// 사용
// test/fixtures/json/home_response.json 파일 생성 후
final json = JsonReader.read('home_response.json');
final dto = HomeDto.fromJson(json);
```

## 8. 테스트 네이밍 컨벤션

### 8.1 파일명

```
{테스트_대상}_test.dart

예시:
- home_bloc_test.dart
- get_home_data_usecase_test.dart
- home_repository_impl_test.dart
```

### 8.2 테스트 설명

```dart
// 한글로 명확하게 작성
group('HomeBloc', () {
  test('초기 상태는 initial이다', () { ... });
  test('started 이벤트 발생 시 데이터를 로드한다', () { ... });
  test('네트워크 오류 시 error 상태로 변경된다', () { ... });
});

// blocTest 설명
blocTest<HomeBloc, HomeState>(
  '새로고침 시 기존 데이터를 유지하면서 로딩 상태로 변경된다',
  ...
);
```

### 8.3 AAA 패턴 (Arrange-Act-Assert)

```dart
test('로그인 성공 시 사용자 정보 반환', () async {
  // Arrange (준비)
  final expected = User(id: '1', name: 'Test');
  when(mockRepo.login(any, any))
      .thenAnswer((_) async => Right(expected));

  // Act (실행)
  final result = await useCase(email: 'test@test.com', password: '1234');

  // Assert (검증)
  expect(result, Right(expected));
  verify(mockRepo.login('test@test.com', '1234')).called(1);
});
```

## 9. 테스트 실행

### 9.1 명령어

```bash
# 전체 테스트 실행
fvm flutter test

# 특정 파일 테스트
fvm flutter test test/domain/usecases/get_home_data_usecase_test.dart

# 특정 폴더 테스트
fvm flutter test test/presentation/

# 커버리지 포함
fvm flutter test --coverage

# Melos로 전체 패키지 테스트
melos run test
```

### 9.2 melos.yaml 설정

```yaml
# melos.yaml
scripts:
  test:
    run: melos exec -- fvm flutter test
    description: Run tests in all packages

  test:coverage:
    run: melos exec -- fvm flutter test --coverage
    description: Run tests with coverage
```

## 10. Best Practices

### 10.1 DO (이렇게 하세요)

| 항목 | 설명 |
|------|------|
| Mock 사용 | 외부 의존성은 항상 Mock으로 대체 |
| Fixture 분리 | 테스트 데이터는 Fixture 클래스로 관리 |
| 단일 책임 | 하나의 테스트는 하나만 검증 |
| 명확한 설명 | 테스트 설명은 한글로 명확하게 |
| AAA 패턴 | Arrange-Act-Assert 구조 유지 |

### 10.2 DON'T (하지 마세요)

```dart
// ❌ 여러 가지를 한 테스트에서 검증
test('로그인 테스트', () async {
  // 성공 케이스
  final result1 = await useCase(...);
  expect(result1.isRight(), true);

  // 실패 케이스 (별도 테스트로 분리해야 함)
  final result2 = await useCase(...);
  expect(result2.isLeft(), true);
});

// ❌ 실제 API 호출
test('데이터 로드', () async {
  final repo = HomeRepositoryImpl(RealDataSource());  // Mock 사용해야 함
  final result = await repo.getHomeData();
});

// ❌ 테스트 간 상태 공유
late HomeBloc bloc;
setUpAll(() {
  bloc = HomeBloc(...);  // setUp에서 매번 새로 생성해야 함
});
```

### 10.3 테스트 커버리지 목표

| 레이어 | 목표 커버리지 |
|--------|--------------|
| Domain (UseCase) | 90%+ |
| Data (Repository) | 80%+ |
| Presentation (Bloc) | 80%+ |
| Widget | 60%+ |

## 11. 자주 하는 실수

### ❌ setUpAll에서 Mock 초기화

```dart
// ❌ 잘못된 패턴 - Mock 상태가 테스트 간 공유됨
late MockRepository mockRepo;
setUpAll(() {
  mockRepo = MockRepository();
});

// ✅ 올바른 패턴 - 매 테스트마다 새로운 Mock
late MockRepository mockRepo;
setUp(() {
  mockRepo = MockRepository();
});
```

### ❌ async 테스트에서 await 누락

```dart
// ❌ 잘못된 패턴 - 테스트가 끝나기 전에 검증
test('데이터 로드', () {
  bloc.add(const HomeEvent.started());
  expect(bloc.state, const HomeState.loaded(...));  // 실패!
});

// ✅ 올바른 패턴 - await로 완료 대기
test('데이터 로드', () async {
  bloc.add(const HomeEvent.started());
  await bloc.stream.firstWhere((s) => s is! HomeLoading);
  expect(bloc.state, const HomeState.loaded(...));
});
```

### ❌ verify 위치 오류

```dart
// ❌ 잘못된 패턴 - act 전에 verify
blocTest<HomeBloc, HomeState>(
  '...',
  build: () => HomeBloc(mockUseCase),
  verify: (_) {
    verify(() => mockUseCase()).called(1);  // act 전에 실행됨!
  },
  act: (bloc) => bloc.add(const HomeEvent.started()),
);

// ✅ verify는 항상 act 이후에 실행됨 (bloc_test에서 자동 처리)
```

## 12. Integration Test

### 12.1 integration_test 패키지

Integration Test는 실제 디바이스나 에뮬레이터에서 전체 앱을 테스트합니다.

**의존성 추가:**

```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_test:
    sdk: flutter
```

### 12.2 기본 Integration Test

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('full app flow test', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 로그인 화면 확인
      expect(find.text('로그인'), findsOneWidget);

      // 이메일 입력
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );

      // 비밀번호 입력
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );

      // 로그인 버튼 탭
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // 홈 화면으로 이동 확인
      expect(find.text('홈'), findsOneWidget);
    });
  });
}
```

### 12.3 스크롤 및 인터랙션 테스트

```dart
testWidgets('리스트 스크롤 및 아이템 탭 테스트', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // 리스트가 로드될 때까지 대기
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // 특정 아이템 찾기 (보이지 않을 수 있음)
  final itemFinder = find.text('마지막 아이템');

  // 아이템이 보일 때까지 스크롤
  await tester.scrollUntilVisible(
    itemFinder,
    500.0, // 스크롤 거리
    scrollable: find.byType(Scrollable),
  );

  // 아이템 탭
  await tester.tap(itemFinder);
  await tester.pumpAndSettle();

  // 상세 화면 확인
  expect(find.text('상세 정보'), findsOneWidget);
});
```

### 12.4 네트워크 응답 대기

```dart
testWidgets('API 데이터 로드 테스트', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // 로딩 인디케이터 확인
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // 네트워크 응답 대기 (최대 10초)
  await tester.pumpAndSettle(const Duration(seconds: 10));

  // 데이터가 로드되었는지 확인
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.byType(ListView), findsOneWidget);
});
```

### 12.5 실행 방법

```bash
# 에뮬레이터/시뮬레이터에서 실행
flutter test integration_test/app_test.dart

# 특정 디바이스에서 실행
flutter test integration_test/app_test.dart -d <device_id>

# 모든 Integration Test 실행
flutter test integration_test/
```

## 13. Golden Test (Visual Regression Testing)

### 13.1 Golden Test란?

Golden Test는 위젯의 시각적 출력을 이미지로 저장하고 비교하여 UI 변경을 감지합니다.

### 13.2 기본 Golden Test

```dart
// test/golden/login_page_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('LoginPage golden test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginPage()),
    );

    await expectLater(
      find.byType(LoginPage),
      matchesGoldenFile('goldens/login_page.png'),
    );
  });
}
```

### 13.3 다양한 상태의 Golden Test

```dart
// test/golden/home_card_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/home_card.dart';

void main() {
  group('HomeCard Golden Tests', () {
    testWidgets('기본 상태', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeCard(
              title: '제목',
              description: '설명',
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(HomeCard),
        matchesGoldenFile('goldens/home_card_default.png'),
      );
    });

    testWidgets('로딩 상태', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeCard(
              title: '제목',
              description: '설명',
              isLoading: true,
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(HomeCard),
        matchesGoldenFile('goldens/home_card_loading.png'),
      );
    });

    testWidgets('에러 상태', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeCard(
              title: '제목',
              description: '설명',
              hasError: true,
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(HomeCard),
        matchesGoldenFile('goldens/home_card_error.png'),
      );
    });
  });
}
```

### 13.4 다양한 디바이스 크기 테스트

```dart
// test/golden/responsive_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('다양한 화면 크기에서 Golden Test', (tester) async {
    final sizes = {
      'phone': const Size(375, 667),      // iPhone SE
      'tablet': const Size(768, 1024),    // iPad
      'desktop': const Size(1920, 1080),  // Desktop
    };

    for (final entry in sizes.entries) {
      await tester.binding.setSurfaceSize(entry.value);

      await tester.pumpWidget(
        const MaterialApp(home: MyResponsivePage()),
      );

      await expectLater(
        find.byType(MyResponsivePage),
        matchesGoldenFile('goldens/responsive_${entry.key}.png'),
      );
    }
  });
}
```

### 13.5 테마 변경 테스트 (다크 모드)

```dart
testWidgets('다크 모드 Golden Test', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: const LoginPage(),
    ),
  );

  await expectLater(
    find.byType(LoginPage),
    matchesGoldenFile('goldens/login_page_dark.png'),
  );
});
```

### 13.6 골든 파일 관리

```bash
# 골든 파일 생성/업데이트
flutter test --update-goldens

# 특정 테스트만 업데이트
flutter test test/golden/login_page_golden_test.dart --update-goldens

# CI에서 골든 테스트 실행 (업데이트 없이)
flutter test test/golden/
```

### 13.7 Best Practices

| 항목 | 설명 |
|------|------|
| 폴더 구조 | `test/golden/` 폴더에 테스트, `test/goldens/` 폴더에 이미지 저장 |
| 파일명 | 명확한 이름 사용 (예: `login_page_dark.png`) |
| 상태별 테스트 | 각 UI 상태마다 별도 Golden 파일 생성 |
| CI 통합 | Git에 골든 파일 커밋하고 CI에서 검증 |
| 주기적 업데이트 | 의도적인 UI 변경 시 `--update-goldens` 실행 |

## 14. E2E Test with Patrol

### 14.1 Patrol이란?

Patrol은 Flutter의 Integration Test를 강화한 프레임워크로, 네이티브 권한 처리 등을 지원합니다.

**의존성 추가:**

```yaml
# pubspec.yaml
dev_dependencies:
  patrol: ^3.14.1
```

### 14.2 기본 Patrol Test

```dart
// integration_test/patrol_test.dart
import 'package:patrol/patrol.dart';
import 'package:my_app/main.dart';

void main() {
  patrolTest('앱 기본 플로우 테스트', ($) async {
    await $.pumpWidgetAndSettle(const MyApp());

    // 로그인 화면 확인
    expect($('로그인'), findsOneWidget);

    // 이메일 입력
    await $('이메일').enterText('test@example.com');

    // 비밀번호 입력
    await $('비밀번호').enterText('password123');

    // 로그인 버튼 탭
    await $('로그인 버튼').tap();

    // 홈 화면 확인
    expect($('홈'), findsOneWidget);
  });
}
```

### 14.3 네이티브 권한 처리

```dart
// integration_test/permission_test.dart
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('카메라 권한 처리 테스트', ($) async {
    await $.pumpWidgetAndSettle(const MyApp());

    // 카메라 버튼 탭
    await $('카메라').tap();

    // 네이티브 권한 다이얼로그 자동 허용
    await $.native.grantPermissionWhenInUse();

    // 카메라 화면 확인
    expect($('Camera Preview'), findsOneWidget);
  });

  patrolTest('위치 권한 처리 테스트', ($) async {
    await $.pumpWidgetAndSettle(const MyApp());

    // 위치 버튼 탭
    await $('내 위치').tap();

    // 위치 권한 항상 허용
    await $.native.grantPermissionOnlyThisTime();

    // 지도 화면 확인
    expect($('지도'), findsOneWidget);
  });
}
```

### 14.4 네이티브 다이얼로그 처리

```dart
patrolTest('네이티브 알림 다이얼로그 처리', ($) async {
  await $.pumpWidgetAndSettle(const MyApp());

  // 알림 설정 버튼 탭
  await $('알림 설정').tap();

  // 네이티브 다이얼로그의 "허용" 버튼 탭
  await $.native.tap(Selector(text: '허용'));

  // 설정 완료 확인
  expect($('알림이 활성화되었습니다'), findsOneWidget);
});
```

### 14.5 스크린샷 캡처

```dart
patrolTest('스크린샷 캡처 테스트', ($) async {
  await $.pumpWidgetAndSettle(const MyApp());

  // 로그인 화면 스크린샷
  await $.native.takeScreenshot('login_screen');

  // 로그인
  await $('이메일').enterText('test@example.com');
  await $('비밀번호').enterText('password123');
  await $('로그인 버튼').tap();

  // 홈 화면 스크린샷
  await $.native.takeScreenshot('home_screen');
});
```

### 14.6 Patrol Custom Config

```dart
// integration_test/patrol_config.dart
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    '커스텀 설정 테스트',
    config: const PatrolTestConfig(
      // 각 액션 후 대기 시간
      settleDuration: Duration(milliseconds: 500),
      // 네이티브 자동화 활성화
      nativeAutomation: true,
    ),
    ($) async {
      await $.pumpWidgetAndSettle(const MyApp());

      // 테스트 로직
    },
  );
}
```

### 14.7 실행 방법

```bash
# Android에서 실행
patrol test -t integration_test/patrol_test.dart

# iOS에서 실행
patrol test -t integration_test/patrol_test.dart --device iphone

# 특정 디바이스 지정
patrol test -d <device_id>

# 모든 Patrol 테스트 실행
patrol test
```

### 14.8 CI/CD 통합

```yaml
# .github/workflows/patrol_test.yml
name: Patrol Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  patrol_test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2

      - name: Install Patrol CLI
        run: dart pub global activate patrol_cli

      - name: Run Patrol Tests
        run: patrol test --verbose
```

### 14.9 Patrol vs Integration Test 비교

| 기능 | Integration Test | Patrol |
|------|------------------|--------|
| **기본 위젯 테스트** | ✅ | ✅ |
| **네이티브 권한 처리** | ❌ | ✅ |
| **네이티브 다이얼로그** | ❌ | ✅ |
| **스크린샷 캡처** | 제한적 | ✅ |
| **Selector API** | 기본 Finder | 강력한 $ API |
| **설정 복잡도** | 낮음 | 중간 |
| **학습 곡선** | 낮음 | 중간 |

**언제 Patrol을 사용할까?**
- 네이티브 권한 처리가 필요한 경우 (카메라, 위치, 알림 등)
- 네이티브 다이얼로그와 상호작용해야 하는 경우
- E2E 테스트에서 스크린샷이 필요한 경우
- 더 강력한 선택자 API가 필요한 경우

---

## 실습 과제

### 과제 1: UseCase + Repository 유닛 테스트
`GetUserProfileUseCase`와 `UserRepositoryImpl`에 대한 테스트를 작성하세요.
- Mockito로 `MockUserRemoteDataSource` 생성
- 성공 시 `User` Entity 반환, 네트워크 에러 시 `Failure` 반환 검증
- AAA 패턴(Arrange-Act-Assert)을 준수하세요.

### 과제 2: Bloc 테스트 작성
`LoginBloc`에 대해 `blocTest`를 사용하여 다음 시나리오를 테스트하세요.
- 로그인 성공 시: `loading → loaded` 상태 변화
- 로그인 실패 시: `loading → error` 상태 변화
- `seed`를 사용하여 이미 로그인된 상태에서 로그아웃 이벤트 테스트
- `verify`로 UseCase 호출 횟수 검증하세요.

### 과제 3: Widget Test + MockBloc
`ProductListScreen`에 대해 Widget Test를 작성하세요.
- `MockBloc`과 `whenListen`으로 loading/loaded/error 각 상태의 UI를 검증
- loaded 상태에서 리스트 아이템이 올바르게 렌더링되는지 확인
- 새로고침 버튼 탭 시 이벤트가 발행되는지 `verify`로 검증하세요.

---

## Self-Check 퀴즈

학습한 내용을 점검해 보세요:

- [ ] 테스트 피라미드에서 Unit:Widget:Integration의 권장 비율(70:20:10)과 그 이유를 설명할 수 있는가?
- [ ] `setUp`과 `setUpAll`의 차이, 그리고 Mock 초기화 시 `setUp`을 사용해야 하는 이유를 설명할 수 있는가?
- [ ] `blocTest`의 `build`, `seed`, `act`, `expect`, `verify` 각 파라미터의 역할을 설명할 수 있는가?
- [ ] `MockBloc`이 mockito 대신 mocktail 스타일을 따르는 이유와 `whenListen`의 사용법을 설명할 수 있는가?
- [ ] Golden Test에서 `--update-goldens` 플래그의 역할과 CI에서의 검증 방식을 설명할 수 있는가?
