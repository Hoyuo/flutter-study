# Flutter 네비게이션 가이드 (GoRouter)

## 개요

GoRouter는 Flutter의 Navigator 2.0 API를 기반으로 한 선언적 라우팅 패키지입니다. URL 기반 라우팅, 딥링크, 리다이렉션, 중첩 네비게이션 등을 간편하게 구현할 수 있습니다.

## 설치 및 설정

### 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  go_router: ^14.0.0
```

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
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

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

```dart
// lib/features/auth/presentation/bloc/auth_bloc.dart
sealed class AuthEffect {
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
BlocListener<AuthBloc, AuthState>(
  listenWhen: (prev, curr) => prev.isAuthenticated != curr.isAuthenticated,
  listener: (context, state) {
    if (!state.isAuthenticated) {
      context.go('/login');
    }
  },
  child: ...
)

// Effect 기반 네비게이션
BlocEffectListener<AuthBloc, AuthEffect>(
  listener: (context, effect) {
    switch (effect) {
      case NavigateToHome():
        context.go('/home');
      case NavigateToLogin():
        context.go('/login');
    }
  },
  child: ...
)
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
