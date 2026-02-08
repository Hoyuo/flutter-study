# Flutter 인앱 결제 가이드 (In-App Purchase)

> **난이도**: 고급 | **카테고리**: features
> **선행 학습**: [Architecture](../core/Architecture.md)
> **예상 학습 시간**: 3h

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - iOS/Android 인앱 결제 흐름을 이해하고 통합 구현할 수 있다
> - 구독, 소모품, 비소모품 상품 유형별 결제를 처리할 수 있다
> - 서버 사이드 영수증 검증과 보안 패턴을 적용할 수 있다

## 개요

인앱 결제(IAP)는 앱 내에서 디지털 상품, 구독, 프리미엄 기능을 판매하는 핵심 수익화 방법입니다. iOS App Store와 Google Play Store의 결제 시스템을 통합하여 안전하고 일관된 결제 경험을 제공합니다.

### 상품 유형

| 유형 | 설명 | 예시 |
|------|------|------|
| **Consumable** | 사용하면 소진되는 상품 | 게임 코인, 크레딧 |
| **Non-Consumable** | 한 번 구매하면 영구 소유 | 광고 제거, 프리미엄 테마 |
| **Auto-Renewable Subscription** | 자동 갱신 구독 | 월간/연간 프리미엄 |
| **Non-Renewing Subscription** | 수동 갱신 구독 | 시즌 패스 |

## 패키지 설정

### 의존성 추가

```yaml
# pubspec.yaml (2026년 2월 기준)
dependencies:
  # 공식 Flutter 인앱 결제 패키지
  in_app_purchase: ^3.2.3

  # 또는 RevenueCat (권장 - 서버 인프라 포함)
  purchases_flutter: ^8.10.0

  # 상태 관리
  flutter_bloc: ^9.1.1

  # 네트워크
  dio: ^5.9.1
```

### Android 설정

```kotlin
// android/app/build.gradle.kts
android {
    defaultConfig {
        // 결제 라이브러리 최소 버전
        minSdk = 21
    }
}

dependencies {
    // Google Play Billing Library (자동 포함되지만 명시적 버전 지정 가능)
    implementation("com.android.billingclient:billing-ktx:7.0.0")
}
```

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
    <!-- 결제 권한 (자동 추가됨) -->
    <uses-permission android:name="com.android.vending.BILLING" />
</manifest>
```

### iOS 설정

```xml
<!-- ios/Runner/Info.plist -->
<dict>
    <!-- StoreKit 설정 -->
    <key>SKAdNetworkItems</key>
    <array>
        <dict>
            <key>SKAdNetworkIdentifier</key>
            <string>cstr6suwn9.skadnetwork</string>
        </dict>
    </array>
</dict>
```

Xcode에서:
1. Signing & Capabilities > + Capability
2. "In-App Purchase" 추가

## 상품 정의

### 스토어 콘솔 설정

#### Google Play Console
1. 앱 선택 > 수익 창출 > 인앱 상품
2. 상품 ID, 이름, 설명, 가격 설정
3. 활성화

#### App Store Connect
1. 앱 선택 > 인앱 구입 > 관리
2. 상품 유형 선택 후 생성
3. 제품 ID, 참조 이름, 가격 설정
4. 검토용 스크린샷 업로드

### 상품 ID 상수

```dart
// lib/core/iap/product_ids.dart
abstract class ProductIds {
  // Consumable (소모품)
  static const coins100 = 'coins_100';
  static const coins500 = 'coins_500';
  static const coins1000 = 'coins_1000';

  // Non-Consumable (비소모품)
  static const removeAds = 'remove_ads';
  static const premiumThemes = 'premium_themes';
  static const unlockAllFeatures = 'unlock_all_features';

  // Subscriptions (구독)
  static const premiumMonthly = 'premium_monthly';
  static const premiumYearly = 'premium_yearly';
  static const premiumLifetime = 'premium_lifetime';

  // 모든 상품 ID 집합
  static const Set<String> all = {
    coins100,
    coins500,
    coins1000,
    removeAds,
    premiumThemes,
    unlockAllFeatures,
    premiumMonthly,
    premiumYearly,
    premiumLifetime,
  };

  // 구독 상품 ID 집합
  static const Set<String> subscriptions = {
    premiumMonthly,
    premiumYearly,
    premiumLifetime,
  };

  // 소모품 ID 집합
  static const Set<String> consumables = {
    coins100,
    coins500,
    coins1000,
  };
}
```

### 상품 모델

```dart
// lib/core/iap/models/iap_product.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

part 'iap_product.freezed.dart';

@freezed
class IAPProduct with _$IAPProduct {
  const factory IAPProduct({
    required String id,
    required String title,
    required String description,
    required String price,
    required double rawPrice,
    required String currencyCode,
    required ProductType type,
    ProductDetails? storeProduct,
  }) = _IAPProduct;

  const IAPProduct._();

  /// 구독 상품인지 확인
  bool get isSubscription => type == ProductType.subscription;

  /// 소모품인지 확인
  bool get isConsumable => type == ProductType.consumable;
}

enum ProductType {
  consumable,
  nonConsumable,
  subscription,
}
```

## 결제 서비스 구현

### IAP Service (핵심)

```dart
// lib/core/iap/iap_service.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:injectable/injectable.dart';

import 'models/iap_product.dart';
import 'product_ids.dart';

@lazySingleton
class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _purchaseController = StreamController<PurchaseUpdate>.broadcast();

  /// 구매 상태 스트림
  Stream<PurchaseUpdate> get purchaseStream => _purchaseController.stream;

  /// 서비스 사용 가능 여부
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// 로드된 상품 목록
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  /// 초기화
  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();

    if (!_isAvailable) {
      debugPrint('IAP not available on this device');
      return;
    }

    // 플랫폼별 초기화
    if (Platform.isIOS) {
      final iosPlatformAddition = _iap
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(PaymentQueueDelegate());
    }

    // 구매 스트림 리스닝
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: _onDone,
      onError: _onError,
    );

    // 상품 로드
    await loadProducts();
  }

  /// 상품 로드
  Future<List<ProductDetails>> loadProducts() async {
    if (!_isAvailable) return [];

    final response = await _iap.queryProductDetails(ProductIds.all);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }

    if (response.error != null) {
      debugPrint('Error loading products: ${response.error}');
      return [];
    }

    _products = response.productDetails;
    return _products;
  }

  /// 상품 구매
  Future<bool> buyProduct(ProductDetails product) async {
    if (!_isAvailable) {
      _purchaseController.add(PurchaseUpdate.error('IAP not available'));
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      if (ProductIds.consumables.contains(product.id)) {
        // 소모품 구매
        return await _iap.buyConsumable(purchaseParam: purchaseParam);
      } else {
        // 비소모품/구독 구매
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      _purchaseController.add(PurchaseUpdate.error(e.toString()));
      return false;
    }
  }

  /// 구매 복원
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    await _iap.restorePurchases();
  }

  /// 구매 처리
  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _processPurchase(purchase);
    }
  }

  Future<void> _processPurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        // 결제 보류 중 (일부 지역 결제 방식)
        _purchaseController.add(PurchaseUpdate.pending(purchase.productID));

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // 구매 완료 또는 복원
        final verified = await _verifyPurchase(purchase);
        if (verified) {
          await _deliverProduct(purchase);
          _purchaseController.add(PurchaseUpdate.success(
            purchase.productID,
            isRestored: purchase.status == PurchaseStatus.restored,
          ));
        } else {
          _purchaseController.add(
            PurchaseUpdate.error('Verification failed for ${purchase.productID}'),
          );
        }
        // 구매 완료 처리 (필수!)
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }

      case PurchaseStatus.error:
        _purchaseController.add(
          PurchaseUpdate.error(purchase.error?.message ?? 'Purchase failed'),
        );
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }

      case PurchaseStatus.canceled:
        _purchaseController.add(PurchaseUpdate.canceled(purchase.productID));
    }
  }

  /// 서버에서 영수증 검증 (필수!)
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // ⚠️ 중요: 클라이언트에서 검증하지 말고 반드시 서버에서 검증!
    // 이 예제는 간단한 구현이며, 실제로는 서버 API를 호출해야 함

    // TODO: 서버 검증 구현
    // final response = await _apiClient.verifyPurchase(
    //   platform: Platform.isIOS ? 'ios' : 'android',
    //   receipt: purchase.verificationData.serverVerificationData,
    //   productId: purchase.productID,
    //   transactionId: purchase.purchaseID,
    // );
    // return response.isValid;

    // 개발 중 임시로 true 반환 (프로덕션에서는 반드시 서버 검증!)
    debugPrint('⚠️ WARNING: Skipping server verification in development');
    return true;
  }

  /// 상품 전달
  Future<void> _deliverProduct(PurchaseDetails purchase) async {
    final productId = purchase.productID;

    // 상품 유형에 따른 처리
    if (ProductIds.consumables.contains(productId)) {
      // 소모품: 수량 증가
      await _deliverConsumable(productId);
    } else if (ProductIds.subscriptions.contains(productId)) {
      // 구독: 프리미엄 상태 활성화
      await _activateSubscription(productId);
    } else {
      // 비소모품: 영구 잠금 해제
      await _unlockFeature(productId);
    }
  }

  Future<void> _deliverConsumable(String productId) async {
    // TODO: 로컬 또는 서버에 코인/크레딧 추가
    debugPrint('Delivering consumable: $productId');
  }

  Future<void> _activateSubscription(String productId) async {
    // TODO: 구독 상태 활성화
    debugPrint('Activating subscription: $productId');
  }

  Future<void> _unlockFeature(String productId) async {
    // TODO: 기능 잠금 해제
    debugPrint('Unlocking feature: $productId');
  }

  void _onDone() {
    _subscription?.cancel();
  }

  void _onError(Object error) {
    debugPrint('Purchase stream error: $error');
  }

  /// 리소스 정리
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _purchaseController.close();
  }
}

/// iOS 결제 대기열 델리게이트
///
/// ⚠️ 주의: SKPaymentQueueDelegateWrapper는 StoreKit 1 API로,
/// iOS 18.0에서 deprecated 되었습니다.
/// 새 프로젝트에서는 StoreKit 2 API 사용을 권장합니다.
///
/// StoreKit 2 마이그레이션:
/// - in_app_purchase_storekit2 패키지 사용 고려
/// - iOS 15+ 타겟 시 네이티브 StoreKit 2 사용 가능
///
/// > **⚠️ StoreKit 2 마이그레이션 필수 (2026년 2월 기준)**
/// >
/// > StoreKit 1 API는 iOS 18+에서 deprecated되었으며, Apple은 새 프로젝트에서
/// > StoreKit 2 사용을 강력히 권장합니다. 기존 프로젝트도 점진적 마이그레이션을 계획하세요.
/// >
/// > **마이그레이션 경로:**
/// > 1. iOS 15+ 타겟: 네이티브 StoreKit 2 + MethodChannel
/// > 2. iOS 13-14 호환 필요: in_app_purchase_storekit2 패키지 (bridging 제공)
/// > 3. 혼합 환경: StoreKit 2 우선, fallback으로 StoreKit 1 유지
/// >
/// > StoreKit 2 주요 개선사항:
/// > - async/await 기반 현대적 API
/// > - Transaction 자동 갱신 및 관리
/// > - 서버 검증 간소화 (JWS 서명)
/// > - 구독 상태 실시간 모니터링
class PaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}

/// 구매 상태 업데이트
sealed class PurchaseUpdate {
  const PurchaseUpdate();

  factory PurchaseUpdate.pending(String productId) = PurchasePending;
  factory PurchaseUpdate.success(String productId, {bool isRestored = false}) = PurchaseSuccess;
  factory PurchaseUpdate.error(String message) = PurchaseError;
  factory PurchaseUpdate.canceled(String productId) = PurchaseCanceled;
}

class PurchasePending extends PurchaseUpdate {
  final String productId;
  const PurchasePending(this.productId);
}

class PurchaseSuccess extends PurchaseUpdate {
  final String productId;
  final bool isRestored;
  const PurchaseSuccess(this.productId, {this.isRestored = false});
}

class PurchaseError extends PurchaseUpdate {
  final String message;
  const PurchaseError(this.message);
}

class PurchaseCanceled extends PurchaseUpdate {
  final String productId;
  const PurchaseCanceled(this.productId);
}
```

## 서버 영수증 검증

### 검증의 중요성

클라이언트에서 영수증을 검증하면 해킹에 취약합니다. **반드시 서버에서 검증해야 합니다.**

```
[앱] → 구매 완료 → [서버] → 스토어 API 검증 → [앱] 상품 전달
```

### 서버 검증 API

```dart
// lib/core/iap/iap_verification_service.dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class IAPVerificationService {
  final Dio _dio;

  IAPVerificationService(this._dio);

  /// 서버에서 영수증 검증
  Future<VerificationResult> verifyPurchase({
    required String platform,
    required String receipt,
    required String productId,
    required String? transactionId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/purchases/verify',
        data: {
          'platform': platform,
          'receipt': receipt,
          'product_id': productId,
          'transaction_id': transactionId,
        },
      );

      return VerificationResult.fromJson(response.data);
    } on DioException catch (e) {
      return VerificationResult(
        isValid: false,
        errorMessage: e.message,
      );
    }
  }

  /// 구독 상태 확인
  Future<SubscriptionStatus> checkSubscriptionStatus() async {
    try {
      final response = await _dio.get('/api/v1/subscription/status');
      return SubscriptionStatus.fromJson(response.data);
    } on DioException {
      return const SubscriptionStatus(isActive: false);
    }
  }
}

class VerificationResult {
  final bool isValid;
  final String? errorMessage;
  final DateTime? expiresAt;

  const VerificationResult({
    required this.isValid,
    this.errorMessage,
    this.expiresAt,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      isValid: json['valid'] == true,
      errorMessage: json['error_message'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }
}

class SubscriptionStatus {
  final bool isActive;
  final String? productId;
  final DateTime? expiresAt;
  final bool willRenew;

  const SubscriptionStatus({
    required this.isActive,
    this.productId,
    this.expiresAt,
    this.willRenew = false,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      isActive: json['is_active'] == true,
      productId: json['product_id'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      willRenew: json['will_renew'] == true,
    );
  }
}
```

### 서버 측 검증 (Node.js 예시)

```javascript
// server/verify-purchase.js
const { google } = require('googleapis');
const axios = require('axios');

// Android 검증
async function verifyAndroidPurchase(receipt, productId) {
  const auth = new google.auth.GoogleAuth({
    keyFile: 'service-account.json',
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });

  const androidPublisher = google.androidpublisher({ version: 'v3', auth });

  const purchaseData = JSON.parse(receipt);

  try {
    // 구독 검증
    if (isSubscription(productId)) {
      const response = await androidPublisher.purchases.subscriptions.get({
        packageName: 'com.example.app',
        subscriptionId: productId,
        token: purchaseData.purchaseToken,
      });

      return {
        valid: response.data.paymentState === 1,
        expiresAt: new Date(parseInt(response.data.expiryTimeMillis)),
      };
    }

    // 일반 상품 검증
    const response = await androidPublisher.purchases.products.get({
      packageName: 'com.example.app',
      productId: productId,
      token: purchaseData.purchaseToken,
    });

    return {
      valid: response.data.purchaseState === 0,
    };
  } catch (error) {
    console.error('Android verification failed:', error);
    return { valid: false, error: error.message };
  }
}

// iOS 검증 (App Store Server API - 권장)
async function verifyiOSPurchase(receipt) {
  // App Store Server API v2 사용 (JWT 인증)
  const jwt = generateAppStoreJWT();

  try {
    // 거래 내역 조회
    const response = await axios.get(
      `https://api.storekit.itunes.apple.com/inApps/v1/transactions/${transactionId}`,
      {
        headers: {
          Authorization: `Bearer ${jwt}`,
        },
      }
    );

    const decodedTransaction = decodeJWS(response.data.signedTransactionInfo);

    return {
      valid: true,
      expiresAt: new Date(decodedTransaction.expiresDate),
      productId: decodedTransaction.productId,
    };
  } catch (error) {
    console.error('iOS verification failed:', error);
    return { valid: false, error: error.message };
  }
}
```

## 구독 관리

### 구독 상태 모델

```dart
// lib/core/iap/models/subscription_info.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_info.freezed.dart';
part 'subscription_info.g.dart';

@freezed
class SubscriptionInfo with _$SubscriptionInfo {
  const factory SubscriptionInfo({
    required bool isActive,
    String? productId,
    DateTime? purchaseDate,
    DateTime? expiresDate,
    @Default(false) bool willRenew,
    @Default(false) bool isInGracePeriod,
    @Default(false) bool isInBillingRetry,
    SubscriptionPlan? plan,
  }) = _SubscriptionInfo;

  const SubscriptionInfo._();

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionInfoFromJson(json);

  /// 남은 일수
  int get daysRemaining {
    if (expiresDate == null) return 0;
    return expiresDate!.difference(DateTime.now()).inDays;
  }

  /// 만료 임박 여부 (7일 이내)
  bool get isExpiringSoon => daysRemaining <= 7 && daysRemaining > 0;

  /// 만료됨
  bool get isExpired => expiresDate?.isBefore(DateTime.now()) ?? true;
}

enum SubscriptionPlan {
  monthly,
  yearly,
  lifetime;

  String get displayName {
    return switch (this) {
      monthly => '월간 구독',
      yearly => '연간 구독',
      lifetime => '평생 이용권',
    };
  }
}
```

### 구독 관리 서비스

```dart
// lib/core/iap/subscription_service.dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'iap_verification_service.dart';
import 'models/subscription_info.dart';

@lazySingleton
class SubscriptionService {
  final IAPVerificationService _verificationService;
  final SharedPreferences _prefs;

  static const _keySubscriptionCache = 'subscription_cache';
  static const _keyCacheExpiry = 'subscription_cache_expiry';

  SubscriptionInfo? _cachedInfo;

  SubscriptionService(this._verificationService, this._prefs);

  /// 구독 상태 확인 (캐시 사용)
  Future<SubscriptionInfo> getSubscriptionStatus({
    bool forceRefresh = false,
  }) async {
    // 캐시 확인 (5분)
    if (!forceRefresh && _isCacheValid()) {
      return _cachedInfo!;
    }

    // 서버에서 상태 조회
    final status = await _verificationService.checkSubscriptionStatus();

    final info = SubscriptionInfo(
      isActive: status.isActive,
      productId: status.productId,
      expiresDate: status.expiresAt,
      willRenew: status.willRenew,
      plan: _planFromProductId(status.productId),
    );

    // 캐시 저장
    await _cacheStatus(info);
    _cachedInfo = info;

    return info;
  }

  /// 프리미엄 기능 접근 가능 여부
  Future<bool> canAccessPremium() async {
    final status = await getSubscriptionStatus();
    return status.isActive;
  }

  /// 구독 관리 페이지 열기
  Future<void> openSubscriptionManagement() async {
    // 플랫폼별 구독 관리 페이지로 이동
    // iOS: App Store 구독 설정
    // Android: Google Play 구독 설정
  }

  bool _isCacheValid() {
    if (_cachedInfo == null) return false;

    final expiry = _prefs.getInt(_keyCacheExpiry) ?? 0;
    return DateTime.now().millisecondsSinceEpoch < expiry;
  }

  Future<void> _cacheStatus(SubscriptionInfo info) async {
    final expiry = DateTime.now()
        .add(const Duration(minutes: 5))
        .millisecondsSinceEpoch;
    await _prefs.setInt(_keyCacheExpiry, expiry);
  }

  SubscriptionPlan? _planFromProductId(String? productId) {
    return switch (productId) {
      'premium_monthly' => SubscriptionPlan.monthly,
      'premium_yearly' => SubscriptionPlan.yearly,
      'premium_lifetime' => SubscriptionPlan.lifetime,
      _ => null,
    };
  }
}
```

## Bloc 통합

### IAP Events

```dart
// lib/core/iap/bloc/iap_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// PurchaseUpdate 모델 import 필요
// import '../models/purchase_update.dart';

part 'iap_event.freezed.dart';

@freezed
sealed class IAPEvent with _$IAPEvent {
  /// 초기화
  const factory IAPEvent.initialize() = IAPInitialize;

  /// 상품 로드
  const factory IAPEvent.loadProducts() = IAPLoadProducts;

  /// 구매 시작
  const factory IAPEvent.purchase(ProductDetails product) = IAPPurchase;

  /// 구매 복원
  const factory IAPEvent.restore() = IAPRestore;

  /// 구매 상태 업데이트
  const factory IAPEvent.purchaseUpdated(PurchaseUpdate update) = IAPPurchaseUpdated;

  /// 구독 상태 확인
  const factory IAPEvent.checkSubscription() = IAPCheckSubscription;
}
```

### IAP State

```dart
// lib/core/iap/bloc/iap_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/subscription_info.dart';

part 'iap_state.freezed.dart';

@freezed
class IAPState with _$IAPState {
  const factory IAPState({
    @Default(false) bool isAvailable,
    @Default(false) bool isLoading,
    @Default([]) List<ProductDetails> products,
    String? purchasingProductId,
    SubscriptionInfo? subscriptionInfo,
    String? errorMessage,
  }) = _IAPState;

  const IAPState._();

  /// 프리미엄 사용자인지
  bool get isPremium => subscriptionInfo?.isActive ?? false;

  /// 특정 상품 구매 중인지
  bool isPurchasing(String productId) => purchasingProductId == productId;
}
```

### IAP Bloc

```dart
// lib/core/iap/bloc/iap_bloc.dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../iap_service.dart';
import '../subscription_service.dart';
import 'iap_event.dart';
import 'iap_state.dart';

@injectable
class IAPBloc extends Bloc<IAPEvent, IAPState> {
  final IAPService _iapService;
  final SubscriptionService _subscriptionService;

  StreamSubscription<PurchaseUpdate>? _purchaseSubscription;

  IAPBloc(this._iapService, this._subscriptionService) : super(const IAPState()) {
    on<IAPInitialize>(_onInitialize);
    on<IAPLoadProducts>(_onLoadProducts);
    on<IAPPurchase>(_onPurchase);
    on<IAPRestore>(_onRestore);
    on<IAPPurchaseUpdated>(_onPurchaseUpdated);
    on<IAPCheckSubscription>(_onCheckSubscription);
  }

  Future<void> _onInitialize(
    IAPInitialize event,
    Emitter<IAPState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    await _iapService.initialize();

    // 구매 스트림 리스닝
    _purchaseSubscription = _iapService.purchaseStream.listen(
      (update) => add(IAPEvent.purchaseUpdated(update)),
    );

    emit(state.copyWith(
      isAvailable: _iapService.isAvailable,
      products: _iapService.products,
      isLoading: false,
    ));

    // 구독 상태 확인
    add(const IAPEvent.checkSubscription());
  }

  Future<void> _onLoadProducts(
    IAPLoadProducts event,
    Emitter<IAPState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final products = await _iapService.loadProducts();

    emit(state.copyWith(
      products: products,
      isLoading: false,
    ));
  }

  Future<void> _onPurchase(
    IAPPurchase event,
    Emitter<IAPState> emit,
  ) async {
    emit(state.copyWith(
      purchasingProductId: event.product.id,
      errorMessage: null,
    ));

    await _iapService.buyProduct(event.product);
  }

  Future<void> _onRestore(
    IAPRestore event,
    Emitter<IAPState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    await _iapService.restorePurchases();

    emit(state.copyWith(isLoading: false));
  }

  void _onPurchaseUpdated(
    IAPPurchaseUpdated event,
    Emitter<IAPState> emit,
  ) {
    switch (event.update) {
      case PurchasePending():
        // 결제 보류 중 - UI에 알림
        break;

      case PurchaseSuccess(:final productId, :final isRestored):
        emit(state.copyWith(purchasingProductId: null));
        // 구독 상태 갱신
        add(const IAPEvent.checkSubscription());

      case PurchaseError(:final message):
        emit(state.copyWith(
          purchasingProductId: null,
          errorMessage: message,
        ));

      case PurchaseCanceled():
        emit(state.copyWith(purchasingProductId: null));
    }
  }

  Future<void> _onCheckSubscription(
    IAPCheckSubscription event,
    Emitter<IAPState> emit,
  ) async {
    final info = await _subscriptionService.getSubscriptionStatus();
    emit(state.copyWith(subscriptionInfo: info));
  }

  @override
  Future<void> close() {
    _purchaseSubscription?.cancel();
    return super.close();
  }
}
```

## UI 구현

### 구독 페이지

```dart
// lib/features/subscription/presentation/pages/subscription_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/iap/bloc/iap_bloc.dart';
import '../../../../core/iap/bloc/iap_event.dart';
import '../../../../core/iap/bloc/iap_state.dart';
import '../../../../core/iap/product_ids.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프리미엄 구독'),
        actions: [
          TextButton(
            onPressed: () {
              context.read<IAPBloc>().add(const IAPEvent.restore());
            },
            child: const Text('복원'),
          ),
        ],
      ),
      body: BlocConsumer<IAPBloc, IAPState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (!state.isAvailable) {
            return const Center(
              child: Text('인앱 결제를 사용할 수 없습니다.'),
            );
          }

          if (state.isLoading && state.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 현재 구독 상태
                if (state.isPremium) ...[
                  _buildCurrentSubscriptionCard(context, state),
                  const SizedBox(height: 24),
                ],

                // 혜택 목록
                _buildBenefitsSection(),
                const SizedBox(height: 24),

                // 구독 옵션
                _buildSubscriptionOptions(context, state),
                const SizedBox(height: 16),

                // 약관
                _buildTermsText(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard(BuildContext context, IAPState state) {
    final info = state.subscriptionInfo!;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '프리미엄 구독 중',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('플랜: ${info.plan?.displayName ?? "알 수 없음"}'),
            if (info.expiresDate != null)
              Text('만료일: ${_formatDate(info.expiresDate!)}'),
            if (info.willRenew)
              const Text('자동 갱신 예정', style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '프리미엄 혜택',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildBenefitItem(Icons.block, '광고 제거'),
        _buildBenefitItem(Icons.cloud_upload, '무제한 클라우드 백업'),
        _buildBenefitItem(Icons.palette, '프리미엄 테마'),
        _buildBenefitItem(Icons.analytics, '고급 통계'),
        _buildBenefitItem(Icons.support_agent, '우선 고객 지원'),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOptions(BuildContext context, IAPState state) {
    final subscriptionProducts = state.products
        .where((p) => ProductIds.subscriptions.contains(p.id))
        .toList();

    return Column(
      children: subscriptionProducts.map((product) {
        return _SubscriptionCard(
          product: product,
          isSelected: false,
          isPurchasing: state.isPurchasing(product.id),
          onTap: () {
            context.read<IAPBloc>().add(IAPEvent.purchase(product));
          },
        );
      }).toList(),
    );
  }

  Widget _buildTermsText() {
    return const Text(
      '구독은 확인 시 iTunes 계정에 청구됩니다. '
      '현재 기간이 끝나기 최소 24시간 전에 자동 갱신을 끄지 않으면 구독이 자동으로 갱신됩니다. '
      '구독 관리는 구매 후 계정 설정에서 할 수 있습니다.',
      style: TextStyle(fontSize: 12, color: Colors.grey),
      textAlign: TextAlign.center,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}

class _SubscriptionCard extends StatelessWidget {
  final ProductDetails product;
  final bool isSelected;
  final bool isPurchasing;
  final VoidCallback onTap;

  const _SubscriptionCard({
    required this.product,
    required this.isSelected,
    required this.isPurchasing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isYearly = product.id.contains('yearly');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isPurchasing ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isYearly) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '베스트',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.price,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isYearly)
                    const Text(
                      '월 ₩4,900',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              if (isPurchasing)
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 프리미엄 기능 게이트

```dart
// lib/core/iap/widgets/premium_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/iap_bloc.dart';
import '../bloc/iap_state.dart';

/// 프리미엄 기능을 감싸는 위젯
class PremiumGate extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final String? featureName;

  const PremiumGate({
    required this.child,
    this.fallback,
    this.featureName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IAPBloc, IAPState>(
      builder: (context, state) {
        if (state.isPremium) {
          return child;
        }

        return fallback ?? _DefaultFallback(featureName: featureName);
      },
    );
  }
}

class _DefaultFallback extends StatelessWidget {
  final String? featureName;

  const _DefaultFallback({this.featureName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            featureName != null
                ? '$featureName은(는) 프리미엄 기능입니다'
                : '프리미엄 기능입니다',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/subscription'),
            child: const Text('프리미엄 구독하기'),
          ),
        ],
      ),
    );
  }
}

/// 프리미엄 버튼 (비프리미엄 사용자에게 잠금 표시)
class PremiumButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final String? featureName;

  const PremiumButton({
    required this.onPressed,
    required this.child,
    this.featureName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IAPBloc, IAPState>(
      builder: (context, state) {
        if (state.isPremium) {
          return ElevatedButton(
            onPressed: onPressed,
            child: child,
          );
        }

        return ElevatedButton.icon(
          onPressed: () => _showPremiumDialog(context),
          icon: const Icon(Icons.lock, size: 16),
          label: child,
        );
      },
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프리미엄 기능'),
        content: Text(
          featureName != null
              ? '$featureName을(를) 사용하려면 프리미엄 구독이 필요합니다.'
              : '이 기능을 사용하려면 프리미엄 구독이 필요합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/subscription');
            },
            child: const Text('구독하기'),
          ),
        ],
      ),
    );
  }
}
```

## 복원 기능

### 복원 처리

```dart
// lib/features/settings/presentation/widgets/restore_purchases_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/iap/bloc/iap_bloc.dart';
import '../../../../core/iap/bloc/iap_event.dart';
import '../../../../core/iap/bloc/iap_state.dart';

class RestorePurchasesButton extends StatelessWidget {
  const RestorePurchasesButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IAPBloc, IAPState>(
      listenWhen: (prev, curr) =>
          prev.isLoading && !curr.isLoading,
      listener: (context, state) {
        final message = state.isPremium
            ? '구매가 복원되었습니다.'
            : '복원할 구매가 없습니다.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      builder: (context, state) {
        return ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('구매 복원'),
          subtitle: const Text('이전에 구매한 항목을 복원합니다'),
          trailing: state.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
          onTap: state.isLoading
              ? null
              : () {
                  context.read<IAPBloc>().add(const IAPEvent.restore());
                },
        );
      },
    );
  }
}
```

## RevenueCat 통합 (대안)

서버 인프라 없이 인앱 결제를 구현하려면 RevenueCat을 권장합니다.

### RevenueCat 설정

```dart
// lib/core/iap/revenuecat_service.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

@lazySingleton
class RevenueCatService {
  static const _apiKeyAndroid = 'goog_xxx';
  static const _apiKeyIOS = 'appl_xxx';

  /// 초기화
  Future<void> initialize() async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

    final configuration = PurchasesConfiguration(
      Platform.isAndroid ? _apiKeyAndroid : _apiKeyIOS,
    );

    await Purchases.configure(configuration);
  }

  /// 사용자 ID 설정 (로그인 시)
  Future<void> setUserId(String userId) async {
    await Purchases.logIn(userId);
  }

  /// 로그아웃
  Future<void> logout() async {
    await Purchases.logOut();
  }

  /// 오퍼링 (상품 목록) 조회
  Future<Offerings> getOfferings() async {
    return await Purchases.getOfferings();
  }

  /// 구매
  Future<CustomerInfo> purchase(Package package) async {
    return await Purchases.purchasePackage(package);
  }

  /// 복원
  Future<CustomerInfo> restore() async {
    return await Purchases.restorePurchases();
  }

  /// 고객 정보 조회
  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  /// 프리미엄 상태 확인
  Future<bool> isPremium() async {
    final customerInfo = await getCustomerInfo();
    return customerInfo.entitlements.active.containsKey('premium');
  }

  /// 고객 정보 스트림
  Stream<CustomerInfo> get customerInfoStream {
    return Purchases.customerInfoStream;
  }
}
```

### RevenueCat Bloc

```dart
// lib/core/iap/bloc/revenuecat_bloc.dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../revenuecat_service.dart';

part 'revenuecat_bloc.freezed.dart';

@freezed
class RevenueCatEvent with _$RevenueCatEvent {
  const factory RevenueCatEvent.initialize() = RevenueCatInitialize;
  const factory RevenueCatEvent.loadOfferings() = RevenueCatLoadOfferings;
  const factory RevenueCatEvent.purchase(Package package) = RevenueCatPurchase;
  const factory RevenueCatEvent.restore() = RevenueCatRestore;
  const factory RevenueCatEvent.customerInfoUpdated(CustomerInfo info) = RevenueCatCustomerInfoUpdated;
}

@freezed
class RevenueCatState with _$RevenueCatState {
  const factory RevenueCatState({
    @Default(false) bool isInitialized,
    @Default(false) bool isLoading,
    @Default(false) bool isPremium,
    @Default(false) bool isPurchasing,
    @Default(false) bool isRestoring,
    Offerings? offerings,
    CustomerInfo? customerInfo,
    String? error,
    String? errorMessage,
  }) = _RevenueCatState;
}

@injectable
class RevenueCatBloc extends Bloc<RevenueCatEvent, RevenueCatState> {
  final RevenueCatService _service;
  StreamSubscription<CustomerInfo>? _subscription;

  RevenueCatBloc(this._service) : super(const RevenueCatState()) {
    on<RevenueCatInitialize>(_onInitialize);
    on<RevenueCatLoadOfferings>(_onLoadOfferings);
    on<RevenueCatPurchase>(_onPurchase);
    on<RevenueCatRestore>(_onRestore);
    on<RevenueCatCustomerInfoUpdated>(_onCustomerInfoUpdated);
  }

  Future<void> _onInitialize(
    RevenueCatInitialize event,
    Emitter<RevenueCatState> emit,
  ) async {
    await _service.initialize();

    // 고객 정보 스트림 리스닝
    _subscription = _service.customerInfoStream.listen(
      (info) => add(RevenueCatCustomerInfoUpdated(info)),
    );

    // 초기 고객 정보 로드
    final customerInfo = await _service.getCustomerInfo();
    emit(state.copyWith(
      customerInfo: customerInfo,
      isPremium: customerInfo.entitlements.active.containsKey('premium'),
    ));

    // 오퍼링 로드
    add(const RevenueCatLoadOfferings());
  }

  Future<void> _onLoadOfferings(
    RevenueCatLoadOfferings event,
    Emitter<RevenueCatState> emit,
  ) async {
    final offerings = await _service.getOfferings();
    emit(state.copyWith(offerings: offerings));
  }

  Future<void> _onPurchase(
    RevenueCatPurchase event,
    Emitter<RevenueCatState> emit,
  ) async {
    emit(state.copyWith(isPurchasing: true, error: null));

    try {
      final customerInfo = await _service.purchase(event.package);
      emit(state.copyWith(
        isPurchasing: false,
        customerInfo: customerInfo,
        isPremium: customerInfo.entitlements.active.containsKey('premium'),
      ));
    } catch (e) {
      emit(state.copyWith(
        isPurchasing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRestore(
    RevenueCatRestore event,
    Emitter<RevenueCatState> emit,
  ) async {
    emit(state.copyWith(isRestoring: true, error: null));

    try {
      final customerInfo = await _service.restore();
      emit(state.copyWith(
        isRestoring: false,
        customerInfo: customerInfo,
        isPremium: customerInfo.entitlements.active.containsKey('premium'),
      ));
    } catch (e) {
      emit(state.copyWith(
        isRestoring: false,
        error: e.toString(),
      ));
    }
  }

  void _onCustomerInfoUpdated(
    RevenueCatCustomerInfoUpdated event,
    Emitter<RevenueCatState> emit,
  ) {
    emit(state.copyWith(
      customerInfo: event.customerInfo,
      isPremium: event.customerInfo.entitlements.active.containsKey('premium'),
    ));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

## 테스트

### 테스트 환경 설정

#### Android - 라이선스 테스터
1. Google Play Console > 설정 > 라이선스 테스트
2. Gmail 계정 추가
3. 테스트 기기에서 해당 계정으로 로그인

#### iOS - 샌드박스 테스터
1. App Store Connect > 사용자 및 액세스 > 샌드박스 테스터
2. 새 테스터 추가
3. 테스트 기기 설정 > App Store > 샌드박스 계정

### 테스트 시나리오

```dart
// test/core/iap/iap_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInAppPurchase extends Mock implements InAppPurchase {}

void main() {
  late MockInAppPurchase mockIAP;
  late IAPService service;

  setUp(() {
    mockIAP = MockInAppPurchase();
    // ⚠️ 주의: 현재 IAPService는 내부에서 InAppPurchase.instance를 생성하므로
    // 테스트를 위해서는 IAPService를 DI 패턴으로 수정해야 합니다:
    //
    // class IAPService {
    //   final InAppPurchase _iap;
    //   IAPService({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;
    // }
    //
    // 수정 후:
    // service = IAPService(iap: mockIAP);
    service = IAPService();
  });

  group('IAPService', () {
    test('should return false when IAP not available', () async {
      when(() => mockIAP.isAvailable()).thenAnswer((_) async => false);

      await service.initialize();

      expect(service.isAvailable, false);
    });

    test('should load products successfully', () async {
      when(() => mockIAP.isAvailable()).thenAnswer((_) async => true);
      when(() => mockIAP.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [
            // Mock product details
          ],
          notFoundIDs: [],
          error: null,
        ),
      );

      await service.initialize();
      final products = await service.loadProducts();

      expect(products, isNotEmpty);
    });
  });
}
```

### StoreKit 테스트 구성 (iOS)

```swift
// ios/Runner/Configuration.storekit
// Xcode에서 StoreKit Configuration File 생성
// 로컬 테스트용 상품 정의
```

## 에러 처리

### 일반적인 에러 시나리오

```dart
// lib/core/iap/iap_error_handler.dart
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPErrorHandler {
  static String getErrorMessage(IAPError error) {
    // 플랫폼별 에러 코드 처리
    return switch (error.code) {
      'E_USER_CANCELLED' => '구매가 취소되었습니다.',
      'E_ITEM_UNAVAILABLE' => '상품을 사용할 수 없습니다.',
      'E_NETWORK_ERROR' => '네트워크 오류가 발생했습니다. 다시 시도해주세요.',
      'E_SERVICE_ERROR' => '스토어 서비스에 문제가 발생했습니다.',
      'E_ALREADY_OWNED' => '이미 구매한 상품입니다.',
      'E_NOT_OWNED' => '소유하지 않은 상품입니다.',
      'E_DEVELOPER_ERROR' => '개발자 오류가 발생했습니다.',
      _ => error.message,
    };
  }

  static bool shouldRetry(IAPError error) {
    return switch (error.code) {
      'E_NETWORK_ERROR' => true,
      'E_SERVICE_ERROR' => true,
      _ => false,
    };
  }
}
```

### Pending Purchase 처리

```dart
// 일부 국가에서는 결제가 즉시 완료되지 않음 (예: 편의점 결제)
void _handlePendingPurchase(PurchaseDetails purchase) {
  // UI에 "결제 대기 중" 상태 표시
  // 사용자에게 결제 완료 방법 안내
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('결제 대기 중'),
      content: const Text(
        '선택하신 결제 방법에 따라 결제가 완료되면 자동으로 상품이 지급됩니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}
```

## Best Practices

### 1. 반드시 서버 검증

```dart
// ❌ 잘못된 예 - 클라이언트 검증
Future<bool> verifyPurchase(PurchaseDetails purchase) async {
  // 클라이언트에서 영수증 파싱 - 해킹 가능!
  final receipt = jsonDecode(purchase.verificationData.localVerificationData);
  return receipt['status'] == 'valid';
}

// ✅ 올바른 예 - 서버 검증
Future<bool> verifyPurchase(PurchaseDetails purchase) async {
  final response = await _api.verifyPurchase(
    receipt: purchase.verificationData.serverVerificationData,
    productId: purchase.productID,
  );
  return response.isValid;
}
```

### 2. 구독 상태는 서버에서 관리

```dart
// ❌ 잘못된 예 - 로컬 저장
Future<void> savePremiumStatus(bool isPremium) async {
  await _prefs.setBool('is_premium', isPremium);  // 쉽게 조작 가능!
}

// ✅ 올바른 예 - 서버 조회
Future<bool> checkPremiumStatus() async {
  final response = await _api.getSubscriptionStatus();
  return response.isActive;  // 서버 데이터 기준
}
```

### 3. completePurchase 반드시 호출

```dart
// 구매 처리 후 반드시 완료 처리
Future<void> _processPurchase(PurchaseDetails purchase) async {
  // ... 검증 및 전달 로직

  // 반드시 호출! 안 하면 다음 구매 불가
  if (purchase.pendingCompletePurchase) {
    await _iap.completePurchase(purchase);
  }
}
```

### 4. 가격 표시는 스토어 데이터 사용

```dart
// ❌ 잘못된 예 - 하드코딩
Text('월 ₩9,900');  // 국가별 가격이 다름!

// ✅ 올바른 예 - 스토어 데이터
Text(product.price);  // 사용자 지역에 맞는 가격 표시
```

### 5. 오프라인 대응

```dart
// 오프라인에서도 프리미엄 기능 사용 가능하도록
class SubscriptionCache {
  static const _keyExpiry = 'subscription_expiry';

  Future<bool> isSubscriptionValid() async {
    final expiry = _prefs.getInt(_keyExpiry);
    if (expiry == null) return false;

    // 서버 검증 주기 + 여유 시간
    final gracePeriod = const Duration(days: 3);
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiry);

    return DateTime.now().isBefore(expiryDate.add(gracePeriod));
  }
}
```

## 체크리스트

### 초기 설정
- [ ] `in_app_purchase` 또는 `purchases_flutter` 패키지 설치
- [ ] Android: BILLING 권한 확인
- [ ] iOS: In-App Purchase capability 추가
- [ ] Google Play Console에 상품 등록
- [ ] App Store Connect에 상품 등록
- [ ] 상품 ID 상수 정의

### 결제 흐름
- [ ] IAPService 초기화 로직 구현
- [ ] 상품 로드 기능 구현
- [ ] 구매 스트림 리스닝 설정
- [ ] 구매 상태별 처리 (pending, purchased, error, canceled)
- [ ] `completePurchase` 호출 확인

### 영수증 검증
- [ ] 서버 검증 API 구현 (필수!)
- [ ] Android: Google Play Developer API 연동
- [ ] iOS: App Store Server API 연동
- [ ] 검증 실패 시 에러 처리

### 구독 관리
- [ ] 구독 상태 모델 정의
- [ ] 서버에서 구독 상태 조회
- [ ] 구독 만료 처리
- [ ] 자동 갱신 상태 표시
- [ ] 구독 관리 페이지 링크

### UI/UX
- [ ] 구독 페이지 UI 구현
- [ ] 프리미엄 기능 게이트 구현
- [ ] 구매 진행 중 로딩 표시
- [ ] 에러 메시지 표시
- [ ] 복원 버튼 제공

### 테스트
- [ ] Android: 라이선스 테스터 설정
- [ ] iOS: 샌드박스 테스터 설정
- [ ] 구매 흐름 테스트
- [ ] 복원 흐름 테스트
- [ ] 구독 갱신 테스트
- [ ] 에러 시나리오 테스트

### 스토어 심사
- [ ] 구독 약관 표시
- [ ] 개인정보처리방침 링크
- [ ] 복원 버튼 설정 화면에 배치
- [ ] 가격 정보 정확히 표시
- [ ] 자동 갱신 안내 문구

---

## 실습 과제

### 과제 1: 구독 결제 흐름 구현
in_app_purchase 패키지를 사용하여 월간/연간 구독 상품의 결제 흐름을 구현하세요. 상품 조회, 결제 처리, 영수증 검증, 구독 상태 관리를 포함해 주세요.

### 과제 2: 서버 사이드 검증 시스템
클라이언트에서 받은 영수증을 서버에서 검증하는 API를 설계하세요. App Store/Play Store 영수증 형식 차이, 구독 갱신/취소 웹훅 처리를 포함해 주세요.

---

## 관련 문서

- [Architecture](../core/Architecture.md) - Repository 패턴과 결제 도메인 설계
- [Bloc](../core/Bloc.md) - Purchase Bloc 패턴 및 결제 상태 관리
- [ErrorHandling](../core/ErrorHandling.md) - 결제 실패 및 에러 처리
- [Networking_Dio](../networking/Networking_Dio.md) - 영수증 검증 API 통신

---

## Self-Check

- [ ] iOS/Android 인앱 결제 흐름의 차이를 설명할 수 있다
- [ ] 구독, 소모품, 비소모품 상품의 처리 방식을 구분할 수 있다
- [ ] 영수증 검증의 필요성과 서버 사이드 검증 패턴을 이해할 수 있다
- [ ] 결제 복원(Restore Purchase) 기능을 구현할 수 있다
