# Flutter 고급 CI/CD 가이드 (시니어)

> 10년차+ 시니어 개발자를 위한 프로덕션 수준 CI/CD 전략과 고급 배포 기법을 다룹니다.

## 목차

1. [Trunk-based Development](#1-trunk-based-development)
2. [Feature Flag 기반 배포](#2-feature-flag-기반-배포)
3. [A/B 테스트 파이프라인](#3-ab-테스트-파이프라인)
4. [Canary Release & Blue-Green Deployment](#4-canary-release--blue-green-deployment)
5. [배포 자동화 심화](#5-배포-자동화-심화)
6. [빌드 캐시 최적화](#6-빌드-캐시-최적화)
7. [모노레포 CI 전략](#7-모노레포-ci-전략)
8. [릴리즈 트레인 관리](#8-릴리즈-트레인-관리)
9. [성능 회귀 감지 자동화](#9-성능-회귀-감지-자동화)
10. [Infrastructure as Code](#10-infrastructure-as-code)

---

## 1. Trunk-based Development

Trunk-based Development는 모든 개발자가 단일 브랜치(trunk/main)에 자주 머지하는 개발 방식으로, CI/CD 파이프라인과 궁합이 좋습니다.

### 1.1 브랜치 전략

```
┌──────────────────────────────────────────────────────────┐
│                    Trunk-based Flow                       │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  main ●──●──●──●──●──●──●──●──●  (항상 배포 가능)        │
│          ╲  ╱  ╲  ╱                                      │
│           ●─●    ●─●  (Short-lived branches)            │
│          feature-1  feature-2                            │
│                                                           │
│  규칙:                                                    │
│  - Feature 브랜치 수명: < 2일                             │
│  - 일일 1회 이상 main 머지                                │
│  - Feature Flag로 미완성 기능 숨김                        │
│  - CI 통과 후 즉시 머지                                   │
└──────────────────────────────────────────────────────────┘
```

### 1.2 Branch Protection Rules

```yaml
# .github/branch-protection.yml
main:
  required_status_checks:
    strict: true
    contexts:
      - analyze
      - test
      - build-android
      - build-ios

  required_pull_request_reviews:
    required_approving_review_count: 1
    dismiss_stale_reviews: true
    require_code_owner_reviews: true

  enforce_admins: true
  required_linear_history: true
  allow_force_pushes: false
  allow_deletions: false

  required_signatures: true  # Signed commits
```

### 1.3 Pre-merge CI Pipeline

```yaml
# .github/workflows/pre-merge.yml
name: Pre-merge Checks

on:
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # 1. 빠른 피드백을 위한 병렬 실행
  quick-checks:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # 전체 히스토리 (변경 파일 감지)

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'
          cache: true

      # 변경된 파일만 분석
      - name: Get changed files
        id: changed-files
        uses: tj-actions/changed-files@v44
        with:
          files: |
            lib/**/*.dart
            test/**/*.dart

      - name: Analyze changed files only
        if: steps.changed-files.outputs.any_changed == 'true'
        run: |
          flutter analyze ${{ steps.changed-files.outputs.all_changed_files }}

      - name: Check formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Run unit tests
        run: flutter test --coverage --reporter=expanded

      - name: Coverage check
        uses: VeryGoodOpenSource/very_good_coverage@v3
        with:
          path: coverage/lcov.info
          min_coverage: 80
          exclude: '**/*.g.dart **/*.freezed.dart'

  # 2. 영향도 분석
  impact-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Analyze dependency graph
        run: |
          # Melos를 사용한 영향받는 패키지 파악
          melos exec --depends-on=changed -- flutter test

      - name: Comment impact on PR
        uses: actions/github-script@v7
        with:
          script: |
            const impactedPackages = process.env.IMPACTED_PACKAGES.split(',');
            const comment = `## 📦 영향받는 패키지\n\n${impactedPackages.map(p => `- ${p}`).join('\n')}`;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });

  # 3. 통합 테스트 (병렬)
  integration-tests:
    runs-on: macos-14
    strategy:
      matrix:
        device: [iPhone-15, Pixel-7]
    steps:
      - uses: actions/checkout@v4

      - name: Run integration tests
        run: |
          flutter drive \
            --driver=test_driver/integration_test.dart \
            --target=integration_test/app_test.dart \
            -d ${{ matrix.device }}
```

### 1.4 Post-merge CD Pipeline

```yaml
# .github/workflows/post-merge.yml
name: Post-merge Deploy

on:
  push:
    branches: [main]

jobs:
  # 자동 버전 태깅
  tag-version:
    runs-on: ubuntu-latest
    outputs:
      new_version: ${{ steps.version.outputs.new_version }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Semantic versioning
        id: version
        uses: paulhatch/semantic-version@v5.4.0
        with:
          tag_prefix: "v"
          major_pattern: "(BREAKING CHANGE:)"
          minor_pattern: "(feat:)"
          version_format: "${major}.${minor}.${patch}"

      - name: Create tag
        run: |
          git tag v${{ steps.version.outputs.new_version }}
          git push origin v${{ steps.version.outputs.new_version }}

  # Feature Flag 기반 배포
  deploy-with-flags:
    needs: tag-version
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Build with feature flags
        env:
          FF_NEW_CHECKOUT: ${{ secrets.FF_NEW_CHECKOUT }}
          FF_AI_RECOMMENDATIONS: ${{ secrets.FF_AI_RECOMMENDATIONS }}
        run: |
          flutter build apk \
            --dart-define=FF_NEW_CHECKOUT=$FF_NEW_CHECKOUT \
            --dart-define=FF_AI_RECOMMENDATIONS=$FF_AI_RECOMMENDATIONS

      - name: Deploy to internal track
        run: fastlane android internal
```

---

## 2. Feature Flag 기반 배포

Feature Flag를 활용하면 코드 배포와 기능 출시를 분리할 수 있습니다.

### 2.1 LaunchDarkly 통합

```yaml
# pubspec.yaml
dependencies:
  launchdarkly_flutter_client_sdk: ^5.2.0
```

```dart
// lib/core/feature_flags/launchdarkly_service.dart
import 'package:launchdarkly_flutter_client_sdk/launchdarkly_flutter_client_sdk.dart';

class LaunchDarklyService {
  static final LaunchDarklyService _instance = LaunchDarklyService._();
  factory LaunchDarklyService() => _instance;
  LaunchDarklyService._();

  late LDClient _client;
  bool _initialized = false;

  Future<void> initialize({
    required String mobileKey,
    required String userId,
    Map<String, dynamic>? userAttributes,
  }) async {
    if (_initialized) return;

    final context = LDContextBuilder()
        .kind('user', userId)
        .name(userAttributes?['name'])
        .email(userAttributes?['email'])
        .set('subscription', LDValue.ofString(userAttributes?['subscription']))
        .set('platform', LDValue.ofString(Platform.operatingSystem))
        .build();

    final config = LDConfig(
      mobileKey,
      AutoEnvAttributes.enabled,
      events: LDEventsConfig(
        capacity: 100,
        flushIntervalMs: 30000,
      ),
      serviceEndpoints: LDServiceEndpoints.defaults(),
    );

    _client = LDClient(config, context);
    await _client.start();
    _initialized = true;
  }

  /// Boolean flag
  bool getBoolFlag(String key, {bool defaultValue = false}) {
    if (!_initialized) return defaultValue;
    return _client.boolVariation(key, defaultValue);
  }

  /// String flag
  String getStringFlag(String key, {String defaultValue = ''}) {
    if (!_initialized) return defaultValue;
    return _client.stringVariation(key, defaultValue);
  }

  /// JSON flag
  Map<String, dynamic> getJsonFlag(String key, {Map<String, dynamic>? defaultValue}) {
    if (!_initialized) return defaultValue ?? {};
    final value = _client.jsonVariation(key, LDValue.ofNull());
    return value.getType() == LDValueType.object
        ? value.toMap()
        : defaultValue ?? {};
  }

  /// Number flag (for gradual rollout percentage)
  int getIntFlag(String key, {int defaultValue = 0}) {
    if (!_initialized) return defaultValue;
    return _client.intVariation(key, defaultValue);
  }

  /// 실시간 변경 감지
  Stream<LDFlagValueChangeEvent> listenToFlag(String flagKey) {
    return _client.flagChanges(flagKey);
  }

  /// 모든 flag 변경 감지
  Stream<void> get onAnyFlagChanged => _client.allFlagsChanges();

  /// Flag 평가 이유 (디버깅용)
  LDEvaluationDetail<bool> getBoolFlagDetail(String key) {
    return _client.boolVariationDetail(key, false);
  }

  /// Track custom event
  void track(String eventName, {Map<String, dynamic>? data}) {
    if (!_initialized) return;
    _client.track(eventName, data: LDValue.buildObject()
      ..addString('timestamp', DateTime.now().toIso8601String())
      ..addAll(data ?? {}));
  }

  /// Flush events immediately
  Future<void> flush() async {
    await _client.flush();
  }

  void dispose() {
    _client.close();
  }
}
```

### 2.2 Firebase Remote Config 심화

```dart
// lib/core/feature_flags/remote_config_service.dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._();

  late FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    _remoteConfig = FirebaseRemoteConfig.instance;

    // 개발 환경 설정
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: kDebugMode
          ? const Duration(minutes: 1)  // 개발: 1분
          : const Duration(hours: 1),   // 프로덕션: 1시간
    ));

    // 기본값 설정
    await _remoteConfig.setDefaults({
      // Feature Flags
      'ff_new_checkout': false,
      'ff_ai_recommendations': false,
      'ff_dark_mode_v2': false,

      // Gradual Rollout
      'rollout_new_checkout_percentage': 0,

      // Configuration
      'api_timeout_seconds': 30,
      'max_retry_count': 3,
      'cache_ttl_minutes': 60,

      // Kill Switch
      'feature_payment_enabled': true,
      'feature_chat_enabled': true,

      // A/B Test Variants
      'ab_test_checkout_variant': 'control',

      // JSON Configuration
      'api_endpoints': jsonEncode({
        'prod': 'https://api.example.com',
        'staging': 'https://api-staging.example.com',
      }),
    });

    // 초기 fetch
    await _remoteConfig.fetchAndActivate();

    // 실시간 업데이트 리스닝
    _remoteConfig.onConfigUpdated.listen((event) async {
      await _remoteConfig.activate();
      debugPrint('[RemoteConfig] Config updated: ${event.updatedKeys}');
    });

    _initialized = true;
  }

  // Feature Flags
  bool isFeatureEnabled(String key) => _remoteConfig.getBool('ff_$key');

  // Gradual Rollout
  bool shouldEnableForUser(String featureName, String userId) {
    final rolloutPercentage = _remoteConfig.getInt('rollout_${featureName}_percentage');
    final userBucket = _getUserBucket(userId);
    return userBucket < rolloutPercentage;
  }

  int _getUserBucket(String userId) {
    return userId.hashCode.abs() % 100;
  }

  // Kill Switch
  bool isServiceEnabled(String serviceName) {
    return _remoteConfig.getBool('feature_${serviceName}_enabled');
  }

  // Configuration Values
  int getInt(String key) => _remoteConfig.getInt(key);
  String getString(String key) => _remoteConfig.getString(key);
  double getDouble(String key) => _remoteConfig.getDouble(key);

  Map<String, dynamic> getJson(String key) {
    try {
      return jsonDecode(_remoteConfig.getString(key));
    } catch (e) {
      return {};
    }
  }

  // A/B Test Variant
  String getExperimentVariant(String experimentName) {
    return _remoteConfig.getString('ab_test_${experimentName}_variant');
  }

  // Force refresh (for testing)
  Future<void> forceRefresh() async {
    await _remoteConfig.fetchAndActivate();
  }

  // Get all values (debugging)
  Map<String, RemoteConfigValue> getAllValues() {
    return _remoteConfig.getAll();
  }
}
```

### 2.3 Feature Flag 기반 UI 컴포넌트

```dart
// lib/core/feature_flags/feature_gate.dart
class FeatureGate extends StatelessWidget {
  final String flagKey;
  final Widget enabledChild;
  final Widget? disabledChild;
  final bool Function()? customEvaluator;

  const FeatureGate({
    super.key,
    required this.flagKey,
    required this.enabledChild,
    this.disabledChild,
    this.customEvaluator,
  });

  @override
  Widget build(BuildContext context) {
    final remoteConfig = RemoteConfigService();
    final isEnabled = customEvaluator?.call()
        ?? remoteConfig.isFeatureEnabled(flagKey);

    return isEnabled ? enabledChild : (disabledChild ?? const SizedBox.shrink());
  }
}

// 사용 예시
class CheckoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      flagKey: 'new_checkout',
      enabledChild: const NewCheckoutFlow(),
      disabledChild: const LegacyCheckoutFlow(),
    );
  }
}
```

---

## 3. A/B 테스트 파이프라인

### 3.1 A/B 테스트 아키텍처

```
┌──────────────────────────────────────────────────────────┐
│                   A/B Test Pipeline                       │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  1. User Assignment                                       │
│     ├─ 50% → Variant A (Control)                         │
│     └─ 50% → Variant B (Treatment)                       │
│                                                           │
│  2. Feature Rendering                                     │
│     ├─ Variant A: Legacy UI                              │
│     └─ Variant B: New UI                                 │
│                                                           │
│  3. Event Tracking                                        │
│     ├─ Conversion Rate                                   │
│     ├─ Time on Page                                      │
│     ├─ Click Through Rate                                │
│     └─ Revenue per User                                  │
│                                                           │
│  4. Analysis                                              │
│     └─ Statistical Significance (p < 0.05)               │
│                                                           │
│  5. Decision                                              │
│     ├─ Winner → Roll out to 100%                         │
│     └─ No difference → Keep control                      │
└──────────────────────────────────────────────────────────┘
```

### 3.2 A/B 테스트 서비스

```dart
// lib/core/ab_testing/ab_test_service.dart
class ABTestService {
  final FirebaseAnalytics _analytics;
  final RemoteConfigService _remoteConfig;
  final SharedPreferences _prefs;

  ABTestService(this._analytics, this._remoteConfig, this._prefs);

  /// 사용자를 실험군에 할당
  Future<String> assignVariant(String experimentName) async {
    final cacheKey = 'ab_test_$experimentName';

    // 이미 할당된 경우 캐시된 variant 반환 (sticky assignment)
    final cachedVariant = _prefs.getString(cacheKey);
    if (cachedVariant != null) {
      return cachedVariant;
    }

    // Remote Config에서 variant 가져오기
    final variant = _remoteConfig.getExperimentVariant(experimentName);

    // 할당 저장 (사용자가 실험 도중 variant 변경되지 않도록)
    await _prefs.setString(cacheKey, variant);

    // Firebase Analytics에 기록
    await _analytics.setUserProperty(
      name: 'ab_${experimentName}',
      value: variant,
    );

    return variant;
  }

  /// 실험 이벤트 추적
  Future<void> trackExperimentEvent({
    required String experimentName,
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    final variant = await assignVariant(experimentName);

    await _analytics.logEvent(
      name: eventName,
      parameters: {
        'experiment_name': experimentName,
        'variant': variant,
        ...?parameters,
      },
    );
  }

  /// 전환 이벤트 추적
  Future<void> trackConversion({
    required String experimentName,
    double? revenue,
  }) async {
    await trackExperimentEvent(
      experimentName: experimentName,
      eventName: 'ab_test_conversion',
      parameters: {
        if (revenue != null) 'revenue': revenue,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
```

### 3.3 A/B 테스트 위젯

```dart
// lib/core/ab_testing/ab_test_widget.dart
class ABTestWidget extends StatefulWidget {
  final String experimentName;
  final Map<String, Widget> variants;
  final Widget? fallback;

  const ABTestWidget({
    super.key,
    required this.experimentName,
    required this.variants,
    this.fallback,
  });

  @override
  State<ABTestWidget> createState() => _ABTestWidgetState();
}

class _ABTestWidgetState extends State<ABTestWidget> {
  String? _assignedVariant;

  @override
  void initState() {
    super.initState();
    _assignVariant();
  }

  Future<void> _assignVariant() async {
    final abTest = GetIt.I<ABTestService>();
    final variant = await abTest.assignVariant(widget.experimentName);

    if (mounted) {
      setState(() {
        _assignedVariant = variant;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_assignedVariant == null) {
      return widget.fallback ?? const CircularProgressIndicator();
    }

    return widget.variants[_assignedVariant]
        ?? widget.variants['control']
        ?? const SizedBox.shrink();
  }
}

// 사용 예시
class ProductCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ABTestWidget(
      experimentName: 'product_card_layout',
      variants: {
        'control': const ProductCardV1(),
        'variant_a': const ProductCardV2(),
        'variant_b': const ProductCardV3(),
      },
    );
  }
}
```

### 3.4 BigQuery로 분석 데이터 전송

```yaml
# Cloud Functions (Node.js)
# functions/src/exportAnalyticsToBigQuery.ts
import * as functions from 'firebase-functions';
import { BigQuery } from '@google-cloud/bigquery';

export const exportABTestResults = functions.pubsub
  .schedule('0 2 * * *')  // 매일 새벽 2시
  .onRun(async (context) => {
    const bigquery = new BigQuery();

    const query = `
      SELECT
        event_params.value.string_value AS experiment_name,
        user_properties.value.string_value AS variant,
        COUNT(*) AS event_count,
        COUNTIF(event_name = 'ab_test_conversion') AS conversions,
        AVG(IF(event_name = 'ab_test_conversion' AND event_params.key = 'revenue',
          event_params.value.double_value, NULL)) AS avg_revenue
      FROM
        \`project.analytics_123456789.events_*\`
      WHERE
        _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))
        AND event_params.key = 'experiment_name'
      GROUP BY
        experiment_name, variant
    `;

    const [rows] = await bigquery.query(query);
    console.log('A/B Test Results:', rows);

    // 통계적 유의성 검정 (Chi-squared test)
    for (const row of rows) {
      const pValue = calculatePValue(row);
      if (pValue < 0.05) {
        // Slack 알림
        await sendSlackNotification({
          text: `🎯 A/B Test "${row.experiment_name}" has significant results!`,
          attachments: [{
            fields: [
              { title: 'Variant', value: row.variant, short: true },
              { title: 'Conversions', value: row.conversions, short: true },
              { title: 'P-value', value: pValue.toFixed(4), short: true },
            ]
          }]
        });
      }
    }
  });
```

---

## 4. Canary Release & Blue-Green Deployment

### 4.1 Canary Release (단계적 출시)

```yaml
# Play Store Canary Release
# fastlane/Fastfile (Android)
lane :deploy_canary do
  # 1단계: Internal (1% 사용자)
  upload_to_play_store(
    track: 'internal',
    rollout: '0.01'  # 1%
  )

  # 24시간 모니터링 후 자동 진행
  sleep 86400

  # Crashlytics 메트릭 확인
  crash_rate = check_crash_rate()
  if crash_rate > 0.01
    rollback_release()
    send_alert("Canary release failed: High crash rate")
    next
  end

  # 2단계: Alpha (10% 사용자)
  upload_to_play_store(
    track: 'alpha',
    rollout: '0.10'
  )

  sleep 86400

  # 3단계: Beta (50% 사용자)
  upload_to_play_store(
    track: 'beta',
    rollout: '0.50'
  )

  sleep 172800  # 48시간

  # 4단계: Production (100%)
  upload_to_play_store(
    track: 'production',
    rollout: '1.0'
  )
end

def check_crash_rate
  # Firebase Crashlytics API 호출
  # crash_free_users < 99.5% 이면 롤백
end
```

### 4.2 App Store Phased Release

```ruby
# fastlane/Fastfile (iOS)
lane :deploy_phased do
  # TestFlight 배포
  upload_to_testflight(
    skip_waiting_for_build_processing: false,
    distribute_external: true,
    groups: ['beta-testers']
  )

  # App Store 배포 with phased release
  upload_to_app_store(
    submit_for_review: true,
    automatic_release: false,
    phased_release: true,  # 7일에 걸쳐 단계적 출시
    submission_information: {
      add_id_info_uses_idfa: false
    }
  )
end
```

### 4.3 Shorebird Code Push (OTA 업데이트)

```yaml
# shorebird.yaml
app_id: my-flutter-app
flavors:
  production:
    app_id: com.example.app

# Shorebird 설치
# brew tap shorebirdtech/tap
# brew install shorebird
```

```bash
#!/bin/bash
# scripts/deploy_code_push.sh

# Shorebird로 Dart 코드만 즉시 배포 (네이티브 변경 없이)
shorebird release android \
  --flutter-version=3.27.0 \
  --force

# 릴리즈 노트
shorebird releases describe \
  --release-version=1.2.3+45

# Patch 배포 (긴급 버그 수정)
shorebird patch android \
  --release-version=1.2.3+45

# 사용자에게 즉시 반영 (앱 재시작 불필요)
# 다음 앱 실행 시 자동 다운로드 및 적용
```

```dart
// lib/core/code_push/shorebird_updater.dart
import 'package:shorebird_code_push/shorebird_code_push.dart';

class ShorebirdUpdater {
  final ShorebirdCodePush _shorebird = ShorebirdCodePush();

  Future<void> checkForUpdates() async {
    final isUpdateAvailable = await _shorebird.isNewPatchAvailableForDownload();

    if (isUpdateAvailable) {
      // 백그라운드에서 다운로드
      await _shorebird.downloadUpdateIfAvailable();

      // 사용자에게 알림
      showUpdateSnackbar();
    }
  }

  void showUpdateSnackbar() {
    // 사용자에게 "앱을 재시작하면 새 버전이 적용됩니다" 안내
  }
}
```

### 4.4 Blue-Green Deployment (서버 환경)

```yaml
# Backend API Blue-Green Deployment
# kubernetes/deployment.yaml
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  selector:
    app: api
    version: blue  # 트래픽은 blue로
  ports:
  - port: 80
---
# Blue 환경
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
      version: blue
  template:
    metadata:
      labels:
        app: api
        version: blue
    spec:
      containers:
      - name: api
        image: myapi:v1.2.3
---
# Green 환경 (신규 배포)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
      version: green
  template:
    metadata:
      labels:
        app: api
        version: green
    spec:
      containers:
      - name: api
        image: myapi:v1.2.4  # 새 버전
```

```bash
# Green으로 트래픽 전환
kubectl patch service api-service -p '{"spec":{"selector":{"version":"green"}}}'

# 문제 발생 시 즉시 Blue로 롤백
kubectl patch service api-service -p '{"spec":{"selector":{"version":"blue"}}}'
```

---

## 5. 배포 자동화 심화

### 5.1 Fastlane Match 심화 (인증서 관리)

```ruby
# fastlane/Matchfile
git_url("git@github.com:company/certificates.git")
git_branch("main")

storage_mode("git")
type("appstore")

app_identifier([
  "com.example.app",
  "com.example.app.dev",
  "com.example.app.staging"
])

username("apple-id@example.com")
team_id("TEAM_ID_123")

readonly(is_ci)  # CI에서는 readonly

# 인증서 암호화
encryption_password(ENV["MATCH_PASSWORD"])
```

```bash
# 초기 설정 (로컬에서 한 번만)
fastlane match appstore --readonly false

# CI에서 사용
export MATCH_PASSWORD="$MATCH_ENCRYPTION_PASSWORD"
fastlane match appstore --readonly
```

### 5.2 Multi-target 빌드 자동화

```ruby
# fastlane/Fastfile
platform :ios do
  desc "Build all targets in parallel"
  lane :build_all_targets do
    targets = ['App', 'NotificationService', 'ShareExtension', 'WidgetExtension']

    # 병렬 빌드
    threads = targets.map do |target|
      Thread.new do
        build_target(target)
      end
    end

    threads.each(&:join)
  end

  private_lane :build_target do |options|
    target = options[:target]

    gym(
      scheme: target,
      export_method: 'app-store',
      output_directory: "./build/#{target}",
      buildlog_path: "./logs/#{target}",
      xcargs: "-parallelizeTargets"
    )
  end
end
```

### 5.3 Firebase App Distribution with Tester Groups

```ruby
# fastlane/Fastfile
lane :distribute_to_groups do |options|
  # 빌드
  build_android_apk

  # 여러 그룹에 동시 배포
  groups = ['qa-team', 'product-managers', 'stakeholders']

  groups.each do |group|
    firebase_app_distribution(
      app: ENV["FIREBASE_ANDROID_APP_ID"],
      apk_path: "build/app/outputs/apk/release/app-release.apk",
      groups: group,
      release_notes: generate_release_notes(group),
      firebase_cli_token: ENV["FIREBASE_TOKEN"]
    )
  end

  # Slack 알림
  slack(
    message: "✅ Build distributed to #{groups.join(', ')}",
    channel: "#releases",
    slack_url: ENV["SLACK_WEBHOOK_URL"]
  )
end

def generate_release_notes(group)
  # 그룹별로 맞춤 릴리즈 노트
  base_notes = changelog_from_git_commits(
    commits_count: 10,
    pretty: "- %s"
  )

  case group
  when 'qa-team'
    "🧪 QA Testing\n\n#{base_notes}\n\nTest Focus:\n- Payment flow\n- New checkout UI"
  when 'product-managers'
    "📊 Product Review\n\n#{base_notes}\n\nPlease review:\n- User onboarding\n- Analytics events"
  else
    base_notes
  end
end
```

---

## 6. 빌드 캐시 최적화

### 6.1 GitHub Actions 캐시 전략

```yaml
# .github/workflows/optimized-build.yml
name: Optimized Build

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: macos-14

    steps:
      - uses: actions/checkout@v4

      # 1. Flutter SDK 캐시
      - name: Cache Flutter SDK
        uses: actions/cache@v4
        with:
          path: |
            /Users/runner/hostedtoolcache/flutter
            ${{ env.FLUTTER_HOME }}
          key: flutter-${{ runner.os }}-${{ hashFiles('**/pubspec.lock') }}
          restore-keys: |
            flutter-${{ runner.os }}-

      # 2. Pub cache
      - name: Cache pub dependencies
        uses: actions/cache@v4
        with:
          path: |
            ~/.pub-cache
            ${{ env.PUB_CACHE }}
          key: pub-${{ runner.os }}-${{ hashFiles('**/pubspec.lock') }}
          restore-keys: |
            pub-${{ runner.os }}-

      # 3. Gradle cache
      - name: Cache Gradle
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
            android/.gradle
          key: gradle-${{ runner.os }}-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
          restore-keys: |
            gradle-${{ runner.os }}-

      # 4. CocoaPods cache
      - name: Cache CocoaPods
        uses: actions/cache@v4
        with:
          path: |
            ios/Pods
            ~/Library/Caches/CocoaPods
          key: pods-${{ runner.os }}-${{ hashFiles('ios/Podfile.lock') }}
          restore-keys: |
            pods-${{ runner.os }}-

      # 5. Build cache (Xcode DerivedData)
      - name: Cache Xcode DerivedData
        uses: actions/cache@v4
        with:
          path: ~/Library/Developer/Xcode/DerivedData
          key: xcode-derived-${{ runner.os }}-${{ hashFiles('ios/**/*.xcodeproj') }}
          restore-keys: |
            xcode-derived-${{ runner.os }}-

      # 6. Pre-compiled dependencies (custom)
      - name: Cache pre-built dependencies
        uses: actions/cache@v4
        with:
          path: |
            build/app/intermediates
            build/ios/archive
          key: prebuilt-${{ runner.os }}-${{ github.sha }}
          restore-keys: |
            prebuilt-${{ runner.os }}-

      - name: Build
        run: |
          flutter build apk --release --cache-dir=build/cache
```

### 6.2 Codemagic 빌드 최적화

```yaml
# codemagic.yaml
workflows:
  optimized-android-build:
    name: Optimized Android Build
    instance_type: mac_mini_m2  # M2 Mac (빠름)
    max_build_duration: 60

    cache:
      cache_paths:
        - $HOME/.gradle/caches
        - $FLUTTER_ROOT/.pub-cache
        - $HOME/Library/Caches/CocoaPods
        - android/.gradle
        - ios/Pods

    environment:
      groups:
        - production
      vars:
        FLUTTER_VERSION: "3.27.0"

      # 빌드 속도 향상
      flutter: $FLUTTER_VERSION
      xcode: latest
      cocoapods: default
      java: 17

    scripts:
      - name: Install dependencies (with cache)
        script: |
          # Pub cache 활용
          flutter pub get --offline || flutter pub get

      - name: Build with Gradle cache
        script: |
          cd android
          ./gradlew assembleRelease \
            --build-cache \
            --configuration-cache \
            --parallel \
            --max-workers=4

      - name: Upload to Play Store
        script: |
          # Fastlane 사용
          bundle exec fastlane android internal
```

### 6.3 로컬 빌드 캐시 최적화

```bash
# scripts/build_with_cache.sh
#!/bin/bash

export FLUTTER_BUILD_CACHE_DIR="$HOME/.flutter_build_cache"
export GRADLE_USER_HOME="$HOME/.gradle"
export PUB_CACHE="$HOME/.pub-cache"

# Gradle daemon 활성화 (빌드 속도 2-3배)
echo "org.gradle.daemon=true" >> android/gradle.properties
echo "org.gradle.parallel=true" >> android/gradle.properties
echo "org.gradle.caching=true" >> android/gradle.properties
echo "org.gradle.configureondemand=true" >> android/gradle.properties

# Flutter 빌드
flutter build apk \
  --release \
  --cache-dir="$FLUTTER_BUILD_CACHE_DIR" \
  --target-platform android-arm64

# 빌드 시간 측정
echo "Build completed in: $SECONDS seconds"
```

---

## 7. 모노레포 CI 전략

### 7.1 Melos 기반 영향 범위 분석

```yaml
# melos.yaml
name: flutter_monorepo
repository: https://github.com/company/flutter-monorepo

packages:
  - apps/**
  - packages/**
  - features/**

command:
  version:
    linkToCommits: true
    workspaceChangelog: true

  bootstrap:
    runPubGetInParallel: true
    runPubGetOffline: false

scripts:
  # 변경된 패키지만 분석
  analyze:changed:
    run: melos exec --diff --fail-fast -- flutter analyze
    description: Analyze only changed packages

  # 변경된 패키지만 테스트
  test:changed:
    run: melos exec --diff --fail-fast -- flutter test
    description: Test only changed packages

  # 영향받는 패키지 찾기
  list:affected:
    run: melos list --diff --depends-on
    description: List packages affected by changes

  # 전체 빌드
  build:all:
    run: melos exec --fail-fast -- flutter build apk
    description: Build all apps
```

### 7.2 선택적 CI 실행

```yaml
# .github/workflows/monorepo-ci.yml
name: Monorepo CI

on:
  pull_request:
    branches: [main]

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      changed_packages: ${{ steps.changes.outputs.packages }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Melos
        run: |
          flutter pub global activate melos
          melos bootstrap

      - name: Detect changed packages
        id: changes
        run: |
          CHANGED=$(melos list --diff --json)
          echo "packages=$CHANGED" >> $GITHUB_OUTPUT

  test-changed:
    needs: detect-changes
    if: needs.detect-changes.outputs.changed_packages != '[]'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        package: ${{ fromJSON(needs.detect-changes.outputs.changed_packages) }}
    steps:
      - uses: actions/checkout@v4

      - name: Test ${{ matrix.package }}
        run: |
          cd ${{ matrix.package }}
          flutter test

  build-affected-apps:
    needs: detect-changes
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Build affected apps
        run: |
          # 영향받는 앱만 빌드
          melos exec --depends-on=changed --scope='*_app' -- flutter build apk
```

### 7.3 패키지 간 의존성 그래프

```bash
# scripts/generate_dependency_graph.sh
#!/bin/bash

# Melos로 의존성 그래프 생성
melos exec -- "echo '\$(pwd) depends on:' && grep 'path:' pubspec.yaml" > dependencies.txt

# Graphviz로 시각화
echo "digraph G {" > graph.dot
echo "  rankdir=LR;" >> graph.dot

# 각 패키지의 의존성 파싱
for dir in packages/* features/* apps/*; do
  if [ -f "$dir/pubspec.yaml" ]; then
    pkg=$(basename $dir)
    deps=$(grep "path:" $dir/pubspec.yaml | awk '{print $2}' | tr -d "'\"")

    for dep in $deps; do
      dep_name=$(basename $dep)
      echo "  \"$pkg\" -> \"$dep_name\";" >> graph.dot
    done
  fi
done

echo "}" >> graph.dot

# PNG 생성
dot -Tpng graph.dot -o dependency_graph.png
```

---

## 8. 릴리즈 트레인 관리

### 8.1 릴리즈 스케줄

```
┌──────────────────────────────────────────────────────────┐
│               Release Train Schedule                      │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  Week 1: Development                                      │
│    ├─ Feature development                                │
│    ├─ Unit tests                                         │
│    └─ Code review                                        │
│                                                           │
│  Week 2: Integration                                      │
│    ├─ Feature freeze (Monday)                            │
│    ├─ Integration tests                                  │
│    ├─ QA testing                                         │
│    └─ Bug fixes only                                     │
│                                                           │
│  Week 3: Stabilization                                    │
│    ├─ Code freeze (Monday)                               │
│    ├─ Release candidate (RC1)                            │
│    ├─ TestFlight / Internal track                        │
│    └─ Critical fixes only                                │
│                                                           │
│  Week 4: Production                                       │
│    ├─ Production release (Monday)                        │
│    ├─ Phased rollout (7 days)                            │
│    ├─ Monitoring & hotfixes                              │
│    └─ Post-mortem (Friday)                               │
└──────────────────────────────────────────────────────────┘
```

### 8.2 자동 릴리즈 브랜치 생성

```bash
# scripts/create_release_branch.sh
#!/bin/bash

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "Usage: ./create_release_branch.sh 1.2.3"
  exit 1
fi

# main에서 release 브랜치 생성
git checkout main
git pull origin main
git checkout -b release/$VERSION

# 버전 업데이트
sed -i '' "s/^version: .*/version: $VERSION+\$(date +%s)/" pubspec.yaml

# Changelog 생성
cat > CHANGELOG_$VERSION.md << EOF
# Release $VERSION

## Features
$(git log --pretty=format:"- %s" --grep="feat:" main..HEAD)

## Bug Fixes
$(git log --pretty=format:"- %s" --grep="fix:" main..HEAD)

## Breaking Changes
$(git log --pretty=format:"- %s" --grep="BREAKING" main..HEAD)
EOF

# 커밋 및 푸시
git add pubspec.yaml CHANGELOG_$VERSION.md
git commit -m "chore: prepare release $VERSION"
git push origin release/$VERSION

# PR 생성
gh pr create \
  --title "Release $VERSION" \
  --body "$(cat CHANGELOG_$VERSION.md)" \
  --base main \
  --head release/$VERSION \
  --label "release"
```

### 8.3 릴리즈 자동화 워크플로우

```yaml
# .github/workflows/release-train.yml
name: Release Train

on:
  schedule:
    - cron: '0 9 * * MON'  # 매주 월요일 오전 9시
  workflow_dispatch:
    inputs:
      version:
        description: 'Release version (e.g., 1.2.3)'
        required: true

jobs:
  create-release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Determine version
        id: version
        run: |
          if [ -n "${{ github.event.inputs.version }}" ]; then
            VERSION="${{ github.event.inputs.version }}"
          else
            # Semantic versioning 자동 계산
            LATEST_TAG=$(git describe --tags --abbrev=0)
            VERSION=$(echo $LATEST_TAG | awk -F. '{$NF = $NF + 1;} 1' | sed 's/ /./g')
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT

      - name: Create release branch
        run: |
          ./scripts/create_release_branch.sh ${{ steps.version.outputs.version }}

      - name: Notify team
        uses: slackapi/slack-github-action@v1.27.0
        with:
          payload: |
            {
              "text": "🚂 Release train departed for version ${{ steps.version.outputs.version }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "Release ${{ steps.version.outputs.version }} is now in stabilization phase.\n\n⚠️ *Code freeze* in effect. Only critical fixes allowed."
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 9. 성능 회귀 감지 자동화

### 9.1 벤치마크 자동 실행

```dart
// test/performance/benchmark_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Homepage render performance', (tester) async {
    await tester.pumpWidget(const MyApp());

    // 렌더링 성능 측정
    await binding.traceAction(
      () async {
        await tester.pumpAndSettle();
        await tester.tap(find.text('Products'));
        await tester.pumpAndSettle();
      },
      reportKey: 'homepage_render',
    );
  });

  testWidgets('Scroll performance', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final listFinder = find.byType(ListView);

    await binding.traceAction(
      () async {
        await tester.fling(listFinder, const Offset(0, -500), 10000);
        await tester.pumpAndSettle();
      },
      reportKey: 'list_scroll',
    );
  });
}
```

### 9.2 성능 메트릭 수집

```yaml
# .github/workflows/performance-regression.yml
name: Performance Regression

on:
  pull_request:
    branches: [main]

jobs:
  benchmark:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'

      - name: Run performance tests
        run: |
          flutter drive \
            --driver=test_driver/perf_driver.dart \
            --target=integration_test/perf_test.dart \
            --profile \
            --trace-startup \
            --verbose-system-logs

      - name: Parse timeline
        run: |
          flutter pub run dev/tools/parse_timeline.dart \
            build/perf_timeline.json \
            --output=performance_metrics.json

      - name: Compare with baseline
        id: compare
        run: |
          # 이전 빌드 메트릭 다운로드
          curl -o baseline.json https://storage.googleapis.com/perf-metrics/main/baseline.json

          # 비교
          python3 scripts/compare_performance.py \
            baseline.json \
            performance_metrics.json \
            --threshold=5  # 5% 이상 느려지면 실패

      - name: Comment on PR
        if: steps.compare.outputs.regression == 'true'
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `⚠️ **Performance Regression Detected**\n\n${process.env.COMPARISON_REPORT}`
            });

      - name: Upload metrics
        if: github.ref == 'refs/heads/main'
        run: |
          # main 브랜치의 메트릭은 baseline으로 저장
          gsutil cp performance_metrics.json gs://perf-metrics/main/baseline.json
```

### 9.3 APK/IPA 크기 추적

```yaml
# .github/workflows/size-check.yml
name: APK Size Check

on:
  pull_request:
    branches: [main]

jobs:
  size-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build APK
        run: |
          flutter build apk --release --split-per-abi

      - name: Get APK size
        id: size
        run: |
          SIZE=$(du -h build/app/outputs/flutter-apk/app-arm64-v8a-release.apk | cut -f1)
          SIZE_BYTES=$(stat -f%z build/app/outputs/flutter-apk/app-arm64-v8a-release.apk)
          echo "size=$SIZE" >> $GITHUB_OUTPUT
          echo "size_bytes=$SIZE_BYTES" >> $GITHUB_OUTPUT

      - name: Compare with main
        run: |
          # main 브랜치 체크아웃
          git fetch origin main
          git checkout origin/main
          flutter build apk --release --split-per-abi

          MAIN_SIZE=$(stat -f%z build/app/outputs/flutter-apk/app-arm64-v8a-release.apk)
          DIFF=$((SIZE_BYTES - MAIN_SIZE))
          DIFF_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($DIFF / $MAIN_SIZE) * 100}")

          echo "APK size changed by $DIFF_PERCENT% ($DIFF bytes)"

          # 10% 이상 증가 시 경고
          if (( $(echo "$DIFF_PERCENT > 10" | bc -l) )); then
            echo "::error::APK size increased by more than 10%!"
            exit 1
          fi

      - name: Comment size on PR
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `📦 **APK Size Report**\n\nCurrent: ${{ steps.size.outputs.size }}\nChange: ${process.env.DIFF_PERCENT}%`
            });
```

---

## 10. Infrastructure as Code

### 10.1 Terraform로 Firebase 프로젝트 관리

```hcl
# terraform/firebase.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "terraform-state-bucket"
    prefix = "firebase"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Firebase 프로젝트
resource "google_firebase_project" "default" {
  provider = google
  project  = var.project_id
}

# Android App
resource "google_firebase_android_app" "default" {
  provider     = google-beta
  project      = var.project_id
  display_name = "My Flutter App"
  package_name = "com.example.app"
}

# iOS App
resource "google_firebase_apple_app" "default" {
  provider     = google-beta
  project      = var.project_id
  display_name = "My Flutter App"
  bundle_id    = "com.example.app"
}

# Remote Config
resource "google_firebase_remote_config_template" "default" {
  project = var.project_id

  parameters = {
    ff_new_checkout = {
      default_value = {
        value = "false"
      }
      conditional_values = {
        beta_users = {
          value = "true"
        }
      }
    }

    api_timeout_seconds = {
      default_value = {
        value = "30"
      }
    }
  }

  conditions = [{
    name = "beta_users"
    expression = "percent <= 10"
  }]
}

# App Distribution Testers
resource "google_firebase_app_distribution_group" "qa_team" {
  project      = var.project_id
  display_name = "QA Team"
}

resource "google_firebase_app_distribution_group" "beta_testers" {
  project      = var.project_id
  display_name = "Beta Testers"
}
```

### 10.2 Play Store 메타데이터 관리

```yaml
# fastlane/metadata/android/en-US/title.txt
My Awesome Flutter App

# fastlane/metadata/android/en-US/short_description.txt
The best app for productivity

# fastlane/metadata/android/en-US/full_description.txt
## Features
- Feature 1
- Feature 2
- Feature 3

## Why Choose Us?
We provide the best experience...

# fastlane/metadata/android/en-US/changelogs/45.txt
- Added new checkout flow
- Fixed payment issues
- Improved performance
```

```ruby
# fastlane/Fastfile
lane :update_metadata do
  upload_to_play_store(
    track: 'production',
    skip_upload_apk: true,
    skip_upload_aab: true,
    skip_upload_screenshots: false,
    skip_upload_images: false,
    skip_upload_metadata: false
  )
end
```

### 10.3 GitHub Actions Self-hosted Runner

```yaml
# terraform/github_runner.tf
resource "google_compute_instance" "github_runner" {
  name         = "github-actions-runner"
  machine_type = "n2-standard-8"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 100
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash

    # GitHub Runner 설치
    mkdir actions-runner && cd actions-runner
    curl -o actions-runner-linux-x64-2.313.0.tar.gz -L \
      https://github.com/actions/runner/releases/download/v2.313.0/actions-runner-linux-x64-2.313.0.tar.gz
    tar xzf ./actions-runner-linux-x64-2.313.0.tar.gz

    # 설정
    ./config.sh \
      --url https://github.com/${var.github_org}/${var.github_repo} \
      --token ${var.github_runner_token} \
      --labels self-hosted,linux,x64,flutter \
      --unattended

    # 서비스 등록
    sudo ./svc.sh install
    sudo ./svc.sh start

    # Flutter 설치
    git clone https://github.com/flutter/flutter.git -b stable
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
    flutter doctor
  EOF
}
```

---

## Best Practices

### CI/CD 성숙도 모델

| 레벨 | 특징 | 배포 주기 |
|------|------|----------|
| **Level 1: Manual** | 수동 빌드, 수동 배포 | 월 1회 |
| **Level 2: Automated Build** | 자동 빌드, 수동 배포 | 주 1회 |
| **Level 3: Continuous Integration** | 자동 빌드, 자동 테스트 | 일 1회 |
| **Level 4: Continuous Delivery** | 수동 승인 후 자동 배포 | 일 여러 번 |
| **Level 5: Continuous Deployment** | 완전 자동 배포 | 커밋마다 |

### 시니어 개발자를 위한 체크리스트

```
## Trunk-based Development
- [ ] Short-lived 브랜치 (< 2일)
- [ ] 일일 1회 이상 main 머지
- [ ] Feature Flag로 WIP 숨김
- [ ] Branch protection 설정

## Feature Flags
- [ ] LaunchDarkly 또는 Remote Config 설정
- [ ] Kill switch 구현
- [ ] Gradual rollout 전략
- [ ] A/B 테스트 인프라

## 배포 전략
- [ ] Canary release (1% → 10% → 50% → 100%)
- [ ] Phased rollout (iOS/Android)
- [ ] Blue-green deployment (Backend)
- [ ] OTA update (Shorebird)

## 성능 모니터링
- [ ] 벤치마크 자동 실행
- [ ] 성능 회귀 감지
- [ ] APK/IPA 크기 추적
- [ ] Baseline 비교

## Infrastructure as Code
- [ ] Terraform로 Firebase 관리
- [ ] Play Store 메타데이터 버전 관리
- [ ] Self-hosted runner 구성
- [ ] 환경 복제 자동화
```

---

## 참고 자료

- [Trunk Based Development](https://trunkbaseddevelopment.com/)
- [LaunchDarkly Flutter SDK](https://docs.launchdarkly.com/sdk/client-side/flutter)
- [Firebase Remote Config](https://firebase.google.com/docs/remote-config)
- [Shorebird Code Push](https://shorebird.dev/)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GitHub Actions Self-hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
