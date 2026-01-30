# Flutter 분석 및 로깅 가이드 (Firebase Analytics + Crashlytics)

## 개요

Firebase Analytics와 Crashlytics를 통해 사용자 행동 분석, 크래시 리포팅, 성능 모니터링을 구현합니다. 프로덕션 앱 운영에 필수적인 기능들입니다.

## 설치 및 설정

### 의존성 추가

```yaml
# pubspec.yaml (2026년 1월 기준)
dependencies:
  firebase_core: ^4.4.0
  firebase_analytics: ^12.1.1
  firebase_crashlytics: ^5.0.7
  firebase_performance: ^0.11.0  # 선택
  logger: ^2.5.0  # 개발용 로깅
```

**Firebase BoM (Bill of Materials) 호환성:**
- Firebase Flutter SDK는 네이티브 Firebase SDK에 의존하며, 버전 충돌을 방지하려면 일관된 버전 사용이 중요합니다.
- Android: `build.gradle`에서 Firebase BoM을 사용하면 모든 Firebase 라이브러리 버전이 자동으로 호환됩니다.
  ```gradle
  dependencies {
    // Firebase BoM (2026년 1월 기준)
    implementation platform('com.google.firebase:firebase-bom:33.7.0')
    // 이제 개별 Firebase 라이브러리에 버전 명시 불필요
    implementation 'com.google.firebase:firebase-analytics-ktx'
    implementation 'com.google.firebase:firebase-crashlytics-ktx'
  }
  ```
- iOS: CocoaPods가 자동으로 호환 버전을 관리하지만, `Podfile`에서 명시적 버전을 설정할 수도 있습니다.
- **권장사항:** `firebase_core` 버전을 먼저 업데이트하고, 다른 Firebase 플러그인들은 호환되는 버전으로 함께 업데이트하세요.

### Android 설정

```kotlin
// android/app/build.gradle
android {
    buildTypes {
        release {
            // Crashlytics 매핑 파일 업로드
            firebaseCrashlytics {
                mappingFileUploadEnabled true
                nativeSymbolUploadEnabled true
            }
        }
    }
}
```

### iOS 설정

```ruby
# ios/Podfile
target 'Runner' do
  # Crashlytics dSYM 업로드
  # Xcode Build Phases에서 스크립트 추가 필요
end
```

Xcode에서:
1. Build Phases > New Run Script Phase
2. 스크립트 추가:
```bash
"${PODS_ROOT}/FirebaseCrashlytics/run"
```

## GDPR/개인정보보호 동의 관리

### 개요

GDPR(EU), 개인정보보호법(한국), CCPA(캘리포니아) 등 개인정보보호 규정을 준수하기 위해 분석 데이터 수집 전 사용자 동의를 받아야 합니다.

### 동의 관리 서비스

```dart
// lib/core/consent/consent_service.dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class ConsentService {
  static const _keyAnalyticsConsent = 'analytics_consent';
  static const _keyCrashlyticsConsent = 'crashlytics_consent';

  final SharedPreferences _prefs;

  ConsentService(this._prefs);

  /// 분석 동의 상태 확인
  bool get hasAnalyticsConsent {
    return _prefs.getBool(_keyAnalyticsConsent) ?? false;
  }

  /// 크래시 리포팅 동의 상태 확인
  bool get hasCrashlyticsConsent {
    return _prefs.getBool(_keyCrashlyticsConsent) ?? false;
  }

  /// 분석 동의 설정
  Future<void> setAnalyticsConsent(bool consent) async {
    await _prefs.setBool(_keyAnalyticsConsent, consent);
  }

  /// 크래시 리포팅 동의 설정
  Future<void> setCrashlyticsConsent(bool consent) async {
    await _prefs.setBool(_keyCrashlyticsConsent, consent);
  }

  /// 모든 동의 초기화
  Future<void> clearAllConsent() async {
    await _prefs.remove(_keyAnalyticsConsent);
    await _prefs.remove(_keyCrashlyticsConsent);
  }

  /// 첫 실행 여부 확인
  bool get isFirstLaunch {
    return !_prefs.containsKey(_keyAnalyticsConsent);
  }
}
```

### Firebase Analytics 활성화/비활성화

```dart
// lib/core/consent/consent_manager.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:injectable/injectable.dart';

import '../analytics/analytics_service.dart';
import 'consent_service.dart';

@lazySingleton
class ConsentManager {
  final ConsentService _consentService;
  final AnalyticsService _analyticsService;

  ConsentManager(this._consentService, this._analyticsService);

  /// 동의 상태에 따라 Firebase 서비스 활성화/비활성화
  Future<void> applyConsent() async {
    final hasAnalyticsConsent = _consentService.hasAnalyticsConsent;
    final hasCrashlyticsConsent = _consentService.hasCrashlyticsConsent;

    // Firebase Analytics 활성화/비활성화
    await FirebaseAnalytics.instance
        .setAnalyticsCollectionEnabled(hasAnalyticsConsent);

    // Firebase Crashlytics 활성화/비활성화
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(hasCrashlyticsConsent);
  }

  /// 동의 승인
  Future<void> grantConsent({
    required bool analytics,
    required bool crashlytics,
  }) async {
    await _consentService.setAnalyticsConsent(analytics);
    await _consentService.setCrashlyticsConsent(crashlytics);
    await applyConsent();
  }

  /// 동의 철회 및 데이터 삭제 요청
  Future<void> revokeConsent() async {
    // 사용자 ID 제거
    await _analyticsService.setUserId(null);

    // 모든 사용자 속성 초기화
    await _analyticsService.setUserProperty(name: 'user_type', value: null);
    await _analyticsService.setUserProperty(name: 'country', value: null);

    // 동의 상태 초기화
    await _consentService.clearAllConsent();

    // Firebase 서비스 비활성화
    await applyConsent();
  }
}
```

### 동의 다이얼로그

```dart
// lib/core/consent/widgets/consent_dialog.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsentDialog extends StatefulWidget {
  final void Function(bool analytics, bool crashlytics) onAccept;
  final VoidCallback onReject;

  const ConsentDialog({
    required this.onAccept,
    required this.onReject,
    super.key,
  });

  @override
  State<ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<ConsentDialog> {
  bool _analyticsConsent = true;
  bool _crashlyticsConsent = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('데이터 수집 동의'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '더 나은 서비스 제공을 위해 다음 데이터 수집에 동의해 주세요.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('앱 사용 분석'),
              subtitle: const Text('앱 사용 패턴 분석을 통해 서비스를 개선합니다.'),
              value: _analyticsConsent,
              onChanged: (value) {
                setState(() => _analyticsConsent = value ?? false);
              },
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('오류 리포팅'),
              subtitle: const Text('앱 오류 정보를 수집하여 안정성을 개선합니다.'),
              value: _crashlyticsConsent,
              onChanged: (value) {
                setState(() => _crashlyticsConsent = value ?? false);
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final uri = Uri.parse('https://example.com/privacy-policy');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: const Text('개인정보처리방침 보기'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onReject,
          child: const Text('거부'),
        ),
        ElevatedButton(
          onPressed: (_analyticsConsent || _crashlyticsConsent)
              ? () {
                  widget.onAccept(_analyticsConsent, _crashlyticsConsent);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('동의'),
        ),
      ],
    );
  }
}
```

### 앱 시작 시 동의 확인

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/consent/consent_manager.dart';
import 'core/consent/consent_service.dart';
import 'core/consent/widgets/consent_dialog.dart';
import 'core/di/injection.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // DI 초기화
  await configureDependencies();

  final consentService = getIt<ConsentService>();
  final consentManager = getIt<ConsentManager>();

  // 저장된 동의 상태 적용
  await consentManager.applyConsent();

  runApp(MyApp(
    shouldShowConsentDialog: consentService.isFirstLaunch,
  ));
}

class MyApp extends StatefulWidget {
  final bool shouldShowConsentDialog;

  const MyApp({
    required this.shouldShowConsentDialog,
    super.key,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    if (widget.shouldShowConsentDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConsentDialog();
      });
    }
  }

  Future<void> _showConsentDialog() async {
    final consentManager = getIt<ConsentManager>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConsentDialog(
        onAccept: (analytics, crashlytics) async {
          await consentManager.grantConsent(
            analytics: analytics,
            crashlytics: crashlytics,
          );
        },
        onReject: () async {
          await consentManager.grantConsent(
            analytics: false,
            crashlytics: false,
          );
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: const HomeScreen(),
    );
  }
}
```

### 설정 화면에서 동의 관리

```dart
// lib/features/settings/presentation/pages/privacy_settings_page.dart
import 'package:flutter/material.dart';

import '../../../../core/consent/consent_manager.dart';
import '../../../../core/consent/consent_service.dart';
import '../../../../core/di/injection.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  final _consentService = getIt<ConsentService>();
  final _consentManager = getIt<ConsentManager>();

  late bool _analyticsConsent;
  late bool _crashlyticsConsent;

  @override
  void initState() {
    super.initState();
    _analyticsConsent = _consentService.hasAnalyticsConsent;
    _crashlyticsConsent = _consentService.hasCrashlyticsConsent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개인정보 설정')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('앱 사용 분석'),
            subtitle: const Text('앱 사용 패턴을 분석하여 서비스를 개선합니다.'),
            value: _analyticsConsent,
            onChanged: (value) async {
              setState(() => _analyticsConsent = value);
              await _consentManager.grantConsent(
                analytics: value,
                crashlytics: _crashlyticsConsent,
              );
            },
          ),
          SwitchListTile(
            title: const Text('오류 리포팅'),
            subtitle: const Text('앱 오류 정보를 수집하여 안정성을 개선합니다.'),
            value: _crashlyticsConsent,
            onChanged: (value) async {
              setState(() => _crashlyticsConsent = value);
              await _consentManager.grantConsent(
                analytics: _analyticsConsent,
                crashlytics: value,
              );
            },
          ),
          ListTile(
            title: const Text('모든 데이터 삭제 요청'),
            subtitle: const Text('수집된 분석 데이터를 삭제하고 동의를 철회합니다.'),
            trailing: const Icon(Icons.delete_outline),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('데이터 삭제'),
                  content: const Text(
                    '수집된 모든 분석 데이터가 삭제되고 동의가 철회됩니다. 계속하시겠습니까?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                await _consentManager.revokeConsent();
                setState(() {
                  _analyticsConsent = false;
                  _crashlyticsConsent = false;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('데이터가 삭제되었습니다.')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
```

### 지역별 규정 대응

#### EU - GDPR (General Data Protection Regulation)
- 사용자 동의 없이 개인정보 수집 금지
- 동의 철회 권리 보장
- 데이터 삭제 요청 권리 (Right to be forgotten)
- 개인정보처리방침 명시 필수

#### 한국 - 개인정보보호법
- 개인정보 수집 전 동의 획득 의무
- 수집 목적 명시 필수
- 동의 철회 및 삭제 요청 권리 보장
- 만 14세 미만 법정대리인 동의 필요

#### 캘리포니아 - CCPA (California Consumer Privacy Act)
- 수집되는 데이터 카테고리 공개
- 데이터 판매 거부 권리 (Do Not Sell)
- 수집된 데이터 열람 권리
- 데이터 삭제 요청 권리

### 구현 체크리스트

- [ ] ConsentService 구현 (SharedPreferences 기반)
- [ ] ConsentManager 구현 (Firebase 활성화/비활성화)
- [ ] 앱 최초 실행 시 동의 다이얼로그 표시
- [ ] 설정 화면에서 동의 관리 기능 제공
- [ ] 동의 철회 시 사용자 ID 및 속성 삭제
- [ ] 개인정보처리방침 페이지 링크 제공
- [ ] Firebase Analytics/Crashlytics 분석 수집 전 동의 확인
- [ ] 지역별 규정 준수 (GDPR, 개인정보보호법, CCPA)
- [ ] 동의 상태를 로컬에 안전하게 저장
- [ ] 사용자에게 데이터 수집 목적 명확히 설명

## 초기화

### Firebase 초기화

```dart
// lib/main.dart
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Crashlytics 초기화
    if (!kDebugMode) {
      // 릴리즈 모드에서만 활성화
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      // 비동기 에러 캐치
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    runApp(const MyApp());
  }, (error, stack) {
    // Zone 에러 캐치
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}
```

## Analytics Service

### 추상 인터페이스

```dart
// lib/core/analytics/analytics_service.dart
abstract class AnalyticsService {
  /// 화면 조회 로깅
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  });

  /// 커스텀 이벤트 로깅
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });

  /// 사용자 속성 설정
  Future<void> setUserProperty({
    required String name,
    required String? value,
  });

  /// 사용자 ID 설정
  Future<void> setUserId(String? userId);

  /// 기본 이벤트 파라미터 설정
  Future<void> setDefaultEventParameters(Map<String, Object>? parameters);
}
```

### Firebase Analytics 구현

```dart
// lib/core/analytics/firebase_analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';

import 'analytics_service.dart';

@LazySingleton(as: AnalyticsService)
class FirebaseAnalyticsService implements AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(
      name: name,
      value: value,
    );
  }

  @override
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  @override
  Future<void> setDefaultEventParameters(
    Map<String, Object>? parameters,
  ) async {
    await _analytics.setDefaultEventParameters(parameters);
  }
}
```

### 이벤트 상수 정의

```dart
// lib/core/analytics/analytics_events.dart
abstract class AnalyticsEvents {
  // 인증
  static const login = 'login';
  static const logout = 'logout';
  static const signUp = 'sign_up';

  // 상품
  static const viewProduct = 'view_product';
  static const addToCart = 'add_to_cart';
  static const removeFromCart = 'remove_from_cart';
  static const viewCart = 'view_cart';

  // 구매
  static const beginCheckout = 'begin_checkout';
  static const addPaymentInfo = 'add_payment_info';
  static const purchase = 'purchase';

  // 검색
  static const search = 'search';
  static const viewSearchResults = 'view_search_results';

  // 공유
  static const share = 'share';

  // 커스텀
  static const buttonClick = 'button_click';
  static const featureUsed = 'feature_used';
  static const errorOccurred = 'error_occurred';
}

abstract class AnalyticsParams {
  static const screenName = 'screen_name';
  static const buttonName = 'button_name';
  static const itemId = 'item_id';
  static const itemName = 'item_name';
  static const itemCategory = 'item_category';
  static const price = 'price';
  static const currency = 'currency';
  static const quantity = 'quantity';
  static const searchTerm = 'search_term';
  static const errorMessage = 'error_message';
  static const success = 'success';
}
```

### 화면별 이벤트 래퍼

```dart
// lib/core/analytics/analytics_logger.dart
import 'package:injectable/injectable.dart';

import 'analytics_events.dart';
import 'analytics_service.dart';

@lazySingleton
class AnalyticsLogger {
  final AnalyticsService _analyticsService;

  AnalyticsLogger(this._analyticsService);

  // 인증 이벤트
  Future<void> logLogin(String method) async {
    await _analyticsService.logEvent(
      name: AnalyticsEvents.login,
      parameters: {'method': method},
    );
  }

  Future<void> logSignUp(String method) async {
    await _analyticsService.logEvent(
      name: AnalyticsEvents.signUp,
      parameters: {'method': method},
    );
  }

  Future<void> logLogout() async {
    await _analyticsService.logEvent(name: AnalyticsEvents.logout);
  }

  // 상품 이벤트
  Future<void> logViewProduct({
    required String productId,
    required String productName,
    required String category,
    required double price,
    required String currency,
  }) async {
    await _analyticsService.logEvent(
      name: AnalyticsEvents.viewProduct,
      parameters: {
        AnalyticsParams.itemId: productId,
        AnalyticsParams.itemName: productName,
        AnalyticsParams.itemCategory: category,
        AnalyticsParams.price: price,
        AnalyticsParams.currency: currency,
      },
    );
  }

  Future<void> logAddToCart({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
    required String currency,
  }) async {
    await _analyticsService.logEvent(
      name: AnalyticsEvents.addToCart,
      parameters: {
        AnalyticsParams.itemId: productId,
        AnalyticsParams.itemName: productName,
        AnalyticsParams.price: price,
        AnalyticsParams.quantity: quantity,
        AnalyticsParams.currency: currency,
      },
    );
  }

  // 구매 이벤트
  Future<void> logPurchase({
    required String transactionId,
    required double totalAmount,
    required String currency,
    required List<Map<String, dynamic>> items,
  }) async {
    await _analyticsService.logEvent(
      name: AnalyticsEvents.purchase,
      parameters: {
        'transaction_id': transactionId,
        'value': totalAmount,
        AnalyticsParams.currency: currency,
        // Firebase Analytics는 중첩 배열을 지원하지 않음
        'item_count': items.length,
        'item_ids': items.map((i) => i['id']).join(','),
      },
    );
  }

  // 검색 이벤트
  Future<void> logSearch(String searchTerm) async {
    await _analyticsService.logEvent(
      name: AnalyticsEvents.search,
      parameters: {AnalyticsParams.searchTerm: searchTerm},
    );
  }

  // 버튼 클릭
  Future<void> logButtonClick({
    required String buttonName,
    required String screenName,
  }) async {
    await _analyticsService.logEvent(
      name: AnalyticsEvents.buttonClick,
      parameters: {
        AnalyticsParams.buttonName: buttonName,
        AnalyticsParams.screenName: screenName,
      },
    );
  }

  // 에러 로깅
  Future<void> logError({
    required String errorMessage,
    required String screenName,
  }) async {
    await _analyticsService.logEvent(
      name: AnalyticsEvents.errorOccurred,
      parameters: {
        AnalyticsParams.errorMessage: errorMessage,
        AnalyticsParams.screenName: screenName,
      },
    );
  }
}
```

## Crashlytics Service

### 크래시 리포팅 서비스

```dart
// lib/core/crashlytics/crashlytics_service.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// 사용자 ID 설정
  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  /// 커스텀 키-값 설정
  Future<void> setCustomKey(String key, Object value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  /// 로그 메시지 기록
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  /// 에러 기록 (non-fatal)
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (kDebugMode) {
      // 디버그 모드에서는 콘솔에만 출력
      debugPrint('Error: $exception');
      debugPrint('Stack: $stack');
      return;
    }

    await _crashlytics.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }

  /// 강제 크래시 (테스트용)
  void crash() {
    _crashlytics.crash();
  }

  /// Crashlytics 활성화/비활성화
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }
}
```

### UseCase에서 에러 로깅

```dart
// lib/features/product/domain/usecases/get_products_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/crashlytics/crashlytics_service.dart';
import '../../../../core/error/failure.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

@injectable
class GetProductsUseCase {
  final ProductRepository _repository;
  final CrashlyticsService _crashlytics;

  GetProductsUseCase(this._repository, this._crashlytics);

  Future<Either<Failure, List<Product>>> call() async {
    try {
      return await _repository.getProducts();
    } catch (e, stack) {
      // 예상치 못한 에러 로깅
      await _crashlytics.recordError(
        e,
        stack,
        reason: 'GetProductsUseCase failed',
      );
      return Left(Failure.unknown(message: e.toString()));
    }
  }
}
```

## 화면 추적

### GoRouter와 통합

```dart
// lib/core/router/app_router.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  observers: [
    // Firebase Analytics 화면 추적
    FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
  ],
  routes: [...],
);
```

### 수동 화면 추적

```dart
// context.read 사용을 위해 필요:
// import 'package:flutter_bloc/flutter_bloc.dart';
// 또는
// import 'package:provider/provider.dart';

// 자동 추적이 안 되는 경우 수동으로
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String category;
  final double price;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.category,
    required this.price,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 로깅
    context.read<AnalyticsLogger>().logViewProduct(
          productId: widget.productId,
          productName: widget.productName,
          category: widget.category,
          price: widget.price,
          currency: 'KRW',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

## 개발용 로깅 (Logger)

### Logger 설정

```dart
// lib/core/logger/app_logger.dart
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    // 릴리즈 모드에서는 warning 이상만
    level: kDebugMode ? Level.trace : Level.warning,
  );

  static void verbose(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
```

### 사용 예시

```dart
// API 호출 로깅
class DioClient {
  Future<Response> get(String path) async {
    AppLogger.debug('GET $path');
    try {
      final response = await _dio.get(path);
      AppLogger.debug('Response: ${response.statusCode}');
      return response;
    } catch (e, stack) {
      AppLogger.error('GET $path failed', e, stack);
      rethrow;
    }
  }
}

// Bloc 로깅
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  @override
  void onEvent(ProductEvent event) {
    super.onEvent(event);
    AppLogger.debug('ProductBloc Event: $event');
  }

  @override
  void onChange(Change<ProductState> change) {
    super.onChange(change);
    AppLogger.debug('ProductBloc State: ${change.currentState} -> ${change.nextState}');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    AppLogger.error('ProductBloc Error', error, stackTrace);
  }
}
```

## Bloc 통합

### Analytics Bloc Observer

```dart
// lib/core/analytics/analytics_bloc_observer.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../logger/app_logger.dart';
import 'analytics_logger.dart';

class AnalyticsBlocObserver extends BlocObserver {
  final AnalyticsLogger _analyticsLogger;

  AnalyticsBlocObserver(this._analyticsLogger);

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    AppLogger.debug('${bloc.runtimeType} Event: $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    AppLogger.debug('${bloc.runtimeType} Change: $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    AppLogger.error('${bloc.runtimeType} Error', error, stackTrace);

    // Analytics에 에러 로깅
    _analyticsLogger.logError(
      errorMessage: error.toString(),
      screenName: bloc.runtimeType.toString(),
    );
  }
}
```

### main.dart에서 등록

```dart
void main() async {
  // ... 초기화 코드

  // Bloc Observer 등록
  Bloc.observer = AnalyticsBlocObserver(getIt<AnalyticsLogger>());

  runApp(const MyApp());
}
```

## 사용자 속성 설정

### 로그인 시 사용자 정보 설정

```dart
// lib/features/auth/presentation/bloc/auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AnalyticsService _analyticsService;
  final CrashlyticsService _crashlyticsService;

  Future<void> _onLoginSuccess(User user, Emitter<AuthState> emit) async {
    // Analytics 사용자 ID
    // ⚠️ WARNING: 실제 사용자 ID를 직접 전송하면 PII(개인식별정보) 노출 위험
    // 프로덕션에서는 해시된 값 사용 권장: await _analyticsService.setUserId(hashUserId(user.id));
    await _analyticsService.setUserId(user.id);

    // Analytics 사용자 속성
    await _analyticsService.setUserProperty(
      name: 'user_type',
      value: user.type.name,
    );
    await _analyticsService.setUserProperty(
      name: 'country',
      value: user.country,
    );

    // Crashlytics 사용자 정보
    await _crashlyticsService.setUserId(user.id);
    await _crashlyticsService.setCustomKey('user_type', user.type.name);
    await _crashlyticsService.setCustomKey('country', user.country);

    // 로그인 이벤트
    await _analyticsService.logEvent(
      name: AnalyticsEvents.login,
      parameters: {'method': 'email'},
    );

    emit(state.copyWith(user: user, isAuthenticated: true));
  }
}
```

### 로그아웃 시 초기화

```dart
Future<void> _onLogout(Emitter<AuthState> emit) async {
  // Analytics 사용자 ID 초기화
  await _analyticsService.setUserId(null);

  // 로그아웃 이벤트
  await _analyticsService.logEvent(name: AnalyticsEvents.logout);

  emit(AuthState.initial());
}
```

## 국가별 분석

### 기본 이벤트 파라미터 설정

```dart
// lib/core/analytics/analytics_initializer.dart
import 'package:injectable/injectable.dart';

import '../env/env_config.dart';
import 'analytics_service.dart';

@injectable
class AnalyticsInitializer {
  final AnalyticsService _analyticsService;

  AnalyticsInitializer(this._analyticsService);

  Future<void> initialize() async {
    // 모든 이벤트에 국가 정보 자동 포함
    await _analyticsService.setDefaultEventParameters({
      'app_country': EnvConfig.country.name,
      'app_env': EnvConfig.environment.name,
      'app_version': EnvConfig.appVersion,
    });

    // 사용자 속성으로도 설정
    await _analyticsService.setUserProperty(
      name: 'country',
      value: EnvConfig.country.name,
    );
  }
}
```

## 12. Firebase Analytics 제한사항 및 Best Practices

### 12.1 이벤트 제한사항

| 제한 항목 | 값 | 초과 시 |
|----------|---|--------|
| 이벤트 파라미터 개수 | **25개** | 초과 파라미터 무시 |
| 이벤트 이름 길이 | **40자** | 이벤트 기록 안됨 |
| 파라미터 이름 길이 | **40자** | 파라미터 무시 |
| 파라미터 값 (문자열) | **100자** | 잘림 처리 |
| 사용자 속성 개수 | **25개** | 초과 속성 무시 |
| 사용자 속성 값 | **36자** | 잘림 처리 |

### 12.2 안전한 이벤트 로깅 유틸리티

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class SafeAnalytics {
  final FirebaseAnalytics _analytics;

  SafeAnalytics(this._analytics);

  /// 제한을 준수하는 안전한 이벤트 로깅
  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    // 이벤트 이름 검증 (40자 제한)
    final safeName = _truncate(name, 40);
    if (safeName != name) {
      debugPrint('⚠️ Event name truncated: $name -> $safeName');
    }

    // 파라미터 정리 (25개 제한, 이름 40자, 값 100자)
    final safeParams = _sanitizeParameters(parameters);

    if (kDebugMode) {
      debugPrint('📊 Analytics: $safeName');
      safeParams?.forEach((k, v) => debugPrint('   $k: $v'));
    }

    await _analytics.logEvent(name: safeName, parameters: safeParams);
  }

  Map<String, Object>? _sanitizeParameters(Map<String, Object>? params) {
    if (params == null || params.isEmpty) return null;

    final result = <String, Object>{};
    var count = 0;

    for (final entry in params.entries) {
      if (count >= 25) {
        debugPrint('⚠️ Exceeded 25 parameter limit, ignoring: ${entry.key}');
        break;
      }

      final key = _truncate(entry.key, 40);
      final value = entry.value is String
          ? _truncate(entry.value as String, 100)
          : entry.value;

      result[key] = value;
      count++;
    }

    return result;
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength);
  }
}
```

### 12.3 이벤트 이름 규칙

```dart
// ✅ 좋은 예
'view_diary'
'click_share_button'
'purchase_complete'

// ❌ 나쁜 예
'ViewDiary'            // 소문자 snake_case 권장
'click_share_btn'      // 축약어 피하기
'diary_view_2024_01'   // 날짜는 파라미터로
'click_'               // 빈 suffix
```

### 12.4 BigQuery Export 설정

프로덕션 앱에서 고급 분석이 필요한 경우:

1. Firebase Console → Project Settings → Integrations
2. BigQuery 링크 활성화
3. 데이터셋 생성 (예: `analytics_123456789`)
4. 일별 내보내기 활성화

```sql
-- BigQuery에서 커스텀 쿼리 예시
SELECT
  event_name,
  COUNT(*) as event_count,
  COUNT(DISTINCT user_pseudo_id) as unique_users
FROM
  `project.analytics_dataset.events_*`
WHERE
  _TABLE_SUFFIX BETWEEN '20260101' AND '20260131'
GROUP BY
  event_name
ORDER BY
  event_count DESC
```

## 테스트

### Mock AnalyticsService

```dart
import 'package:mocktail/mocktail.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockAnalyticsService mockAnalytics;
  late AnalyticsLogger logger;

  setUp(() {
    mockAnalytics = MockAnalyticsService();
    logger = AnalyticsLogger(mockAnalytics);

    when(() => mockAnalytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        )).thenAnswer((_) async {});
  });

  test('should log login event', () async {
    await logger.logLogin('email');

    verify(() => mockAnalytics.logEvent(
          name: 'login',
          parameters: {'method': 'email'},
        )).called(1);
  });
}
```

### DebugView 확인

```dart
// Firebase Analytics DebugView 활성화
// Android: adb shell setprop debug.firebase.analytics.app com.example.app
// iOS: -FIRAnalyticsDebugEnabled 런타임 인수 추가
```

## 체크리스트

- [ ] Firebase Analytics, Crashlytics 패키지 설치
- [ ] Firebase 프로젝트 설정 (google-services.json, GoogleService-Info.plist)
- [ ] Crashlytics 초기화 및 에러 핸들러 설정
- [ ] AnalyticsService 인터페이스 및 구현체 작성
- [ ] CrashlyticsService 구현
- [ ] 이벤트 상수 정의 (AnalyticsEvents, AnalyticsParams)
- [ ] AnalyticsLogger 래퍼 클래스 구현
- [ ] GoRouter에 FirebaseAnalyticsObserver 연결
- [ ] BlocObserver에 Analytics 로깅 추가
- [ ] 개발용 Logger 설정
- [ ] 로그인/로그아웃 시 사용자 정보 설정
- [ ] 국가별 기본 파라미터 설정
- [ ] DebugView로 이벤트 확인
