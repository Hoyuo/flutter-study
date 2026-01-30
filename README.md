# Flutter Clean Architecture Reference Guide

Flutter 개발을 위한 포괄적인 참조 가이드입니다. Clean Architecture + Bloc 패턴을 기반으로 한 32개의 문서와 실제 구현 예제를 제공합니다.

## Overview

이 저장소는 Flutter 앱 개발에 필요한 모든 핵심 패턴을 다룹니다:

- **Clean Architecture** - 계층 분리와 의존성 규칙
- **Bloc Pattern** - Event-Driven 상태 관리
- **Functional Error Handling** - Either<Failure, T> 패턴
- **Multi-country Support** - KR/JP/TW 다국어 지원

## Documentation Structure

```
flutter-study/
├── core/           # 핵심 아키텍처 (5개)
├── infrastructure/ # 인프라 (5개)
├── networking/     # 네트워킹 (2개)
├── features/       # 기능별 가이드 (4개)
├── patterns/       # 필수 패턴 (7개)
├── system/         # 시스템 (9개)
└── examples/       # 실제 구현 예제
```

**총 32개 문서** - 자세한 내용은 [AGENTS.md](./AGENTS.md) 참조

## Quick Start

### 1. 문서 탐색

권장 학습 순서:

| 단계 | 문서 | 내용 |
|------|------|------|
| 1 | [Architecture](./core/Architecture.md) | 전체 구조 이해 |
| 2 | [DI](./infrastructure/DI.md) | 의존성 주입 설정 |
| 3 | [Bloc](./core/Bloc.md) | 상태 관리 패턴 |
| 4 | [Freezed](./core/Freezed.md) | 불변 데이터 모델 |
| 5 | [Networking](./networking/Networking_Dio.md) | API 통신 |

### 2. 예제 앱 실행

[Photo Diary](./examples/photo_diary/) 앱은 32개 문서의 모든 패턴을 구현한 완전한 예제입니다.

```bash
cd examples/photo_diary
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Documentation Categories

### Core (5개)
핵심 아키텍처 패턴
- Architecture, Bloc, BlocUiEffect, Freezed, Fpdart

### Infrastructure (5개)
인프라 설정
- DI, Environment, LocalStorage, CICD, StoreSubmission

### Networking (2개)
네트워크 통신
- Networking_Dio, Networking_Retrofit

### Features (4개)
기능별 구현
- Navigation, Localization, Permission, PushNotification

### Patterns (7개)
공통 패턴
- Analytics, ImageHandling, Pagination, FormValidation, InAppPurchase, Animation, OfflineSupport

### System (9개)
시스템 품질
- ErrorHandling, Theming, AppLifecycle, Testing, Performance, Security, Accessibility, Logging, Monitoring

## Tech Stack

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_bloc | ^9.1.1 | State Management |
| freezed | ^3.1.0 | Immutable Data Classes |
| fpdart | ^1.1.0 | Functional Programming |
| get_it + injectable | ^8.0.2 | Dependency Injection |
| go_router | ^14.6.2 | Navigation |
| dio + retrofit | ^5.9.0 | HTTP Client |
| easy_localization | ^3.0.7 | i18n (KR/JP/TW) |

## For AI Agents

이 저장소는 AI 코딩 어시스턴트와 함께 사용하도록 설계되었습니다.

- 각 폴더에 `AGENTS.md` 파일이 있어 AI가 컨텍스트를 빠르게 파악할 수 있습니다
- 루트의 [AGENTS.md](./AGENTS.md)에서 전체 구조를 확인할 수 있습니다

## License

MIT License - 자유롭게 사용, 수정, 배포할 수 있습니다.
