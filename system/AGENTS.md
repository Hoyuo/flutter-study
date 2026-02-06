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
| `Performance.md` | 렌더링 최적화, 메모리 관리, Isolate 활용, DevTools 프로파일링, Bloc 성능 |
| `Security.md` | 데이터 암호화, Certificate Pinning, 코드 난독화, 인증 보안, 플랫폼별 설정 |
| `Accessibility.md` | Semantics 설정, 스크린 리더 지원, 색상 대비, 모터 접근성, 테스트 |
| `Logging.md` | 구조화된 로깅, BlocObserver, 네트워크 로깅, Crashlytics/Sentry 연동 |
| `Monitoring.md` | 앱 모니터링, Crashlytics, Sentry, Firebase Performance, 인시던트 대응 |
| `AdvancedPerformance.md` | Custom RenderObject, Impeller 최적화, Fragment Shader, Memory Profiling |
| `AdvancedTesting.md` | Property-based Testing, Golden Test, E2E Patrol, Visual Regression |
| `ProductionOperations.md` | SLO/SLI 모니터링, Crash-free Rate, Incident Management, A/B Testing |
| `AdvancedSecurity.md` | Code Obfuscation, RASP, mTLS, Certificate Transparency, Jailbreak Detection |

## For AI Agents

### Working In This Directory

- ErrorHandling은 전체 앱에서 참조되는 핵심 패턴
- Logging은 ErrorHandling과 함께 사용하여 에러 추적
- Performance는 프로덕션 배포 전 최적화 체크
- Security는 민감 데이터 처리 및 네트워크 통신 시 필수 참고
- Accessibility는 모든 위젯 구현 시 고려 필요
- Theming은 디자인 시스템과 연계 (색상 대비 WCAG 기준 확인)
- Testing은 모든 기능 개발 시 함께 참고

### Learning Path

1. `ErrorHandling.md` → 에러 처리 기초 (필수)
2. `Logging.md` → 로깅 전략 (에러 처리와 연계)
3. `Theming.md` → UI 테마 시스템
4. `Accessibility.md` → 모든 사용자가 사용 가능한 UI 설계
5. `Performance.md` → 성능 최적화
6. `Security.md` → 보안 강화
7. `AppLifecycle.md` → 생명주기 관리
8. `Testing.md` → 테스트 작성

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
- `mockito` - Mocking
- `logger` - 구조화된 로깅
- `firebase_crashlytics` - 크래시 리포팅
- `sentry_flutter` - 에러 모니터링
- `flutter_secure_storage` - 보안 저장소
- `local_auth` - 생체 인증
- `cached_network_image` - 이미지 캐싱

<!-- MANUAL: -->
