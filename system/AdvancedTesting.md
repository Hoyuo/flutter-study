# Flutter 고급 테스트 가이드 (시니어)

> **대상**: 10년차+ 시니어 개발자 | Flutter 3.27+ | Dart 3.10+ | TDD/BDD 전문가

## 개요

이 가이드는 Flutter 앱의 품질을 보장하기 위한 고급 테스트 기법을 다룹니다. Property-based Testing, Golden Test 자동화, Mutation Testing, Contract Testing, Visual Regression Testing, Fuzz Testing 등 엔터프라이즈급 테스트 전략을 제시합니다.

### 테스트 성숙도 모델

| 레벨 | 설명 | 커버리지 | 자동화 |
|------|------|---------|--------|
| **Level 0** | 테스트 없음 | 0% | 없음 |
| **Level 1** | 기본 Unit Test | 30-50% | 수동 실행 |
| **Level 2** | Unit + Widget Test | 60-80% | CI/CD 통합 |
| **Level 3** | Property-based + Contract | 80-90% | 자동 회귀 테스트 |
| **Level 4** | Mutation + Fuzz Testing | 90%+ | 품질 게이트 |
| **Level 5** (목표) | Visual Regression + E2E | 95%+ | 완전 자동화 |

### 테스트 전략 매트릭스

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

## 1. Property-based Testing

Property-based Testing은 랜덤 입력값으로 함수의 불변성(invariant)을 검증합니다.

### 1.1 의존성 설치

```yaml
# pubspec.yaml
dev_dependencies:
  test: ^1.25.0
  glados: ^2.0.0  # Property-based testing
  fake: ^2.5.0    # 랜덤 데이터 생성
```

### 1.2 기본 개념

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

### 1.3 실전 예제: 금융 계산 검증

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

### 1.4 Custom Generator 작성

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

### 1.5 Shrinking (최소 실패 케이스 찾기)

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

## 2. Golden Test 자동화

Golden Test는 UI의 스냅샷을 저장하고 변경사항을 감지합니다.

### 2.1 의존성 설치

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  golden_toolkit: ^0.15.0
  alchemist: ^0.7.0  # 고급 Golden Test
```

### 2.2 기본 Golden Test

```dart
// test/widgets/product_card_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:my_app/widgets/product_card.dart';

void main() {
  setUpAll(() async {
    // 커스텀 폰트 로드
    await loadAppFonts();
  });

  group('ProductCard Golden Tests', () {
    testGoldens('기본 상태', (tester) async {
      final builder = GoldenBuilder.grid(
        columns: 2,
        widthToHeightRatio: 1,
      )
        ..addScenario(
          '일반 상품',
          ProductCard(
            title: '아이폰 15 Pro',
            price: '1,550,000원',
            imageUrl: 'https://example.com/image.png',
          ),
        )
        ..addScenario(
          '할인 상품',
          ProductCard(
            title: '갤럭시 S24',
            price: '999,000원',
            originalPrice: '1,200,000원',
            discountRate: 17,
            imageUrl: 'https://example.com/image.png',
          ),
        )
        ..addScenario(
          '품절 상품',
          ProductCard(
            title: '에어팟 Pro',
            price: '359,000원',
            isSoldOut: true,
            imageUrl: 'https://example.com/image.png',
          ),
        )
        ..addScenario(
          '긴 제목',
          ProductCard(
            title: '매우 긴 상품명을 가진 제품으로 텍스트 오버플로우를 테스트합니다',
            price: '50,000원',
            imageUrl: 'https://example.com/image.png',
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        surfaceSize: const Size(800, 600),
      );

      await screenMatchesGolden(tester, 'product_card_grid');
    });

    testGoldens('다크 모드', (tester) async {
      await tester.pumpWidgetBuilder(
        ProductCard(
          title: '아이폰 15 Pro',
          price: '1,550,000원',
          imageUrl: 'https://example.com/image.png',
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
        ),
        surfaceSize: const Size(400, 200),
      );

      await screenMatchesGolden(tester, 'product_card_dark');
    });

    testGoldens('반응형 레이아웃', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Mobile (375x667)',
          ProductCard(
            title: '아이폰 15 Pro',
            price: '1,550,000원',
            imageUrl: 'https://example.com/image.png',
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        surfaceSize: const Size(375, 667),
      );

      await screenMatchesGolden(tester, 'product_card_mobile');

      // Tablet
      await tester.pumpWidgetBuilder(
        builder.build(),
        surfaceSize: const Size(768, 1024),
      );

      await screenMatchesGolden(tester, 'product_card_tablet');
    });
  });
}
```

### 2.3 Alchemist로 고급 Golden Test

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

### 2.4 CI/CD 통합

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
              body: '🚨 Golden tests failed! Check artifacts for diff images.'
            })
```

---

## 3. Mutation Testing

Mutation Testing은 테스트의 품질을 검증합니다. 코드에 의도적인 버그(mutation)를 주입하고, 테스트가 이를 감지하는지 확인합니다.

### 3.1 개념

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

### 3.2 수동 Mutation Testing

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

### 3.3 Mutation Testing 체크리스트

| Mutation Type | 예제 | 테스트 전략 |
|--------------|------|-----------|
| **산술 연산자** | `+` → `-`, `*` → `/` | 다양한 입력값으로 결과 검증 |
| **비교 연산자** | `<` → `<=`, `==` → `!=` | 경계값 테스트 |
| **논리 연산자** | `&&` → `||`, `!` 제거 | 모든 분기 커버 |
| **상수 변경** | `0` → `1`, `true` → `false` | 엣지 케이스 테스트 |
| **문장 제거** | `return` 문 삭제 | 반환값 검증 |
| **조건 반전** | `if (x)` → `if (!x)` | 양/음 케이스 모두 테스트 |

---

## 4. Contract Testing

API의 요청/응답 스키마를 검증하여 프론트엔드-백엔드 계약을 보장합니다.

### 4.1 의존성 설치

```yaml
dev_dependencies:
  http_mock_adapter: ^0.6.0
  json_schema: ^5.1.0
```

### 4.2 JSON Schema 정의

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

### 4.3 Contract Test 구현

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

## 5. Visual Regression Testing

UI 변경사항을 자동으로 감지하고 의도하지 않은 변경을 방지합니다.

### 5.1 Percy 통합 (Cloud 기반)

```yaml
# pubspec.yaml
dev_dependencies:
  percy_cli: ^1.0.0  # Percy CLI wrapper
```

```dart
// test/visual/home_screen_visual_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/home/presentation/home_screen.dart';
import 'package:percy_flutter/percy_flutter.dart';

void main() {
  testWidgets('HomeScreen visual regression', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen()),
    );

    // Percy 스냅샷
    await Percy.screenshot(
      tester,
      name: 'HomeScreen - Default State',
    );

    // 상태 변경
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await Percy.screenshot(
      tester,
      name: 'HomeScreen - Menu Opened',
    );
  });
}
```

### 5.2 로컬 Visual Regression (Alchemist)

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

## 6. Fuzz Testing

랜덤하고 예상치 못한 입력으로 앱의 견고성을 테스트합니다.

### 6.1 입력 검증 Fuzz Testing

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

### 6.2 네트워크 Fuzz Testing

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

## 7. Performance Testing

성능 벤치마크를 자동화합니다.

### 7.1 위젯 렌더링 벤치마크

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

### 7.2 비즈니스 로직 벤치마크

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

## 8. E2E 테스트 (Patrol)

patrol 패키지로 네이티브 기능까지 테스트합니다.

### 8.1 의존성 설치

```yaml
dev_dependencies:
  patrol: ^3.0.0
```

### 8.2 기본 E2E 테스트

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:my_app/main.dart' as app;

void main() {
  patrolTest(
    '로그인 플로우 E2E 테스트',
    ($) async {
      await app.main();
      await $.pumpAndSettle();

      // 로그인 화면 확인
      expect($(#emailField), findsOneWidget);
      expect($(#passwordField), findsOneWidget);

      // 입력
      await $(#emailField).enterText('user@example.com');
      await $(#passwordField).enterText('password123');

      // 로그인 버튼 탭
      await $(#loginButton).tap();
      await $.pumpAndSettle();

      // 홈 화면 확인
      expect($(HomeScreen), findsOneWidget);
      expect($('Welcome, User'), findsOneWidget);

      // 네이티브 권한 요청 처리
      await $.native.grantPermissionWhenInUse();

      // 네이티브 알림 확인
      await $.native.openNotifications();
      expect($('New Message'), findsOneWidget);
      await $.native.pressBack();
    },
  );

  patrolTest(
    '결제 플로우 E2E 테스트',
    ($) async {
      await app.main();

      // 상품 선택
      await $(ProductCard).at(0).tap();
      await $.pumpAndSettle();

      // 장바구니 추가
      await $(#addToCartButton).tap();
      await $.pumpAndSettle();

      // 장바구니 이동
      await $(Icons.shopping_cart).tap();
      await $.pumpAndSettle();

      // 결제 진행
      await $(#checkoutButton).tap();
      await $.pumpAndSettle();

      // 배송 정보 입력
      await $(#addressField).enterText('서울시 강남구');
      await $(#phoneField).enterText('010-1234-5678');

      // 결제 수단 선택
      await $(#creditCardOption).tap();
      await $.pumpAndSettle();

      // 주문 완료
      await $(#confirmOrderButton).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 10));

      // 성공 메시지 확인
      expect($('주문이 완료되었습니다'), findsOneWidget);
    },
  );
}
```

---

## 9. 테스트 커버리지 자동화

### 9.1 커버리지 수집

```bash
# 전체 커버리지
flutter test --coverage

# HTML 리포트 생성 (lcov 필요)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 9.2 품질 게이트

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

## 10. Flaky Test 관리

### 10.1 Flaky Test 감지

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
    print('⚠️ Test is FLAKY!');
    exit(1);
  }
}
```

### 10.2 Flaky Test 수정 전략

| 원인 | 증상 | 해결 방법 |
|------|------|----------|
| **타이밍 이슈** | 간헐적 실패 | `pumpAndSettle()` 사용, timeout 증가 |
| **비동기 경쟁** | Future 완료 전 테스트 종료 | `await tester.runAsync()` |
| **랜덤 데이터** | 특정 값에서만 실패 | Seed 고정, 경계값 테스트 |
| **외부 의존성** | 네트워크/파일 시스템 | Mock 사용, Fixture 데이터 |
| **시간 의존성** | `DateTime.now()` 사용 | Clock abstraction |

```dart
// ✅ Flaky Test 수정 예제
testWidgets('애니메이션 완료 후 상태 확인', (tester) async {
  await tester.pumpWidget(MyAnimatedWidget());

  // ❌ Flaky: 애니메이션이 완료되지 않을 수 있음
  // await tester.pump(const Duration(seconds: 1));

  // ✅ 안정적: 모든 애니메이션 완료 대기
  await tester.pumpAndSettle();

  expect(find.text('Animation Complete'), findsOneWidget);
});
```

---

## 결론

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
