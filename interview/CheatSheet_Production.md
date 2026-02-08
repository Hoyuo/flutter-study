# Flutter Production & Quality 인터뷰 치트시트

> **대상**: L4(Mid) ~ L6(Staff) | **Flutter 3.38** | **Dart 3.10**
> **범위**: Testing, Security, CI/CD, Production Operations, Dependency Management, Team Collaboration
> **레벨 표시**: L4 | L5 | L6

---

## 1. 테스트 전략

### 1.1 테스트 피라미드

```
          /\
         /  \      E2E / Integration (10%)
        /----\
       /      \    Widget Test (20%)
      /--------\
     /          \  Unit Test (70%)
    --------------
```

| 계층 | 비율 | 속도 | 신뢰도 | 비용 | 레벨 |
|------|------|------|--------|------|------|
| **Unit Test** | 70% | 빠름 (ms) | 낮음 | 저 | L4 |
| **Widget Test** | 20% | 중간 (s) | 중간 | 중 | L4 |
| **Integration Test** | 10% | 느림 (min) | 높음 | 고 | L5 |

### 1.2 테스트 종류별 도구/용도 비교표

| 테스트 종류 | 패키지 | 대상 | 핵심 API | 레벨 |
|------------|--------|------|----------|------|
| Unit Test | `flutter_test` | 함수, 클래스, Bloc | `test()`, `group()`, `expect()` | L4 |
| Mock/Stub | `mocktail` | 의존성 격리 | `Mock`, `when()`, `verify()` | L4 |
| Bloc Test | `bloc_test` | Bloc 상태 변화 | `blocTest()`, `seed()`, `expect()` | L4 |
| Widget Test | `flutter_test` | UI 컴포넌트 | `pumpWidget()`, `find.*`, `expect()` | L4 |
| Golden Test | `alchemist` | UI 회귀 감지 | `goldenTest()`, `updateGoldens` | L5 |
| Integration | `patrol` | E2E + 네이티브 | `patrolTest()`, `$.native.*` | L5 |
| Property-based | `glados` | 엣지 케이스 발견 | `Glados<T>().test()` | L5 |
| Mutation | `mutation_test` | 테스트 품질 검증 | 뮤턴트 Kill Rate | L5 |
| Contract | `pact_dart` | API 계약 보장 | Provider/Consumer 계약 | L6 |
| Fuzz | `dart:ffi` + libFuzzer | 예외 입력 탐색 | 랜덤 입력 생성 | L6 |

### 1.3 blocTest 핵심 코드 템플릿 (L4)

```dart
blocTest<HomeBloc, HomeState>(
  '설명: started 이벤트 -> loading -> loaded',
  // 1) build: Bloc 인스턴스 생성 + Mock 설정
  build: () {
    when(() => mockUseCase())
        .thenAnswer((_) async => Right(homeData));
    return HomeBloc(mockUseCase);
  },
  // 2) seed: 초기 상태 지정 (선택)
  seed: () => const HomeState.initial(),
  // 3) act: 이벤트 발행
  act: (bloc) => bloc.add(const HomeEvent.started()),
  // 4) expect: 상태 변화 순서 검증
  expect: () => [
    const HomeState.loading(),
    HomeState.loaded(homeData),
  ],
  // 5) verify: 호출 검증
  verify: (_) {
    verify(() => mockUseCase()).called(1);
  },
);
```

**blocTest 주요 파라미터 정리:**

| 파라미터 | 용도 | 필수 |
|----------|------|------|
| `build` | Bloc 인스턴스 생성 | O |
| `act` | 이벤트 발행 | O |
| `expect` | 상태 변화 리스트 | O |
| `seed` | 초기 상태 오버라이드 | X |
| `verify` | Mock 호출 검증 | X |
| `wait` | 비동기 대기 시간 | X |
| `errors` | 예외 검증 | X |

### 1.4 Widget Test 핵심 패턴 (L4)

```dart
testWidgets('홈 카드 렌더링 검증', (tester) async {
  // 1) pump: 위젯 렌더링
  await tester.pumpWidget(
    MaterialApp(home: HomeCard(title: '테스트')),
  );

  // 2) find: 위젯 탐색
  expect(find.text('테스트'), findsOneWidget);
  expect(find.byType(Card), findsOneWidget);
  expect(find.byIcon(Icons.home), findsOneWidget);

  // 3) 인터랙션
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle(); // 애니메이션 완료 대기

  // 4) 결과 검증
  expect(find.text('완료'), findsOneWidget);
});
```

**Widget Test 핵심 API:**

| API | 용도 | 사용 시점 |
|-----|------|----------|
| `pumpWidget()` | 위젯 최초 렌더링 | 테스트 시작 |
| `pump()` | 한 프레임 전진 | 상태 변경 후 |
| `pumpAndSettle()` | 애니메이션 완료까지 대기 | 탭/스크롤 후 |
| `find.text()` | 텍스트로 위젯 검색 | 텍스트 검증 |
| `find.byType()` | 타입으로 위젯 검색 | 구조 검증 |
| `find.byKey()` | Key로 위젯 검색 | 특정 위젯 타겟팅 |
| `tester.tap()` | 탭 이벤트 | 버튼 클릭 |
| `tester.enterText()` | 텍스트 입력 | 폼 입력 |
| `tester.drag()` | 드래그 | 스크롤/스와이프 |

### 1.5 Bloc과 함께 Widget Test (L4)

```dart
testWidgets('Bloc 상태별 UI 검증', (tester) async {
  final mockBloc = MockHomeBloc();

  // whenListen: Bloc 스트림 모킹
  whenListen(
    mockBloc,
    Stream.fromIterable([
      const HomeState.loading(),
      HomeState.loaded(homeData),
    ]),
    initialState: const HomeState.initial(),
  );

  await tester.pumpWidget(
    BlocProvider<HomeBloc>.value(
      value: mockBloc,
      child: const MaterialApp(home: HomeScreen()),
    ),
  );

  await tester.pumpAndSettle();
  expect(find.byType(HomeContent), findsOneWidget);
});
```

### 1.6 Golden Test 워크플로우 (L5)

```bash
# 1. 골든 파일 생성/업데이트
flutter test --update-goldens

# 2. 테스트 실행 (비교)
flutter test

# 3. CI에서 골든 테스트
flutter test --tags=golden
```

```dart
// alchemist를 사용한 골든 테스트
goldenTest(
  'HomeCard 골든 테스트',
  fileName: 'home_card',
  builder: () => GoldenTestGroup(
    scenarioConstraints: BoxConstraints(maxWidth: 400),
    children: [
      GoldenTestScenario(
        name: '기본',
        child: HomeCard(title: '제목'),
      ),
      GoldenTestScenario(
        name: '긴 텍스트',
        child: HomeCard(title: '매우 긴 제목이 들어간 카드'),
      ),
    ],
  ),
);
```

### 1.7 Property-based / Mutation / Contract Testing 비교표 (L5)

| 항목 | Property-based | Mutation | Contract |
|------|---------------|----------|----------|
| **목적** | 엣지 케이스 자동 발견 | 테스트 품질 검증 | API 계약 보장 |
| **원리** | 랜덤 입력 생성 + 속성 검증 | 코드 변형 후 테스트 실패 확인 | Provider-Consumer 계약 검증 |
| **도구** | `glados` | `mutation_test` | `pact_dart` |
| **질문** | "모든 입력에 대해 성립하는가?" | "테스트가 버그를 잡는가?" | "API가 약속을 지키는가?" |
| **비용** | 중간 (실행 시간 증가) | 높음 (N개 뮤턴트 x 테스트) | 중간 (계약 관리 필요) |
| **적용 시기** | 파서, 변환 로직 | 핵심 비즈니스 로직 | MSA 환경 |

### 1.8 테스트 커버리지 목표 기준표

| 레벨 | 라인 커버리지 | 브랜치 커버리지 | 필수 테스트 | 선택 테스트 |
|------|-------------|---------------|------------|------------|
| L4 | >= 70% | >= 60% | Unit, Widget | Golden |
| L5 | >= 80% | >= 70% | Unit, Widget, Golden | Property-based, Integration |
| L6 | >= 85% | >= 80% | Unit, Widget, Golden, Integration | Mutation, Contract, Fuzz |

**커버리지 명령어:**

```bash
# 커버리지 생성
flutter test --coverage

# HTML 리포트 생성 (lcov 필요)
genhtml coverage/lcov.info -o coverage/html

# 커버리지 확인
lcov --summary coverage/lcov.info
```

---

## 2. 보안

### 2.1 OWASP Mobile Top 10 요약표

| 순위 | 취약점 | Flutter 대응 방법 | 레벨 |
|------|--------|------------------|------|
| M1 | 부적절한 인증/인가 | 토큰 관리, 세션 검증, RBAC | L4 |
| M2 | 부적절한 암호화 | AES-256, TLS 1.3, SecureStorage | L4 |
| M3 | 불충분한 로깅/모니터링 | Crashlytics, 감사 로그 | L5 |
| M4 | 불충분한 코드 품질 | 정적 분석, `flutter analyze` | L4 |
| M5 | 부적절한 키 도출 | PBKDF2, Argon2 | L5 |
| M6 | 부적절한 권한 검증 | 최소 권한 원칙, permission_handler | L4 |
| M7 | 클라이언트 측 주입 | 입력 검증, 파라미터 바인딩 | L4 |
| M8 | 부적절한 API 구현 | API 보안, Rate Limiting | L5 |
| M9 | 부적절한 암호 저장 | 단방향 해싱, salt 사용 | L5 |
| M10 | 역공학 | 코드 난독화, RASP | L6 |

### 2.2 데이터 저장 보안 비교표

| 항목 | SharedPreferences | Hive | flutter_secure_storage |
|------|-------------------|------|----------------------|
| **암호화** | 없음 (평문) | 선택적 (AES) | 자동 (AES-GCM + RSA OAEP) |
| **저장소** | XML/plist | 바이너리 파일 | iOS Keychain / Android Keystore |
| **용도** | 설정값, 플래그 | 구조화 데이터 캐시 | 토큰, 비밀번호, 민감 데이터 |
| **속도** | 빠름 | 매우 빠름 | 느림 (암호화 오버헤드) |
| **보안 등급** | 낮음 | 중간 | 높음 |
| **루팅 대응** | 취약 | 취약 (암호화 시 중간) | 강함 (하드웨어 보안 모듈) |
| **레벨** | L4 | L4 | L4 |

**저장 대상별 권장 저장소:**

| 데이터 | 저장소 | 이유 |
|--------|--------|------|
| 테마 설정 | SharedPreferences | 민감하지 않은 설정값 |
| 검색 기록 | Hive (암호화) | 개인 정보이나 고속 접근 필요 |
| Access Token | flutter_secure_storage | 인증 토큰은 반드시 암호화 저장 |
| Refresh Token | flutter_secure_storage | 장기 토큰, 보안 필수 |
| 생체 인증 키 | flutter_secure_storage | 하드웨어 보안 모듈 활용 |

### 2.3 네트워크 보안 계층

| 계층 | 기술 | 보호 대상 | 구현 난이도 | 레벨 |
|------|------|----------|-----------|------|
| **기본** | HTTPS (TLS 1.3) | 전송 데이터 암호화 | 낮음 | L4 |
| **중급** | Certificate Pinning | MITM 공격 방지 | 중간 | L5 |
| **고급** | mTLS (양방향 인증) | 클라이언트 인증 | 높음 | L6 |

**Certificate Pinning 구현 (dio):**

```dart
final dio = Dio();
(dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  final client = HttpClient();
  client.badCertificateCallback = (cert, host, port) {
    // SHA-256 핑거프린트 비교
    final fingerprint = sha256.convert(cert.der).toString();
    return fingerprint == expectedFingerprint;
  };
  return client;
};
```

### 2.4 코드 보안

| 기법 | 도구/방법 | 목적 | 레벨 |
|------|----------|------|------|
| **코드 난독화** | `flutter build --obfuscate --split-debug-info` | 디컴파일 방지 | L4 |
| **탈옥/루팅 감지** | `flutter_jailbreak_detection` | 변조 환경 감지 | L5 |
| **디버거 감지** | `freerasp` | 동적 분석 방지 | L5 |
| **RASP** | `freerasp`, Talsec | 런타임 자가 보호 | L6 |
| **앱 무결성 검증** | Play Integrity / App Attest | 위변조 검증 | L6 |

**난독화 빌드 명령어:**

```bash
# Android
flutter build appbundle \
  --obfuscate \
  --split-debug-info=build/debug-info/android

# iOS
flutter build ipa \
  --obfuscate \
  --split-debug-info=build/debug-info/ios
```

### 2.5 인증 보안 체크리스트

| 항목 | 체크 | 설명 | 레벨 |
|------|------|------|------|
| Access Token 보안 저장 | [ ] | flutter_secure_storage 사용 | L4 |
| Refresh Token 보안 저장 | [ ] | Keychain/Keystore 활용 | L4 |
| Token 만료 처리 | [ ] | 401 인터셉터 + 자동 갱신 | L4 |
| 생체 인증 | [ ] | local_auth + Keychain | L5 |
| PKCE 플로우 | [ ] | OAuth 2.0 + PKCE (appauth) | L5 |
| 다중 디바이스 세션 관리 | [ ] | 서버 측 세션 추적 | L5 |
| Token Rotation | [ ] | Refresh 시 새 Refresh Token 발급 | L6 |
| Device Binding | [ ] | 디바이스 ID + 토큰 바인딩 | L6 |

**PKCE 플로우 요약:**

```
1. 앱 -> code_verifier (랜덤 문자열) 생성
2. 앱 -> code_challenge = SHA256(code_verifier) 계산
3. 앱 -> 인증 서버: code_challenge 전송 (Authorization Request)
4. 사용자 인증 후 -> 앱: authorization_code 수신
5. 앱 -> 인증 서버: authorization_code + code_verifier 전송
6. 인증 서버: SHA256(code_verifier) == code_challenge 검증
7. 검증 성공 -> Access Token + Refresh Token 발급
```

---

## 3. CI/CD

### 3.1 CI/CD 파이프라인 단계

```
Push/PR -> [Analyze] -> [Test] -> [Build] -> [Sign] -> [Deploy] -> [Monitor]
   |          |           |         |          |          |            |
   v          v           v         v          v          v            v
 Trigger   dart format  Unit     APK/IPA   Keystore   Firebase    Crashlytics
           flutter      Widget   AAB/IPA   Match      TestFlight  Sentry
           analyze      Golden              Signing    Play Store  Slack Alert
```

### 3.2 GitHub Actions 핵심 워크플로우 구조 (L4)

```yaml
name: Flutter CI/CD
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

env:
  FLUTTER_VERSION: '3.38.0'
  JAVA_VERSION: '17'

jobs:
  analyze:                          # 1단계: 정적 분석 + 테스트
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze --fatal-infos
      - run: flutter test --coverage

  build-android:                    # 2단계: Android 빌드
    needs: analyze
    runs-on: ubuntu-latest
    strategy:
      matrix:
        flavor: [dev, staging, prod]
    steps:
      - uses: actions/setup-java@v4
        with: { distribution: 'temurin', java-version: '17' }
      - run: flutter build appbundle --flavor ${{ matrix.flavor }}

  build-ios:                        # 3단계: iOS 빌드
    needs: analyze
    runs-on: macos-14               # M1 Mac
    steps:
      - run: flutter build ipa --flavor ${{ matrix.flavor }}

  deploy:                           # 4단계: 배포
    needs: [build-android, build-ios]
    if: github.ref == 'refs/heads/main'
    steps:
      - run: fastlane deploy         # Store 배포
```

### 3.3 빌드 최적화 전략

| 전략 | 방법 | 절감 효과 | 레벨 |
|------|------|----------|------|
| **Flutter 캐싱** | `subosito/flutter-action` `cache: true` | SDK 설치 -70% | L4 |
| **Gradle 캐싱** | `actions/setup-java` `cache: 'gradle'` | Android 빌드 -40% | L4 |
| **CocoaPods 캐싱** | `actions/cache` + `Pods/` | iOS 빌드 -30% | L4 |
| **pub 캐싱** | `cache-key: flutter-${{ hashFiles('pubspec.lock') }}` | pub get -80% | L4 |
| **병렬 빌드** | `strategy.matrix` + `fail-fast: false` | 전체 시간 -50% | L5 |
| **선택적 실행** | `paths-filter` 액션 + 변경 파일 감지 | 불필요 빌드 제거 | L5 |
| **Self-hosted Runner** | macOS 전용 러너 | iOS 빌드 비용 -90% | L6 |

**선택적 실행 예시 (L5):**

```yaml
- uses: dorny/paths-filter@v3
  id: changes
  with:
    filters: |
      flutter:
        - 'lib/**'
        - 'test/**'
        - 'pubspec.*'
      ios:
        - 'ios/**'
      android:
        - 'android/**'

- if: steps.changes.outputs.flutter == 'true'
  run: flutter test
```

### 3.4 Fastlane 주요 명령어 표

| 명령어 | 용도 | 플랫폼 | 레벨 |
|--------|------|--------|------|
| `fastlane init` | 초기 설정 | 공통 | L4 |
| `fastlane match` | 인증서 관리 (Git 저장) | iOS | L5 |
| `fastlane pilot upload` | TestFlight 업로드 | iOS | L4 |
| `fastlane deliver` | App Store 제출 | iOS | L5 |
| `fastlane supply` | Play Store 업로드 | Android | L5 |
| `fastlane scan` | 테스트 실행 | iOS | L4 |
| `fastlane gym` | IPA 빌드 | iOS | L4 |
| `fastlane gradle` | AAB/APK 빌드 | Android | L4 |

**Fastlane 배포 레인 예시:**

```ruby
# ios/fastlane/Fastfile
lane :deploy_testflight do
  build_ios_app(
    scheme: "Runner",
    export_method: "app-store"
  )
  upload_to_testflight(
    skip_waiting_for_build_processing: true
  )
  slack(message: "iOS 빌드 TestFlight 업로드 완료")
end
```

### 3.5 앱 배포 프로세스 플로우

| 단계 | 활동 | 도구 | 자동화 |
|------|------|------|--------|
| 1. 코드 머지 | PR 승인 + main 머지 | GitHub | O |
| 2. CI 트리거 | 분석 + 테스트 + 빌드 | GitHub Actions | O |
| 3. 코드 서명 | Keystore / Match | Fastlane | O |
| 4. 아티팩트 생성 | APK/AAB/IPA 생성 | Flutter CLI | O |
| 5. 내부 배포 | Firebase App Distribution | Fastlane | O |
| 6. QA 테스트 | 수동 + 자동 테스트 | QA 팀 | 부분 |
| 7. 스토어 제출 | Play Store / App Store | Fastlane | O |
| 8. 단계적 출시 | 1% -> 10% -> 50% -> 100% | 스토어 콘솔 | 부분 |
| 9. 모니터링 | Crash-free Rate 추적 | Crashlytics | O |

### 3.6 Shorebird OTA 업데이트 워크플로우 (L5)

| 단계 | 명령어 | 설명 |
|------|--------|------|
| 1. 설치 | `curl https://docs.shorebird.dev/install.sh \| bash` | CLI 설치 |
| 2. 초기화 | `shorebird init` | 프로젝트 설정 |
| 3. 릴리스 생성 | `shorebird release android` | 기준 릴리스 |
| 4. 패치 배포 | `shorebird patch android` | OTA 패치 Push |
| 5. 확인 | `shorebird apps list` | 배포 상태 확인 |

**Shorebird 주의사항:**

| 항목 | 가능 | 불가능 |
|------|------|--------|
| Dart 코드 변경 | O | - |
| 에셋 변경 | O | - |
| 네이티브 코드 변경 | - | X (풀 릴리스 필요) |
| 플러그인 추가/제거 | - | X (풀 릴리스 필요) |
| Flutter SDK 버전 변경 | - | X (풀 릴리스 필요) |

### 3.7 Canary Release 전략 (L6)

```
[Canary Release 플로우]

1. 내부 테스트 (Dog-fooding)
   └── 팀 내부 100% 배포
2. Alpha (1%)
   └── 초기 크래시/성능 모니터링
3. Beta (10%)
   └── SLO 지표 확인 (Crash-free >= 99.5%)
4. Staged Rollout (25% -> 50%)
   └── A/B 테스트 결과 비교
5. GA (100%)
   └── 전체 사용자 배포
```

**Canary 판단 기준표:**

| 지표 | 진행 기준 | 롤백 기준 |
|------|----------|----------|
| Crash-free Rate | >= 99.5% | < 99.0% |
| ANR Rate | < 0.5% | > 1.0% |
| API Error Rate | < 1% | > 5% |
| 앱 시작 시간 | < 기존 대비 +10% | > 기존 대비 +30% |
| 사용자 피드백 | 부정 < 5% | 부정 > 15% |

---

## 4. 프로덕션 운영

### 4.1 SLO/SLI 핵심 지표 표

| SLI (지표) | SLO (목표) | 측정 도구 | 레벨 |
|-----------|-----------|----------|------|
| **Crash-free Rate** | >= 99.5% | Crashlytics | L4 |
| **ANR Rate** | < 0.47% | Play Console | L5 |
| **앱 시작 시간 (Cold)** | < 2초 | Firebase Performance | L4 |
| **앱 시작 시간 (Warm)** | < 1초 | Firebase Performance | L4 |
| **프레임 드롭율** | < 5% (60fps 기준) | DevTools | L5 |
| **API 성공률** | >= 99.9% | Sentry / 자체 모니터링 | L5 |
| **API P95 응답시간** | < 500ms | Firebase Performance | L5 |
| **OOM 발생률** | < 0.1% | Crashlytics | L6 |
| **배포 성공률** | >= 95% | CI/CD 메트릭 | L6 |

**SLO vs SLA vs SLI 구분:**

| 용어 | 의미 | 예시 |
|------|------|------|
| **SLI** (Service Level Indicator) | 실제 측정값 | Crash-free Rate = 99.7% |
| **SLO** (Service Level Objective) | 내부 목표 | Crash-free Rate >= 99.5% |
| **SLA** (Service Level Agreement) | 외부 계약 | 월 가용성 99.9% (위반 시 환불) |

### 4.2 앱 모니터링 도구 비교표

| 항목 | Crashlytics | Sentry | Datadog |
|------|------------|--------|---------|
| **비용** | 무료 (Firebase) | 유료 (무료 tier 有) | 유료 |
| **크래시 리포팅** | 우수 | 우수 | 양호 |
| **성능 모니터링** | Firebase Performance | Sentry Performance | APM 전체 |
| **사용자 세션** | 기본 | 세션 리플레이 | 세션 리플레이 |
| **Flutter 지원** | 공식 | 공식 | 공식 |
| **커스텀 이벤트** | Custom Key/Log | Breadcrumb/Tag | Custom Metric |
| **알림** | 기본 (이메일) | Slack/PagerDuty | 다양한 통합 |
| **서버 연동** | Firebase 생태계 | 독립적 | 풀스택 관측 |
| **추천 규모** | 소~중규모 | 중~대규모 | 대규모/엔터프라이즈 |
| **레벨** | L4 | L5 | L6 |

### 4.3 인시던트 관리 프로세스

**우선순위 분류 (P1-P4):**

| 등급 | 영향 범위 | 응답 시간 | 해결 목표 | 에스컬레이션 |
|------|----------|----------|----------|------------|
| **P1** (Critical) | 전체 사용자 / 핵심 기능 불가 | 15분 | 1시간 | VP/CTO 즉시 |
| **P2** (High) | 다수 사용자 / 주요 기능 장애 | 30분 | 4시간 | 팀 리드 |
| **P3** (Medium) | 일부 사용자 / 부가 기능 장애 | 4시간 | 24시간 | 담당 개발자 |
| **P4** (Low) | 소수 사용자 / 미미한 영향 | 1일 | 1주 | 백로그 |

**인시던트 대응 플로우:**

```
감지 -> 분류(P1-P4) -> 알림 -> 담당자 배정 -> 조사 -> 해결 -> 검증 -> 포스트모템
  |                      |                              |
  v                      v                              v
Crashlytics        Slack/PagerDuty                  핫픽스 배포
Sentry Alert       On-call 엔지니어                  or 롤백
사용자 리포트       에스컬레이션                      Feature Flag Off
```

### 4.4 릴리스 체크리스트

**빌드 전 체크리스트:**

| 항목 | 체크 | 담당 | 레벨 |
|------|------|------|------|
| 버전 번호 업데이트 (pubspec.yaml) | [ ] | 개발자 | L4 |
| 릴리스 노트 작성 | [ ] | PM/개발자 | L4 |
| 모든 테스트 통과 확인 | [ ] | CI/CD | L4 |
| 정적 분석 오류 0건 | [ ] | CI/CD | L4 |
| API 호환성 확인 | [ ] | 백엔드 팀 | L5 |
| Feature Flag 상태 확인 | [ ] | 개발자 | L5 |
| DB 마이그레이션 검증 | [ ] | 개발자 | L5 |
| 보안 스캔 통과 | [ ] | 보안 팀 | L6 |

**빌드 후 체크리스트:**

| 항목 | 체크 | 담당 | 레벨 |
|------|------|------|------|
| QA 승인 (스모크 테스트) | [ ] | QA | L4 |
| 앱 크기 확인 (이전 대비) | [ ] | 개발자 | L4 |
| 단계적 출시 설정 (1% 시작) | [ ] | 개발자 | L5 |
| 모니터링 대시보드 확인 | [ ] | On-call | L5 |
| 롤백 계획 준비 | [ ] | 팀 리드 | L5 |
| SLO 알림 임계값 설정 | [ ] | SRE | L6 |

### 4.5 핫픽스 배포 플로우

```
[크리티컬 버그 발견]
       |
       v
1. main에서 hotfix 브랜치 생성
   └── git checkout -b hotfix/1.2.1 main
       |
       v
2. 최소 범위 수정 + 테스트
   └── 영향 범위 최소화, 유닛 테스트 필수
       |
       v
3. 긴급 코드 리뷰 (1인 이상)
   └── 핫픽스 전용 체크리스트 적용
       |
       v
4. main + develop 머지
   └── 양쪽 브랜치 동기화 필수
       |
       v
5. 빌드 + 배포 (Expedited Review 요청)
   └── iOS: Expedited App Review
   └── Android: 즉시 배포 가능
       |
       v
6. 모니터링 (24시간)
   └── Crash-free Rate, ANR Rate 추적
```

### 4.6 App Store / Play Store 제출 체크리스트

| 항목 | App Store (iOS) | Play Store (Android) | 레벨 |
|------|----------------|---------------------|------|
| **앱 크기** | < 200MB (셀룰러 다운로드 제한) | < 150MB (AAB), 기타 on-demand | L4 |
| **스크린샷** | 6.7", 6.5", 5.5" 필수 | 최소 2장, 최대 8장 | L4 |
| **개인정보 처리방침** | URL 필수 | URL 필수 | L4 |
| **연령 등급** | 자체 심사 질문 응답 | IARC 등급 | L4 |
| **Target SDK** | 최신 iOS SDK | targetSdk 34+ (2024 필수) | L5 |
| **코드 서명** | Apple Distribution Certificate | Upload Key + Google 서명 | L5 |
| **백그라운드 모드** | 사용 시 심사 설명 필수 | 서비스 선언 | L5 |
| **IDFA / 광고 추적** | ATT 프레임워크 적용 | Google 광고 ID 정책 | L5 |
| **데이터 안전** | App Privacy Details | Data Safety Section | L5 |
| **리뷰 가이드라인** | App Review Guidelines 준수 | Developer Policy 준수 | L6 |

---

## 5. 의존성 & 버전 관리

### 5.1 pubspec.yaml 버전 제약 문법 표

| 제약 구문 | 의미 | 허용 범위 | 레벨 |
|----------|------|----------|------|
| `^1.2.3` | `>=1.2.3 <2.0.0` | 1.2.3 ~ 1.x.x | L4 |
| `^0.2.3` | `>=0.2.3 <0.3.0` | 0.2.x만 (0.x는 불안정) | L4 |
| `^0.0.3` | `>=0.0.3 <0.0.4` | 0.0.3만 (매우 제한적) | L4 |
| `>=1.0.0 <3.0.0` | 명시적 범위 | 1.x, 2.x | L5 |
| `1.2.3` | 정확히 1.2.3 | 1.2.3만 (pin) | L4 |
| `any` | 모든 버전 | 전체 (비권장) | - |

**프로젝트 유형별 전략:**

| 유형 | 전략 | 예시 | pubspec.lock |
|------|------|------|-------------|
| **앱 프로젝트** | 캐럿 + 구체적 버전 | `dio: ^5.9.1` | Git 커밋 O |
| **라이브러리** | 넓은 범위 | `http: '>=1.0.0 <3.0.0'` | Git 커밋 X |

### 5.2 pub outdated / upgrade 워크플로우

```bash
# 1. 현재 의존성 상태 확인
dart pub outdated

# 2. 출력 컬럼 해석
#    Current  : 현재 설치된 버전
#    Upgradable: pubspec.yaml 제약 내 최신 (pub upgrade 대상)
#    Resolvable: 제약 변경 시 설치 가능한 최신
#    Latest   : pub.dev 최신 버전

# 3. 안전한 업그레이드 (제약 범위 내)
dart pub upgrade

# 4. 특정 패키지만 메이저 업그레이드
dart pub upgrade --major-versions dio

# 5. 업그레이드 후 검증
flutter analyze && flutter test
```

**업그레이드 안전 등급:**

| 변경 유형 | 위험도 | 대응 |
|----------|--------|------|
| patch (1.2.3 -> 1.2.4) | 낮음 | 즉시 적용 |
| minor (1.2.3 -> 1.3.0) | 중간 | 테스트 후 적용 |
| major (1.2.3 -> 2.0.0) | 높음 | 마이그레이션 가이드 확인 + 별도 브랜치 |

### 5.3 FVM 버전 관리 핵심 명령어 표

| 명령어 | 용도 | 레벨 |
|--------|------|------|
| `fvm install 3.38.0` | 특정 버전 설치 | L4 |
| `fvm use 3.38.0` | 프로젝트에 버전 지정 | L4 |
| `fvm list` | 설치된 버전 목록 | L4 |
| `fvm current` | 현재 프로젝트 버전 확인 | L4 |
| `fvm global 3.38.0` | 글로벌 기본 버전 설정 | L4 |
| `fvm releases` | 설치 가능한 릴리스 목록 | L4 |
| `fvm flutter doctor` | FVM 통한 Flutter 명령 실행 | L4 |
| `fvm use stable` | stable 채널 최신 버전 사용 | L5 |

**팀 온보딩 절차:**

```bash
git clone <repo> && cd <repo>
brew install fvm           # FVM 설치 (최초 1회)
fvm install                # .fvmrc 기반 자동 설치
fvm flutter pub get        # 의존성 설치
```

**`.fvmrc` (Git 추적 대상):**

```json
{
  "flutter": "3.38.0"
}
```

### 5.4 Renovate / Dependabot 설정 요약

| 항목 | Renovate | Dependabot |
|------|----------|------------|
| **설정 파일** | `renovate.json` | `.github/dependabot.yml` |
| **자동 머지** | O (automerge 옵션) | X (별도 액션 필요) |
| **그룹 업데이트** | O (group 옵션) | X |
| **스케줄** | 세밀 제어 가능 | 주간/월간 |
| **Monorepo 지원** | 우수 | 기본 |
| **추천** | 대규모 프로젝트 | 소규모 프로젝트 |

**Dependabot 설정 예시:**

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "pub"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    labels:
      - "dependencies"
```

**Renovate 설정 예시:**

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "packageRules": [
    {
      "matchPackagePatterns": ["*"],
      "groupName": "all dependencies",
      "schedule": ["before 7am on Monday"]
    }
  ],
  "flutter": { "enabled": true }
}
```

### 5.5 보안 취약점 스캔 (OSV Scanner)

```bash
# OSV Scanner 설치
go install github.com/google/osv-scanner/cmd/osv-scanner@latest

# pubspec.lock 기반 스캔
osv-scanner --lockfile=pubspec.lock

# CI 통합 (GitHub Actions)
- name: OSV Scan
  uses: google/osv-scanner-action/osv-scanner-action@v2
  with:
    scan-args: '--lockfile=pubspec.lock'
```

**취약점 발견 시 대응 플로우:**

| 심각도 | 대응 | 기한 |
|--------|------|------|
| Critical (CVSS 9.0+) | 즉시 패치/업그레이드 | 24시간 |
| High (CVSS 7.0-8.9) | 우선 패치 | 1주 |
| Medium (CVSS 4.0-6.9) | 다음 스프린트 | 1달 |
| Low (CVSS 0.1-3.9) | 백로그 등록 | 분기 |

---

## 6. 팀 협업

### 6.1 코드 리뷰 체크리스트

| 영역 | 체크 항목 | 레벨 |
|------|----------|------|
| **기능** | 요구사항 충족 여부 | L4 |
| | 엣지 케이스 처리 | L4 |
| | 에러 핸들링 적절성 | L4 |
| **아키텍처** | 계층 분리 준수 (Data/Domain/Presentation) | L5 |
| | 의존성 방향 (안쪽 -> 바깥쪽 의존 금지) | L5 |
| | 단일 책임 원칙 | L5 |
| **성능** | 불필요한 리빌드 방지 (const, Selector) | L5 |
| | 메모리 누수 (dispose, 스트림 구독 해제) | L5 |
| | N+1 쿼리 / 과도한 API 호출 | L6 |
| **보안** | 민감 데이터 노출 (로그, 에러 메시지) | L4 |
| | 하드코딩된 시크릿 | L4 |
| | 입력 검증 | L5 |
| **테스트** | 새 코드 테스트 존재 여부 | L4 |
| | 테스트 품질 (엣지 케이스, 실패 시나리오) | L5 |
| | 테스트 커버리지 하락 여부 | L5 |

### 6.2 브랜치 전략 비교표

| 항목 | Git Flow | Trunk-based |
|------|----------|-------------|
| **브랜치 수** | 많음 (main, develop, feature, release, hotfix) | 적음 (main + 단기 feature) |
| **머지 빈도** | 낮음 (릴리스 단위) | 높음 (매일) |
| **충돌 빈도** | 높음 (장기 브랜치) | 낮음 (단기 브랜치) |
| **릴리스 주기** | 스케줄 기반 | 지속적 배포 |
| **CI/CD 복잡도** | 높음 (브랜치별 파이프라인) | 낮음 (단일 파이프라인) |
| **Feature Flag 필요** | 낮음 | 높음 (미완성 코드 숨김) |
| **팀 규모** | 대규모 팀 | 소규모~중규모 팀 |
| **추천 시기** | 릴리스 관리 엄격한 프로젝트 | 빠른 배포 주기 프로젝트 |

### 6.3 PR 템플릿 핵심 항목

```markdown
## 변경 사항
<!-- 무엇을, 왜 변경했는지 간결하게 설명 -->

## 변경 유형
- [ ] 기능 추가
- [ ] 버그 수정
- [ ] 리팩토링
- [ ] 문서 수정

## 테스트
- [ ] 유닛 테스트 추가/수정
- [ ] 위젯 테스트 추가/수정
- [ ] 수동 테스트 완료

## 체크리스트
- [ ] 코드 컨벤션 준수
- [ ] 불필요한 print/debugPrint 제거
- [ ] 스크린샷/영상 첨부 (UI 변경 시)
- [ ] 영향 받는 문서 업데이트

## 관련 이슈
<!-- Closes #123 -->
```

---

## 부록: 레벨별 면접 질문 Quick Reference

### L4 (Mid) 핵심 질문

| 주제 | 질문 |
|------|------|
| 테스트 | blocTest의 build/act/expect 역할을 설명하세요 |
| 테스트 | Widget Test에서 pump vs pumpAndSettle 차이는? |
| 보안 | Access Token을 SharedPreferences에 저장하면 안 되는 이유는? |
| CI/CD | GitHub Actions 워크플로우의 기본 구조(trigger, jobs, steps)를 설명하세요 |
| 운영 | Crash-free Rate란 무엇이고, 목표값은? |
| 의존성 | `^1.2.3`의 의미와 허용 범위를 설명하세요 |

### L5 (Senior) 핵심 질문

| 주제 | 질문 |
|------|------|
| 테스트 | Property-based Testing과 Unit Test의 차이를 설명하세요 |
| 테스트 | 테스트 커버리지 80%와 Mutation Testing Kill Rate 80%의 차이는? |
| 보안 | Certificate Pinning의 원리와 한계를 설명하세요 |
| 보안 | PKCE 플로우의 각 단계를 설명하세요 |
| CI/CD | Shorebird OTA로 할 수 있는 것과 없는 것은? |
| 운영 | SLI/SLO/SLA의 차이를 실제 예시로 설명하세요 |
| 운영 | 인시던트 P1 발생 시 대응 절차를 설명하세요 |

### L6 (Staff) 핵심 질문

| 주제 | 질문 |
|------|------|
| 테스트 | Contract Testing이 MSA 환경에서 필요한 이유를 설명하세요 |
| 보안 | RASP(Runtime Application Self-Protection)의 동작 원리를 설명하세요 |
| CI/CD | Canary Release에서 롤백 판단 기준을 어떻게 설정하시겠습니까? |
| 운영 | App Health Score를 정의한다면 어떤 지표를 포함하시겠습니까? |
| 운영 | 포스트모템(Post-mortem) 문화를 팀에 도입하는 방법을 설명하세요 |
| 협업 | Git Flow vs Trunk-based Development 선택 기준을 설명하세요 |
