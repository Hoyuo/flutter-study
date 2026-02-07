# Flutter Environment & Multi-Country Guide

> **난이도**: 중급 | **카테고리**: infrastructure
> **선행 학습**: [DI](./DI.md)
> **예상 학습 시간**: 1h

> 이 문서는 KR, JP, TW 다국가 환경 설정 및 코드 패리티를 유지하는 방법을 설명합니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Flavor를 사용하여 dev/stg/prod 환경을 분리할 수 있다
> - 다국가(KR/JP/TW) 환경별 설정을 구성할 수 있다
> - 환경 변수를 안전하게 관리하고 코드 패리티를 유지할 수 있다

## 1. 개요

### 1.1 핵심 원칙: 코드 패리티

```
✅ 코드 패리티 (Code Parity)
├── 모든 국가에서 동일한 코드베이스 사용
├── 조건부 컴파일(#if) 사용 금지
├── 설정값으로만 국가별 차이 처리
└── 기능 분기는 런타임 설정으로 처리

❌ 코드 패리티 위반
├── #if COUNTRY_KR ... #endif
├── 국가별 별도 브랜치
├── 국가별 다른 파일 복사
└── 하드코딩된 국가별 로직
```

### 1.2 환경 구조

```
┌─────────────────────────────────────────────────────────┐
│                    Build Variants                        │
│   (dev / staging / prod) × (KR / JP / TW)               │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    Environment Config                    │
│   ├── API Base URL                                      │
│   ├── Country Code                                      │
│   ├── Default Language                                  │
│   └── Feature Flags                                     │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    Single Codebase                       │
│   (동일한 코드가 모든 국가에서 실행)                       │
└─────────────────────────────────────────────────────────┘
```

### 1.3 지원 국가

| 국가 코드 | 국가명 | 기본 언어 | 통화 |
|-----------|--------|----------|------|
| `KR` | 한국 | ko | KRW |
| `JP` | 일본 | ja | JPY |
| `TW` | 대만 | zh-TW | TWD |

## 2. 프로젝트 구조

### 2.1 환경 설정 폴더 구조

```
app/
├── lib/
│   ├── main_dev_kr.dart
│   ├── main_dev_jp.dart
│   ├── main_dev_tw.dart
│   ├── main_staging_kr.dart
│   ├── main_staging_jp.dart
│   ├── main_staging_tw.dart
│   ├── main_prod_kr.dart
│   ├── main_prod_jp.dart
│   ├── main_prod_tw.dart
│   └── src/
│       └── config/
│           ├── app_config.dart
│           ├── country_config.dart
│           ├── environment.dart
│           └── feature_flags.dart
├── .env.dev.kr
├── .env.dev.jp
├── .env.dev.tw
├── .env.staging.kr
├── .env.staging.jp
├── .env.staging.tw
├── .env.prod.kr
├── .env.prod.jp
└── .env.prod.tw
```

## 3. 환경 설정

### 3.1 Environment 열거형

```dart
// app/lib/src/config/environment.dart
enum Environment {
  dev,
  staging,
  prod,
}

enum Country {
  kr('KR', 'ko', 'KRW', '한국'),
  jp('JP', 'ja', 'JPY', '日本'),
  tw('TW', 'zh-TW', 'TWD', '台灣');

  const Country(
    this.code,
    this.defaultLanguage,
    this.currency,
    this.displayName,
  );

  final String code;
  final String defaultLanguage;
  final String currency;
  final String displayName;
}
```

### 3.2 AppConfig 정의

```dart
// app/lib/src/config/app_config.dart
import 'package:flutter/foundation.dart';

class AppConfig {
  final Environment environment;
  final Country country;
  final String apiBaseUrl;
  final String appName;
  final bool enableLogging;
  final bool enableCrashlytics;
  final FeatureFlags featureFlags;

  const AppConfig({
    required this.environment,
    required this.country,
    required this.apiBaseUrl,
    required this.appName,
    required this.enableLogging,
    required this.enableCrashlytics,
    required this.featureFlags,
  });

  // 편의 프로퍼티
  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;

  String get countryCode => country.code;
  String get defaultLanguage => country.defaultLanguage;
  String get currency => country.currency;
}
```

### 3.3 FeatureFlags 정의

```dart
// app/lib/src/config/feature_flags.dart
class FeatureFlags {
  final bool enableNewPayment;
  final bool enableSocialLogin;
  final bool enablePushNotification;
  final bool enableAnalytics;
  final bool enableABTesting;

  const FeatureFlags({
    this.enableNewPayment = false,
    this.enableSocialLogin = true,
    this.enablePushNotification = true,
    this.enableAnalytics = true,
    this.enableABTesting = false,
  });

  // 국가별 기본 FeatureFlags
  factory FeatureFlags.forCountry(Country country, Environment env) {
    // 모든 국가에서 동일한 기능 제공 (코드 패리티)
    // 국가별 차이는 서버 설정으로 처리
    return FeatureFlags(
      enableNewPayment: env != Environment.prod,  // prod에서는 점진적 롤아웃
      enableSocialLogin: true,
      enablePushNotification: true,
      enableAnalytics: env == Environment.prod,
      enableABTesting: env == Environment.prod,
    );
  }
}
```

### 3.4 CountryConfig 정의

```dart
// app/lib/src/config/country_config.dart
class CountryConfig {
  final Country country;
  final String apiBaseUrl;
  final String termsUrl;
  final String privacyUrl;
  final String supportEmail;
  final List<String> supportedLanguages;
  final PaymentConfig paymentConfig;

  const CountryConfig({
    required this.country,
    required this.apiBaseUrl,
    required this.termsUrl,
    required this.privacyUrl,
    required this.supportEmail,
    required this.supportedLanguages,
    required this.paymentConfig,
  });

  // 국가별 설정 팩토리
  factory CountryConfig.kr(Environment env) {
    return CountryConfig(
      country: Country.kr,
      apiBaseUrl: _getApiUrl(env, 'kr'),
      termsUrl: 'https://example.com/kr/terms',
      privacyUrl: 'https://example.com/kr/privacy',
      supportEmail: 'support-kr@example.com',
      supportedLanguages: ['ko', 'en'],
      paymentConfig: PaymentConfig.kr(),
    );
  }

  factory CountryConfig.jp(Environment env) {
    return CountryConfig(
      country: Country.jp,
      apiBaseUrl: _getApiUrl(env, 'jp'),
      termsUrl: 'https://example.com/jp/terms',
      privacyUrl: 'https://example.com/jp/privacy',
      supportEmail: 'support-jp@example.com',
      supportedLanguages: ['ja', 'en'],
      paymentConfig: PaymentConfig.jp(),
    );
  }

  factory CountryConfig.tw(Environment env) {
    return CountryConfig(
      country: Country.tw,
      apiBaseUrl: _getApiUrl(env, 'tw'),
      termsUrl: 'https://example.com/tw/terms',
      privacyUrl: 'https://example.com/tw/privacy',
      supportEmail: 'support-tw@example.com',
      supportedLanguages: ['zh-TW', 'en'],
      paymentConfig: PaymentConfig.tw(),
    );
  }

  static String _getApiUrl(Environment env, String region) {
    switch (env) {
      case Environment.dev:
        return 'https://api-dev-$region.example.com';
      case Environment.staging:
        return 'https://api-staging-$region.example.com';
      case Environment.prod:
        return 'https://api-$region.example.com';
    }
  }
}

class PaymentConfig {
  final List<String> supportedMethods;
  final String pgProvider;

  const PaymentConfig({
    required this.supportedMethods,
    required this.pgProvider,
  });

  factory PaymentConfig.kr() => const PaymentConfig(
    supportedMethods: ['card', 'bank', 'kakao', 'naver'],
    pgProvider: 'toss',
  );

  factory PaymentConfig.jp() => const PaymentConfig(
    supportedMethods: ['card', 'conbini', 'paypay'],
    pgProvider: 'stripe',
  );

  factory PaymentConfig.tw() => const PaymentConfig(
    supportedMethods: ['card', 'linepay', 'jkopay'],
    pgProvider: 'tappay',
  );
}
```

## 4. Entry Points

### 4.1 Main 파일 생성

```dart
// app/lib/main_dev_kr.dart
import 'package:flutter/material.dart';
import 'src/config/app_config.dart';
import 'src/config/country_config.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final countryConfig = CountryConfig.kr(Environment.dev);

  final config = AppConfig(
    environment: Environment.dev,
    country: Country.kr,
    apiBaseUrl: countryConfig.apiBaseUrl,
    appName: 'MyApp DEV (KR)',
    enableLogging: true,
    enableCrashlytics: false,
    featureFlags: FeatureFlags.forCountry(Country.kr, Environment.dev),
  );

  runApp(App(config: config, countryConfig: countryConfig));
}
```

```dart
// app/lib/main_prod_jp.dart
import 'package:flutter/material.dart';
import 'src/config/app_config.dart';
import 'src/config/country_config.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final countryConfig = CountryConfig.jp(Environment.prod);

  final config = AppConfig(
    environment: Environment.prod,
    country: Country.jp,
    apiBaseUrl: countryConfig.apiBaseUrl,
    appName: 'MyApp',
    enableLogging: false,
    enableCrashlytics: true,
    featureFlags: FeatureFlags.forCountry(Country.jp, Environment.prod),
  );

  runApp(App(config: config, countryConfig: countryConfig));
}
```

### 4.2 공통 Main 함수 (선택적)

```dart
// app/lib/src/bootstrap.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> bootstrap({
  required AppConfig config,
  required CountryConfig countryConfig,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 시스템 UI 설정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // DI 초기화
  await configureDependencies(config, countryConfig);

  // 로깅 설정
  if (config.enableLogging) {
    // Logger 초기화
  }

  // Crashlytics 설정
  if (config.enableCrashlytics) {
    // Crashlytics 초기화
  }

  runApp(App(config: config, countryConfig: countryConfig));
}

// main_dev_kr.dart에서 사용
Future<void> main() async {
  await bootstrap(
    config: AppConfig(...),
    countryConfig: CountryConfig.kr(Environment.dev),
  );
}
```

## 5. DI 연동

### 5.1 Config 주입

```dart
// app/lib/src/injection/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies(
  AppConfig config,
  CountryConfig countryConfig,
) async {
  // Config 등록 (먼저 등록해야 다른 서비스에서 사용 가능)
  getIt.registerSingleton<AppConfig>(config);
  getIt.registerSingleton<CountryConfig>(countryConfig);

  // Injectable 초기화
  getIt.init(environment: config.environment.name);

  // Feature 모듈 초기화
  // ...
}
```

### 5.2 Config 사용

```dart
// 어디서든 Config 접근
final config = GetIt.I<AppConfig>();
final countryConfig = GetIt.I<CountryConfig>();

// API URL
final apiUrl = config.apiBaseUrl;

// 국가별 설정
final currency = config.currency;
final supportedLanguages = countryConfig.supportedLanguages;
```

## 6. 국가별 로직 처리 (코드 패리티 유지)

### 6.1 결제 처리 예시

```dart
// features/payment/lib/domain/usecases/process_payment_usecase.dart
import 'package:injectable/injectable.dart';

@injectable
class ProcessPaymentUseCase {
  final PaymentRepository _repository;
  final CountryConfig _countryConfig;

  ProcessPaymentUseCase(this._repository, this._countryConfig);

  Future<Either<PaymentFailure, PaymentResult>> call(PaymentParams params) {
    // 국가별 PG사 설정은 Config에서 가져옴
    // 코드는 동일하게 유지
    return _repository.processPayment(
      params: params,
      pgProvider: _countryConfig.paymentConfig.pgProvider,
    );
  }
}
```

### 6.2 조건부 UI (설정 기반)

```dart
// features/payment/lib/presentation/screens/payment_screen.dart
class PaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final countryConfig = GetIt.I<CountryConfig>();

    return Column(
      children: [
        // 모든 국가에서 동일한 코드
        // 지원 결제 수단은 Config에서 결정
        for (final method in countryConfig.paymentConfig.supportedMethods)
          PaymentMethodTile(method: method),
      ],
    );
  }
}
```

### 6.3 Feature Flag 사용

```dart
// features/home/lib/presentation/screens/home_screen.dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final config = GetIt.I<AppConfig>();

    return Scaffold(
      body: Column(
        children: [
          // 기본 컨텐츠
          HomeContent(),

          // Feature Flag로 조건부 표시
          if (config.featureFlags.enableNewPayment)
            NewPaymentBanner(),
        ],
      ),
    );
  }
}
```

## 7. 다국어 지원

### 7.1 Locale 설정

```dart
// app/lib/src/app.dart
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatelessWidget {
  final AppConfig config;
  final CountryConfig countryConfig;

  const App({
    required this.config,
    required this.countryConfig,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 지원 언어
      supportedLocales: countryConfig.supportedLanguages
          .map((lang) => Locale(lang.split('-').first, lang.contains('-') ? lang.split('-').last : null))
          .toList(),

      // 기본 Locale
      locale: Locale(
        config.defaultLanguage.split('-').first,
        config.defaultLanguage.contains('-') ? config.defaultLanguage.split('-').last : null,
      ),

      // Localization Delegates
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Locale 결정 로직
      localeResolutionCallback: (locale, supportedLocales) {
        // 사용자 설정 언어 확인
        final savedLocale = _getSavedLocale();
        if (savedLocale != null) {
          return savedLocale;
        }

        // 시스템 언어가 지원되면 사용
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }

        // 기본 언어
        // defaultLanguage가 'zh-TW' 형태일 수 있으므로 분리
        final parts = config.defaultLanguage.split('-');
        return Locale(parts.first, parts.length > 1 ? parts.last : null);
      },

      home: const HomeScreen(),
    );
  }

  Locale? _getSavedLocale() {
    final languageCode = GetIt.I<AppPreferences>().getLanguageCode();
    if (languageCode == null) return null;
    return Locale(languageCode);
  }
}
```

### 7.2 국가별 포맷팅

```dart
// core/core_utils/lib/src/formatters/currency_formatter.dart
import 'package:intl/intl.dart';

class CurrencyFormatter {
  final Country country;

  CurrencyFormatter(this.country);

  String format(double amount) {
    final formatter = NumberFormat.currency(
      locale: country.defaultLanguage,
      symbol: _getCurrencySymbol(),
      decimalDigits: _getDecimalDigits(),
    );
    return formatter.format(amount);
  }

  String _getCurrencySymbol() {
    switch (country) {
      case Country.kr:
        return '₩';
      case Country.jp:
        return '¥';
      case Country.tw:
        return 'NT\$';
    }
  }

  int _getDecimalDigits() {
    switch (country) {
      case Country.kr:
      case Country.jp:
        return 0;  // 원, 엔은 소수점 없음
      case Country.tw:
        return 0;  // 대만 달러도 보통 정수
    }
  }
}

// 사용
final formatter = CurrencyFormatter(GetIt.I<AppConfig>().country);
final price = formatter.format(10000);
// KR: ₩10,000
// JP: ¥10,000
// TW: NT$10,000
```

## 8. 빌드 설정

### 8.1 Android Flavor 설정

```groovy
// android/app/build.gradle
android {
    flavorDimensions "environment", "country"

    productFlavors {
        // Environment
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            versionNameSuffix "-staging"
        }
        prod {
            dimension "environment"
        }

        // Country
        kr {
            dimension "country"
            resValue "string", "app_name", "MyApp KR"
        }
        jp {
            dimension "country"
            resValue "string", "app_name", "MyApp JP"
        }
        tw {
            dimension "country"
            resValue "string", "app_name", "MyApp TW"
        }
    }
}
```

### 8.2 iOS Scheme 설정

```ruby
# ios/Podfile
# Scheme별로 다른 Bundle ID 설정

# XCode에서 Scheme 생성:
# - MyApp-dev-kr
# - MyApp-dev-jp
# - MyApp-dev-tw
# - MyApp-staging-kr
# - MyApp-staging-jp
# - MyApp-staging-tw
# - MyApp-prod-kr
# - MyApp-prod-jp
# - MyApp-prod-tw
```

### 8.3 빌드 스크립트

```bash
#!/bin/bash
# scripts/build.sh

ENV=$1    # dev, staging, prod
COUNTRY=$2  # kr, jp, tw

# Flutter 빌드
fvm flutter build apk \
  --flavor "${ENV}${COUNTRY^}" \
  --target "lib/main_${ENV}_${COUNTRY}.dart" \
  --release

# 예시: ./scripts/build.sh prod kr
# → flavor: prodKr
# → target: lib/main_prod_kr.dart
```

### 8.4 Melos 스크립트

```yaml
# melos.yaml
scripts:
  build:android:dev:kr:
    run: fvm flutter build apk --flavor devKr --target lib/main_dev_kr.dart --debug
    description: Build dev KR Android APK

  build:android:prod:kr:
    run: fvm flutter build apk --flavor prodKr --target lib/main_prod_kr.dart --release
    description: Build prod KR Android APK

  build:ios:dev:kr:
    run: fvm flutter build ios --flavor devKr --target lib/main_dev_kr.dart --debug
    description: Build dev KR iOS

  build:all:prod:
    run: |
      melos run build:android:prod:kr
      melos run build:android:prod:jp
      melos run build:android:prod:tw
    description: Build all production APKs
```

## 9. 환경 변수 (.env)

> **🔒 보안 경고**: .env 파일은 민감한 정보를 포함할 수 있습니다.
> - ✅ `.gitignore`에 `.env*` 추가 필수
> - ✅ API 키, 토큰 등 민감 정보는 .env에 저장 금지
> - ✅ 프로덕션 환경에서는 **envied** 패키지 사용 권장 (컴파일 타임 난독화)
> - ❌ .env 파일을 Git에 커밋하지 마세요

### 9.0 선택 가이드: flutter_dotenv vs envied

| 기준 | flutter_dotenv | envied |
|------|---------------|--------|
| **로딩 방식** | 런타임 (.env 파일 읽기) | 컴파일 타임 (코드 생성) |
| **보안** | 낮음 (APK에 .env 포함) | 높음 (난독화 지원) |
| **타입 안전성** | 없음 (String만) | 있음 (타입 지정 가능) |
| **설정 난이도** | 쉬움 | build_runner 필요 |
| **권장 대상** | 소규모 프로젝트, 프로토타입 | 프로덕션, 민감 정보 포함 프로젝트 |

**선택 기준:**
- 환경변수 10개 미만 + 민감 정보 없음 → `flutter_dotenv`
- 프로덕션 배포 + API 키/시크릿 포함 → `envied`
- Dart/build_runner 경험 부족 → `flutter_dotenv`로 시작 후 envied로 마이그레이션

### 9.1 flutter_dotenv 사용 (개발 환경)

```yaml
# pubspec.yaml
dependencies:
  flutter_dotenv: ^5.2.0  # 런타임 로드 (보안 취약)

  # 권장 대안 (프로덕션):
  # envied: ^0.5.4+1  # 컴파일 타임 난독화, 타입 안전

# dev_dependencies:
#   envied_generator: ^0.5.4+1
#   build_runner: ^2.4.15
```

**envied 패키지 (프로덕션 권장)**

```dart
// lib/env/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env.prod.kr')
abstract class Env {
  @EnviedField(varName: 'API_BASE_URL')
  static const String apiBaseUrl = _Env.apiBaseUrl;

  @EnviedField(varName: 'API_KEY', obfuscate: true)  // 난독화
  static final String apiKey = _Env.apiKey;
}

// 사용: Env.apiBaseUrl, Env.apiKey
// 장점: 컴파일 타임에 .env 검증, 난독화로 보안 강화
```

**보안 체크리스트:**
- [ ] `.gitignore`에 `.env*` 추가됨
- [ ] 민감 정보는 환경변수 또는 비밀 관리 시스템 사용
- [ ] 프로덕션 빌드는 envied로 난독화
- [ ] .env.example 파일만 Git에 커밋 (실제 값 제외)

```dart
// .env.prod.kr
API_BASE_URL=https://api-kr.example.com
SENTRY_DSN=https://xxx@sentry.io/kr
FIREBASE_PROJECT=myapp-kr
ANALYTICS_KEY=UA-XXXXX-KR
```

```dart
// app/lib/src/config/env_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> load(Environment env, Country country) async {
    final envFile = '.env.${env.name}.${country.code.toLowerCase()}';
    await dotenv.load(fileName: envFile);
  }

  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get sentryDsn => dotenv.env['SENTRY_DSN'] ?? '';
  static String get firebaseProject => dotenv.env['FIREBASE_PROJECT'] ?? '';
}
```

### 9.2 Main에서 로드

```dart
// app/lib/main_prod_kr.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await EnvConfig.load(Environment.prod, Country.kr);

  final config = AppConfig(
    environment: Environment.prod,
    country: Country.kr,
    apiBaseUrl: EnvConfig.apiBaseUrl,
    // ...
  );

  runApp(App(config: config));
}
```

## 10. 원격 설정 (Remote Config)

### 10.1 Firebase Remote Config

```dart
// core/core_config/lib/src/remote_config_service.dart
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:injectable/injectable.dart';

abstract class RemoteConfigService {
  Future<void> initialize();
  bool getBool(String key);
  String getString(String key);
  int getInt(String key);
  Future<void> fetchAndActivate();
}

@LazySingleton(as: RemoteConfigService)
class RemoteConfigServiceImpl implements RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;
  final AppConfig _appConfig;

  RemoteConfigServiceImpl(this._remoteConfig, this._appConfig);

  @override
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: _appConfig.isDev
          ? const Duration(minutes: 5)
          : const Duration(hours: 1),
    ));

    // 기본값 설정
    await _remoteConfig.setDefaults({
      'enable_new_feature': false,
      'min_app_version': '1.0.0',
      'maintenance_mode': false,
    });

    await fetchAndActivate();
  }

  @override
  bool getBool(String key) => _remoteConfig.getBool(key);

  @override
  String getString(String key) => _remoteConfig.getString(key);

  @override
  int getInt(String key) => _remoteConfig.getInt(key);

  @override
  Future<void> fetchAndActivate() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // 실패해도 기본값 사용
    }
  }
}
```

### 10.2 국가별 Feature Flag

```dart
// Firebase Remote Config에서 국가별 키 사용
// enable_new_payment_kr: true
// enable_new_payment_jp: false
// enable_new_payment_tw: true

class FeatureFlagService {
  final RemoteConfigService _remoteConfig;
  final AppConfig _appConfig;

  FeatureFlagService(this._remoteConfig, this._appConfig);

  bool isFeatureEnabled(String feature) {
    // 국가별 키 확인
    final countryKey = '${feature}_${_appConfig.countryCode.toLowerCase()}';
    return _remoteConfig.getBool(countryKey);
  }
}
```

## 11. 테스트

### 11.1 Config Mock

```dart
// test/mocks/mock_config.dart
class MockAppConfig {
  final AppConfig _config;

  MockAppConfig({
    Environment environment = Environment.dev,
    Country country = Country.kr,
    String apiBaseUrl = 'https://api-test.example.com',
    String appName = 'Test App',
    bool enableLogging = false,
    bool enableCrashlytics = false,
    FeatureFlags featureFlags = const FeatureFlags(),
  }) : _config = AppConfig(
    environment: environment,
    country: country,
    apiBaseUrl: apiBaseUrl,
    appName: appName,
    enableLogging: enableLogging,
    enableCrashlytics: enableCrashlytics,
    featureFlags: featureFlags,
  );

  AppConfig get config => _config;
}

// 테스트에서 사용
void main() {
  setUp(() {
    GetIt.I.registerSingleton<AppConfig>(MockAppConfig().config);
    GetIt.I.registerSingleton<CountryConfig>(
      CountryConfig.kr(Environment.dev),
    );
  });

  tearDown(() {
    GetIt.I.reset();
  });
}
```

### 11.2 국가별 테스트

```dart
// test/features/payment/payment_test.dart
void main() {
  group('Payment - KR', () {
    setUp(() {
      GetIt.I.registerSingleton<CountryConfig>(
        CountryConfig.kr(Environment.dev),
      );
    });

    tearDown(() {
      GetIt.I.reset();
    });

    test('한국 결제 수단 표시', () {
      final config = GetIt.I<CountryConfig>();
      expect(
        config.paymentConfig.supportedMethods,
        contains('kakao'),
      );
    });
  });

  group('Payment - JP', () {
    setUp(() {
      GetIt.I.registerSingleton<CountryConfig>(
        CountryConfig.jp(Environment.dev),
      );
    });

    tearDown(() {
      GetIt.I.reset();
    });

    test('일본 결제 수단 표시', () {
      final config = GetIt.I<CountryConfig>();
      expect(
        config.paymentConfig.supportedMethods,
        contains('paypay'),
      );
    });
  });
}
```

## 12. CI/CD 환경 통합

### 12.1 GitHub Actions 기본 설정

```yaml
# .github/workflows/flutter.yml
name: Flutter CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  FLUTTER_VERSION: '3.27.0'

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Run tests
        run: flutter test --coverage

      - name: Build APK (dev)
        run: flutter build apk --flavor dev --dart-define=ENV=dev

      - name: Build APK (prod)
        run: flutter build apk --flavor prod --dart-define=ENV=prod
```

### 12.2 환경별 시크릿 관리

```yaml
# .github/workflows/flutter.yml (계속)
jobs:
  build-prod:
    runs-on: ubuntu-latest
    environment: production  # GitHub Environment 사용

    steps:
      - uses: actions/checkout@v4

      - name: Create .env file
        run: |
          echo "API_BASE_URL=${{ secrets.API_BASE_URL }}" >> .env
          echo "SENTRY_DSN=${{ secrets.SENTRY_DSN }}" >> .env

      - name: Decode keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/release.keystore

      - name: Build release APK
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
        run: flutter build apk --release --flavor prod
```

### 12.3 Codemagic 설정

```yaml
# codemagic.yaml
workflows:
  android-workflow:
    name: Android Build
    environment:
      flutter: stable
      vars:
        ENV: dev
      groups:
        - android_credentials

    triggering:
      events:
        - push
      branch_patterns:
        - pattern: develop
          include: true

    scripts:
      - name: Get dependencies
        script: flutter pub get

      - name: Build APK
        script: |
          flutter build apk --flavor $ENV --dart-define=ENV=$ENV

    artifacts:
      - build/**/outputs/apk/**/*.apk

  ios-workflow:
    name: iOS Build
    environment:
      flutter: stable
      xcode: latest
      cocoapods: default
      vars:
        ENV: dev

    scripts:
      - name: Install pods
        script: |
          cd ios && pod install

      - name: Build IPA
        script: |
          flutter build ipa --flavor $ENV --dart-define=ENV=$ENV
```

### 12.4 환경 변수 주입 패턴

```dart
// lib/core/config/ci_config.dart
class CIConfig {
  // CI 환경에서 주입되는 빌드 정보
  static const String buildNumber = String.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: 'local',
  );

  static const String commitSha = String.fromEnvironment(
    'COMMIT_SHA',
    defaultValue: 'unknown',
  );

  static const String branch = String.fromEnvironment(
    'BRANCH',
    defaultValue: 'local',
  );

  static Map<String, String> get buildInfo => {
    'buildNumber': buildNumber,
    'commitSha': commitSha,
    'branch': branch,
    'buildTime': DateTime.now().toIso8601String(),
  };
}

// 빌드 명령어
// flutter build apk \
//   --dart-define=BUILD_NUMBER=$GITHUB_RUN_NUMBER \
//   --dart-define=COMMIT_SHA=$GITHUB_SHA \
//   --dart-define=BRANCH=$GITHUB_REF_NAME
```

### 12.5 환경별 Firebase 설정

```yaml
# .github/workflows/flutter.yml
- name: Setup Firebase (dev)
  if: github.ref == 'refs/heads/develop'
  run: |
    cp firebase/dev/google-services.json android/app/src/dev/google-services.json
    cp firebase/dev/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist

- name: Setup Firebase (prod)
  if: github.ref == 'refs/heads/main'
  run: |
    cp firebase/prod/google-services.json android/app/src/prod/google-services.json
    cp firebase/prod/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
```

### 12.6 CI/CD 체크리스트

| 항목 | Dev | Staging | Prod |
|-----|-----|---------|------|
| 자동 빌드 | ✓ | ✓ | ✓ |
| 자동 테스트 | ✓ | ✓ | ✓ |
| 코드 분석 | ✓ | ✓ | ✓ |
| 환경별 시크릿 | ✓ | ✓ | ✓ |
| Firebase 프로젝트 | dev | staging | prod |
| 스토어 배포 | ✗ | Internal | Production |

## 13. Best Practices

### 13.1 코드 패리티 체크리스트

| 항목 | 확인 |
|------|------|
| 조건부 컴파일(#if) 사용 안함 | ☐ |
| 국가별 다른 파일/클래스 없음 | ☐ |
| 모든 분기는 Config 기반 | ☐ |
| Feature Flag로 기능 제어 | ☐ |
| 하드코딩된 국가 로직 없음 | ☐ |

### 13.2 DO (이렇게 하세요)

```dart
// ✅ Config로 분기
if (config.featureFlags.enableNewPayment) {
  showNewPaymentUI();
}

// ✅ 설정값 사용
final currency = countryConfig.country.currency;
final price = formatter.format(amount, currency);

// ✅ Remote Config로 제어
if (remoteConfig.getBool('enable_promotion')) {
  showPromotion();
}
```

### 13.3 DON'T (하지 마세요)

```dart
// ❌ 하드코딩된 국가 분기
if (country == 'KR') {
  // 한국 전용 로직
} else if (country == 'JP') {
  // 일본 전용 로직
}

// ❌ 조건부 컴파일
#if COUNTRY_KR
  return KoreanPaymentService();
#endif

// ❌ 국가별 다른 클래스
class KrPaymentService { }
class JpPaymentService { }
class TwPaymentService { }
```

## 14. 참고

- [Flutter Flavors](https://docs.flutter.dev/deployment/flavors)
- [flutter_dotenv](https://pub.dev/packages/flutter_dotenv)
- [Firebase Remote Config](https://firebase.google.com/docs/remote-config)

---

## 실습 과제

### 과제 1: Flavor 환경 분리
dev, staging, prod 3개의 Flavor를 설정하고, 각 환경에서 다른 API 엔드포인트와 앱 이름을 사용하도록 구성하세요.

### 과제 2: 다국가 설정 구현
KR과 JP 두 국가에 대해 서로 다른 결제 수단, API 서버, 약관 URL을 환경 변수로 관리하세요.

## Self-Check

- [ ] Flavor별 빌드 설정(Android productFlavors, iOS Scheme)을 구성할 수 있는가?
- [ ] 환경 변수를 안전하게 관리하고 .env 파일을 gitignore 처리하는가?
- [ ] dart-define을 사용하여 빌드 시 환경 값을 주입할 수 있는가?
- [ ] 국가별 설정을 코드 패리티를 유지하면서 분리할 수 있는가?
