import 'package:core/services/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:auth/auth.dart';

import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/diary/presentation/pages/diary_list_page.dart';
import '../../features/diary/presentation/pages/diary_detail_page.dart';
import '../../features/diary/presentation/pages/diary_edit_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import 'analytics_route_observer.dart';

/// 앱 전체의 라우팅을 관리하는 클래스
///
/// GoRouter를 사용한 선언적 라우팅 설정
/// - Auth Guard를 통한 인증 보호
/// - 계층적 라우팅 구조
/// - Deep Link 지원
/// - Analytics 화면 조회 추적
@singleton
class AppRouter {
  final AuthBloc _authBloc;
  final AnalyticsService _analyticsService;

  late final GoRouter router;

  AppRouter(this._authBloc, this._analyticsService) {
    router = GoRouter(
      initialLocation: '/splash',
      debugLogDiagnostics: true,

      // Analytics 화면 조회 추적
      observers: [AnalyticsRouteObserver(_analyticsService)],

      // Auth Guard: 인증 상태에 따라 자동 리다이렉트
      redirect: (context, state) {
        final authState = _authBloc.state;
        final isAuthenticated = authState.status == AuthStatus.authenticated;

        final isAuthRoute = state.matchedLocation.startsWith('/auth');
        final isSplashRoute = state.matchedLocation == '/splash';

        // 인증되지 않은 상태에서 보호된 페이지 접근 시 로그인 페이지로
        if (!isAuthenticated && !isAuthRoute && !isSplashRoute) {
          return '/auth/login';
        }

        // 인증된 상태에서 auth 페이지 접근 시 홈으로
        if (isAuthenticated && isAuthRoute) {
          return '/diary';
        }

        return null; // 리다이렉트 없음
      },

      // 라우트 정의
      routes: [
        // Splash
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),

        // Auth Routes
        GoRoute(
          path: '/auth',
          redirect: (_, __) => '/auth/login', // /auth로 접근 시 login으로 리다이렉트
          routes: [
            GoRoute(
              path: 'login',
              name: 'login',
              builder: (context, state) => const LoginPage(),
            ),
            GoRoute(
              path: 'register',
              name: 'register',
              builder: (context, state) => const RegisterPage(),
            ),
          ],
        ),

        // Diary Routes (Main)
        GoRoute(
          path: '/diary',
          name: 'diary_list',
          builder: (context, state) => const DiaryListPage(),
          routes: [
            // New Diary
            GoRoute(
              path: 'new',
              name: 'diary_new',
              builder: (context, state) => const DiaryEditPage(),
            ),
            // Diary Detail
            GoRoute(
              path: ':id',
              name: 'diary_detail',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return DiaryDetailPage(entryId: id);
              },
              routes: [
                // Edit Diary
                GoRoute(
                  path: 'edit',
                  name: 'diary_edit',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return DiaryEditPage(entryId: id);
                  },
                ),
              ],
            ),
          ],
        ),

        // Search
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) => const SearchPage(),
        ),

        // Settings
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),

        // Home (Legacy - redirect to diary)
        GoRoute(path: '/home', name: 'home', redirect: (_, __) => '/diary'),

        // Root - redirect to diary
        GoRoute(path: '/', redirect: (_, __) => '/diary'),
      ],

      // Error Handler
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('오류')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '페이지를 찾을 수 없습니다',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? '알 수 없는 오류',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/diary'),
                child: const Text('홈으로 이동'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
