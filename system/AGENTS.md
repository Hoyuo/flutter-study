<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-01-27 | Updated: 2026-02-07 -->

# System

## Purpose

앱의 시스템 레벨 기능을 다루는 문서 모음입니다. 앱 생명주기 관리, 테스트 전략, 성능 최적화, 보안, 접근성 등 앱 전반의 품질과 안정성에 관련된 가이드를 제공합니다.

## Key Files

| File | Description |
|------|-------------|
| `AppLifecycle.md` | 앱 생명주기 관리, WidgetsBindingObserver, 상태 유지, 백그라운드 처리 |
| `Testing.md` | 기본+심화 통합: Unit/Widget/Integration 테스트, Mocktail, BlocTest, Property-based, Golden Test, Mutation, Contract, Fuzz, E2E Patrol |
| `Performance.md` | 기본+심화 통합: 렌더링/메모리/비동기 최적화, Bloc 성능, Custom RenderObject, Impeller, Fragment Shader, Memory Profiling |
| `Security.md` | 데이터 암호화, Certificate Pinning, 코드 난독화, 인증 보안, 플랫폼별 설정, RASP, mTLS, Jailbreak Detection |
| `Accessibility.md` | Semantics 설정, 스크린 리더 지원, 색상 대비, 모터 접근성, 테스트 |
| `ProductionOperations.md` | SLO/SLI 모니터링, Crash-free Rate, Incident Management, A/B Testing |
| `TeamCollaboration.md` | 팀 협업, 코드 리뷰, 브랜치 전략, 문서화, 온보딩 |
| `Isolates.md` | Isolate 개념, compute() 함수, 백그라운드 처리, Worker Pool, 병렬 처리 패턴 |
| `Observability.md` | 통합 관찰성 - 구조화된 로깅, 에러 추적, 성능 모니터링, Crashlytics/Sentry 연동 |
| `DevToolsProfiling.md` | Flutter DevTools 활용, 성능 프로파일링, 메모리 분석, Widget Inspector, Timeline |

## For AI Agents

### Working In This Directory

- 모든 문서는 프로덕션 품질 달성을 위한 가이드
- Performance는 프로덕션 배포 전 최적화 체크
- Security는 민감 데이터 처리 및 네트워크 통신 시 필수 참고
- Accessibility는 모든 위젯 구현 시 고려 필요
- Testing은 모든 기능 개발 시 함께 참고
- Observability는 로깅, 모니터링, 에러 추적을 통합하여 다룸

### Learning Path

1. `../core/ErrorHandling.md` → 에러 처리 기초 (core로 이동)
2. `Observability.md` → 로깅, 모니터링, 에러 추적 전략
3. `../fundamentals/DesignSystem.md` → UI 테마 시스템 (fundamentals로 이동)
4. `Accessibility.md` → 모든 사용자가 사용 가능한 UI 설계
5. `Performance.md` → 성능 최적화
6. `DevToolsProfiling.md` → DevTools 프로파일링
7. `Security.md` → 보안 강화
8. `AppLifecycle.md` → 생명주기 관리
9. `Testing.md` → 테스트 작성
10. `Isolates.md` → 백그라운드 처리 및 병렬화

### Common Patterns

```dart
// Failure Sealed Class (core/ErrorHandling.md 참조)
@freezed
sealed class Failure with _$Failure {
  const factory Failure.network({String? message}) = NetworkFailure;
  const factory Failure.server({required int code, String? message}) = ServerFailure;
  const factory Failure.auth({String? message}) = AuthFailure;
  const factory Failure.unknown({String? message}) = UnknownFailure;
}

// Accessible Semantics
Semantics(
  button: true,
  enabled: true,
  onTap: onPressed,
  label: 'Save',
  hint: 'Save all changes',
  child: ElevatedButton(onPressed: onPressed, child: const Text('Save')),
)

// Color Contrast Check
assert(
  AccessibilityColorUtils.meetsAAContrast(foreground, background),
  'Color contrast ratio does not meet WCAG AA standards',
);

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

// Isolate Background Processing
final result = await compute(heavyComputation, largeData);
```

## Dependencies

### Internal

- `../core/Freezed.md` - Failure, State 정의
- `../core/Fpdart.md` - Either 에러 처리
- `../core/ErrorHandling.md` - Failure 클래스 정의 (core로 이동)
- `../networking/` - API 에러 처리

### External

- `flutter_test` - Testing Framework
- `bloc_test` - Bloc Testing
- `mockito` - Mocking
- `logger` - 구조화된 로깅
- `firebase_crashlytics` - 크래시 리포팅
- `sentry_flutter` - 에러 모니터링
- `flutter_secure_storage` - 보안 저장소
- `local_auth` - 생체 인증
- `cached_network_image` - 이미지 캐싱

<!-- MANUAL: -->
