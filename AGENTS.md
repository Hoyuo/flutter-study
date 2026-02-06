<!-- Generated: 2026-01-27 | Updated: 2026-01-27 -->

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
| `core/` | 핵심 아키텍처 - Architecture, Bloc, BlocUiEffect, Freezed, Fpdart, ModularArchitecture, PlatformIntegration, AdvancedStateManagement | 8개 (see `core/AGENTS.md`) |
| `infrastructure/` | 인프라 - DI, Environment, LocalStorage, CICD, StoreSubmission, AdvancedCICD | 6개 (see `infrastructure/AGENTS.md`) |
| `networking/` | 네트워킹 - Dio, Retrofit | 2개 (see `networking/AGENTS.md`) |
| `features/` | 기능별 - Navigation, Localization, Permission, PushNotification | 4개 (see `features/AGENTS.md`) |
| `patterns/` | 필수 패턴 - Analytics, ImageHandling, Pagination, FormValidation, OfflineSupport, InAppPurchase, Animation, AdvancedPatterns | 8개 (see `patterns/AGENTS.md`) |
| `system/` | 시스템 - ErrorHandling, Theming, AppLifecycle, Testing, Performance, Security, Accessibility, Logging, Monitoring, AdvancedPerformance, AdvancedTesting, ProductionOperations, AdvancedSecurity | 13개 (see `system/AGENTS.md`) |

**총 41개 문서**

## Directory Structure

```
flutter-study/
├── AGENTS.md                 ← 이 파일 (루트 인덱스)
├── core/                     ← 핵심 아키텍처
│   ├── AGENTS.md
│   ├── Architecture.md
│   ├── Bloc.md
│   ├── BlocUiEffect.md
│   ├── Freezed.md
│   ├── Fpdart.md
│   ├── ModularArchitecture.md
│   ├── PlatformIntegration.md
│   └── AdvancedStateManagement.md
├── infrastructure/           ← 인프라
│   ├── AGENTS.md
│   ├── DI.md
│   ├── Environment.md
│   ├── LocalStorage.md
│   ├── CICD.md
│   ├── StoreSubmission.md
│   └── AdvancedCICD.md
├── networking/               ← 네트워킹
│   ├── AGENTS.md
│   ├── Networking_Dio.md
│   └── Networking_Retrofit.md
├── features/                 ← 기능별
│   ├── AGENTS.md
│   ├── Navigation.md
│   ├── Localization.md
│   ├── Permission.md
│   └── PushNotification.md
├── patterns/                 ← 필수 패턴
│   ├── AGENTS.md
│   ├── Analytics.md
│   ├── ImageHandling.md
│   ├── Pagination.md
│   ├── FormValidation.md
│   ├── OfflineSupport.md
│   ├── InAppPurchase.md
│   ├── Animation.md
│   └── AdvancedPatterns.md
└── system/                   ← 시스템
    ├── AGENTS.md
    ├── ErrorHandling.md
    ├── Theming.md
    ├── AppLifecycle.md
    ├── Testing.md
    ├── Performance.md
    ├── Security.md
    ├── Accessibility.md
    ├── Logging.md
    ├── Monitoring.md
    ├── AdvancedPerformance.md
    ├── AdvancedTesting.md
    ├── ProductionOperations.md
    └── AdvancedSecurity.md
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

- **Error Handling**: `Failure` sealed class + `Either<Failure, T>`
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
| `go_router` | Navigation |
| `easy_localization` | i18n |
| `permission_handler` | Permissions |
| `firebase_messaging` | Push Notifications |
| `firebase_analytics` | Analytics |
| `hive` | Local Storage |

## Document Index (권장 참조 순서)

### 기초 (Foundation)

1. `core/Architecture.md` - 전체 구조
2. `infrastructure/DI.md` - 의존성 주입
3. `core/Bloc.md` - 상태 관리
4. `core/Freezed.md` - 불변 데이터 모델
5. `networking/Networking_Dio.md` → `networking/Networking_Retrofit.md` - API 통신

### 심화 (Advanced)

6. `core/Fpdart.md` - 함수형 프로그래밍
7. `system/ErrorHandling.md` - 에러 처리 패턴
8. `core/BlocUiEffect.md` - UI 효과 처리
9. `features/Navigation.md` - 라우팅
10. `patterns/FormValidation.md` - 폼 처리

### 기능별 가이드 (Features)

11. `features/Localization.md` - 다국어
12. `features/Permission.md` - 권한 관리
13. `features/PushNotification.md` - 푸시 알림
14. `patterns/Analytics.md` - 분석/추적
15. `system/Theming.md` - 테마 시스템

### 시스템 및 인프라 (System)

16. `infrastructure/Environment.md` - 환경 설정
17. `infrastructure/LocalStorage.md` - 로컬 저장소
18. `patterns/ImageHandling.md` - 이미지 처리
19. `patterns/Pagination.md` - 페이지네이션
20. `system/AppLifecycle.md` - 생명주기
21. `system/Testing.md` - 테스트 전략
22. `system/Performance.md` - 성능 최적화
23. `system/Security.md` - 보안
24. `system/Accessibility.md` - 접근성
25. `system/Logging.md` - 로깅

### Production 운영 (Production)

26. `system/Monitoring.md` - 모니터링 (Crashlytics, Sentry, Performance)
27. `infrastructure/CICD.md` - CI/CD 파이프라인 (GitHub Actions, Fastlane)
28. `infrastructure/StoreSubmission.md` - 앱스토어 제출
29. `patterns/OfflineSupport.md` - 오프라인 지원
30. `patterns/InAppPurchase.md` - 인앱 결제
31. `patterns/Animation.md` - 애니메이션

### 시니어 (Senior Level)

32. `core/ModularArchitecture.md` - Mono-repo, Melos, Micro Frontend
33. `core/AdvancedStateManagement.md` - CQRS, Event Sourcing, Undo/Redo
34. `core/PlatformIntegration.md` - Platform Channel, FFI, Pigeon
35. `system/AdvancedPerformance.md` - Custom RenderObject, Impeller, Memory Profiling
36. `system/AdvancedTesting.md` - Property-based, Golden Test, E2E
37. `system/AdvancedSecurity.md` - Code Obfuscation, RASP, mTLS
38. `infrastructure/AdvancedCICD.md` - Trunk-based, Canary Release, Shorebird
39. `system/ProductionOperations.md` - SLO/SLI, Crash-free Rate, Incident Management
40. `patterns/AdvancedPatterns.md` - DDD, Hexagonal, Saga, Specification

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
