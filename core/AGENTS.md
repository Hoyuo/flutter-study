<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-01-27 | Updated: 2026-01-27 -->

# Core

## Purpose

Flutter 앱 개발의 핵심 아키텍처와 패턴을 다루는 문서 모음입니다. Clean Architecture의 기반이 되는 구조 설계, 상태 관리, 데이터 모델링에 대한 가이드를 제공합니다.

## Key Files

| File | Description |
|------|-------------|
| `Architecture.md` | Clean Architecture 구조, Feature 모듈화, 레이어(Presentation/Domain/Data) 책임 정의 |
| `Bloc.md` | Bloc 패턴 구현, Event/State 설계, Transformer 활용, BlocProvider 구성 |
| `BlocUiEffect.md` | UI Effect 패턴, 일회성 이벤트 처리 (Toast, Navigation, Dialog, SnackBar) |
| `Freezed.md` | 불변 데이터 클래스 생성, Union Type(Sealed Class), copyWith 패턴 |
| `Fpdart.md` | 함수형 프로그래밍, Either/Option/TaskEither를 활용한 에러 처리 |

## For AI Agents

### Working In This Directory

- 문서 수정 시 Clean Architecture 원칙 준수 확인
- Bloc 관련 문서는 Event → State → Bloc 순서로 설명
- 코드 예제는 Freezed + fpdart 조합 패턴 사용

### Learning Path

1. `Architecture.md` → 전체 구조 이해 (필수 선행)
2. `Bloc.md` → 상태 관리 기초
3. `Freezed.md` → 불변 데이터 모델
4. `Fpdart.md` → 함수형 에러 처리
5. `BlocUiEffect.md` → 고급 UI 효과 처리

### Common Patterns

```dart
// Freezed State 정의
@freezed
class UserState with _$UserState {
  const factory UserState.initial() = _Initial;
  const factory UserState.loading() = _Loading;
  const factory UserState.loaded(User user) = _Loaded;
  const factory UserState.error(Failure failure) = _Error;
}

// Either를 활용한 UseCase
Future<Either<Failure, User>> call(String id) async {
  return await repository.getUser(id);
}
```

## Dependencies

### Internal

- `../infrastructure/` - DI 설정 참조
- `../system/ErrorHandling.md` - Failure 클래스 정의 참조

### External

- `flutter_bloc` - State Management
- `freezed` / `freezed_annotation` - Code Generation
- `fpdart` - Functional Programming

<!-- MANUAL: -->
