<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-02-08 -->

# Advanced

## Purpose

시니어급 아키텍처 패턴과 고급 상태 관리를 다루는 문서 모음입니다. 대규모 팀과 복잡한 시스템을 위한 고급 설계 패턴, 모듈화 전략, 이벤트 소싱 등을 제공합니다.

## Key Files

| File | Description |
|------|-------------|
| `ModularArchitecture.md` | Mono-repo/Multi-package 구조, Melos 워크스페이스, Micro Frontend 패턴, 대규모 팀 모듈화 |
| `AdvancedStateManagement.md` | CQRS, Event Sourcing, Optimistic UI, Undo/Redo, State Sync, Time Travel Debugging |
| `AdvancedPatterns.md` | DDD(Domain-Driven Design), Hexagonal Architecture, Saga Pattern, Specification Pattern |
| `ServerDrivenUI.md` | Server-Driven UI 패턴, JSON 기반 동적 렌더링, 원격 구성, A/B 테스팅 |
| `OfflineSupport.md` | Offline-first 아키텍처, Drift ORM, Sync Queue, Conflict Resolution, 동기화 전략 |

## For AI Agents

### Working In This Directory

- 이 카테고리는 시니어 개발자(1년+ 경험)를 위한 고급 주제
- 대규모 팀, 복잡한 비즈니스 로직, 엔터프라이즈 요구사항에 적합
- Clean Architecture와 DDD 원칙에 대한 깊은 이해 필요

### Learning Path

1. `../core/Architecture.md` → 기본 아키텍처 이해 (필수 선행)
2. `ModularArchitecture.md` → 대규모 모듈화 전략
3. `AdvancedPatterns.md` → DDD 및 Hexagonal Architecture
4. `AdvancedStateManagement.md` → CQRS와 Event Sourcing
5. `ServerDrivenUI.md` → 동적 UI 렌더링
6. `OfflineSupport.md` → 오프라인 우선 아키텍처

### Common Patterns

```dart
// DDD Entity with Value Objects
class User extends Entity {
  final UserId id;
  final EmailAddress email;
  final UserName name;

  User({required this.id, required this.email, required this.name});
}

// Event Sourcing
abstract class DomainEvent {
  final DateTime occurredAt;
  DomainEvent() : occurredAt = DateTime.now();
}

class UserCreatedEvent extends DomainEvent {
  final String userId;
  final String email;
  UserCreatedEvent(this.userId, this.email);
}

// CQRS Command
class CreateUserCommand {
  final String email;
  final String name;
  CreateUserCommand(this.email, this.name);
}

// Offline-first with Sync Queue
class SyncQueue {
  Future<void> enqueue(SyncOperation operation) async {
    await _storage.save(operation);
    _processPendingOperations();
  }
}
```

## Dependencies

### Internal

- `../core/Architecture.md` - 기본 아키텍처 패턴
- `../core/Bloc.md` - 상태 관리 기초
- `../core/ErrorHandling.md` - 에러 처리

### External

- `melos` - Mono-repo 관리
- `drift` - SQLite ORM (오프라인 지원)
- `connectivity_plus` - 네트워크 상태 모니터링
- `hive` - 로컬 스토리지
- `json_dynamic_widget` - 동적 위젯 렌더링 (Server-Driven UI)

<!-- MANUAL: -->
