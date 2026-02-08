# Flutter Clean Architecture Reference Guide

> **마지막 업데이트**: 2026-02-08 | **Flutter 3.38** | **Dart 3.10**
Flutter 개발을 위한 포괄적인 참조 가이드입니다. Clean Architecture + Bloc 패턴을 기반으로 한 56개의 문서와 실제 구현 예제를 제공합니다.

## Overview

이 저장소는 Flutter 앱 개발에 필요한 모든 핵심 패턴을 다룹니다:

- **Clean Architecture** - 계층 분리와 의존성 규칙
- **Bloc Pattern** - Event-Driven 상태 관리
- **Functional Error Handling** - Either<Failure, T> 패턴
- **Multi-country Support** - KR/JP/TW 다국어 지원

## Documentation Structure

```
flutter-study/
├── fundamentals/   # 기초 (5개)
├── core/           # 핵심 아키텍처 (7개)
├── advanced/       # 시니어급 고급 주제 (5개)
├── infrastructure/ # 인프라 (10개)
├── networking/     # 네트워킹 (4개)
├── features/       # 기능별 가이드 (14개)
├── system/         # 시스템 (10개)
└── projects/       # 실전 프로젝트 (1개)
```

**총 56개 문서** - 자세한 내용은 [AGENTS.md](./AGENTS.md) 참조

## Quick Start

### 문서 탐색

권장 학습 순서:

| 단계 | 문서 | 내용 |
|------|------|------|
| 1 | [Architecture](./core/Architecture.md) | 전체 구조 이해 |
| 2 | [DI](./infrastructure/DI.md) | 의존성 주입 설정 |
| 3 | [Bloc](./core/Bloc.md) | 상태 관리 패턴 |
| 4 | [Freezed](./core/Freezed.md) | 불변 데이터 모델 |
| 5 | [Networking](./networking/Networking_Dio.md) | API 통신 |

## Documentation Categories

### Fundamentals (5개)
Dart 언어와 Flutter 기본기
- DartAdvanced, WidgetFundamentals, LayoutSystem, FlutterInternals, DesignSystem

### Core (7개)
핵심 아키텍처 패턴
- Architecture, Bloc, BlocUiEffect, Freezed, Fpdart, Riverpod, ErrorHandling

### Advanced (5개)
시니어급 아키텍처 패턴과 고급 상태 관리
- ModularArchitecture, AdvancedStateManagement, AdvancedPatterns, ServerDrivenUI, OfflineSupport

### Infrastructure (10개)
인프라 설정
- DI, Environment, LocalStorage, CICD, StoreSubmission, Firebase, FlutterMultiPlatform, PackageDevelopment, CachingStrategy, PlatformIntegration

### Networking (4개)
네트워크 통신
- Networking_Dio, Networking_Retrofit, WebSocket, GraphQL

### Features (14개)
기능별 구현
- Navigation, Localization, Permission, PushNotification, DeepLinking, MapsGeolocation, CameraMedia, Animation, CustomPainting, FormValidation, ImageHandling, InAppPurchase, Pagination, ResponsiveDesign

### System (10개)
시스템 품질
- AppLifecycle, Testing, Performance, Security, Accessibility, ProductionOperations, TeamCollaboration, Isolates, Observability, DevToolsProfiling

### Projects (1개)
실전 프로젝트 튜토리얼
- FullStackProject (Clean Architecture + Bloc 패턴으로 Todo 앱 처음부터 끝까지)

### Advanced - Senior Level (10개)
10년차+ 시니어 개발자를 위한 고급 주제
- [ModularArchitecture](./advanced/ModularArchitecture.md) - Mono-repo, Melos, Micro Frontend
- [AdvancedStateManagement](./advanced/AdvancedStateManagement.md) - CQRS, Event Sourcing, Undo/Redo
- [AdvancedPatterns](./advanced/AdvancedPatterns.md) - DDD, Hexagonal, Saga, Specification
- [ServerDrivenUI](./advanced/ServerDrivenUI.md) - Server-Driven UI 패턴
- [OfflineSupport](./advanced/OfflineSupport.md) - Offline-first Architecture
- [PlatformIntegration](./infrastructure/PlatformIntegration.md) - Platform Channel, FFI, Pigeon
- [Performance](./system/Performance.md) - Custom RenderObject, Impeller, Memory Profiling
- [Testing](./system/Testing.md) - Property-based, Golden Test, Mutation, Contract, Fuzz Testing
- [CICD](./infrastructure/CICD.md) - Trunk-based, Canary Release, Shorebird
- [ProductionOperations](./system/ProductionOperations.md) - SLO/SLI, Crash-free Rate, Incident Management

## Tech Stack

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_bloc | ^9.1.1 | State Management |
| freezed | ^3.1.0 | Immutable Data Classes |
| fpdart | ^1.2.0 | Functional Programming |
| get_it + injectable | ^9.2.0 | Dependency Injection |
| go_router | ^17.1.0 | Navigation |
| dio + retrofit | ^5.9.0 | HTTP Client |
| riverpod | ^3.0.0 | Alternative State Management |
| web_socket_channel | ^3.0.2 | WebSocket Communication |
| firebase_core | ^3.12.1 | Firebase Integration |
| easy_localization | ^3.0.7 | i18n (KR/JP/TW) |

## For AI Agents

이 저장소는 AI 코딩 어시스턴트와 함께 사용하도록 설계되었습니다.

- 각 폴더에 `AGENTS.md` 파일이 있어 AI가 컨텍스트를 빠르게 파악할 수 있습니다
- 루트의 [AGENTS.md](./AGENTS.md)에서 전체 구조를 확인할 수 있습니다

## License

MIT License - 자유롭게 사용, 수정, 배포할 수 있습니다.
