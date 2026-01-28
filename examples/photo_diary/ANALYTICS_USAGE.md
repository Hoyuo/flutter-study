# Analytics & Crashlytics 사용 가이드

Photo Diary 앱의 Analytics 및 Crashlytics 서비스 사용 방법을 설명합니다.

## 설치 완료 항목

### 1. Core 패키지 서비스
- ✅ `AnalyticsService` 인터페이스
- ✅ `FirebaseAnalyticsServiceImpl` 구현체
- ✅ `CrashlyticsService` 인터페이스
- ✅ `FirebaseCrashlyticsServiceImpl` 구현체

### 2. App 레벨 통합
- ✅ `AnalyticsRouteObserver` - GoRouter용 화면 조회 추적
- ✅ `main.dart` - Crashlytics 초기화

### 3. 의존성
- ✅ `firebase_analytics: ^11.6.0`
- ✅ `firebase_crashlytics: ^4.3.10`

---

## 1. Router에 Analytics Observer 추가

`lib/core/router/app_router.dart` 파일을 수정하여 Analytics Observer를 추가합니다:

```dart
import 'package:core/services/services.dart';
import '../router/analytics_route_observer.dart';

@singleton
class AppRouter {
  final AuthBloc _authBloc;
  final AnalyticsService _analyticsService; // 추가

  late final GoRouter router;

  AppRouter(
    this._authBloc,
    this._analyticsService, // 추가
  ) {
    router = GoRouter(
      initialLocation: '/splash',
      debugLogDiagnostics: true,

      // Analytics Observer 추가
      observers: [
        AnalyticsRouteObserver(_analyticsService),
      ],

      redirect: (context, state) {
        // ... 기존 코드
      },
      routes: [
        // ... 기존 라우트
      ],
    );
  }
}
```

이제 화면 전환이 자동으로 Analytics에 기록됩니다.

---

## 2. 이벤트 로깅 사용

### 기본 이벤트 로깅

```dart
import 'package:core/services/services.dart';
import 'package:injectable/injectable.dart';

@injectable
class DiaryRepository {
  final AnalyticsService _analyticsService;

  DiaryRepository(this._analyticsService);

  Future<void> createDiary(DiaryEntry entry) async {
    // 일기 생성 로직

    // Analytics 이벤트 로깅
    await _analyticsService.logEvent(
      type: AnalyticsEventType.createDiary,
      parameters: {
        'has_photo': entry.photoUrl != null,
        'weather': entry.weather,
        'mood': entry.mood,
      },
    );
  }
}
```

### 사용자 속성 설정

```dart
// 사용자 로그인 시
await _analyticsService.setUserId(user.id);
await _analyticsService.setUserProperty(
  name: 'user_tier',
  value: 'premium',
);

// 로그아웃 시
await _analyticsService.setUserId(null);
```

### 설정 변경 추적

```dart
// 테마 변경
await _analyticsService.logEvent(
  type: AnalyticsEventType.changeTheme,
  parameters: {'theme': isDark ? 'dark' : 'light'},
);

// 언어 변경
await _analyticsService.logEvent(
  type: AnalyticsEventType.changeLanguage,
  parameters: {'language': locale.languageCode},
);

// 생체 인증 토글
await _analyticsService.logEvent(
  type: AnalyticsEventType.toggleBiometric,
  parameters: {'enabled': isEnabled},
);
```

---

## 3. Crashlytics 사용

### 비치명적 에러 기록

```dart
import 'package:core/services/services.dart';

@injectable
class DiaryRepository {
  final CrashlyticsService _crashlyticsService;

  DiaryRepository(this._crashlyticsService);

  Future<void> loadDiary(String id) async {
    try {
      // 일기 로드 로직
    } catch (error, stackTrace) {
      // Crashlytics에 에러 기록
      await _crashlyticsService.recordError(
        error,
        stackTrace,
        reason: 'Failed to load diary entry',
        fatal: false,
      );

      // 사용자에게 에러 표시
      rethrow;
    }
  }
}
```

### 로그 컨텍스트 추가

```dart
// 사용자 식별자 설정
await _crashlyticsService.setUserIdentifier(userId);

// 커스텀 키 설정 (디버깅용 컨텍스트)
await _crashlyticsService.setCustomKey('last_screen', 'diary_detail');
await _crashlyticsService.setCustomKey('diary_count', diaryCount);

// 로그 메시지 추가
await _crashlyticsService.log('User started editing diary');
```

### Bloc에서 에러 처리

```dart
class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  final CrashlyticsService _crashlyticsService;

  DiaryBloc(this._crashlyticsService) : super(DiaryInitial()) {
    on<LoadDiary>(_onLoadDiary);
  }

  Future<void> _onLoadDiary(
    LoadDiary event,
    Emitter<DiaryState> emit,
  ) async {
    emit(DiaryLoading());

    try {
      final diary = await _repository.getDiary(event.id);
      emit(DiaryLoaded(diary));
    } catch (error, stackTrace) {
      // Crashlytics에 기록
      await _crashlyticsService.recordError(
        error,
        stackTrace,
        reason: 'Failed to load diary in bloc',
      );

      emit(DiaryError('일기를 불러오는데 실패했습니다'));
    }
  }
}
```

---

## 4. 사용 가능한 이벤트 타입

```dart
enum AnalyticsEventType {
  // 인증
  login,
  signUp,
  logout,

  // 일기
  createDiary,
  viewDiary,
  editDiary,
  deleteDiary,

  // 검색
  search,

  // 설정
  changeTheme,
  changeLanguage,
  toggleBiometric,

  // 기타
  screenView,
  appOpen,
  share,
}
```

---

## 5. Best Practices

### Analytics

1. **개인정보 보호**: 사용자 개인정보를 파라미터에 포함시키지 않습니다
2. **의미있는 이벤트**: 비즈니스 가치가 있는 이벤트만 로깅합니다
3. **파라미터 일관성**: 같은 이벤트는 항상 같은 파라미터 구조를 사용합니다

```dart
// ✅ Good
await _analyticsService.logEvent(
  type: AnalyticsEventType.createDiary,
  parameters: {
    'has_photo': true,
    'weather': 'sunny',
    'content_length': 250,
  },
);

// ❌ Bad - 개인정보 포함
await _analyticsService.logEvent(
  type: AnalyticsEventType.createDiary,
  parameters: {
    'user_email': 'user@example.com', // 개인정보!
    'diary_content': 'Today I...', // 민감한 내용!
  },
);
```

### Crashlytics

1. **적절한 컨텍스트**: 에러 발생 시점의 상태를 커스텀 키로 기록
2. **로그 활용**: 에러 발생 전 사용자 행동을 로그로 남김
3. **Fatal 플래그**: 실제 앱이 종료될 수 있는 치명적 에러만 `fatal: true` 사용

```dart
// ✅ Good - 적절한 컨텍스트
await _crashlyticsService.setCustomKey('screen', 'diary_edit');
await _crashlyticsService.setCustomKey('diary_id', diaryId);
await _crashlyticsService.log('User tapped save button');

try {
  await saveDiary();
} catch (error, stackTrace) {
  await _crashlyticsService.recordError(
    error,
    stackTrace,
    reason: 'Failed to save diary',
    fatal: false,
  );
}
```

---

## 6. 테스트 환경 설정

개발 중에는 Crashlytics를 비활성화할 수 있습니다:

```dart
// main.dart
void main() async {
  // ...

  // 개발 환경에서는 Crashlytics 비활성화 (선택사항)
  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }

  // ...
}
```

---

## 7. Firebase Console에서 확인

### Analytics
1. Firebase Console → Analytics → Events
2. 실시간 이벤트 모니터링
3. 사용자 속성별 분석

### Crashlytics
1. Firebase Console → Crashlytics
2. 크래시 및 비치명적 에러 목록
3. 영향받은 사용자 수 확인
4. 스택 트레이스 및 로그 확인

---

## 문제 해결

### "Missing google-services.json" 에러
- `android/app/` 폴더에 `google-services.json` 파일이 있는지 확인
- Firebase Console에서 다운로드 가능

### Analytics 이벤트가 보이지 않음
- 이벤트가 Firebase에 표시되기까지 최대 24시간 소요
- DebugView를 활성화하여 실시간으로 확인 가능

### Crashlytics가 작동하지 않음
- Release 모드에서 테스트 (`flutter run --release`)
- iOS: dSYM 파일 업로드 필요
- Android: ProGuard 설정 확인
