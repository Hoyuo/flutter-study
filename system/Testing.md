# Flutter Testing Guide

> 이 문서는 Flutter 프로젝트에서 테스트를 작성하는 방법을 설명합니다.

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
  bloc_test: ^10.0.0
  mockito: ^5.6.3
  build_runner: ^2.4.0  # mockito 코드 생성용
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
flutter pub run build_runner build --delete-conflicting-outputs
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

// 여러 번 호출 시 다른 결과
when(mockRepository.getHomeData())
    .thenAnswer((_) async => Right(homeData1))
    .thenAnswer((_) async => Right(homeData2));
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

@GenerateMocks([AuthRepository])
void main() {}

// 실제 테스트 파일
import 'login_bloc_test.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  group('LoginBloc Effect', () {
    test('로그인 성공 시 NavigateToHome Effect 발행', () async {
      // Arrange
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
import 'package:mockito/mockito.dart';
import 'package:home/presentation/presentation.dart';

import '../../mocks/mocks.mocks.dart';
import '../../fixtures/home_fixture.dart';

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
      when(mockBloc.state).thenReturn(const HomeState.initial());

      // Act
      await tester.pumpWidget(buildWidget());

      // Assert
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('loading 상태에서 로딩 인디케이터 표시', (tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(const HomeState.loading());

      // Act
      await tester.pumpWidget(buildWidget());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('loaded 상태에서 데이터 표시', (tester) async {
      // Arrange
      when(mockBloc.state)
          .thenReturn(HomeState.loaded(HomeFixture.homeData));

      // Act
      await tester.pumpWidget(buildWidget());

      // Assert
      expect(find.text(HomeFixture.homeData.title), findsOneWidget);
    });

    testWidgets('error 상태에서 에러 메시지 표시', (tester) async {
      // Arrange
      const errorMessage = '에러가 발생했습니다.';
      when(mockBloc.state)
          .thenReturn(const HomeState.error(errorMessage));

      // Act
      await tester.pumpWidget(buildWidget());

      // Assert
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('새로고침 버튼 탭 시 refresh 이벤트 발행', (tester) async {
      // Arrange
      when(mockBloc.state)
          .thenReturn(HomeState.loaded(HomeFixture.homeData));

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
