# Photo Diary - Flutter Clean Architecture 예시 앱

26개 Flutter 문서의 모든 패턴을 적용한 포토 다이어리 앱입니다.

## 📸 주요 기능

- **일기 CRUD**: 사진과 함께 일기 작성/조회/수정/삭제
- **사진 처리**: 카메라/갤러리에서 사진 선택, 압축, Firebase Storage 업로드
- **날씨 연동**: OpenWeatherMap API로 현재 날씨 자동 기록
- **검색/필터**: 키워드 검색, 태그 필터링
- **다국어 지원**: 한국어/일본어/중국어 번체 (KR/JP/TW)
- **다크 모드**: Material 3 테마 시스템
- **생체 인증**: Face ID / 지문 인식으로 앱 잠금
- **푸시 알림**: 일기 작성 리마인더
- **분석**: Firebase Analytics + Crashlytics

## 🏗️ 아키텍처

### Clean Architecture + Bloc 패턴

```
┌─────────────────────────────────────────────┐
│           Presentation Layer                │
│  (Pages, Widgets, Blocs, BlocUiEffect)     │
├─────────────────────────────────────────────┤
│             Domain Layer                    │
│    (Entities, Repositories, UseCases)       │
├─────────────────────────────────────────────┤
│              Data Layer                     │
│ (Models, DataSources, RepositoryImpl)       │
└─────────────────────────────────────────────┘
```

### Dart Workspace 구조

```
photo_diary/
├── apps/
│   └── photo_diary/          # 메인 앱
├── packages/
│   ├── core/                 # 공유 코어 (에러, 테마, 유틸)
│   ├── auth/                 # 인증 기능
│   ├── diary/                # 일기 기능
│   ├── weather/              # 날씨 기능
│   └── settings/             # 설정 기능
└── pubspec.yaml              # Workspace root
```

## 📚 적용된 문서 패턴

### Core (5개)
- ✅ Architecture.md - Clean Architecture 구조
- ✅ Bloc.md - 상태관리 (flutter_bloc)
- ✅ BlocUiEffect.md - 일회성 UI 효과
- ✅ Freezed.md - 불변 데이터 클래스
- ✅ Fpdart.md - Either<Failure, T> 에러 처리

### Infrastructure (3개)
- ✅ DI.md - GetIt + Injectable 의존성 주입
- ✅ Environment.md - 환경 변수 (.env.dev, .env.prod)
- ✅ LocalStorage.md - SharedPreferences, SecureStorage

### Networking (2개)
- ✅ Networking_Dio.md - Dio HTTP 클라이언트
- ✅ Networking_Retrofit.md - Retrofit API 정의

### Features (4개)
- ✅ Navigation.md - GoRouter 선언적 라우팅
- ✅ Localization.md - easy_localization (KR/JP/TW)
- ✅ Permission.md - permission_handler
- ✅ PushNotification.md - Firebase Messaging

### Patterns (4개)
- ✅ Analytics.md - Firebase Analytics
- ✅ ImageHandling.md - 이미지 선택/압축/업로드
- ✅ Pagination.md - 무한 스크롤
- ✅ FormValidation.md - 폼 검증

### System (8개)
- ✅ ErrorHandling.md - Failure sealed class
- ✅ Theming.md - Material 3 다크모드
- ✅ AppLifecycle.md - 앱 생명주기 관리
- ✅ Testing.md - Unit/Widget/Integration 테스트
- ✅ Performance.md - 이미지 캐싱, 최적화
- ✅ Security.md - 생체인증, SecureStorage
- ✅ Accessibility.md - Semantics, WCAG 준수
- ✅ Logging.md - AppLogger, BlocObserver

## 🚀 시작하기

### 1. 의존성 설치
```bash
flutter pub get
```

### 2. 코드 생성
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. 실행 방법 선택

#### Option A: Firebase Emulator 사용 (추천 - Firebase 프로젝트 필요 없음)

실제 Firebase 프로젝트 없이 로컬에서 앱을 테스트할 수 있습니다.

**1) Firebase CLI 설치**
```bash
npm install -g firebase-tools
```

**2) Emulator 시작**
```bash
cd examples/photo_diary
firebase emulators:start
```

Emulator UI: http://localhost:4000

**3) 앱 실행 (Emulator 모드)**
```bash
cd apps/photo_diary

# .env.emulator 파일을 .env.dev로 복사
cp .env.emulator .env.dev

flutter run
```

> **참고**: Android Emulator에서는 `10.0.2.2`가 호스트 머신의 localhost입니다.
> iOS Simulator에서는 `.env.emulator`의 `EMULATOR_HOST`를 `localhost`로 변경하세요.

#### Option B: 실제 Firebase 프로젝트 사용

**1) Firebase 설정 파일 추가**
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

**2) 환경 변수 설정**
```bash
cp .env.example .env.dev
# Firebase 설정값 입력
```

**3) 앱 실행**
```bash
flutter run
```

### Firebase Emulator 포트 정보

| 서비스 | 포트 |
|--------|------|
| Emulator UI | 4000 |
| Auth | 9099 |
| Firestore | 8080 |
| Storage | 9199 |

## 🧪 테스트

### Unit 테스트
```bash
flutter test
```

### Integration 테스트
```bash
flutter test integration_test
```

## 📦 주요 패키지

| 패키지 | 버전 | 용도 |
|--------|------|------|
| flutter_bloc | ^8.1.6 | 상태관리 |
| freezed | ^2.5.7 | 불변 데이터 |
| fpdart | ^1.1.0 | 함수형 프로그래밍 |
| get_it | ^8.0.2 | DI 컨테이너 |
| injectable | ^2.5.0 | DI 코드 생성 |
| go_router | ^14.6.2 | 라우팅 |
| dio | ^5.7.0 | HTTP 클라이언트 |
| retrofit | ^4.1.0 | REST API |
| firebase_core | ^3.8.1 | Firebase |
| easy_localization | ^3.0.7 | 다국어 |
| local_auth | ^2.3.0 | 생체인증 |

## 📱 지원 플랫폼

- ✅ Android (minSdk 23)
- ✅ iOS (12.0+)

## 📄 라이선스

MIT License
