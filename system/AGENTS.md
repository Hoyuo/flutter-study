<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-01-27 | Updated: 2026-01-27 -->

# System

## Purpose

앱의 시스템 레벨 기능을 다루는 문서 모음입니다. 에러 처리, 테마 시스템, 앱 생명주기 관리, 테스트 전략 등 앱 전반의 품질과 안정성에 관련된 가이드를 제공합니다.

## Key Files

| File | Description |
|------|-------------|
| `ErrorHandling.md` | Failure sealed class 설계, Dio 에러 인터셉터, ErrorView 위젯, 재시도 패턴 |
| `Theming.md` | Material 3 테마 시스템, 다크 모드, ThemeExtension, 디자인 토큰 |
| `AppLifecycle.md` | 앱 생명주기 관리, WidgetsBindingObserver, 상태 유지, 백그라운드 처리 |
| `Testing.md` | Unit/Widget/Integration 테스트 전략, Mocktail, BlocTest 활용 |

## For AI Agents

### Working In This Directory

- ErrorHandling은 전체 앱에서 참조되는 핵심 패턴
- Theming은 디자인 시스템과 연계
- Testing은 모든 기능 개발 시 함께 참고

### Learning Path

1. `ErrorHandling.md` → 에러 처리 기초 (필수)
2. `Theming.md` → UI 테마 시스템
3. `AppLifecycle.md` → 생명주기 관리
4. `Testing.md` → 테스트 작성

### Common Patterns

```dart
// Failure Sealed Class
@freezed
sealed class Failure with _$Failure {
  const factory Failure.network({String? message}) = NetworkFailure;
  const factory Failure.server({required int code, String? message}) = ServerFailure;
  const factory Failure.auth({String? message}) = AuthFailure;
  const factory Failure.unknown({String? message}) = UnknownFailure;
}

// Theme Extension
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  final Color success;
  final Color warning;
  final Color error;
  // ...
}

// Bloc Test
blocTest<UserBloc, UserState>(
  'emits [loading, loaded] when fetch succeeds',
  build: () => UserBloc(mockUseCase),
  act: (bloc) => bloc.add(const UserEvent.fetch()),
  expect: () => [
    const UserState.loading(),
    UserState.loaded(testUser),
  ],
);
```

## Dependencies

### Internal

- `../core/Freezed.md` - Failure, State 정의
- `../core/Fpdart.md` - Either 에러 처리
- `../networking/` - API 에러 처리

### External

- `flutter_test` - Testing Framework
- `bloc_test` - Bloc Testing
- `mocktail` - Mocking

<!-- MANUAL: -->
