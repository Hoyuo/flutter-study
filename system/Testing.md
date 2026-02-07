# Flutter Testing Guide (기본+심화 통합)

> **난이도**: 고급 | **카테고리**: system
> **선행 학습**: [Architecture](../core/Architecture.md), [Bloc](../core/Bloc.md) | **예상 학습 시간**: 3h

> 이 문서는 Flutter 프로젝트에서 기본 테스트부터 고급 테스트 전략까지 포괄적으로 다룹니다. Unit/Widget/Integration 테스트 기초와 Property-based Testing, Mutation Testing, Contract Testing, Fuzz Testing 등 엔터프라이즈급 테스트 기법을 포함합니다.

## 학습 목표

이 문서를 학습하면 다음을 할 수 있습니다:

1. **Unit Test / Widget Test / Integration Test**의 차이와 테스트 피라미드 전략을 이해할 수 있다
2. **mocktail**을 사용하여 Mock 객체를 생성하고 Stub을 설정할 수 있다
3. **bloc_test** 패키지로 Bloc의 상태 변화를 `blocTest`로 검증할 수 있다
4. **Widget Test**에서 `MockBloc`과 `whenListen`을 사용하여 UI 상태별 렌더링을 테스트할 수 있다
5. **Patrol**을 활용하여 네이티브 권한 처리를 포함한 E2E 테스트를 작성할 수 있다
6. **Property-based Testing**으로 엣지 케이스를 자동 발견할 수 있다
7. **Mutation Testing**으로 테스트 품질을 검증할 수 있다
8. **Contract Testing**으로 API 계약을 보장할 수 있다
9. **Golden Test 고급 기법**(Alchemist)으로 UI 회귀를 자동 감지할 수 있다

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

# mocktail 사용법:
# import: import 'package:mocktail/mocktail.dart';
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

## 3. mocktail 사용법

> **💡 참고:** bloc_test의 `MockBloc`은 mocktail 기반이므로, 프로젝트 전체에서 mocktail을 표준 모킹 라이브러리로 사용합니다.
> - 코드 생성 불필요 (`build_runner` 없이 Mock 클래스를 직접 정의)
> - `when(() => mock.method())` 클로저 문법 사용
> - 자세한 내용은 "6.2 Bloc과 함께 Widget Test" 섹션 참조

### 3.1 Mock 클래스 정의

```dart
// test/mocks/mocks.dart
import 'package:mocktail/mocktail.dart';
import 'package:home/domain/domain.dart';
import 'package:home/data/data.dart';

// mocktail은 코드 생성 없이 Mock 클래스를 직접 정의합니다.
class MockHomeRepository extends Mock implements HomeRepository {}
class MockHomeRemoteDataSource extends Mock implements HomeRemoteDataSource {}
class MockGetHomeDataUseCase extends Mock implements GetHomeDataUseCase {}
```

> **💡 mocktail vs mockito:** mocktail은 `build_runner`를 사용한 코드 생성이 필요 없습니다. `extends Mock implements 대상클래스` 패턴으로 즉시 Mock을 정의할 수 있습니다.

### 3.2 테스트 파일에서 Mock 사용

```dart
// test/domain/usecases/get_home_data_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../mocks/mocks.dart';  // Mock 클래스 import

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
when(() => mockRepository.getHomeData())
    .thenAnswer((_) async => Right(homeData));

// 실패 케이스
when(() => mockRepository.getHomeData())
    .thenAnswer((_) async => Left(const HomeFailure.network()));

// Exception 발생
when(() => mockDataSource.fetchData())
    .thenThrow(DioException(requestOptions: RequestOptions()));

// 여러 번 호출 시 다른 결과를 반환하려면 카운터 변수 사용
// ❌ 잘못된 방법: 체이닝 시 마지막 thenAnswer만 적용됨
// when(() => mockRepository.getHomeData())
//     .thenAnswer((_) async => Right(homeData1))
//     .thenAnswer((_) async => Right(homeData2));

// ✅ 올바른 방법: 카운터 변수로 순차 반환 구현
var callCount = 0;
when(() => mockRepository.getHomeData()).thenAnswer((_) async {
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
import 'package:mocktail/mocktail.dart';
import 'package:home/domain/domain.dart';

import '../../mocks/mocks.dart';
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
      when(() => mockRepository.getHomeData())
          .thenAnswer((_) async => Right(expected));

      // Act
      final result = await useCase();

      // Assert
      expect(result, Right(expected));
      verify(() => mockRepository.getHomeData()).called(1);
    });

    test('실패 시 HomeFailure 반환', () async {
      // Arrange
      when(() => mockRepository.getHomeData())
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
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:home/data/data.dart';
import 'package:home/domain/domain.dart';

import '../../mocks/mocks.dart';
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
      when(() => mockDataSource.getHomeData())
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
      when(() => mockDataSource.getHomeData()).thenThrow(
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
      when(() => mockDataSource.getHomeData()).thenThrow(
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
import 'package:mocktail/mocktail.dart';
import 'package:home/domain/domain.dart';
import 'package:home/presentation/presentation.dart';

import '../../mocks/mocks.dart';
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
        when(() => mockUseCase())
            .thenAnswer((_) async => Right(HomeFixture.homeData));
        return HomeBloc(mockUseCase);
      },
      act: (bloc) => bloc.add(const HomeEvent.started()),
      expect: () => [
        const HomeState.loading(),
        HomeState.loaded(HomeFixture.homeData),
      ],
      verify: (_) {
        verify(() => mockUseCase()).called(1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      '실패 시 loading → error 상태 변화',
      build: () {
        when(() => mockUseCase())
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
        when(() => mockUseCase())
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
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  group('LoginBloc Effect', () {
    test('로그인 성공 시 NavigateToHome Effect 발행', () async {
      // Arrange
      final user = User(id: '1', name: 'Test User', email: 'test@example.com');
      when(() => mockAuthRepo.login(any(), any()))
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
      when(() => mockAuthRepo.login(any(), any()))
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
import 'package:mocktail/mocktail.dart';
import 'package:home/presentation/presentation.dart';

import '../../fixtures/home_fixture.dart';

// 💡 bloc_test의 MockBloc은 mocktail 기반이므로 whenListen()과 verify()를 함께 사용합니다.

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
      verify(() => mockBloc.add(const HomeEvent.refresh())).called(1);
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
  when(() => mockRepo.login(any(), any()))
      .thenAnswer((_) async => Right(expected));

  // Act (실행)
  final result = await useCase(email: 'test@test.com', password: '1234');

  // Assert (검증)
  expect(result, Right(expected));
  verify(() => mockRepo.login('test@test.com', '1234')).called(1);
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
  patrol: ^4.0.0
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
    await $.platform.grantPermissionWhenInUse();

    // 카메라 화면 확인
    expect($('Camera Preview'), findsOneWidget);
  });

  patrolTest('위치 권한 처리 테스트', ($) async {
    await $.pumpWidgetAndSettle(const MyApp());

    // 위치 버튼 탭
    await $('내 위치').tap();

    // 위치 권한 항상 허용
    await $.platform.grantPermissionOnlyThisTime();

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
  await $.platform.tap(Selector(text: '허용'));

  // 설정 완료 확인
  expect($('알림이 활성화되었습니다'), findsOneWidget);
});
```

### 14.5 스크린샷 캡처

```dart
patrolTest('스크린샷 캡처 테스트', ($) async {
  await $.pumpWidgetAndSettle(const MyApp());

  // 로그인 화면 스크린샷
  await $.platform.takeScreenshot('login_screen');

  // 로그인
  await $('이메일').enterText('test@example.com');
  await $('비밀번호').enterText('password123');
  await $('로그인 버튼').tap();

  // 홈 화면 스크린샷
  await $.platform.takeScreenshot('home_screen');
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
      - uses: actions/checkout@v4

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

## 15. 심화: 테스트 성숙도와 전략

> 이하 15~25절은 엔터프라이즈급 고급 테스트 기법을 다룹니다.

### 15.1 테스트 성숙도 모델

| 레벨 | 설명 | 커버리지 | 자동화 |
|------|------|---------|--------|
| **Level 0** | 테스트 없음 | 0% | 없음 |
| **Level 1** | 기본 Unit Test | 30-50% | 수동 실행 |
| **Level 2** | Unit + Widget Test | 60-80% | CI/CD 통합 |
| **Level 3** | Property-based + Contract | 80-90% | 자동 회귀 테스트 |
| **Level 4** | Mutation + Fuzz Testing | 90%+ | 품질 게이트 |
| **Level 5** (목표) | Visual Regression + E2E | 95%+ | 완전 자동화 |

### 15.2 테스트 전략 매트릭스

| 테스트 유형 | 범위 | 속도 | 신뢰도 | 유지보수 비용 |
|------------|------|------|--------|--------------|
| **Unit Test** | 함수/클래스 | 매우 빠름 | 높음 | 낮음 |
| **Property Test** | 함수 불변성 | 빠름 | 매우 높음 | 중간 |
| **Widget Test** | UI 컴포넌트 | 중간 | 높음 | 중간 |
| **Golden Test** | UI 스냅샷 | 중간 | 높음 | 높음 |
| **Contract Test** | API 스키마 | 빠름 | 높음 | 낮음 |
| **Integration Test** | 전체 플로우 | 느림 | 매우 높음 | 높음 |
| **Mutation Test** | 테스트 품질 | 매우 느림 | 매우 높음 | 낮음 |

---

## 16. Property-based Testing

Property-based Testing은 랜덤 입력값으로 함수의 불변성(invariant)을 검증합니다.

### 16.1 의존성 설치

```yaml
# pubspec.yaml
dev_dependencies:
  test: ^1.25.0
  glados: ^2.0.0  # Property-based testing
  # 💡 Fake 객체는 mocktail 또는 직접 구현으로 생성합니다. (별도 패키지 불필요)
```

### 16.2 기본 개념

**Example-based Testing (기존 방식):**
```dart
test('문자열 길이는 항상 0 이상', () {
  expect('hello'.length, greaterThanOrEqualTo(0));
  expect(''.length, equals(0));
  expect('a'.length, equals(1));
});
```

**Property-based Testing (개선):**
```dart
import 'package:glados/glados.dart';

void main() {
  Glados<String>().test('모든 문자열의 길이는 0 이상', (string) {
    expect(string.length, greaterThanOrEqualTo(0));
  });
}
```

Glados는 자동으로 100개 이상의 랜덤 문자열을 생성해 테스트합니다.

### 16.3 실전 예제: 금융 계산 검증

```dart
// lib/domain/models/money.dart
class Money {
  const Money(this.amount, this.currency);

  final double amount;
  final String currency;

  Money operator +(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot add different currencies');
    }
    return Money(amount + other.amount, currency);
  }

  Money operator *(double multiplier) {
    return Money(amount * multiplier, currency);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          amount == other.amount &&
          currency == other.currency;

  @override
  int get hashCode => Object.hash(amount, currency);
}
```

**Property Test:**

```dart
// test/domain/models/money_property_test.dart
import 'package:glados/glados.dart';
import 'package:test/test.dart';
import 'package:my_app/domain/models/money.dart';

// **참고:** `glados` 패키지의 generator API는 버전에 따라 다를 수 있습니다. 최신 문서를 확인하세요.
// Custom Generator
final moneyGenerator = Any.of([
  any.double.map((amount) => Money(amount, 'USD')),
  any.double.map((amount) => Money(amount, 'KRW')),
  any.double.map((amount) => Money(amount, 'EUR')),
]);

void main() {
  group('Money Property Tests', () {
    Glados2<Money, Money>(moneyGenerator, moneyGenerator).test(
      '덧셈 교환 법칙: a + b = b + a',
      (a, b) {
        if (a.currency != b.currency) return; // 같은 통화만 테스트

        final result1 = a + b;
        final result2 = b + a;

        expect(result1, equals(result2));
      },
    );

    Glados3<Money, Money, Money>(
      moneyGenerator,
      moneyGenerator,
      moneyGenerator,
    ).test(
      '덧셈 결합 법칙: (a + b) + c = a + (b + c)',
      (a, b, c) {
        if (a.currency != b.currency || b.currency != c.currency) return;

        final result1 = (a + b) + c;
        final result2 = a + (b + c);

        expect(result1.amount, closeTo(result2.amount, 0.0001));
      },
    );

    Glados<Money>(moneyGenerator).test(
      '항등원: a + 0 = a',
      (a) {
        final zero = Money(0, a.currency);
        final result = a + zero;

        expect(result, equals(a));
      },
    );

    Glados2<Money, double>(moneyGenerator, any.double).test(
      '곱셈과 덧셈 분배 법칙: a * (1 + k) = a + a * k',
      (a, k) {
        if (k.isNaN || k.isInfinite) return;

        final result1 = a * (1 + k);
        final result2 = a + (a * k);

        expect(result1.amount, closeTo(result2.amount, 0.0001));
      },
    );

    Glados<Money>(moneyGenerator).test(
      '역원: a + (-a) = 0',
      (a) {
        final negated = a * -1;
        final result = a + negated;

        expect(result.amount, closeTo(0, 0.0001));
      },
    );
  });

  group('Money Error Cases', () {
    Glados2<String, String>(any.letterOrDigits, any.letterOrDigits).test(
      '다른 통화 덧셈 시 예외 발생',
      (currency1, currency2) {
        if (currency1 == currency2) return;

        final money1 = Money(100, currency1);
        final money2 = Money(200, currency2);

        expect(
          () => money1 + money2,
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });
}
```

### 16.4 Custom Generator 작성

```dart
// test/generators/custom_generators.dart
import 'package:glados/glados.dart';
import 'package:my_app/domain/models/user.dart';

// 이메일 Generator
final emailGenerator = Any.of([
  any.letterOrDigits.map((name) => '$name@example.com'),
  any.letterOrDigits.map((name) => '$name@test.com'),
  any.choose(['john', 'jane', 'admin']).map((name) => '$name@company.com'),
]);

// 전화번호 Generator
final phoneGenerator = any.intInRange(1000000000, 9999999999).map(
  (number) => '010-$number',
);

// User Generator
final userGenerator = Glados3<String, String, int>(
  any.letterOrDigits,
  emailGenerator,
  any.intInRange(18, 100),
).map((name, email, age) => User(
      name: name,
      email: email,
      age: age,
    ));

// Positive Integer Generator
final positiveIntGenerator = any.intInRange(1, 1000000);

// Non-empty String Generator
final nonEmptyStringGenerator = any.letterOrDigits.suchThat(
  (s) => s.isNotEmpty,
  maxTries: 100,
);

// Future Date Generator
final futureDateGenerator = any.intInRange(0, 365).map((days) {
  return DateTime.now().add(Duration(days: days));
});
```

### 16.5 Shrinking (최소 실패 케이스 찾기)

Property test 실패 시 Glados는 자동으로 최소 입력값을 찾습니다:

```dart
Glados<int>().test('모든 정수는 100보다 작다 (의도적 실패)', (n) {
  expect(n, lessThan(100));
});

// 출력:
// Failed after 23 tests.
// Shrunk input: 100  ← 최소 실패 케이스
```

---

## 17. Golden Test 고급 기법

> **Golden Test 기본 설정 및 사용법은 위의 13절을 참조하세요.** 이 섹션에서는 고급 자동화 기법만 다룹니다.

### 17.1 의존성 설치

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  golden_toolkit: ^0.15.0
  alchemist: ^0.7.0  # 고급 Golden Test
```

### 17.2 Alchemist로 고급 Golden Test

```dart
// test/widgets/user_profile_golden_test.dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:my_app/widgets/user_profile.dart';

void main() {
  group('UserProfile Golden Tests', () {
    goldenTest(
      'should render all user states correctly',
      fileName: 'user_profile',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          GoldenTestScenario(
            name: 'verified user',
            child: UserProfile(
              name: 'John Doe',
              email: 'john@example.com',
              avatarUrl: 'https://example.com/avatar.png',
              isVerified: true,
            ),
          ),
          GoldenTestScenario(
            name: 'unverified user',
            child: UserProfile(
              name: 'Jane Smith',
              email: 'jane@example.com',
              avatarUrl: 'https://example.com/avatar.png',
              isVerified: false,
            ),
          ),
          GoldenTestScenario(
            name: 'no avatar',
            child: UserProfile(
              name: 'Anonymous',
              email: 'anon@example.com',
              isVerified: false,
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'should render correctly in different themes',
      fileName: 'user_profile_themes',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'light theme',
            child: Theme(
              data: ThemeData.light(),
              child: UserProfile(
                name: 'John Doe',
                email: 'john@example.com',
                isVerified: true,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'dark theme',
            child: Theme(
              data: ThemeData.dark(),
              child: UserProfile(
                name: 'John Doe',
                email: 'john@example.com',
                isVerified: true,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
```

### 17.3 Golden Test CI/CD 통합

```yaml
# .github/workflows/golden_test.yml
name: Golden Tests

on:
  pull_request:
    branches: [ main ]

jobs:
  golden-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run golden tests
        run: flutter test --update-goldens --tags golden

      - name: Upload golden files
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: golden-failures
          path: test/**/failures/*.png

      - name: Comment PR with failures
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'Golden tests failed! Check artifacts for diff images.'
            })
```

---

## 18. Mutation Testing

Mutation Testing은 테스트의 품질을 검증합니다. 코드에 의도적인 버그(mutation)를 주입하고, 테스트가 이를 감지하는지 확인합니다.

### 18.1 개념

```dart
// 원본 코드
int add(int a, int b) {
  return a + b;
}

// Mutation 1: 연산자 변경
int add(int a, int b) {
  return a - b;  // + → -
}

// Mutation 2: 상수 변경
int add(int a, int b) {
  return a + b + 1;  // + 1
}

// 좋은 테스트는 모든 mutation을 잡아냄
test('add', () {
  expect(add(2, 3), equals(5));  // Mutation 1, 2 모두 실패
});
```

### 18.2 수동 Mutation Testing

```dart
// lib/domain/usecases/calculate_discount.dart
class CalculateDiscountUseCase {
  double execute(double price, int discountRate) {
    if (discountRate < 0 || discountRate > 100) {
      throw ArgumentError('Discount rate must be between 0 and 100');
    }
    return price * (1 - discountRate / 100);
  }
}

// test/domain/usecases/calculate_discount_test.dart
void main() {
  late CalculateDiscountUseCase useCase;

  setUp(() {
    useCase = CalculateDiscountUseCase();
  });

  group('CalculateDiscountUseCase', () {
    test('정상 할인 계산', () {
      expect(useCase.execute(10000, 20), equals(8000));
    });

    test('할인율 0%', () {
      expect(useCase.execute(10000, 0), equals(10000));
    });

    test('할인율 100%', () {
      expect(useCase.execute(10000, 100), equals(0));
    });

    test('음수 할인율 예외', () {
      expect(
        () => useCase.execute(10000, -10),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('100 초과 할인율 예외', () {
      expect(
        () => useCase.execute(10000, 101),
        throwsA(isA<ArgumentError>()),
      );
    });

    // Mutation Testing: 경계값 변경 감지
    test('할인율 1%', () {
      expect(useCase.execute(10000, 1), equals(9900));
    });

    test('할인율 99%', () {
      expect(useCase.execute(10000, 99), equals(100));
    });

    // Mutation Testing: 연산자 변경 감지
    test('할인율 50%', () {
      expect(useCase.execute(10000, 50), equals(5000));
      expect(useCase.execute(20000, 50), equals(10000));
    });
  });
}
```

### 18.3 Mutation Testing 체크리스트

| Mutation Type | 예제 | 테스트 전략 |
|--------------|------|-----------|
| **산술 연산자** | `+` → `-`, `*` → `/` | 다양한 입력값으로 결과 검증 |
| **비교 연산자** | `<` → `<=`, `==` → `!=` | 경계값 테스트 |
| **논리 연산자** | `&&` → `||`, `!` 제거 | 모든 분기 커버 |
| **상수 변경** | `0` → `1`, `true` → `false` | 엣지 케이스 테스트 |
| **문장 제거** | `return` 문 삭제 | 반환값 검증 |
| **조건 반전** | `if (x)` → `if (!x)` | 양/음 케이스 모두 테스트 |

---

## 19. Contract Testing

API의 요청/응답 스키마를 검증하여 프론트엔드-백엔드 계약을 보장합니다.

### 19.1 의존성 설치

```yaml
dev_dependencies:
  http_mock_adapter: ^0.6.0
  json_schema: ^5.1.0
```

### 19.2 JSON Schema 정의

```dart
// test/contracts/user_api_contract.dart
const userSchemaV1 = {
  r'$schema': 'http://json-schema.org/draft-07/schema#',
  'type': 'object',
  'required': ['id', 'name', 'email', 'createdAt'],
  'properties': {
    'id': {'type': 'string', 'format': 'uuid'},
    'name': {'type': 'string', 'minLength': 1},
    'email': {'type': 'string', 'format': 'email'},
    'age': {'type': 'integer', 'minimum': 0, 'maximum': 150},
    'createdAt': {'type': 'string', 'format': 'date-time'},
    'isVerified': {'type': 'boolean'},
  },
  'additionalProperties': false,
};

const usersListSchemaV1 = {
  r'$schema': 'http://json-schema.org/draft-07/schema#',
  'type': 'object',
  'required': ['users', 'total', 'page'],
  'properties': {
    'users': {
      'type': 'array',
      'items': userSchemaV1,
    },
    'total': {'type': 'integer', 'minimum': 0},
    'page': {'type': 'integer', 'minimum': 1},
    'hasMore': {'type': 'boolean'},
  },
};
```

### 19.3 Contract Test 구현

```dart
// test/data/datasources/user_remote_datasource_contract_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:json_schema/json_schema.dart';
import 'package:my_app/data/datasources/user_remote_datasource.dart';
import '../contracts/user_api_contract.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late UserRemoteDataSource dataSource;
  late JsonSchema userSchema;
  late JsonSchema usersListSchema;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dioAdapter = DioAdapter(dio: dio);
    dataSource = UserRemoteDataSourceImpl(dio);

    userSchema = JsonSchema.create(userSchemaV1);
    usersListSchema = JsonSchema.create(usersListSchemaV1);
  });

  group('User API Contract Tests', () {
    test('GET /users/:id - 스키마 검증', () async {
      // Mock 응답
      final mockResponse = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'name': 'John Doe',
        'email': 'john@example.com',
        'age': 30,
        'createdAt': '2024-01-15T10:30:00Z',
        'isVerified': true,
      };

      dioAdapter.onGet(
        '/users/550e8400-e29b-41d4-a716-446655440000',
        (server) => server.reply(200, mockResponse),
      );

      // API 호출
      final user = await dataSource.getUser('550e8400-e29b-41d4-a716-446655440000');

      // 스키마 검증
      final validationResult = userSchema.validate(user.toJson());
      expect(validationResult.isValid, isTrue,
          reason: 'Schema validation errors: ${validationResult.errors}');
    });

    test('GET /users - 리스트 스키마 검증', () async {
      final mockResponse = {
        'users': [
          {
            'id': '550e8400-e29b-41d4-a716-446655440000',
            'name': 'John Doe',
            'email': 'john@example.com',
            'createdAt': '2024-01-15T10:30:00Z',
            'isVerified': true,
          },
          {
            'id': '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
            'name': 'Jane Smith',
            'email': 'jane@example.com',
            'age': 25,
            'createdAt': '2024-01-16T11:00:00Z',
            'isVerified': false,
          },
        ],
        'total': 2,
        'page': 1,
        'hasMore': false,
      };

      dioAdapter.onGet(
        '/users',
        (server) => server.reply(200, mockResponse),
      );

      final result = await dataSource.getUsers();

      final validationResult = usersListSchema.validate(mockResponse);
      expect(validationResult.isValid, isTrue);
    });

    test('스키마 위반 감지 - 필수 필드 누락', () async {
      final invalidResponse = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'name': 'John Doe',
        // 'email' 누락 (required)
        'createdAt': '2024-01-15T10:30:00Z',
      };

      final validationResult = userSchema.validate(invalidResponse);
      expect(validationResult.isValid, isFalse);
      expect(
        validationResult.errors.first.message,
        contains('email'),
      );
    });

    test('스키마 위반 감지 - 잘못된 타입', () async {
      final invalidResponse = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'name': 'John Doe',
        'email': 'john@example.com',
        'age': '30',  // string (올바른 타입: integer)
        'createdAt': '2024-01-15T10:30:00Z',
      };

      final validationResult = userSchema.validate(invalidResponse);
      expect(validationResult.isValid, isFalse);
    });

    test('스키마 위반 감지 - 추가 필드', () async {
      final invalidResponse = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'name': 'John Doe',
        'email': 'john@example.com',
        'createdAt': '2024-01-15T10:30:00Z',
        'unexpectedField': 'value',  // additionalProperties: false
      };

      final validationResult = userSchema.validate(invalidResponse);
      expect(validationResult.isValid, isFalse);
    });
  });

  group('Contract Versioning', () {
    test('API 버전 협상', () async {
      dioAdapter.onGet(
        '/users/1',
        (server) {
          final apiVersion = server.request.headers['Accept-Version']?.first;
          expect(apiVersion, equals('v1'));
          return server.reply(200, {
            'id': '1',
            'name': 'John',
            'email': 'john@example.com',
            'createdAt': '2024-01-15T10:30:00Z',
          });
        },
      );

      await dataSource.getUser('1');
    });
  });
}
```

---

## 20. Visual Regression Testing

UI 변경사항을 자동으로 감지하고 의도하지 않은 변경을 방지합니다.

### 20.1 Alchemist를 활용한 Visual Regression

> **참고:** Cloud 기반 Visual Regression 서비스(Percy 등) 대신 로컬에서 동작하는 `alchemist` 패키지를 사용합니다.

```yaml
# pubspec.yaml (17.1에서 이미 추가됨)
dev_dependencies:
  flutter_test:
    sdk: flutter
  golden_toolkit: ^0.15.0
  alchemist: ^0.7.0
```

```dart
// test/visual/home_screen_visual_test.dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:my_app/features/home/presentation/home_screen.dart';

void main() {
  group('HomeScreen Visual Regression', () {
    goldenTest(
      'should render all home screen states',
      fileName: 'home_screen_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          GoldenTestScenario(
            name: 'default state',
            child: const MaterialApp(home: HomeScreen()),
          ),
          GoldenTestScenario(
            name: 'dark theme',
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const HomeScreen(),
            ),
          ),
        ],
      ),
    );
  });
}
```

### 20.2 로컬 Visual Regression (Alchemist)

```dart
// test/visual/button_visual_test.dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';

void main() {
  group('Button Visual Regression', () {
    goldenTest(
      'should render all button states',
      fileName: 'button_states',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'enabled',
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Click Me'),
            ),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: const ElevatedButton(
              onPressed: null,
              child: Text('Disabled'),
            ),
          ),
          GoldenTestScenario(
            name: 'loading',
            child: ElevatedButton(
              onPressed: () {},
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
```

---

## 21. Fuzz Testing

랜덤하고 예상치 못한 입력으로 앱의 견고성을 테스트합니다.

### 21.1 입력 검증 Fuzz Testing

```dart
// test/fuzz/input_validation_fuzz_test.dart
import 'package:glados/glados.dart';
import 'package:test/test.dart';
import 'package:my_app/core/validators/email_validator.dart';

void main() {
  group('Email Validator Fuzz Tests', () {
    final emailValidator = EmailValidator();

    Glados<String>().test('어떤 입력도 크래시 없이 처리', (input) {
      // 예외가 발생하면 안 됨
      expect(
        () => emailValidator.validate(input),
        returnsNormally,
      );
    });

    Glados<String>(any.unicode).test('유니코드 입력 처리', (input) {
      final result = emailValidator.validate(input);
      expect(result, isA<ValidationResult>());
    });

    Glados<String>().test('극단적으로 긴 입력 처리', (input) {
      final longInput = input * 1000; // 1000배 반복
      expect(
        () => emailValidator.validate(longInput),
        returnsNormally,
      );
    });

    test('특수 문자 Fuzz Testing', () {
      final specialChars = [
        '\x00', // NULL
        '\n', '\r', '\t', // Whitespace
        '<script>', // XSS
        '; DROP TABLE users;--', // SQL Injection
        '../../../etc/passwd', // Path Traversal
        '\u202E', // Right-to-Left Override
      ];

      for (final char in specialChars) {
        expect(
          () => emailValidator.validate(char),
          returnsNormally,
          reason: 'Failed on: $char',
        );
      }
    });
  });

  group('JSON Parser Fuzz Tests', () {
    Glados<Map<String, dynamic>>().test('임의의 JSON 파싱', (json) {
      // JSON 파싱이 크래시 없이 완료되어야 함
      expect(
        () => MyJsonParser.parse(json),
        returnsNormally,
      );
    });
  });
}
```

### 21.2 네트워크 Fuzz Testing

```dart
// test/fuzz/api_fuzz_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:glados/glados.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;

  setUp(() {
    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);
  });

  group('API Fuzz Tests', () {
    test('잘못된 HTTP 상태 코드 처리', () async {
      final invalidStatusCodes = [
        -1, 0, 99, 600, 999, 10000,
      ];

      for (final statusCode in invalidStatusCodes) {
        dioAdapter.onGet(
          '/test',
          (server) => server.reply(statusCode, {'error': 'Fuzz test'}),
        );

        expect(
          () async => await dio.get('/test'),
          throwsA(isA<DioException>()),
          reason: 'Failed on status code: $statusCode',
        );
      }
    });

    test('잘못된 JSON 응답 처리', () async {
      final invalidJsonResponses = [
        '{invalid', // 불완전한 JSON
        'null', // null 응답
        '[]', // 배열 (객체 예상)
        '12345', // 숫자
        'true', // boolean
        '', // 빈 문자열
      ];

      for (final response in invalidJsonResponses) {
        dioAdapter.onGet(
          '/test',
          (server) => server.reply(200, response),
        );

        expect(
          () async {
            final result = await dio.get('/test');
            return result.data as Map<String, dynamic>;
          },
          throwsA(anything),
          reason: 'Failed on response: $response',
        );
      }
    });
  });
}
```

---

## 22. Performance Testing

성능 벤치마크를 자동화합니다.

### 22.1 위젯 렌더링 벤치마크

```dart
// test/performance/widget_benchmark_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ListView 렌더링 성능', (tester) async {
    const itemCount = 1000;

    final stopwatch = Stopwatch()..start();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Item $index'),
              );
            },
          ),
        ),
      ),
    );

    stopwatch.stop();
    final buildTime = stopwatch.elapsedMilliseconds;

    // 빌드 시간 검증 (목표: 100ms 이내)
    expect(buildTime, lessThan(100),
        reason: 'ListView build took ${buildTime}ms');

    // 프레임 검증
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('CustomPaint 렌더링 성능', (tester) async {
    await tester.runAsync(() async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: CustomPaint(
            painter: ComplexPainter(),
            size: const Size(1000, 1000),
          ),
        ),
      );

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });
}

class ComplexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue;
    for (int i = 0; i < 1000; i++) {
      canvas.drawCircle(
        Offset(i.toDouble(), i.toDouble()),
        10,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### 22.2 비즈니스 로직 벤치마크

```dart
// test/performance/business_logic_benchmark_test.dart
import 'package:test/test.dart';
import 'package:my_app/domain/usecases/process_large_dataset.dart';

void main() {
  group('Performance Benchmarks', () {
    test('대용량 데이터 처리 성능', () async {
      final useCase = ProcessLargeDatasetUseCase();
      final testData = List.generate(100000, (i) => i);

      final stopwatch = Stopwatch()..start();
      final result = await useCase.execute(testData);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: 'Processing took ${stopwatch.elapsedMilliseconds}ms');
      expect(result.length, equals(testData.length));
    });

    test('JSON 파싱 성능', () {
      final largeJson = _generateLargeJson(10000);

      final stopwatch = Stopwatch()..start();
      final parsed = jsonDecode(largeJson);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(parsed, isA<List>());
    });
  });
}

String _generateLargeJson(int size) {
  final items = List.generate(
    size,
    (i) => '{"id": $i, "name": "Item $i", "value": ${i * 10}}',
  );
  return '[${items.join(',')}]';
}
```

---

## 23. 고급 E2E 테스트 패턴

> **Patrol 기본 설정, 네이티브 권한 처리, 실행 방법, CI/CD 통합은 위의 14절을 참조하세요.** 이 섹션에서는 고급 E2E 테스트 패턴을 다룹니다.

### 23.1 복잡한 E2E 시나리오 예제

```dart
// integration_test/advanced_patrol_test.dart
import 'package:patrol/patrol.dart';
import 'package:my_app/main.dart' as app;

void main() {
  patrolTest(
    '복합 플로우 E2E 테스트 - 로그인부터 결제까지',
    ($) async {
      await app.main();
      await $.pumpAndSettle();

      // 1. 로그인
      await $(#emailField).enterText('user@example.com');
      await $(#passwordField).enterText('password123');
      await $(#loginButton).tap();
      await $.pumpAndSettle();

      // 2. 네이티브 권한 처리
      await $.platform.grantPermissionWhenInUse();

      // 3. 상품 검색 및 선택
      await $(#searchField).enterText('아이폰');
      await $.pumpAndSettle();
      await $(ProductCard).at(0).tap();
      await $.pumpAndSettle();

      // 4. 장바구니 추가
      await $(#addToCartButton).tap();
      await $.pumpAndSettle();

      // 5. 결제 플로우
      await $(Icons.shopping_cart).tap();
      await $.pumpAndSettle();
      await $(#checkoutButton).tap();
      await $.pumpAndSettle();

      // 6. 배송 정보 입력
      await $(#addressField).enterText('서울시 강남구');
      await $(#phoneField).enterText('010-1234-5678');
      await $(#creditCardOption).tap();
      await $.pumpAndSettle();

      // 7. 주문 완료
      await $(#confirmOrderButton).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 10));

      // 8. 검증
      expect($('주문이 완료되었습니다'), findsOneWidget);
    },
  );
}
```

---

## 24. 테스트 커버리지 자동화

### 24.1 커버리지 수집

```bash
# 전체 커버리지
flutter test --coverage

# HTML 리포트 생성 (lcov 필요)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 24.2 품질 게이트

```yaml
# .github/workflows/test.yml
name: Test & Coverage

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2

      - run: flutter pub get
      - run: flutter test --coverage

      - name: Check coverage threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info | grep 'lines......:' | awk '{print $2}' | sed 's/%//')
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage $COVERAGE% is below 80% threshold"
            exit 1
          fi

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          file: coverage/lcov.info
```

---

## 25. Flaky Test 관리

### 25.1 Flaky Test 감지

```dart
// test/flaky_test_detector.dart
import 'dart:io';

void main() async {
  const iterations = 10;
  int failures = 0;

  for (int i = 0; i < iterations; i++) {
    print('Run ${i + 1}/$iterations');

    final result = await Process.run(
      'flutter',
      ['test', 'test/suspected_flaky_test.dart'],
    );

    if (result.exitCode != 0) {
      failures++;
    }
  }

  final flakyRate = (failures / iterations * 100).toStringAsFixed(1);
  print('Flaky rate: $flakyRate% ($failures/$iterations failures)');

  if (failures > 0 && failures < iterations) {
    print('Test is FLAKY!');
    exit(1);
  }
}
```

### 25.2 Flaky Test 수정 전략

| 원인 | 증상 | 해결 방법 |
|------|------|----------|
| **타이밍 이슈** | 간헐적 실패 | `pumpAndSettle()` 사용, timeout 증가 |
| **비동기 경쟁** | Future 완료 전 테스트 종료 | `await tester.runAsync()` |
| **랜덤 데이터** | 특정 값에서만 실패 | Seed 고정, 경계값 테스트 |
| **외부 의존성** | 네트워크/파일 시스템 | Mock 사용, Fixture 데이터 |
| **시간 의존성** | `DateTime.now()` 사용 | Clock abstraction |

```dart
// Flaky Test 수정 예제
testWidgets('애니메이션 완료 후 상태 확인', (tester) async {
  await tester.pumpWidget(MyAnimatedWidget());

  // Flaky: 애니메이션이 완료되지 않을 수 있음
  // await tester.pump(const Duration(seconds: 1));

  // 안정적: 모든 애니메이션 완료 대기
  await tester.pumpAndSettle();

  expect(find.text('Animation Complete'), findsOneWidget);
});
```

---

## 26. 결론

고급 테스트 전략은 단순히 코드 커버리지를 높이는 것이 아니라, **테스트 자체의 품질**을 보장하는 것입니다.

**핵심 원칙:**
1. **Property-based Testing**: 수백 개의 엣지 케이스를 자동 검증
2. **Golden Testing**: UI 변경사항 자동 감지
3. **Mutation Testing**: 테스트가 실제로 버그를 잡는지 검증
4. **Contract Testing**: API 계약 위반 사전 감지
5. **Fuzz Testing**: 예상치 못한 입력에도 안정적

**테스트 자동화 로드맵:**
```
Level 1: Unit Test (70%) → CI 통합
Level 2: Widget Test + Golden Test → PR 자동 리뷰
Level 3: Contract Test → API 변경 감지
Level 4: Mutation Test → 주간 품질 리포트
Level 5: E2E + Visual Regression → 릴리스 전 필수
```

95% 이상의 커버리지와 함께 Mutation Score 80%+를 달성하면, 프로덕션 버그를 90% 이상 사전에 방지할 수 있습니다.

---

## 실습 과제

### 과제 1: UseCase + Repository 유닛 테스트
`GetUserProfileUseCase`와 `UserRepositoryImpl`에 대한 테스트를 작성하세요.
- mocktail로 `MockUserRemoteDataSource` 생성
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

### 과제 4: Golden Test 작성
주요 화면 3개에 대해 Golden Test를 작성하고, CI에서 자동 비교되도록 설정하세요.

### 과제 5: E2E 테스트 with Patrol
로그인 → 목록 조회 → 상세 보기 → 로그아웃 시나리오를 Patrol로 E2E 테스트하세요.

---

## Self-Check 퀴즈

학습한 내용을 점검해 보세요:

**기본:**
- [ ] 테스트 피라미드에서 Unit:Widget:Integration의 권장 비율(70:20:10)과 그 이유를 설명할 수 있는가?
- [ ] `setUp`과 `setUpAll`의 차이, 그리고 Mock 초기화 시 `setUp`을 사용해야 하는 이유를 설명할 수 있는가?
- [ ] `blocTest`의 `build`, `seed`, `act`, `expect`, `verify` 각 파라미터의 역할을 설명할 수 있는가?
- [ ] `MockBloc`이 mockito 대신 mocktail 스타일을 따르는 이유와 `whenListen`의 사용법을 설명할 수 있는가?
- [ ] Golden Test에서 `--update-goldens` 플래그의 역할과 CI에서의 검증 방식을 설명할 수 있는가?

**심화:**
- [ ] Property-based Testing의 장점과 적용 시점을 설명할 수 있는가?
- [ ] Mutation Testing으로 테스트 품질을 측정할 수 있는가?
- [ ] Contract Testing으로 API 스키마 위반을 사전에 감지할 수 있는가?
- [ ] CI에서 E2E 테스트를 안정적으로 실행할 수 있는가?
