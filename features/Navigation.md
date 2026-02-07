# Flutter 네비게이션 가이드 (GoRouter)

## 학습 목표

이 문서를 학습하면 다음을 할 수 있습니다:

1. GoRouter를 사용하여 Flutter 앱에 선언적 라우팅 시스템을 구축할 수 있다
2. ShellRoute와 StatefulShellRoute를 활용한 Bottom Navigation 중첩 네비게이션을 구현할 수 있다
3. 인증 기반 리다이렉트와 라우트별 리다이렉트를 설정할 수 있다
4. Path/Query/Extra 파라미터를 활용한 화면 간 데이터 전달을 구현할 수 있다
5. go_router_builder를 사용한 타입 안전한 라우팅을 적용할 수 있다

## 개요

GoRouter는 Flutter의 Navigator 2.0 API를 기반으로 한 선언적 라우팅 패키지입니다. URL 기반 라우팅, 딥링크, 리다이렉션, 중첩 네비게이션 등을 간편하게 구현할 수 있습니다.

## 설치 및 설정

### 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  go_router: ^17.0.1
```

### Migration Notes (v16 → v17)

**Breaking Changes:**
- ShellRoute의 네비게이션 변경이 기본적으로 GoRouter의 observers에 알림을 보냅니다.
- 최소 지원 버전: Flutter 3.32, Dart 3.8 (go_router v17)

> **⚠️ 버전 호환성 주의:**
> | go_router 버전 | Flutter 최소 버전 | Dart 최소 버전 | 비고 |
> |---------------|------------------|---------------|------|
> | v17.x | Flutter 3.32+ | Dart 3.8+ | 차기 Flutter 버전 필요 |
> | v14.x - v16.x | Flutter 3.19+ | Dart 3.3+ | **Flutter 3.27 호환** |
> | v13.x | Flutter 3.16+ | Dart 3.2+ | 레거시 |
>
> **현재 Flutter 3.27 사용 시 `go_router: ^14.0.0` ~ `^16.x.x`를 사용하세요.**
> go_router v17은 아직 출시되지 않은 Flutter 3.32+를 요구하므로, 현재 프로젝트에서는 v14~v16을 권장합니다.

**New Features:**
- `notifyRootObserver` 파라미터 추가 (ShellRouteBase, ShellRoute, StatefulShellRoute)
- `onEnter` 콜백 블로킹 시 네비게이션 스택 손실 버그 수정
- Shell route observer 통합 개선

## 기본 설정

### Router 설정

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,  // 개발 중 디버그 로깅
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/profile/:userId',
      name: 'profile',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ProfileScreen(userId: userId);
      },
    ),
  ],
);
```

### MaterialApp 연동

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'core/router/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'My App',
    );
  }
}
```

## 라우트 정의

### 라우트 이름 상수

```dart
// lib/core/router/route_names.dart
abstract class RouteNames {
  // Auth
  static const splash = 'splash';
  static const login = 'login';
  static const register = 'register';

  // Main
  static const home = 'home';
  static const profile = 'profile';
  static const settings = 'settings';

  // Product
  static const productList = 'product-list';
  static const productDetail = 'product-detail';

  // Order
  static const orderList = 'order-list';
  static const orderDetail = 'order-detail';
}
```

### 라우트 경로 상수

```dart
// lib/core/router/route_paths.dart
abstract class RoutePaths {
  // Auth
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';

  // Main
  static const home = '/home';
  static const profile = '/profile/:userId';
  static const settings = '/settings';

  // Product
  static const productList = '/products';
  static const productDetail = '/products/:productId';

  // Order
  static const orderList = '/orders';
  static const orderDetail = '/orders/:orderId';
}
```

## 네비게이션 메서드

### 기본 네비게이션

```dart
// 경로로 이동
context.go('/home');

// 이름으로 이동
context.goNamed('home');

// 경로 파라미터와 함께
context.goNamed(
  'profile',
  pathParameters: {'userId': '123'},
);

// 쿼리 파라미터와 함께
context.goNamed(
  'product-list',
  queryParameters: {'category': 'electronics', 'sort': 'price'},
);
// 결과 URL: /products?category=electronics&sort=price

// extra 데이터 전달 (객체 전달)
context.goNamed(
  'product-detail',
  pathParameters: {'productId': '123'},
  extra: productData,  // 타입 안전하게 객체 전달
);
```

### go vs push

```dart
// go: 현재 스택을 새 경로로 교체
context.go('/home');        // 스택: [Home]
context.go('/profile/1');   // 스택: [Profile] - Home이 제거됨

// push: 스택 위에 새 화면 추가
context.push('/home');      // 스택: [Home]
context.push('/profile/1'); // 스택: [Home, Profile]

// pushNamed: 이름으로 push
context.pushNamed('profile', pathParameters: {'userId': '1'});

// pop: 이전 화면으로
context.pop();

// pop with result: 결과값과 함께 이전 화면으로
context.pop(result);

// canPop: pop 가능 여부 확인
if (context.canPop()) {
  context.pop();
} else {
  context.go('/home');
}
```

### pushReplacement

```dart
// 현재 화면을 새 화면으로 교체 (스택 유지)
// 스택: [Home, Login]
context.pushReplacement('/home/dashboard');
// 스택: [Home, Dashboard] - Login이 Dashboard로 교체됨

context.pushReplacementNamed('dashboard');
```

## 파라미터 처리

### Path Parameters

```dart
GoRoute(
  path: '/users/:userId/posts/:postId',
  name: 'user-post',
  builder: (context, state) {
    final userId = state.pathParameters['userId']!;
    final postId = state.pathParameters['postId']!;
    return UserPostScreen(userId: userId, postId: postId);
  },
),

// 사용
context.goNamed(
  'user-post',
  pathParameters: {
    'userId': '123',
    'postId': '456',
  },
);
// URL: /users/123/posts/456
```

### Query Parameters

```dart
GoRoute(
  path: '/search',
  name: 'search',
  builder: (context, state) {
    final query = state.uri.queryParameters['q'] ?? '';
    final page = int.tryParse(state.uri.queryParameters['page'] ?? '1') ?? 1;
    return SearchScreen(query: query, page: page);
  },
),

// 사용
context.goNamed(
  'search',
  queryParameters: {'q': 'flutter', 'page': '2'},
);
// URL: /search?q=flutter&page=2
```

### Extra (객체 전달)

```dart
GoRoute(
  path: '/product/:id',
  name: 'product-detail',
  builder: (context, state) {
    // extra로 전달받은 객체
    final product = state.extra as Product?;
    final productId = state.pathParameters['id']!;

    return ProductDetailScreen(
      productId: productId,
      initialProduct: product,  // 있으면 사용, 없으면 API 호출
    );
  },
),

// 사용
context.goNamed(
  'product-detail',
  pathParameters: {'id': product.id},
  extra: product,  // Product 객체 전달
);
```

## 중첩 네비게이션 (Nested Navigation)

### ShellRoute를 이용한 Bottom Navigation

```dart
// lib/core/router/app_router.dart
final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    // 로그인 (shell 밖)
    GoRoute(
      path: '/login',
      name: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),

    // Bottom Navigation Shell
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          name: RouteNames.home,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/search',
          name: RouteNames.search,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SearchScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          name: RouteNames.profile,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),

    // 전체 화면 (shell 밖)
    GoRoute(
      path: '/product/:id',
      name: RouteNames.productDetail,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProductDetailScreen(productId: id);
      },
    ),
  ],
);
```

### MainShell 구현

```dart
// lib/features/main/presentation/pages/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// RouteNames는 프로젝트에서 정의 (route_names.dart 참조)
// import 'package:your_app/core/router/route_names.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed(RouteNames.home);
        break;
      case 1:
        context.goNamed(RouteNames.search);
        break;
      case 2:
        context.goNamed(RouteNames.profile);
        break;
    }
  }
}
```

### StatefulShellRoute (각 탭 독립 스택)

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) {
    return MainShell(navigationShell: navigationShell);
  },
  branches: [
    // Home 탭
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/home',
          name: RouteNames.home,
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'notifications',
              name: RouteNames.notifications,
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),
      ],
    ),
    // Search 탭
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/search',
          name: RouteNames.search,
          builder: (context, state) => const SearchScreen(),
          routes: [
            GoRoute(
              path: 'results',
              name: RouteNames.searchResults,
              builder: (context, state) => const SearchResultsScreen(),
            ),
          ],
        ),
      ],
    ),
    // Profile 탭
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/profile',
          name: RouteNames.profile,
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              name: RouteNames.editProfile,
              builder: (context, state) => const EditProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
)
```

```dart
// StatefulShellRoute용 MainShell
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,  // 현재 브랜치의 화면
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          // 해당 브랜치로 이동 (스택 유지)
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
```

## 리다이렉트

### 인증 기반 리다이렉트

```dart
final appRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final authBloc = context.read<AuthBloc>();
    final isLoggedIn = authBloc.state.isAuthenticated;
    final isLoggingIn = state.matchedLocation == '/login';
    final isRegistering = state.matchedLocation == '/register';

    // 로그인 필요 없는 경로
    final publicPaths = ['/login', '/register', '/forgot-password'];
    final isPublicPath = publicPaths.contains(state.matchedLocation);

    // 로그인 안 됐고 공개 경로 아니면 → 로그인으로
    if (!isLoggedIn && !isPublicPath) {
      // 원래 가려던 경로 저장
      return '/login?redirect=${state.matchedLocation}';
    }

    // 로그인 됐고 로그인 페이지면 → 홈으로
    if (isLoggedIn && (isLoggingIn || isRegistering)) {
      return '/home';
    }

    // 리다이렉트 필요 없음
    return null;
  },
  routes: [...],
);
```

### Listenable로 상태 변화 감지

```dart
// lib/core/router/app_router.dart
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      // 상태가 변할 때마다 redirect 재평가
      final isAuthenticated = authBloc.state.isAuthenticated;
      // ... 리다이렉트 로직
    },
    routes: [...],
  );
}

// Stream을 Listenable로 변환
/// GoRouterRefreshStream - 인증 상태 변화 시 라우터 새로고침
///
/// ⚠️ 메모리 관리 주의사항:
/// - GoRouter가 dispose될 때 refreshListenable의 dispose가 자동 호출됨
/// - 앱 전체 생명주기 동안 유지되므로 일반적으로 문제없음
/// - 만약 GoRouter를 동적으로 생성/삭제한다면 수동 dispose 필요
// import 'dart:async';
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

### 라우트별 리다이렉트

```dart
GoRoute(
  path: '/admin',
  name: 'admin',
  redirect: (context, state) {
    final user = context.read<AuthBloc>().state.user;
    if (user?.role != UserRole.admin) {
      return '/unauthorized';
    }
    return null;  // 리다이렉트 없음
  },
  builder: (context, state) => const AdminScreen(),
),
```

## 딥링크

### URL 스킴 설정 (iOS)

```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
    <key>CFBundleURLName</key>
    <string>com.example.myapp</string>
  </dict>
</array>
```

### URL 스킴 설정 (Android)

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<activity>
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="myapp" android:host="open" />
  </intent-filter>
</activity>
```

### Universal Links (iOS)

```json
// apple-app-site-association (서버에 배포)
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.example.myapp",
        "paths": ["/products/*", "/orders/*"]
      }
    ]
  }
}
```

### App Links (Android)

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="example.com" />
</intent-filter>
```

### 딥링크 처리

GoRouter는 딥링크를 자동으로 처리합니다. 라우트만 정의하면 됩니다.

```dart
// myapp://open/products/123 → /products/123
// https://example.com/products/123 → /products/123

GoRoute(
  path: '/products/:id',
  name: 'product-detail',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return ProductDetailScreen(productId: id);
  },
),
```

## 페이지 전환 애니메이션

### 커스텀 전환

```dart
GoRoute(
  path: '/profile',
  name: 'profile',
  pageBuilder: (context, state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: const ProfileScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  },
),
```

### 슬라이드 전환

```dart
pageBuilder: (context, state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: const DetailScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
},
```

### 전환 없음 (Bottom Navigation용)

```dart
pageBuilder: (context, state) => const NoTransitionPage(
  child: HomeScreen(),
),
```

## 에러 처리

### 404 에러 페이지

```dart
final appRouter = GoRouter(
  routes: [...],
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Page not found: ${state.uri.path}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  },
);
```

### 에러 페이지 커스터마이징

```dart
errorPageBuilder: (context, state) {
  return MaterialPage(
    key: state.pageKey,
    child: ErrorScreen(
      error: state.error,
      path: state.uri.path,
    ),
  );
},
```

## Bloc과 통합

### Navigation Effect 처리

> **Note**: `sealed class`는 Dart 3.0+ 이상에서 사용 가능합니다. Dart 2.x를 사용하는 경우 `abstract class`를 사용하세요.

```dart
// lib/features/auth/presentation/bloc/auth_bloc.dart
sealed class AuthEffect {  // Dart 3.0+ required
  const AuthEffect();
}

class NavigateToHome extends AuthEffect {
  const NavigateToHome();
}

class NavigateToLogin extends AuthEffect {
  const NavigateToLogin();
}

// Bloc에서 Effect 발생
class AuthBloc extends BaseBloc<AuthEvent, AuthState, AuthEffect> {
  Future<void> _onLogout(Emitter<AuthState> emit) async {
    await _logoutUseCase();
    emit(state.copyWith(isAuthenticated: false));
    emitEffect(const NavigateToLogin());
  }
}
```

### BlocListener에서 네비게이션

```dart
// 방법 1: 표준 BlocListener 사용 (State 변화 감지)
BlocListener<AuthBloc, AuthState>(
  listenWhen: (prev, curr) => prev.isAuthenticated != curr.isAuthenticated,
  listener: (context, state) {
    if (!state.isAuthenticated) {
      context.go('/login');
    }
  },
  child: ...
)

// 방법 2: Effect 기반 네비게이션 (BlocUiEffect.md 패턴)
// BlocEffectListener는 커스텀 위젯입니다.
// core/BlocUiEffect.md의 패턴과 함께 사용하거나 아래 대안을 사용하세요.

// 대안 2-1: 표준 BlocListener로 Effect 처리
BlocListener<AuthBloc, AuthState>(
  listenWhen: (previous, current) => previous.effect != current.effect,
  listener: (context, state) {
    final effect = state.effect;
    if (effect == null) return;

    // Effect 처리
    switch (effect) {
      case NavigateToHome():
        context.go('/home');
      case NavigateToLogin():
        context.go('/login');
    }

    // Effect 소비 후 초기화 (필요시)
    context.read<AuthBloc>().add(const AuthEvent.clearEffect());
  },
  child: ...
)

// 대안 2-2: BaseBloc의 effectStream 사용
// BlocUiEffect.md의 BaseBloc 패턴 참조
// effectStream을 직접 구독하여 일회성 이벤트 처리
```

## 12. 화면 분석 (Screen Analytics) 통합

### 12.1 NavigatorObserver 활용

```dart
// lib/core/analytics/screen_analytics_observer.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class ScreenAnalyticsObserver extends NavigatorObserver {
  final FirebaseAnalytics _analytics;

  ScreenAnalyticsObserver(this._analytics);

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreenView(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _logScreenView(previousRoute);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logScreenView(newRoute);
    }
  }

  void _logScreenView(Route route) {
    final screenName = _extractScreenName(route);
    if (screenName != null) {
      _analytics.logScreenView(
        screenName: screenName,
        screenClass: route.settings.name,
      );
    }
  }

  String? _extractScreenName(Route route) {
    // GoRouter의 경우 route.settings.name이 경로를 포함
    final name = route.settings.name;
    if (name == null || name.isEmpty) return null;

    // 경로에서 화면 이름 추출 (예: /home -> Home, /diary/123 -> DiaryDetail)
    final segments = name.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return 'Home';

    // 숫자 ID 제거 (예: /diary/123 -> diary)
    final screenPart = segments.firstWhere(
      (s) => !RegExp(r'^\d+$').hasMatch(s),
      orElse: () => segments.first,
    );

    return _formatScreenName(screenPart);
  }

  String _formatScreenName(String path) {
    // snake_case나 kebab-case를 PascalCase로 변환
    return path
        .split(RegExp(r'[-_]'))
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join('');
  }
}
```

### 12.2 GoRouter에 적용

```dart
// lib/core/router/app_router.dart
final appRouter = GoRouter(
  observers: [
    ScreenAnalyticsObserver(FirebaseAnalytics.instance),
  ],
  routes: [...],
);
```

### 12.3 화면별 커스텀 이벤트

```dart
// 상세 페이지에서 아이템 조회 이벤트
class DiaryDetailPage extends StatefulWidget {
  final String diaryId;

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> with RouteAware {
  late final RouteObserver<ModalRoute> _routeObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver = context.read<RouteObserver<ModalRoute>>();
    _routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    // 화면 진입 시 이벤트
    AnalyticsService.logEvent('view_diary', {
      'diary_id': widget.diaryId,
      'source': 'push',
    });
  }

  @override
  void didPopNext() {
    // 다른 화면에서 돌아왔을 때
    AnalyticsService.logEvent('view_diary', {
      'diary_id': widget.diaryId,
      'source': 'pop_back',
    });
  }
}
```

### 12.4 스크롤 깊이 추적

```dart
class AnalyticsScrollListener extends StatelessWidget {
  final Widget child;
  final String screenName;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final progress = notification.metrics.pixels /
              notification.metrics.maxScrollExtent;

          // 25%, 50%, 75%, 100% 지점 추적
          final milestone = (progress * 4).floor() * 25;
          if (milestone > 0) {
            AnalyticsService.logEvent('scroll_depth', {
              'screen': screenName,
              'depth': milestone,
            });
          }
        }
        return false;
      },
      child: child,
    );
  }
}
```

## 전체 Router 예시

```dart
// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import 'route_names.dart';

class AppRouter {
  final AuthBloc authBloc;
  late final GoRouter router;

  AppRouter({required this.authBloc}) {
    router = GoRouter(
      initialLocation: '/splash',
      debugLogDiagnostics: true,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: _handleRedirect,
      routes: _routes,
      errorBuilder: _errorBuilder,
    );
  }

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = authBloc.state.isAuthenticated;
    final isSplash = state.matchedLocation == '/splash';
    final isAuthPath = state.matchedLocation.startsWith('/auth');

    // Splash 화면은 항상 허용
    if (isSplash) return null;

    // 인증 안됨 + 인증 경로 아님 → 로그인으로
    if (!isAuthenticated && !isAuthPath) {
      return '/auth/login?redirect=${Uri.encodeComponent(state.matchedLocation)}';
    }

    // 인증됨 + 인증 경로 → 홈으로
    if (isAuthenticated && isAuthPath) {
      final redirect = state.uri.queryParameters['redirect'];
      return redirect != null ? Uri.decodeComponent(redirect) : '/home';
    }

    return null;
  }

  List<RouteBase> get _routes => [
        // Splash
        GoRoute(
          path: '/splash',
          name: RouteNames.splash,
          builder: (context, state) => const SplashScreen(),
        ),

        // Auth Routes
        GoRoute(
          path: '/auth/login',
          name: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/register',
          name: RouteNames.register,
          builder: (context, state) => const RegisterScreen(),
        ),

        // Main Shell (Bottom Navigation)
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            // Home Branch
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  name: RouteNames.home,
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            // Search Branch
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/search',
                  name: RouteNames.search,
                  builder: (context, state) => const SearchScreen(),
                ),
              ],
            ),
            // Profile Branch
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  name: RouteNames.profile,
                  builder: (context, state) => const ProfileScreen(),
                  routes: [
                    GoRoute(
                      path: 'settings',
                      name: RouteNames.settings,
                      builder: (context, state) => const SettingsScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Full Screen Routes (outside shell)
        GoRoute(
          path: '/product/:id',
          name: RouteNames.productDetail,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            // Product 클래스는 프로젝트에서 정의해야 합니다.
            // 예시:
            // @freezed
            // class Product with _$Product {
            //   const factory Product({
            //     required String id,
            //     required String name,
            //     required int price,
            //   }) = _Product;
            // }
            final product = state.extra as Product?;
            return ProductDetailScreen(
              productId: id,
              initialProduct: product,
            );
          },
        ),
      ];

  Widget _errorBuilder(BuildContext context, GoRouterState state) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri.path}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 테스트

### 라우터 테스트

```dart
void main() {
  testWidgets('should navigate to login when not authenticated', (tester) async {
    final authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(
      const AuthState(isAuthenticated: false),
    );

    final router = AppRouter(authBloc: authBloc).router;

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );

    router.go('/home');
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
```

## 타입 안전한 라우팅 (선택적)

대규모 프로젝트에서는 `go_router_builder`를 사용한 타입 안전 라우팅을 권장합니다. 이를 통해 컴파일 타임에 경로와 파라미터 오류를 방지할 수 있습니다.

### 설치

```yaml
# pubspec.yaml
dependencies:
  go_router: ^17.0.1

dev_dependencies:
  go_router_builder: ^2.7.0
  build_runner: ^2.4.15
```

### 라우트 정의

```dart
// lib/core/router/app_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'app_routes.g.dart';

// 파라미터 없는 라우트
@TypedGoRoute<HomeRoute>(path: '/home')
class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomeScreen();
  }
}

// Path 파라미터가 있는 라우트
@TypedGoRoute<ProductRoute>(path: '/product/:id')
class ProductRoute extends GoRouteData {
  final String id;

  const ProductRoute({required this.id});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ProductScreen(productId: id);
  }
}

// Query 파라미터가 있는 라우트
@TypedGoRoute<SearchRoute>(path: '/search')
class SearchRoute extends GoRouteData {
  final String? query;
  final int? page;

  const SearchRoute({this.query, this.page});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SearchScreen(
      query: query ?? '',
      page: page ?? 1,
    );
  }
}

// 중첩 라우트
@TypedGoRoute<UserRoute>(
  path: '/user/:userId',
  routes: [
    TypedGoRoute<UserPostsRoute>(path: 'posts'),
    TypedGoRoute<UserSettingsRoute>(path: 'settings'),
  ],
)
class UserRoute extends GoRouteData {
  final String userId;

  const UserRoute({required this.userId});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return UserScreen(userId: userId);
  }
}

class UserPostsRoute extends GoRouteData {
  final String userId;

  const UserPostsRoute({required this.userId});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return UserPostsScreen(userId: userId);
  }
}
```

### 코드 생성

```bash
# 라우트 코드 생성
dart run build_runner build --delete-conflicting-outputs

# Watch 모드 (자동 재생성)
dart run build_runner watch --delete-conflicting-outputs
```

### 사용 예시

```dart
// 타입 안전한 네비게이션
const HomeRoute().go(context);
ProductRoute(id: '123').push(context);
SearchRoute(query: 'flutter', page: 2).go(context);

// URL 생성
final url = ProductRoute(id: '123').location;  // "/product/123"

// 기존 방식과 혼용 가능
context.go('/legacy-route');
```

### GoRouter 연동

```dart
// lib/core/router/app_router.dart
import 'app_routes.dart';

final appRouter = GoRouter(
  routes: $appRoutes,  // 생성된 라우트 사용
  // ... 기타 설정
);
```

### 장점

- **컴파일 타임 안전성**: 잘못된 경로나 파라미터를 컴파일 단계에서 감지
- **자동완성**: IDE에서 라우트와 파라미터 자동완성 지원
- **리팩토링 용이**: 라우트 이름 변경 시 모든 참조가 자동 업데이트
- **명확한 타입**: 파라미터 타입이 명확하여 런타임 오류 감소

## 실습 과제

### 과제 1: 기본 라우팅 구현
GoRouter를 사용하여 홈, 로그인, 프로필(userId 파라미터) 3개 화면으로 구성된 라우터를 구현하세요. 로그인 상태에 따라 미인증 사용자를 로그인 화면으로 리다이렉트하세요.

### 과제 2: StatefulShellRoute 탭 네비게이션
StatefulShellRoute.indexedStack를 사용하여 3개 탭(홈, 검색, 마이페이지)으로 구성된 Bottom Navigation을 구현하세요. 각 탭은 독립적인 네비게이션 스택을 유지해야 합니다.

### 과제 3: 타입 안전한 라우팅 적용
go_router_builder를 사용하여 기존 라우트를 타입 안전한 방식으로 변환하세요. Path 파라미터와 Query 파라미터를 포함한 라우트를 최소 2개 이상 정의하세요.

## Self-Check 퀴즈

- [ ] `context.go()`와 `context.push()`의 차이점을 설명할 수 있는가?
- [ ] ShellRoute와 StatefulShellRoute의 차이점과 각각의 사용 시점을 이해하고 있는가?
- [ ] GoRouter의 redirect 콜백에서 `null`을 반환하는 것과 경로를 반환하는 것의 의미를 이해하고 있는가?
- [ ] GoRouterRefreshStream을 사용하여 인증 상태 변화 시 라우터를 자동으로 갱신하는 방법을 구현할 수 있는가?
- [ ] extra를 사용한 객체 전달의 장단점을 설명할 수 있는가? (딥링크 미지원 등)

## 체크리스트

- [ ] go_router 패키지 설치
- [ ] 라우트 이름과 경로 상수 정의
- [ ] GoRouter 인스턴스 생성 및 MaterialApp.router 연동
- [ ] 인증 기반 리다이렉트 구현
- [ ] ShellRoute/StatefulShellRoute로 Bottom Navigation 구현
- [ ] 딥링크 URL 스킴 설정 (iOS/Android)
- [ ] 에러 페이지 구현
- [ ] 페이지 전환 애니메이션 커스터마이징 (필요시)
- [ ] Bloc과 연동하여 네비게이션 Effect 처리
- [ ] 타입 안전한 라우팅 적용 (대규모 프로젝트)
