<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-01-27 | Updated: 2026-01-27 -->

# Patterns

## Purpose

앱 개발에서 자주 사용되는 필수 패턴과 구현 가이드 문서 모음입니다. 분석/추적, 이미지 처리, 페이지네이션, 폼 유효성 검사 등 실무에서 반복적으로 필요한 패턴을 설명합니다.

## Key Files

| File | Description |
|------|-------------|
| `Analytics.md` | Firebase Analytics/Crashlytics, 이벤트 추적, 사용자 속성, 크래시 리포팅 |
| `ImageHandling.md` | 이미지 캐싱, 갤러리/카메라 선택, 크롭, 압축, 서버 업로드 |
| `Pagination.md` | 무한 스크롤, 커서 기반 페이지네이션, PaginationState 설계 |
| `FormValidation.md` | 폼 유효성 검사 패턴, ValidatorBuilder, Form Bloc 통합, 실시간 검증 |
| `OfflineSupport.md` | 오프라인 우선 아키텍처, Drift ORM, sync queue, conflict resolution |
| `InAppPurchase.md` | 인앱 결제, native in_app_purchase, RevenueCat, 서버 검증 |
| `Animation.md` | 암시적/명시적 애니메이션, Lottie, Hero, 접근성 고려 |
| `AdvancedPatterns.md` | DDD, Hexagonal Architecture, Saga 패턴, Specification 패턴, SOLID 심화 |
| `CustomPainting.md` | Canvas API, CustomPainter, 커스텀 그래픽, Path 드로잉, 성능 최적화 |

## For AI Agents

### Working In This Directory

- 모든 패턴은 Bloc과 통합되어 사용
- 재사용 가능한 컴포넌트 설계 지향
- 성능 최적화 고려 (이미지 압축, 페이지네이션 등)

### Learning Path

1. `FormValidation.md` → 폼 처리 기초
2. `Pagination.md` → 리스트 처리
3. `ImageHandling.md` → 미디어 처리
4. `Analytics.md` → 분석/추적
5. `Animation.md` → 애니메이션 패턴
6. `OfflineSupport.md` → 오프라인 아키텍처
7. `InAppPurchase.md` → 인앱 결제

### Common Patterns

```dart
// Pagination State
@freezed
class PaginationState<T> with _$PaginationState<T> {
  const factory PaginationState({
    @Default([]) List<T> items,
    @Default(false) bool isLoading,
    @Default(false) bool hasReachedEnd,
    String? nextCursor,
    Failure? error,
  }) = _PaginationState<T>;
}

// Form Validation
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return '이메일을 입력하세요';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return '올바른 이메일 형식이 아닙니다';
    }
    return null;
  }
}
```

## Dependencies

### Internal

- `../core/Bloc.md` - Bloc 패턴 통합
- `../core/Freezed.md` - State 정의
- `../networking/` - 서버 통신 (업로드, 페이지네이션 API)

### External

- `firebase_analytics` - Analytics
- `firebase_crashlytics` - Crash Reporting
- `cached_network_image` - Image Caching
- `image_picker` - Gallery/Camera
- `image_cropper` - Image Cropping
- `flutter_image_compress` - Image Compression

<!-- MANUAL: -->
