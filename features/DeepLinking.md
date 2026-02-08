# Flutter Deep Linking 가이드

> 앱 외부(웹 브라우저, 이메일, SMS 등)에서 특정 URL을 통해 Flutter 앱의 특정 화면으로 직접 이동하는 기술을 구현하는 방법을 다룹니다. URL Scheme, Universal Links(iOS), App Links(Android), Firebase Dynamic Links를 활용하여 사용자 경험을 개선하고, go_router와 Bloc을 연동하여 Clean Architecture 기반의 딥링크 처리 시스템을 구축합니다.

> **난이도**: 고급 | **카테고리**: features
> **선행 학습**: [Navigation](./Navigation.md) | **예상 학습 시간**: 2h

## 학습 목표

이 문서를 학습하면 다음을 할 수 있습니다:

1. URL Scheme, Universal Links(iOS), App Links(Android)의 차이를 이해하고 프로젝트에 적절히 설정할 수 있다
2. go_router와 연동하여 딥링크를 Flutter 라우트로 변환하는 파싱 시스템을 구현할 수 있다
3. Firebase Dynamic Links를 사용한 Deferred Deep Linking(앱 미설치 시 스토어 경유 후 복귀)을 구현할 수 있다
4. Bloc 패턴으로 딥링크 수신/처리/네비게이션을 상태 관리할 수 있다
5. 딥링크 보안 검증(호스트 허용 목록, XSS 방지, Rate Limiting)을 적용할 수 있다

## 1. 개요

### 1.1 Deep Linking이란?

Deep Linking은 사용자가 앱 외부의 링크를 클릭했을 때 앱 내부의 특정 화면으로 직접 이동하는 기능입니다. 단순히 앱을 실행하는 것이 아니라, 특정 콘텐츠나 기능이 있는 화면으로 바로 연결됩니다.

**사용 사례:**
- 이메일의 비밀번호 재설정 링크 클릭 시 앱의 비밀번호 변경 화면으로 이동
- SNS 공유 링크 클릭 시 해당 게시물 상세 화면 표시
- 푸시 알림 클릭 시 관련 콘텐츠 화면으로 이동
- 마케팅 캠페인 링크를 통한 특정 프로모션 페이지 진입

### 1.2 Deep Linking 유형 비교

| 유형 | 지원 플랫폼 | 앱 미설치 시 동작 | 검증 방식 | 설정 복잡도 | 사용 예시 |
|------|------------|------------------|----------|------------|-----------|
| **URL Scheme** | iOS, Android | 브라우저 에러 | 없음 | 낮음 | `myapp://product/123` |
| **Universal Links** | iOS | Safari로 웹사이트 열림 | HTTPS + 서버 검증 | 높음 | `https://example.com/product/123` |
| **App Links** | Android 6.0+ | Chrome으로 웹사이트 열림 | HTTPS + 서버 검증 | 높음 | `https://example.com/product/123` |
| **Firebase Dynamic Links** | iOS, Android | 스토어로 리디렉션 | Firebase 서버 | 중간 | `https://myapp.page.link/abc123` |

**URL Scheme vs Universal/App Links:**
- URL Scheme: 앱 전용 프로토콜(`myapp://`), 빠르고 간단하지만 앱 미설치 시 대응 불가
- Universal/App Links: 일반 웹 URL(`https://`), 앱-웹 전환이 자연스럽고 SEO 친화적

## 2. 프로젝트 설정

### 2.1 pubspec.yaml 의존성

```yaml
# pubspec.yaml
name: my_app
description: Deep Linking example app
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.10.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Routing
  go_router: ^17.1.0

  # State Management
  flutter_bloc: ^9.1.1

  # Dependency Injection
  injectable: ^2.7.1
  get_it: ^9.2.0

  # Functional Programming
  fpdart: ^1.2.0

  # Code Generation
  freezed_annotation: ^3.1.0
  json_annotation: ^4.10.0

  # Deep Linking
  app_links: ^7.0.0  # uni_links는 deprecated됨

  # Firebase (Optional)
  firebase_core: ^4.4.0
  firebase_dynamic_links: ^6.0.11  # ⚠️ DEPRECATED: Firebase Dynamic Links는 2025년 8월 서비스 종료됨 - Branch.io 또는 app_links 사용 권장

dev_dependencies:
  flutter_test:
    sdk: flutter
  lints: ^6.1.0

  # Code Generation
  build_runner: ^2.11.0
  freezed: ^3.2.5
  json_serializable: ^6.12.0
  injectable_generator: ^2.12.0

  # Testing
  mocktail: ^1.0.4
  bloc_test: ^10.0.0

flutter:
  uses-material-design: true
```

### 2.2 프로젝트 구조

```
lib/
├── core/
│   ├── di/
│   │   └── injection.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_paths.dart
│   └── error/
│       └── failures.dart
├── features/
│   └── deep_linking/
│       ├── domain/
│       │   ├── entities/
│       │   │   └── deep_link_data.dart
│       │   ├── repositories/
│       │   │   └── deep_link_repository.dart
│       │   └── usecases/
│       │       ├── handle_deep_link_usecase.dart
│       │       └── parse_deep_link_usecase.dart
│       ├── data/
│       │   ├── models/
│       │   │   └── deep_link_data_model.dart
│       │   ├── datasources/
│       │   │   ├── deep_link_local_datasource.dart
│       │   │   └── deep_link_remote_datasource.dart
│       │   └── repositories/
│       │       └── deep_link_repository_impl.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── deep_link_bloc.dart
│           │   ├── deep_link_event.dart
│           │   └── deep_link_state.dart
│           └── widgets/
│               └── deep_link_handler_widget.dart
└── main.dart
```

### 2.3 Android 설정

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="my_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTask"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <!-- Default App Launcher -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <!-- URL Scheme Deep Links -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="myapp" />
            </intent-filter>

            <!-- App Links (Android 6.0+) -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data
                    android:scheme="https"
                    android:host="example.com"
                    android:pathPrefix="/app" />
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### 2.4 iOS 설정

```xml
<!-- ios/Runner/Info.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... 기존 설정 ... -->

    <!-- URL Scheme -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLName</key>
            <string>com.example.myapp</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>myapp</string>
            </array>
        </dict>
    </array>

    <!-- Universal Links -->
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:example.com</string>
    </array>
</dict>
</plist>
```

## 3. URL Scheme

### 3.1 URL Scheme 정의

URL Scheme은 앱만의 고유한 프로토콜을 사용하여 딥링크를 처리합니다.

**형식:** `myapp://screen/param?query=value`

### 3.2 URL Scheme 처리 구현

```dart
// lib/features/deep_linking/data/datasources/deep_link_local_datasource.dart
import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:app_links/app_links.dart';

abstract class DeepLinkLocalDataSource {
  Stream<Uri?> getUriLinkStream();
  Future<Uri?> getInitialUri();
}

@LazySingleton(as: DeepLinkLocalDataSource)
class DeepLinkLocalDataSourceImpl implements DeepLinkLocalDataSource {
  final _appLinks = AppLinks();
  StreamSubscription? _sub;

  @override
  Stream<Uri?> getUriLinkStream() {
    return _appLinks.uriLinkStream;
  }

  @override
  Future<Uri?> getInitialUri() async {
    try {
      final uri = await _appLinks.getInitialLink();
      return uri;
    } catch (e) {
      return null;
    }
  }

  @disposeMethod
  void dispose() {
    _sub?.cancel();
  }
}
```

### 3.3 Deep Link Entity

```dart
// lib/features/deep_linking/domain/entities/deep_link_data.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'deep_link_data.freezed.dart';

@freezed
class DeepLinkData with _$DeepLinkData {
  const factory DeepLinkData({
    required String scheme,
    required String host,
    required String path,
    required Map<String, String> queryParameters,
    required DeepLinkType type,
  }) = _DeepLinkData;

  const DeepLinkData._();

  // Getters for common use cases
  String? get id => queryParameters['id'];
  String? get token => queryParameters['token'];
  String? get userId => queryParameters['userId'];
}

enum DeepLinkType {
  urlScheme,
  universalLink,
  appLink,
  dynamicLink,
  unknown,
}
```

### 3.4 URL Scheme 테스트

**Android (adb):**
```bash
adb shell am start -W -a android.intent.action.VIEW \
  -d "myapp://product/123?category=electronics" \
  com.example.myapp
```

**iOS (xcrun):**
```bash
xcrun simctl openurl booted "myapp://product/123?category=electronics"
```

## 4. Universal Links (iOS)

### 4.1 Associated Domains 설정

1. Apple Developer Console에서 App ID에 Associated Domains capability 추가
2. Xcode → Signing & Capabilities → Associated Domains 추가
3. `applinks:example.com` 입력

### 4.2 apple-app-site-association 파일

서버의 `https://example.com/.well-known/apple-app-site-association` 경로에 배치:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.example.myapp",
        "paths": [
          "/app/*",
          "/product/*",
          "/user/*/profile",
          "NOT /web/*"
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": [
      "TEAM_ID.com.example.myapp"
    ]
  }
}
```

**주의사항:**
- Content-Type: `application/json`
- HTTPS 필수
- 리디렉션 없이 직접 접근 가능해야 함
- 파일 크기 128KB 이하

### 4.3 Universal Links 검증

```bash
# Apple의 CDN 캐시 확인
curl -v https://example.com/.well-known/apple-app-site-association

# 실제 테스트
xcrun simctl openurl booted "https://example.com/app/product/123"
```

## 5. App Links (Android)

### 5.1 assetlinks.json 파일

서버의 `https://example.com/.well-known/assetlinks.json` 경로에 배치:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.myapp",
      "sha256_cert_fingerprints": [
        "14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5"
      ]
    }
  }
]
```

### 5.2 SHA-256 인증서 지문 얻기

```bash
# Debug 키스토어
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release 키스토어
keytool -list -v -keystore /path/to/release.keystore -alias release
```

### 5.3 App Links 검증

```bash
# assetlinks.json 확인
curl https://example.com/.well-known/assetlinks.json

# 테스트
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://example.com/app/product/123" \
  com.example.myapp

# App Links 검증 상태 확인
adb shell dumpsys package domain-preferred-apps
```

## 6. go_router 연동

### 6.1 라우트 경로 정의

```dart
// lib/core/router/route_paths.dart
class RoutePaths {
  static const String home = '/';
  static const String product = '/product/:id';
  static const String productDetail = '/product/:id/detail';
  static const String userProfile = '/user/:userId/profile';
  static const String resetPassword = '/auth/reset-password';
  static const String notification = '/notification/:notificationId';
  static const String promo = '/promo/:campaignId';
}
```

### 6.2 GoRouter 설정

```dart
// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'route_paths.dart';

@singleton
class AppRouter {
  final GoRouter router;

  AppRouter(this.router);

  @factoryMethod
  static AppRouter create() {
    final router = GoRouter(
      debugLogDiagnostics: true,
      initialLocation: RoutePaths.home,
      redirect: (context, state) => _handleRedirect(context, state),
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: RoutePaths.product,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final category = state.uri.queryParameters['category'];
            return ProductScreen(
              productId: id,
              category: category,
            );
          },
        ),
        GoRoute(
          path: RoutePaths.productDetail,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ProductDetailScreen(productId: id);
          },
        ),
        GoRoute(
          path: RoutePaths.userProfile,
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return UserProfileScreen(userId: userId);
          },
        ),
        GoRoute(
          path: RoutePaths.resetPassword,
          builder: (context, state) {
            final token = state.uri.queryParameters['token'];
            return ResetPasswordScreen(token: token);
          },
        ),
        GoRoute(
          path: RoutePaths.notification,
          builder: (context, state) {
            final notificationId = state.pathParameters['notificationId']!;
            return NotificationDetailScreen(notificationId: notificationId);
          },
        ),
        GoRoute(
          path: RoutePaths.promo,
          builder: (context, state) {
            final campaignId = state.pathParameters['campaignId']!;
            final source = state.uri.queryParameters['source'];
            return PromoScreen(
              campaignId: campaignId,
              source: source,
            );
          },
        ),
      ],
      errorBuilder: (context, state) => ErrorScreen(error: state.error),
    );

    return AppRouter(router);
  }

  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    // 인증 필요 여부 체크
    final authRequired = _isAuthRequired(state.uri.path);
    final isAuthenticated = _checkAuthentication();

    if (authRequired && !isAuthenticated) {
      return '/login?redirect=${Uri.encodeComponent(state.uri.toString())}';
    }

    return null;
  }

  static bool _isAuthRequired(String path) {
    final protectedPaths = [
      '/user/',
      '/profile',
      '/settings',
    ];
    return protectedPaths.any((p) => path.contains(p));
  }

  static bool _checkAuthentication() {
    // TODO: 실제 인증 상태 확인 로직
    return true;
  }
}
```

### 6.3 Deep Link → Route 매핑

```dart
// lib/features/deep_linking/domain/usecases/parse_deep_link_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../entities/deep_link_data.dart';
import '../../../../core/error/failures.dart';

@injectable
class ParseDeepLinkUseCase {
  String? parseToRoute(DeepLinkData deepLink) {
    // URL Scheme 처리: myapp://product/123
    if (deepLink.scheme == 'myapp') {
      return _parseUrlScheme(deepLink);
    }

    // Universal/App Links 처리: https://example.com/app/product/123
    if (deepLink.scheme == 'https' && deepLink.host == 'example.com') {
      return _parseWebLink(deepLink);
    }

    return null;
  }

  String? _parseUrlScheme(DeepLinkData deepLink) {
    final path = deepLink.path;
    final query = deepLink.queryParameters;

    if (path.startsWith('/product/')) {
      final id = path.replaceFirst('/product/', '');
      final category = query['category'];
      return category != null
          ? '/product/$id?category=$category'
          : '/product/$id';
    }

    if (path.startsWith('/user/') && path.endsWith('/profile')) {
      final userId = path.split('/')[2];
      return '/user/$userId/profile';
    }

    if (path == '/reset-password') {
      final token = query['token'];
      return token != null
          ? '/auth/reset-password?token=$token'
          : '/auth/reset-password';
    }

    return null;
  }

  String? _parseWebLink(DeepLinkData deepLink) {
    final path = deepLink.path;

    // /app 프리픽스 제거
    if (path.startsWith('/app/')) {
      final routePath = path.replaceFirst('/app', '');
      final queryString = _buildQueryString(deepLink.queryParameters);
      return queryString.isEmpty ? routePath : '$routePath?$queryString';
    }

    return null;
  }

  String _buildQueryString(Map<String, String> params) {
    if (params.isEmpty) return '';
    return params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
```

## 7. Firebase Dynamic Links

### 7.1 Firebase 설정

```dart
// lib/core/firebase/firebase_setup.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class FirebaseSetup {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  static Future<PendingDynamicLinkData?> getInitialDynamicLink() async {
    return await FirebaseDynamicLinks.instance.getInitialLink();
  }

  static Stream<PendingDynamicLinkData> getDynamicLinkStream() {
    return FirebaseDynamicLinks.instance.onLink;
  }
}
```

### 7.2 Dynamic Link 생성

```dart
// lib/features/deep_linking/data/datasources/deep_link_remote_datasource.dart
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:injectable/injectable.dart';

abstract class DeepLinkRemoteDataSource {
  Future<String> createDynamicLink({
    required String path,
    Map<String, String>? parameters,
  });
}

@LazySingleton(as: DeepLinkRemoteDataSource)
class DeepLinkRemoteDataSourceImpl implements DeepLinkRemoteDataSource {
  static const String _dynamicLinkDomain = 'myapp.page.link';
  static const String _webUrl = 'https://example.com';
  static const String _androidPackageName = 'com.example.myapp';
  static const String _iosBundleId = 'com.example.myapp';

  @override
  Future<String> createDynamicLink({
    required String path,
    Map<String, String>? parameters,
  }) async {
    final queryString = parameters?.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&') ??
        '';

    final deepLinkUrl = queryString.isEmpty
        ? '$_webUrl$path'
        : '$_webUrl$path?$queryString';

    final dynamicLinkParams = DynamicLinkParameters(
      uriPrefix: 'https://$_dynamicLinkDomain',
      link: Uri.parse(deepLinkUrl),
      androidParameters: const AndroidParameters(
        packageName: _androidPackageName,
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: _iosBundleId,
        minimumVersion: '1.0.0',
        appStoreId: '123456789',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'My App',
        description: 'Check out this content!',
        imageUrl: Uri.parse('https://example.com/share-image.png'),
      ),
    );

    final shortLink = await FirebaseDynamicLinks.instance.buildShortLink(
      dynamicLinkParams,
      shortLinkType: ShortDynamicLinkType.unguessable,
    );

    return shortLink.shortUrl.toString();
  }
}
```

### 7.3 Dynamic Link 수신 처리

```dart
// lib/features/deep_linking/data/repositories/deep_link_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import '../../domain/entities/deep_link_data.dart';
import '../../domain/repositories/deep_link_repository.dart';
import '../datasources/deep_link_local_datasource.dart';
import '../datasources/deep_link_remote_datasource.dart';
import '../../../../core/error/failures.dart';

@LazySingleton(as: DeepLinkRepository)
class DeepLinkRepositoryImpl implements DeepLinkRepository {
  final DeepLinkLocalDataSource localDataSource;
  final DeepLinkRemoteDataSource remoteDataSource;

  DeepLinkRepositoryImpl(this.localDataSource, this.remoteDataSource);

  @override
  Stream<Either<Failure, DeepLinkData>> watchDeepLinks() async* {
    // URL Scheme / Universal Links / App Links
    await for (final uri in localDataSource.getUriLinkStream()) {
      if (uri != null) {
        yield Right(_parseUri(uri, DeepLinkType.urlScheme));
      }
    }

    // Firebase Dynamic Links
    await for (final dynamicLink in FirebaseDynamicLinks.instance.onLink) {
      final uri = dynamicLink.link;
      yield Right(_parseUri(uri, DeepLinkType.dynamicLink));
    }
  }

  @override
  Future<Either<Failure, DeepLinkData?>> getInitialDeepLink() async {
    try {
      // URL Scheme 확인
      final uri = await localDataSource.getInitialUri();
      if (uri != null) {
        return Right(_parseUri(uri, DeepLinkType.urlScheme));
      }

      // Dynamic Link 확인
      final dynamicLink = await FirebaseDynamicLinks.instance.getInitialLink();
      if (dynamicLink != null) {
        return Right(_parseUri(dynamicLink.link, DeepLinkType.dynamicLink));
      }

      return const Right(null);
    } catch (e) {
      return Left(DeepLinkFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createShareLink({
    required String path,
    Map<String, String>? parameters,
  }) async {
    try {
      final link = await remoteDataSource.createDynamicLink(
        path: path,
        parameters: parameters,
      );
      return Right(link);
    } catch (e) {
      return Left(DeepLinkFailure(message: e.toString()));
    }
  }

  DeepLinkData _parseUri(Uri uri, DeepLinkType type) {
    return DeepLinkData(
      scheme: uri.scheme,
      host: uri.host,
      path: uri.path,
      queryParameters: Map.from(uri.queryParameters),
      type: type,
    );
  }
}
```

## 8. Deferred Deep Linking

### 8.1 개념

사용자가 앱을 설치하지 않은 상태에서 딥링크를 클릭하면:
1. 앱 스토어로 리디렉션
2. 앱 설치 완료
3. 첫 실행 시 원래 의도했던 화면으로 이동

### 8.2 Firebase Dynamic Links로 구현

Firebase Dynamic Links는 기본적으로 Deferred Deep Linking을 지원합니다.

```dart
// lib/features/deep_linking/domain/usecases/handle_deferred_deep_link_usecase.dart
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../repositories/deep_link_repository.dart';
import '../entities/deep_link_data.dart';
import '../../../../core/error/failures.dart';

@injectable
class HandleDeferredDeepLinkUseCase {
  final DeepLinkRepository repository;

  HandleDeferredDeepLinkUseCase(this.repository);

  Future<Either<Failure, DeepLinkData?>> call() async {
    // 앱이 처음 실행될 때 호출
    // Firebase는 자동으로 설치 전 클릭한 Dynamic Link를 반환
    return await repository.getInitialDeepLink();
  }
}
```

### 8.3 첫 실행 시 처리

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'features/deep_linking/presentation/widgets/deep_link_handler_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DI 초기화
  configureDependencies();

  // Firebase 초기화
  await FirebaseSetup.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();

    return MaterialApp.router(
      title: 'Deep Linking Demo',
      routerConfig: appRouter.router,
      builder: (context, child) {
        // Deep Link Handler로 래핑
        return DeepLinkHandlerWidget(child: child!);
      },
    );
  }
}
```

## 9. 딥링크 데이터 파싱

### 9.1 Deep Link Data Model

```dart
// lib/features/deep_linking/data/models/deep_link_data_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/deep_link_data.dart';

part 'deep_link_data_model.freezed.dart';
part 'deep_link_data_model.g.dart';

@freezed
class DeepLinkDataModel with _$DeepLinkDataModel {
  const factory DeepLinkDataModel({
    required String scheme,
    required String host,
    required String path,
    required Map<String, String> queryParameters,
    required String type,
  }) = _DeepLinkDataModel;

  const DeepLinkDataModel._();

  factory DeepLinkDataModel.fromJson(Map<String, dynamic> json) =>
      _$DeepLinkDataModelFromJson(json);

  factory DeepLinkDataModel.fromEntity(DeepLinkData entity) {
    return DeepLinkDataModel(
      scheme: entity.scheme,
      host: entity.host,
      path: entity.path,
      queryParameters: entity.queryParameters,
      type: entity.type.name,
    );
  }

  DeepLinkData toEntity() {
    return DeepLinkData(
      scheme: scheme,
      host: host,
      path: path,
      queryParameters: queryParameters,
      type: DeepLinkType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => DeepLinkType.unknown,
      ),
    );
  }
}
```

### 9.2 복잡한 파라미터 파싱

```dart
// lib/features/deep_linking/domain/usecases/parse_deep_link_usecase.dart (확장)
import 'package:fpdart/fpdart.dart';

extension DeepLinkParsing on ParseDeepLinkUseCase {
  /// 프로모션 딥링크 파싱
  /// 예: myapp://promo/summer2024?discount=20&category=electronics
  Option<PromoData> parsePromoLink(DeepLinkData deepLink) {
    if (!deepLink.path.startsWith('/promo/')) {
      return const None();
    }

    final campaignId = deepLink.path.replaceFirst('/promo/', '');
    final discount = int.tryParse(deepLink.queryParameters['discount'] ?? '');
    final category = deepLink.queryParameters['category'];
    final source = deepLink.queryParameters['source'];

    if (campaignId.isEmpty) {
      return const None();
    }

    return Some(PromoData(
      campaignId: campaignId,
      discount: discount,
      category: category,
      source: source,
    ));
  }

  /// 알림 딥링크 파싱
  /// 예: myapp://notification/order123?type=delivery&status=completed
  Option<NotificationData> parseNotificationLink(DeepLinkData deepLink) {
    if (!deepLink.path.startsWith('/notification/')) {
      return const None();
    }

    final notificationId = deepLink.path.replaceFirst('/notification/', '');
    final type = deepLink.queryParameters['type'];
    final status = deepLink.queryParameters['status'];
    final timestamp = int.tryParse(
      deepLink.queryParameters['timestamp'] ?? '',
    );

    return Some(NotificationData(
      id: notificationId,
      type: type,
      status: status,
      timestamp: timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null,
    ));
  }

  /// 유저 프로필 딥링크 파싱
  /// 예: myapp://user/john123/profile?tab=posts&filter=recent
  Option<UserProfileData> parseUserProfileLink(DeepLinkData deepLink) {
    final pathRegex = RegExp(r'^/user/([^/]+)/profile$');
    final match = pathRegex.firstMatch(deepLink.path);

    if (match == null) {
      return const None();
    }

    final userId = match.group(1)!;
    final tab = deepLink.queryParameters['tab'];
    final filter = deepLink.queryParameters['filter'];

    return Some(UserProfileData(
      userId: userId,
      selectedTab: tab,
      filter: filter,
    ));
  }
}

@freezed
class PromoData with _$PromoData {
  const factory PromoData({
    required String campaignId,
    int? discount,
    String? category,
    String? source,
  }) = _PromoData;
}

@freezed
class NotificationData with _$NotificationData {
  const factory NotificationData({
    required String id,
    String? type,
    String? status,
    DateTime? timestamp,
  }) = _NotificationData;
}

@freezed
class UserProfileData with _$UserProfileData {
  const factory UserProfileData({
    required String userId,
    String? selectedTab,
    String? filter,
  }) = _UserProfileData;
}
```

## 10. Bloc 연동

### 10.1 Deep Link Events

```dart
// lib/features/deep_linking/presentation/bloc/deep_link_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/deep_link_data.dart';

part 'deep_link_event.freezed.dart';

@freezed
class DeepLinkEvent with _$DeepLinkEvent {
  const factory DeepLinkEvent.started() = _Started;
  const factory DeepLinkEvent.deepLinkReceived(DeepLinkData data) = _DeepLinkReceived;
  const factory DeepLinkEvent.handleInitialDeepLink() = _HandleInitialDeepLink;
  const factory DeepLinkEvent.clearDeepLink() = _ClearDeepLink;
}
```

### 10.2 Deep Link States

```dart
// lib/features/deep_linking/presentation/bloc/deep_link_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/deep_link_data.dart';

part 'deep_link_state.freezed.dart';

@freezed
class DeepLinkState with _$DeepLinkState {
  const factory DeepLinkState.initial() = _Initial;
  const factory DeepLinkState.listening() = _Listening;
  const factory DeepLinkState.received(DeepLinkData data) = _Received;
  const factory DeepLinkState.navigated() = _Navigated;
  const factory DeepLinkState.error(String message) = _Error;
}
```

### 10.3 Deep Link Bloc

```dart
// lib/features/deep_linking/presentation/bloc/deep_link_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:go_router/go_router.dart';
import '../../domain/repositories/deep_link_repository.dart';
import '../../domain/usecases/parse_deep_link_usecase.dart';
import '../../domain/usecases/handle_deferred_deep_link_usecase.dart';
import 'deep_link_event.dart';
import 'deep_link_state.dart';

@injectable
class DeepLinkBloc extends Bloc<DeepLinkEvent, DeepLinkState> {
  final DeepLinkRepository repository;
  final ParseDeepLinkUseCase parseDeepLink;
  final HandleDeferredDeepLinkUseCase handleDeferredDeepLink;
  final GoRouter router;

  StreamSubscription? _deepLinkSubscription;

  DeepLinkBloc(
    this.repository,
    this.parseDeepLink,
    this.handleDeferredDeepLink,
    this.router,
  ) : super(const DeepLinkState.initial()) {
    on<_Started>(_onStarted);
    on<_DeepLinkReceived>(_onDeepLinkReceived);
    on<_HandleInitialDeepLink>(_onHandleInitialDeepLink);
    on<_ClearDeepLink>(_onClearDeepLink);
  }

  Future<void> _onStarted(
    _Started event,
    Emitter<DeepLinkState> emit,
  ) async {
    emit(const DeepLinkState.listening());

    // 초기 딥링크 처리 (Deferred Deep Linking)
    add(const DeepLinkEvent.handleInitialDeepLink());

    // 딥링크 스트림 리스닝
    await _deepLinkSubscription?.cancel();
    _deepLinkSubscription = repository.watchDeepLinks().listen(
      (either) {
        either.fold(
          (failure) => emit(DeepLinkState.error(failure.message)),
          (data) => add(DeepLinkEvent.deepLinkReceived(data)),
        );
      },
    );
  }

  Future<void> _onDeepLinkReceived(
    _DeepLinkReceived event,
    Emitter<DeepLinkState> emit,
  ) async {
    emit(DeepLinkState.received(event.data));

    // 딥링크를 라우트로 변환
    final route = parseDeepLink.parseToRoute(event.data);

    if (route != null) {
      // 라우터로 이동
      router.go(route);
      emit(const DeepLinkState.navigated());
    } else {
      emit(const DeepLinkState.error('Invalid deep link'));
    }
  }

  Future<void> _onHandleInitialDeepLink(
    _HandleInitialDeepLink event,
    Emitter<DeepLinkState> emit,
  ) async {
    final result = await handleDeferredDeepLink();

    result.fold(
      (failure) => emit(DeepLinkState.error(failure.message)),
      (deepLinkData) {
        if (deepLinkData != null) {
          add(DeepLinkEvent.deepLinkReceived(deepLinkData));
        }
      },
    );
  }

  Future<void> _onClearDeepLink(
    _ClearDeepLink event,
    Emitter<DeepLinkState> emit,
  ) async {
    emit(const DeepLinkState.initial());
  }

  @override
  Future<void> close() {
    _deepLinkSubscription?.cancel();
    return super.close();
  }
}
```

### 10.4 Deep Link Handler Widget

```dart
// lib/features/deep_linking/presentation/widgets/deep_link_handler_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../bloc/deep_link_bloc.dart';
import '../bloc/deep_link_event.dart';
import '../bloc/deep_link_state.dart';

class DeepLinkHandlerWidget extends StatelessWidget {
  final Widget child;

  const DeepLinkHandlerWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DeepLinkBloc>()
        ..add(const DeepLinkEvent.started()),
      child: BlocListener<DeepLinkBloc, DeepLinkState>(
        listener: (context, state) {
          state.maybeWhen(
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deep Link Error: $message'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            orElse: () {},
          );
        },
        child: child,
      ),
    );
  }
}
```

## 11. 푸시 알림 연동

### 11.1 FCM 메시지에 딥링크 포함

```json
{
  "notification": {
    "title": "주문 배송 완료",
    "body": "주문하신 상품이 배송 완료되었습니다."
  },
  "data": {
    "deep_link": "myapp://order/ORD123456/detail",
    "type": "order_delivered",
    "order_id": "ORD123456"
  }
}
```

### 11.2 FCM 메시지 처리

```dart
// lib/features/notifications/data/datasources/fcm_datasource.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

@singleton
class FCMDataSource {
  final FirebaseMessaging _firebaseMessaging;

  FCMDataSource(this._firebaseMessaging);

  @factoryMethod
  static FCMDataSource create() {
    return FCMDataSource(FirebaseMessaging.instance);
  }

  Future<void> initialize({
    required Function(RemoteMessage) onMessage,
    required Function(RemoteMessage) onMessageOpenedApp,
  }) async {
    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen(onMessage);

    // 백그라운드에서 알림 클릭 시 처리
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);

    // 앱이 종료된 상태에서 알림으로 앱 실행
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      onMessageOpenedApp(initialMessage);
    }

    // 권한 요청 (iOS)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
```

### 11.3 알림에서 딥링크 추출 및 처리

```dart
// lib/features/notifications/presentation/bloc/notification_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../deep_linking/domain/entities/deep_link_data.dart';
import '../../../deep_linking/presentation/bloc/deep_link_bloc.dart';
import '../../../deep_linking/presentation/bloc/deep_link_event.dart';
import '../../data/datasources/fcm_datasource.dart';

@injectable
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final FCMDataSource fcmDataSource;
  final DeepLinkBloc deepLinkBloc;

  NotificationBloc(this.fcmDataSource, this.deepLinkBloc)
      : super(const NotificationState.initial()) {
    on<_Initialize>(_onInitialize);
  }

  Future<void> _onInitialize(
    _Initialize event,
    Emitter<NotificationState> emit,
  ) async {
    await fcmDataSource.initialize(
      onMessage: _handleForegroundMessage,
      onMessageOpenedApp: _handleNotificationTap,
    );

    emit(const NotificationState.initialized());
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // 포그라운드에서는 로컬 알림 표시만
    debugPrint('Foreground message: ${message.notification?.title}');
  }

  void _handleNotificationTap(RemoteMessage message) {
    final deepLinkUrl = message.data['deep_link'] as String?;

    if (deepLinkUrl != null) {
      final uri = Uri.parse(deepLinkUrl);
      final deepLinkData = DeepLinkData(
        scheme: uri.scheme,
        host: uri.host,
        path: uri.path,
        queryParameters: Map.from(uri.queryParameters),
        type: DeepLinkType.urlScheme,
      );

      // DeepLinkBloc으로 전달
      deepLinkBloc.add(DeepLinkEvent.deepLinkReceived(deepLinkData));
    }
  }
}
```

## 12. 디버깅 & 테스트

### 12.1 딥링크 디버깅 도구

```dart
// lib/core/debug/deep_link_logger.dart
import 'package:flutter/foundation.dart';
import '../../features/deep_linking/domain/entities/deep_link_data.dart';

class DeepLinkLogger {
  static void logReceived(DeepLinkData data) {
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔗 Deep Link Received');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('Type:       ${data.type.name}');
      debugPrint('Scheme:     ${data.scheme}');
      debugPrint('Host:       ${data.host}');
      debugPrint('Path:       ${data.path}');
      if (data.queryParameters.isNotEmpty) {
        debugPrint('Parameters:');
        data.queryParameters.forEach((key, value) {
          debugPrint('  - $key: $value');
        });
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  static void logNavigation(String route) {
    if (kDebugMode) {
      debugPrint('🧭 Navigating to: $route');
    }
  }

  static void logError(String error) {
    if (kDebugMode) {
      debugPrint('❌ Deep Link Error: $error');
    }
  }
}
```

### 12.2 단위 테스트

```dart
// test/features/deep_linking/domain/usecases/parse_deep_link_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/deep_linking/domain/entities/deep_link_data.dart';
import 'package:my_app/features/deep_linking/domain/usecases/parse_deep_link_usecase.dart';

void main() {
  late ParseDeepLinkUseCase useCase;

  setUp(() {
    useCase = ParseDeepLinkUseCase();
  });

  group('parseToRoute', () {
    test('should parse URL Scheme product link correctly', () {
      // Arrange
      final deepLink = DeepLinkData(
        scheme: 'myapp',
        host: '',
        path: '/product/123',
        queryParameters: {'category': 'electronics'},
        type: DeepLinkType.urlScheme,
      );

      // Act
      final result = useCase.parseToRoute(deepLink);

      // Assert
      expect(result, '/product/123?category=electronics');
    });

    test('should parse Universal Link correctly', () {
      // Arrange
      final deepLink = DeepLinkData(
        scheme: 'https',
        host: 'example.com',
        path: '/app/user/john123/profile',
        queryParameters: {'tab': 'posts'},
        type: DeepLinkType.universalLink,
      );

      // Act
      final result = useCase.parseToRoute(deepLink);

      // Assert
      expect(result, '/user/john123/profile?tab=posts');
    });

    test('should return null for invalid deep link', () {
      // Arrange
      final deepLink = DeepLinkData(
        scheme: 'unknown',
        host: 'invalid',
        path: '/invalid',
        queryParameters: {},
        type: DeepLinkType.unknown,
      );

      // Act
      final result = useCase.parseToRoute(deepLink);

      // Assert
      expect(result, isNull);
    });
  });
}
```

### 12.3 통합 테스트

```dart
// integration_test/deep_linking_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Deep Linking Integration Tests', () {
    testWidgets('should navigate to product screen from deep link',
        (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Simulate deep link
      final uri = Uri.parse('myapp://product/123?category=electronics');
      // Note: 실제 테스트에서는 platform channel을 통해 deep link 전달 필요

      await tester.pumpAndSettle();

      // Verify navigation
      expect(find.text('Product 123'), findsOneWidget);
      expect(find.text('Category: electronics'), findsOneWidget);
    });

    testWidgets('should handle authentication required deep link',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Simulate deep link to protected route
      final uri = Uri.parse('myapp://user/john123/profile');

      await tester.pumpAndSettle();

      // Should redirect to login
      expect(find.text('Login'), findsOneWidget);
    });
  });
}
```

## 13. 보안

### 13.1 딥링크 검증

```dart
// lib/core/security/deep_link_validator.dart
import 'package:injectable/injectable.dart';
import '../../features/deep_linking/domain/entities/deep_link_data.dart';

@singleton
class DeepLinkValidator {
  // 허용된 호스트 목록
  static const _allowedHosts = [
    'example.com',
    'www.example.com',
    'api.example.com',
  ];

  // 허용된 스킴 목록
  static const _allowedSchemes = [
    'myapp',
    'https',
  ];

  // 차단된 경로 패턴
  static final _blockedPathPatterns = [
    RegExp(r'/admin/.*'),
    RegExp(r'/internal/.*'),
    RegExp(r'\.\.'),  // Path traversal 방지
  ];

  bool validate(DeepLinkData data) {
    // 스킴 검증
    if (!_allowedSchemes.contains(data.scheme)) {
      return false;
    }

    // 호스트 검증 (https인 경우만)
    if (data.scheme == 'https' && !_allowedHosts.contains(data.host)) {
      return false;
    }

    // 차단된 경로 검증
    for (final pattern in _blockedPathPatterns) {
      if (pattern.hasMatch(data.path)) {
        return false;
      }
    }

    // 파라미터 검증
    if (!_validateParameters(data.queryParameters)) {
      return false;
    }

    return true;
  }

  bool _validateParameters(Map<String, String> params) {
    for (final value in params.values) {
      // XSS 방지: 스크립트 태그 검사
      if (value.contains('<script>') || value.contains('javascript:')) {
        return false;
      }

      // SQL Injection 방지: 기본적인 패턴 검사
      if (value.contains("'") && value.contains('--')) {
        return false;
      }
    }
    return true;
  }

  /// URL 인코딩 검증
  bool isProperlyEncoded(String param) {
    try {
      final decoded = Uri.decodeComponent(param);
      final reencoded = Uri.encodeComponent(decoded);
      return param == reencoded;
    } catch (e) {
      return false;
    }
  }
}
```

### 13.2 인증 보호

```dart
// lib/core/router/app_router.dart (확장)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthGuard {
  static String? checkAuth(BuildContext context, GoRouterState state) {
    final isAuthenticated = _isUserAuthenticated();
    final isPublicRoute = _isPublicRoute(state.uri.path);

    if (!isAuthenticated && !isPublicRoute) {
      // 로그인 후 원래 목적지로 리디렉션
      final redirectUrl = Uri.encodeComponent(state.uri.toString());
      return '/login?redirect=$redirectUrl';
    }

    return null;
  }

  static bool _isUserAuthenticated() {
    // TODO: 실제 인증 상태 확인
    // 예: SharedPreferences, Secure Storage에서 토큰 확인
    return false;
  }

  static bool _isPublicRoute(String path) {
    const publicRoutes = [
      '/',
      '/login',
      '/register',
      '/forgot-password',
      '/reset-password',
    ];

    return publicRoutes.any((route) => path.startsWith(route));
  }
}

// 라우터에 적용
final router = GoRouter(
  redirect: AuthGuard.checkAuth,
  routes: [...],
);
```

### 13.3 Rate Limiting

```dart
// lib/core/security/deep_link_rate_limiter.dart
import 'package:injectable/injectable.dart';

@singleton
class DeepLinkRateLimiter {
  final Map<String, List<DateTime>> _attempts = {};
  static const int _maxAttempts = 10;
  static const Duration _timeWindow = Duration(minutes: 1);

  bool isAllowed(String identifier) {
    final now = DateTime.now();
    final attempts = _attempts[identifier] ?? [];

    // 시간 윈도우 내의 시도만 유지
    attempts.removeWhere(
      (attempt) => now.difference(attempt) > _timeWindow,
    );

    if (attempts.length >= _maxAttempts) {
      return false;
    }

    attempts.add(now);
    _attempts[identifier] = attempts;
    return true;
  }

  void reset(String identifier) {
    _attempts.remove(identifier);
  }
}
```

## 14. Best Practices

### 14.1 Do & Don't

| ✅ Do | ❌ Don't |
|------|---------|
| Universal/App Links를 우선 사용 (SEO, 신뢰성) | URL Scheme만 사용 (앱 미설치 시 에러) |
| 딥링크 파라미터 검증 및 sanitization | 사용자 입력 그대로 사용 |
| 인증 필요 화면은 redirect 로직 구현 | 보안 체크 없이 민감한 화면 노출 |
| 딥링크를 analytics로 추적 | 딥링크 사용 패턴 무시 |
| Deferred Deep Linking 구현 (신규 유저 경험) | 앱 미설치 사용자 무시 |
| 딥링크별 에러 핸들링 | 모든 에러를 동일하게 처리 |
| 로컬/스테이징/프로덕션 환경별 호스트 분리 | 하드코딩된 단일 호스트 |
| 딥링크 테스트 자동화 | 수동 테스트만 진행 |

### 14.2 성능 최적화

```dart
// lib/features/deep_linking/domain/usecases/handle_deep_link_usecase.dart
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../repositories/deep_link_repository.dart';
import '../entities/deep_link_data.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/security/deep_link_validator.dart';
import '../../../../core/security/deep_link_rate_limiter.dart';

@injectable
class HandleDeepLinkUseCase {
  final DeepLinkRepository repository;
  final DeepLinkValidator validator;
  final DeepLinkRateLimiter rateLimiter;

  HandleDeepLinkUseCase(
    this.repository,
    this.validator,
    this.rateLimiter,
  );

  Future<Either<Failure, DeepLinkData>> call(Uri uri) async {
    final deepLink = DeepLinkData(
      scheme: uri.scheme,
      host: uri.host,
      path: uri.path,
      queryParameters: Map.from(uri.queryParameters),
      type: _detectType(uri),
    );

    // 1. Rate Limiting 체크
    final identifier = '${deepLink.scheme}://${deepLink.host}${deepLink.path}';
    if (!rateLimiter.isAllowed(identifier)) {
      return Left(DeepLinkFailure(
        message: 'Too many requests. Please try again later.',
      ));
    }

    // 2. 검증
    if (!validator.validate(deepLink)) {
      return Left(DeepLinkFailure(
        message: 'Invalid or malicious deep link detected.',
      ));
    }

    // 3. 처리
    return Right(deepLink);
  }

  DeepLinkType _detectType(Uri uri) {
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      return DeepLinkType.universalLink;
    } else {
      return DeepLinkType.urlScheme;
    }
  }
}
```

### 14.3 Analytics 연동

```dart
// lib/features/deep_linking/domain/usecases/track_deep_link_usecase.dart
import 'package:injectable/injectable.dart';
import '../entities/deep_link_data.dart';

abstract class AnalyticsService {
  void logEvent(String name, Map<String, dynamic> parameters);
}

@injectable
class TrackDeepLinkUseCase {
  final AnalyticsService analyticsService;

  TrackDeepLinkUseCase(this.analyticsService);

  void call(DeepLinkData deepLink) {
    analyticsService.logEvent('deep_link_received', {
      'type': deepLink.type.name,
      'scheme': deepLink.scheme,
      'host': deepLink.host,
      'path': deepLink.path,
      'has_parameters': deepLink.queryParameters.isNotEmpty,
      'parameter_count': deepLink.queryParameters.length,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void trackConversion(DeepLinkData deepLink, String action) {
    analyticsService.logEvent('deep_link_conversion', {
      'type': deepLink.type.name,
      'path': deepLink.path,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

### 14.4 환경별 설정

```dart
// lib/core/config/deep_link_config.dart
import 'package:flutter/foundation.dart';

class DeepLinkConfig {
  static String get webHost {
    if (kDebugMode) {
      return 'dev.example.com';
    } else if (kReleaseMode) {
      return 'example.com';
    } else {
      return 'staging.example.com';
    }
  }

  static String get urlScheme {
    if (kDebugMode) {
      return 'myapp-dev';
    } else if (kReleaseMode) {
      return 'myapp';
    } else {
      return 'myapp-staging';
    }
  }

  static String get dynamicLinkDomain {
    if (kDebugMode) {
      return 'myappdev.page.link';
    } else if (kReleaseMode) {
      return 'myapp.page.link';
    } else {
      return 'myappstaging.page.link';
    }
  }
}
```

### 14.5 에러 복구 전략

```dart
// lib/features/deep_linking/presentation/bloc/deep_link_bloc.dart (확장)
extension DeepLinkErrorRecovery on DeepLinkBloc {
  Future<void> handleError(
    String error,
    DeepLinkData? data,
    Emitter<DeepLinkState> emit,
  ) async {
    // 1. 에러 로깅
    debugPrint('Deep Link Error: $error');

    // 2. Fallback 라우트로 이동
    if (data != null) {
      final fallbackRoute = _getFallbackRoute(data);
      if (fallbackRoute != null) {
        router.go(fallbackRoute);
        emit(const DeepLinkState.navigated());
        return;
      }
    }

    // 3. 홈으로 리디렉션
    router.go('/');
    emit(DeepLinkState.error(error));
  }

  String? _getFallbackRoute(DeepLinkData data) {
    if (data.path.startsWith('/product/')) {
      return '/products';  // 전체 상품 목록으로
    }
    if (data.path.startsWith('/user/')) {
      return '/home';  // 홈으로
    }
    return null;
  }
}
```

---

## 요약

이 가이드에서는 Flutter에서 Deep Linking을 구현하는 방법을 다음과 같이 다루었습니다:

1. **기본 개념**: URL Scheme, Universal Links, App Links, Firebase Dynamic Links의 차이점과 사용 사례
2. **플랫폼 설정**: Android와 iOS에서 딥링크를 처리하기 위한 설정
3. **go_router 연동**: 딥링크를 Flutter 라우트로 변환하는 방법
4. **Clean Architecture**: Domain, Data, Presentation 레이어로 분리된 구조
5. **Bloc 패턴**: 딥링크 이벤트와 상태를 관리하는 방법
6. **보안**: 딥링크 검증, 인증, Rate Limiting
7. **테스트**: 단위 테스트와 통합 테스트
8. **Best Practices**: 실무에서 적용 가능한 패턴과 안티패턴

딥링크는 사용자 경험을 크게 개선할 수 있는 강력한 도구이며, 적절한 보안 및 에러 핸들링과 함께 구현되어야 합니다.

## 실습 과제

### 과제 1: URL Scheme 딥링크 구현
`myapp://` URL Scheme을 설정하고, `myapp://product/123?category=electronics` 형태의 딥링크를 GoRouter 라우트로 변환하여 해당 화면으로 이동하는 전체 흐름을 구현하세요.

### 과제 2: Universal Links / App Links 설정
서버에 `apple-app-site-association`(iOS)과 `assetlinks.json`(Android) 파일을 배포하고, `https://example.com/app/product/123` 형태의 웹 URL로 앱이 열리는 것을 확인하세요.

### 과제 3: 딥링크 보안 검증
DeepLinkValidator를 구현하여 허용된 호스트/스킴만 처리하고, path traversal과 XSS 공격을 차단하며, Rate Limiting으로 과도한 요청을 방지하는 보안 레이어를 적용하세요.

## Self-Check 퀴즈

- [ ] URL Scheme과 Universal Links/App Links의 차이점, 그리고 앱 미설치 시 각각의 동작을 설명할 수 있는가?
- [ ] `apple-app-site-association` 파일의 필수 조건(Content-Type, HTTPS, 리디렉션 없음 등)을 이해하고 있는가?
- [ ] Deferred Deep Linking이란 무엇이며, Firebase Dynamic Links가 이를 어떻게 지원하는지 설명할 수 있는가?
- [ ] 딥링크 파라미터의 보안 검증이 필요한 이유와 주요 검증 항목을 나열할 수 있는가?
- [ ] GoRouter의 redirect와 딥링크가 결합될 때, 인증이 필요한 경로를 어떻게 보호하는지 설명할 수 있는가?

## 체크리스트

- [ ] URL Scheme 설정 (iOS Info.plist, Android AndroidManifest.xml)
- [ ] Universal Links 설정 (apple-app-site-association, Associated Domains)
- [ ] App Links 설정 (assetlinks.json, autoVerify)
- [ ] GoRouter 라우트 정의 및 딥링크 매핑
- [ ] DeepLinkBloc 구현 (수신, 파싱, 네비게이션)
- [ ] DeepLinkHandlerWidget으로 앱 전역 딥링크 리스닝
- [ ] 딥링크 보안 검증 (호스트 허용 목록, 파라미터 검증)
- [ ] Firebase Dynamic Links 설정 (필요시)
- [ ] Deferred Deep Linking 테스트
- [ ] 딥링크 단위 테스트 및 통합 테스트
