<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-01-27 | Updated: 2026-01-27 -->

# Features

## Purpose

앱의 주요 기능별 구현 가이드 문서 모음입니다. 네비게이션, 다국어 지원, 권한 관리, 푸시 알림 등 대부분의 앱에서 필요로 하는 공통 기능 구현 방법을 설명합니다.

## Key Files

| File | Description |
|------|-------------|
| `Navigation.md` | GoRouter 설정, 딥링크 처리, 인증 리다이렉트, ShellRoute 구성 |
| `Localization.md` | easy_localization 다국어 지원, JSON 번역 파일 관리, 런타임 언어 변경 |
| `Permission.md` | permission_handler 권한 관리, 플랫폼별 설정, 권한 요청 플로우 |
| `PushNotification.md` | FCM + flutter_local_notifications 푸시 알림, 토픽 구독, 백그라운드 처리 |
| `DeepLinking.md` | Universal Links, App Links, 딥링크 처리, 라우팅 통합, 동적 링크 |
| `MapsGeolocation.md` | Google Maps 통합, 위치 서비스, Geofencing, 마커/폴리라인, 권한 처리 |
| `CameraMedia.md` | 카메라 촬영, 이미지/비디오 처리, 갤러리 접근, 미디어 압축, 권한 관리 |
| `Animation.md` | 암시적/명시적 애니메이션, AnimatedBuilder, Lottie, Hero, Custom Tween |
| `CustomPainting.md` | Canvas API, CustomPainter, Path 그리기, 차트/그래픽 렌더링 |
| `FormValidation.md` | 폼 유효성 검사, ValidatorBuilder, Form Bloc, 실시간 검증 |
| `ImageHandling.md` | 이미지 캐싱, 크롭, 압축, 서버 업로드, cached_network_image |
| `InAppPurchase.md` | 인앱 결제, 구독 관리, 영수증 검증, 복원 처리 |
| `Pagination.md` | 무한 스크롤, 커서 기반 페이지네이션, PaginationState, LazyLoad |
| `ResponsiveDesign.md` | 반응형/적응형 디자인, LayoutBuilder, MediaQuery, Breakpoints |
| `Authentication.md` | 인증/로그인 통합 가이드: JWT/Refresh Token, OAuth2/PKCE, 소셜 로그인(Google/Apple/Kakao), AuthBloc, 생체인증, RBAC |
| `WebView.md` | WebView 통합: PG 결제(iamport/portone), JavaScript Bridge, OAuth WebView, 하이브리드 앱, 보안 |

## For AI Agents

### Working In This Directory

- Multi-country (KR/JP/TW) 지원을 고려한 설계
- 플랫폼별(iOS/Android) 네이티브 설정 포함
- 각 기능은 Bloc 패턴과 통합되어 사용

### Learning Path

1. `Navigation.md` → 앱 라우팅 구성
2. `Localization.md` → 다국어 지원
3. `Permission.md` → 권한 관리
4. `PushNotification.md` → 알림 시스템
5. `FormValidation.md` → 폼 처리
6. `Animation.md` → 애니메이션
7. `Pagination.md` → 페이지네이션

### Common Patterns

```dart
// GoRouter with Auth Redirect
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = authBloc.state.isAuthenticated;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginRoute) return '/login';
    if (isLoggedIn && isLoginRoute) return '/home';
    return null;
  },
  routes: [...],
);

// easy_localization 사용
Text('welcome'.tr(args: [userName]));
```

## Dependencies

### Internal

- `../core/Bloc.md` - 각 기능의 Bloc 통합
- `../infrastructure/` - DI 및 환경 설정

### External

- `go_router` - Declarative Routing
- `easy_localization` - Internationalization
- `permission_handler` - Runtime Permissions
- `firebase_messaging` - FCM
- `flutter_local_notifications` - Local Notifications

<!-- MANUAL: -->
