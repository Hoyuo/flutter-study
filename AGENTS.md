<!-- Generated: 2026-01-27 | Updated: 2026-02-07 -->

# Flutter Study

## Purpose

Flutter 개발팀을 위한 포괄적인 개발 가이드 문서 저장소입니다. Clean Architecture + Bloc 패턴을 기반으로 한 일관된 개발 패턴과 모범 사례를 제공합니다.

**핵심 원칙:**
- Clean Architecture (Presentation → Domain → Data)
- Feature-based Modularization
- Bloc 패턴 (Event-Driven State Management)
- Multi-country Support (KR, JP, TW) with Code Parity

## Subdirectories

| Directory | Purpose | Documents |
|-----------|---------|-----------|
| `fundamentals/` | 기초 - DartAdvanced, WidgetFundamentals, LayoutSystem, FlutterInternals, DesignSystem | 5개 (see `fundamentals/AGENTS.md`) |
| `core/` | 핵심 아키텍처 - Architecture, Bloc, BlocUiEffect, Freezed, Fpdart, Riverpod, ErrorHandling | 7개 (see `core/AGENTS.md`) |
| `advanced/` | 시니어급 고급 - ModularArchitecture, AdvancedStateManagement, AdvancedPatterns, ServerDrivenUI, OfflineSupport | 5개 (see `advanced/AGENTS.md`) |
| `infrastructure/` | 인프라 - DI, Environment, LocalStorage, CICD, StoreSubmission, Firebase, FlutterMultiPlatform, PackageDevelopment, CachingStrategy, PlatformIntegration | 10개 (see `infrastructure/AGENTS.md`) |
| `networking/` | 네트워킹 - Dio, Retrofit, WebSocket, GraphQL | 4개 (see `networking/AGENTS.md`) |
| `features/` | 기능별 - Navigation, Localization, Permission, PushNotification, DeepLinking, MapsGeolocation, CameraMedia, Animation, CustomPainting, FormValidation, ImageHandling, InAppPurchase, Pagination, ResponsiveDesign | 14개 (see `features/AGENTS.md`) |
| `system/` | 시스템 - AppLifecycle, Testing, Performance, Security, Accessibility, ProductionOperations, TeamCollaboration, Isolates, Observability, DevToolsProfiling | 10개 (see `system/AGENTS.md`) |
| `projects/` | 실전 프로젝트 - FullStackProject (Clean Architecture + Bloc Todo 앱 튜토리얼) | 1개 |

**총 56개 문서**

## Directory Structure

```
flutter-study/
├── AGENTS.md                 ← 이 파일 (루트 인덱스)
├── fundamentals/             ← 기초
│   ├── AGENTS.md
│   ├── DartAdvanced.md
│   ├── WidgetFundamentals.md
│   ├── LayoutSystem.md
│   ├── FlutterInternals.md
│   └── DesignSystem.md
├── core/                     ← 핵심 아키텍처
│   ├── AGENTS.md
│   ├── Architecture.md
│   ├── Bloc.md
│   ├── BlocUiEffect.md
│   ├── Freezed.md
│   ├── Fpdart.md
│   ├── Riverpod.md
│   └── ErrorHandling.md
├── advanced/                 ← 시니어급 고급
│   ├── AGENTS.md
│   ├── ModularArchitecture.md
│   ├── AdvancedStateManagement.md
│   ├── AdvancedPatterns.md
│   ├── ServerDrivenUI.md
│   └── OfflineSupport.md
├── infrastructure/           ← 인프라
│   ├── AGENTS.md
│   ├── DI.md
│   ├── Environment.md
│   ├── LocalStorage.md
│   ├── CICD.md
│   ├── StoreSubmission.md
│   ├── Firebase.md
│   ├── FlutterMultiPlatform.md
│   ├── PackageDevelopment.md
│   ├── CachingStrategy.md
│   └── PlatformIntegration.md
├── networking/               ← 네트워킹
│   ├── AGENTS.md
│   ├── Networking_Dio.md
│   ├── Networking_Retrofit.md
│   ├── WebSocket.md
│   └── GraphQL.md
├── features/                 ← 기능별
│   ├── AGENTS.md
│   ├── Navigation.md
│   ├── Localization.md
│   ├── Permission.md
│   ├── PushNotification.md
│   ├── DeepLinking.md
│   ├── MapsGeolocation.md
│   ├── CameraMedia.md
│   ├── Animation.md
│   ├── CustomPainting.md
│   ├── FormValidation.md
│   ├── ImageHandling.md
│   ├── InAppPurchase.md
│   ├── Pagination.md
│   └── ResponsiveDesign.md
├── system/                   ← 시스템
│   ├── AGENTS.md
│   ├── AppLifecycle.md
│   ├── Testing.md
│   ├── Performance.md
│   ├── Security.md
│   ├── Accessibility.md
│   ├── ProductionOperations.md
│   ├── TeamCollaboration.md
│   ├── Isolates.md
│   ├── Observability.md
│   └── DevToolsProfiling.md
└── projects/                 ← 실전 프로젝트
    └── FullStackProject.md
```

## For AI Agents

### Working In This Directory

- 모든 문서는 PascalCase 파일명 규칙을 따름 (예: `BlocUiEffect.md`)
- 각 폴더에는 해당 카테고리의 AGENTS.md 파일이 존재
- 문서 수정 시 일관된 마크다운 구조 유지
- 코드 예제는 반드시 Dart 언어로 작성
- Multi-country (KR/JP/TW) 지원 원칙 준수

### Document Structure Convention

모든 가이드 문서는 다음 구조를 따름:
1. **Overview** - 개념 설명 및 목적
2. **Setup** - 패키지 설치 및 초기 설정
3. **Implementation** - 레이어별 구현 (Data → Domain → Presentation)
4. **Integration with Bloc** - Bloc 패턴과의 통합
5. **Best Practices** - 모범 사례 및 주의사항
6. **Testing** - 테스트 방법

### Code Example Conventions

```dart
// 1. Freezed 모델은 @freezed 어노테이션 사용
@freezed
class UserState with _$UserState { ... }

// 2. Either 타입으로 에러 처리
Future<Either<Failure, User>> getUser(String id);

// 3. Bloc은 Event/State 분리
class UserBloc extends Bloc<UserEvent, UserState> { ... }
```

### Testing Requirements

- 문서 추가 시 코드 예제가 문법적으로 올바른지 확인
- 패키지 버전이 최신인지 주기적으로 검토

### Common Patterns

- **Error Handling**: `Failure` sealed class + `Either<Failure, T>` (core/ErrorHandling.md)
- **State Management**: Bloc + Freezed State
- **DI**: GetIt + Injectable
- **Navigation**: GoRouter
- **Networking**: Dio + Retrofit

## Dependencies

### External Packages (문서에서 다루는 주요 패키지)

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State Management |
| `freezed` | Immutable Data Classes |
| `fpdart` | Functional Programming |
| `get_it` + `injectable` | Dependency Injection |
| `dio` + `retrofit` | HTTP Client |
| `web_socket_channel` | WebSocket Communication |
| `riverpod` | Alternative State Management |
| `firebase_core` | Firebase Integration |
| `go_router` | Navigation |
| `easy_localization` | i18n |
| `permission_handler` | Permissions |
| `firebase_messaging` | Push Notifications |
| `hive` | Local Storage |

## Document Index (권장 참조 순서)

### 기초 (Foundation)

0. `fundamentals/DartAdvanced.md` - Dart 심화 문법
1. `core/Architecture.md` - 전체 구조
2. `infrastructure/DI.md` - 의존성 주입
3. `core/Bloc.md` - 상태 관리
4. `core/Freezed.md` - 불변 데이터 모델
5. `networking/Networking_Dio.md` → `networking/Networking_Retrofit.md` - API 통신

### 심화 (Advanced)

6. `core/Fpdart.md` - 함수형 프로그래밍
7. `core/ErrorHandling.md` - 에러 처리 패턴
8. `core/BlocUiEffect.md` - UI 효과 처리
9. `features/Navigation.md` - 라우팅
10. `features/FormValidation.md` - 폼 처리

### 기능별 가이드 (Features)

11. `features/Localization.md` - 다국어
12. `features/Permission.md` - 권한 관리
13. `features/PushNotification.md` - 푸시 알림
14. `system/Observability.md` - 로깅/모니터링/분석 통합
15. `fundamentals/DesignSystem.md` - 테마 시스템 + 디자인 시스템

### 시스템 및 인프라 (System)

16. `infrastructure/Environment.md` - 환경 설정
17. `infrastructure/LocalStorage.md` - 로컬 저장소
18. `features/ImageHandling.md` - 이미지 처리
19. `features/Pagination.md` - 페이지네이션
20. `system/AppLifecycle.md` - 생명주기
21. `system/Testing.md` - 테스트 전략
22. `system/Performance.md` - 성능 최적화
23. `system/Security.md` - 보안
24. `system/Accessibility.md` - 접근성

### Production 운영 (Production)

25. `infrastructure/CICD.md` - CI/CD 파이프라인
26. `infrastructure/StoreSubmission.md` - 앱스토어 제출
27. `advanced/OfflineSupport.md` - 오프라인 지원
28. `features/InAppPurchase.md` - 인앱 결제
29. `features/Animation.md` - 애니메이션
30. `system/ProductionOperations.md` - SLO/SLI, Incident Management

### 시니어 (Senior Level)

31. `advanced/ModularArchitecture.md` - Mono-repo, Melos, Micro Frontend
32. `advanced/AdvancedStateManagement.md` - CQRS, Event Sourcing, Undo/Redo
33. `advanced/AdvancedPatterns.md` - DDD, Hexagonal, Saga, Specification
34. `advanced/ServerDrivenUI.md` - Server-Driven UI
35. `advanced/OfflineSupport.md` - Offline-first Architecture
36. `infrastructure/PlatformIntegration.md` - Platform Channel, FFI, Pigeon
37. `system/Performance.md` (심화) - Custom RenderObject, Impeller, Memory Profiling
38. `system/Testing.md` (심화) - Property-based, Golden Test, Mutation, Contract, Fuzz Testing
39. `infrastructure/CICD.md` (심화) - Trunk-based, Canary Release, Shorebird

### 실전 심화 (Phase 1)

40. `core/Riverpod.md` - Riverpod 상태 관리, Bloc 마이그레이션
41. `networking/WebSocket.md` - WebSocket 실시간 통신
42. `infrastructure/Firebase.md` - Firebase 통합
43. `system/Isolates.md` - Isolate, compute(), 백그라운드 처리
44. `infrastructure/FlutterMultiPlatform.md` - Web/Desktop 멀티플랫폼
45. `infrastructure/PackageDevelopment.md` - Dart/Flutter 패키지 개발
46. `networking/GraphQL.md` - GraphQL 클라이언트
47. `features/DeepLinking.md` - Universal Links, 딥링크
48. `features/MapsGeolocation.md` - Google Maps, 위치 서비스
49. `features/CameraMedia.md` - 카메라, 미디어 처리
50. `features/CustomPainting.md` - Canvas API, CustomPainter

### 신규 추가 (Phase 2)

51. `features/ResponsiveDesign.md` - 반응형/적응형 디자인
52. `infrastructure/CachingStrategy.md` - 캐싱 전략
53. `system/TeamCollaboration.md` - 팀 협업
54. `fundamentals/WidgetFundamentals.md` - Widget/Element/RenderObject 트리
55. `fundamentals/LayoutSystem.md` - Constraints 전파, Flex, Sliver
56. `fundamentals/FlutterInternals.md` - 렌더링 파이프라인
57. `system/DevToolsProfiling.md` - DevTools, 프로파일링
58. `projects/FullStackProject.md` - Clean Architecture + Bloc Todo 앱 튜토리얼
59. `features/Animation.md` - 애니메이션
60. `features/FormValidation.md` - 폼 검증
61. `features/ImageHandling.md` - 이미지 처리
62. `features/InAppPurchase.md` - 인앱 결제
63. `features/Pagination.md` - 페이지네이션

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
