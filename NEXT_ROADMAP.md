# Flutter 실전/심화 학습 로드맵

## 📋 개요

현재까지 **41개의 문서**를 통해 Flutter 개발의 핵심 개념과 실무 패턴을 학습했습니다. 이 로드맵은 다음 단계에서 학습할 추천 주제들을 단계별로 제시합니다.

### 현재 학습 상태

| 카테고리 | 완료 문서 수 | 상태 |
|---------|-----------|------|
| Core (핵심) | 8개 | ✅ 완료 |
| Infrastructure (인프라) | 6개 | ✅ 완료 |
| Networking (네트워킹) | 2개 | ✅ 완료 |
| Features (기능) | 4개 | ✅ 완료 |
| Patterns (패턴) | 8개 | ✅ 완료 |
| System (시스템) | 13개 | ✅ 완료 |
| **합계** | **41개** | ✅ 기초 완성 |

### 다음 단계에서 추가될 주제

- **Phase 1 (필수):** 5개 주제 → 총 46개
- **Phase 2 (확장):** 4개 주제 → 총 50개
- **Phase 3 (심화):** 4개 주제 → 총 54개

---

## Phase 1: 실전 필수 (우선순위: 높음)

현 시점에서 실무 프로젝트에 **즉시 적용 가능**한 주제들입니다. Bloc 외 상태관리 옵션, 실시간 통신, 서버 통합이 중심입니다.

### 1.1 Riverpod (상태 관리)

| 항목 | 내용 |
|------|------|
| **파일 경로** | `core/Riverpod.md` |
| **난이도** | ★★ |
| **학습 시간** | 6-8시간 |
| **선행 학습** | Architecture, AdvancedStateManagement |

**핵심 패키지:**
- `riverpod`
- `flutter_riverpod`
- `hooks_riverpod`
- `riverpod_generator`

**주요 학습 내용:**
- [ ] Riverpod의 철학과 Bloc과의 비교
- [ ] Provider, StateNotifier, StateNotifierProvider 개념
- [ ] 의존성 주입과 스코핑 (Scoping)
- [ ] Bloc에서 Riverpod로 마이그레이션 전략
- [ ] Code generation (`@riverpod` annotation)
- [ ] AsyncValue를 활용한 비동기 처리

**실전 예시:**
```
- 사용자 인증 상태를 Riverpod으로 관리
- API 데이터 페칭 및 캐싱
- 복잡한 비동기 플로우 간단하게 표현
```

---

### 1.2 WebSocket & 실시간 통신

| 항목 | 내용 |
|------|------|
| **파일 경로** | `networking/WebSocket.md` |
| **난이도** | ★★ |
| **학습 시간** | 8-10시간 |
| **선행 학습** | Networking_Dio, Networking_Retrofit |

**핵심 패키지:**
- `web_socket_channel`
- `socket_io_client`
- `phoenix_channel`
- `fpdart` (함수형 에러 처리)

**주요 학습 내용:**
- [ ] WebSocket 프로토콜 기초
- [ ] web_socket_channel으로 연결 관리
- [ ] Socket.IO 패턴 구현
- [ ] 재연결 및 하트비트 메커니즘
- [ ] 메시지 큐잉과 오프라인 지원
- [ ] Stream과 StreamController를 활용한 실시간 처리
- [ ] 성능 최적화 및 메모리 누수 방지

**실전 예시:**
```
- 실시간 채팅 애플리케이션
- 실시간 알림 시스템
- 라이브 데이터 스트림 (주식, 스포츠)
- 멀티플레이어 게임 동기화
```

---

### 1.3 Firebase 통합

| 항목 | 내용 |
|------|------|
| **파일 경로** | `infrastructure/Firebase.md` |
| **난이도** | ★★ |
| **학습 시간** | 10-12시간 |
| **선행 학습** | DI, Environment, Security |

**핵심 패키지:**
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `firebase_messaging`
- `firebase_crashlytics`
- `firebase_analytics`
- `firebase_functions`

**주요 학습 내용:**
- [ ] Firebase 프로젝트 설정 및 초기화
- [ ] Authentication (이메일, Google, Apple, 소셜 로그인)
- [ ] Firestore 데이터베이스 (실시간 DB, 쿼리)
- [ ] Cloud Storage (파일 업로드/다운로드)
- [ ] Cloud Functions와의 통신
- [ ] Push Notification 고급 설정
- [ ] Crashlytics를 통한 에러 모니터링
- [ ] Analytics 통합 및 추적
- [ ] 보안 규칙 (Security Rules) 설정

**실전 예시:**
```
- Firebase 인증으로 사용자 관리
- Firestore로 실시간 데이터 동기화
- Cloud Storage에 사용자 프로필 이미지 저장
- Cloud Functions로 서버 로직 구현
```

---

## Phase 2: 기능 확장 (우선순위: 중간)

더욱 다양한 사용자 경험을 제공하기 위한 고급 기능들입니다. Phase 1 완료 후 순차적으로 학습하세요.

### 2.1 Deep Linking & 동적 라우팅

| 항목 | 내용 |
|------|------|
| **파일 경로** | `features/DeepLinking.md` |
| **난이도** | ★★ |
| **학습 시간** | 7-9시간 |
| **선행 학습** | Navigation |

**핵심 패키지:**
- `go_router` (2.0+)
- `app_links`
- `uni_links`
- `firebase_dynamic_links`

**주요 학습 내용:**
- [ ] Universal Links (iOS) vs App Links (Android) 차이점
- [ ] Deep link 처리 플로우
- [ ] go_router의 Deep linking 지원
- [ ] Dynamic Links로 동적 라우팅
- [ ] 앱 설치 유도 및 리디렉션
- [ ] 쿠폰, 초대 링크, 구인 광고 등 활용 사례

**실전 예시:**
```
- 푸시 알림 클릭 → 특정 화면 열기
- 웹 링크 공유 → 앱에서 열기
- 초대 링크로 친구 추가
- 이메일 링크로 계정 복구
```

---

### 2.2 지도 & 위치 서비스

| 항목 | 내용 |
|------|------|
| **파일 경로** | `features/MapsGeolocation.md` |
| **난이도** | ★★★ |
| **학습 시간** | 10-12시간 |
| **선행 학습** | Permission, PlatformIntegration |

**핵심 패키지:**
- `google_maps_flutter`
- `geolocator`
- `geohash`
- `latlong2`
- `location`

**주요 학습 내용:**
- [ ] Google Maps 통합 및 API 설정
- [ ] 지도 마커, 폴리곤, 폴리라인 그리기
- [ ] 사용자 위치 추적
- [ ] Geofencing (지역 기반 알림)
- [ ] 경로 탐색 및 거리 계산
- [ ] 지도 카메라 애니메이션
- [ ] 플랫폼별 차이점 처리

**실전 예시:**
```
- 배달/택시 앱 (실시간 위치 추적)
- 가게 찾기 앱 (근처 가게 표시)
- 산책 기록 앱 (경로 시각화)
- 위치 기반 마케팅 (Geofencing)
```

---

### 2.3 카메라 & 미디어 처리

| 항목 | 내용 |
|------|------|
| **파일 경로** | `features/CameraMedia.md` |
| **난이도** | ★★ |
| **학습 시간** | 9-11시간 |
| **선행 학습** | Permission, PlatformIntegration |

**핵심 패키지:**
- `camera`
- `image_picker`
- `video_player`
- `ffmpeg_kit_flutter`
- `image` (이미지 처리)
- `compressor` (압축)

**주요 학습 내용:**
- [ ] 카메라 스트림 접근 및 제어
- [ ] QR 코드 스캔
- [ ] 갤러리에서 이미지/비디오 선택
- [ ] 비디오 촬영 및 재생
- [ ] FFmpeg를 활용한 미디어 처리
- [ ] 이미지 필터 및 효과 적용
- [ ] 미디어 압축 최적화

**실전 예시:**
```
- SNS 앱 (이미지 촬영/필터)
- 신분증 촬영 앱 (카메라 최적화)
- 바코드 스캐너
- 동영상 편집 앱
```

---

### 2.4 Custom Painting & 그래픽

| 항목 | 내용 |
|------|------|
| **파일 경로** | `patterns/CustomPainting.md` |
| **난이도** | ★★★ |
| **학습 시간** | 9-11시간 |
| **선행 학습** | Animation, Performance |

**핵심 패키지:**
- `flutter` (Canvas, CustomPainter)
- `vector_math`
- `palette_generator`

**주요 학습 내용:**
- [ ] CustomPainter 기초
- [ ] Canvas API (drawRect, drawCircle, drawPath 등)
- [ ] Path와 경로 그리기
- [ ] 커스텀 차트 및 그래프 구현
- [ ] 애니메이션과의 결합
- [ ] 성능 최적화 (shouldRepaint)
- [ ] 터치 감지와 상호작용

**실전 예시:**
```
- 커스텀 차트 라이브러리
- 손글씨 입력 (메모, 서명)
- 실시간 그래프 (주식, 센서)
- 게임 엔진 기초
```

---

## Phase 3: 고급 심화 (우선순위: 낮음, Senior 레벨)

복잡한 아키텍처, 크로스 플랫폼 지원, 고성능 처리가 필요한 주제들입니다. 실무에서 필요할 때 학습하세요.

### 3.1 Isolate & 백그라운드 처리

| 항목 | 내용 |
|------|------|
| **파일 경로** | `core/Isolates.md` |
| **난이도** | ★★★ |
| **학습 시간** | 8-10시간 |
| **선행 학습** | AppLifecycle, Performance |

**핵심 패키지:**
- `dart:isolate`
- `compute()`
- `workmanager`
- `android_alarm_manager_plus`

**주요 학습 내용:**
- [ ] Isolate 개념 및 Dart의 동시성 모델
- [ ] compute() 함수로 백그라운드 작업
- [ ] Isolate 간 통신 (SendPort, ReceivePort)
- [ ] WorkManager로 주기적 작업
- [ ] 백그라운드 서비스 구현
- [ ] 성능 모니터링 및 최적화
- [ ] 플랫폼 채널을 통한 네이티브 호출

**실전 예시:**
```
- 대용량 데이터 처리 (UI 블로킹 방지)
- 주기적인 동기화 (예: 1시간마다 데이터 갱신)
- 백그라운드 파일 다운로드
- 센서 데이터 수집
```

---

### 3.2 Flutter Web & 데스크톱 확장

| 항목 | 내용 |
|------|------|
| **파일 경로** | `infrastructure/FlutterMultiPlatform.md` |
| **난이도** | ★★★ |
| **학습 시간** | 10-12시간 |
| **선행 학습** | PlatformIntegration, CICD (심화) |

**핵심 패키지:**
- `flutter_web`
- `desktop_window`
- `window_size`
- `url_launcher`
- `package_info_plus`

**주요 학습 내용:**
- [ ] Flutter Web 프로젝트 생성 및 배포
- [ ] Windows, macOS 데스크톱 앱 개발
- [ ] 조건부 import (Conditional Imports)
- [ ] 플랫폼별 UI 차별화
- [ ] 웹 특화 기능 (LocalStorage, IndexedDB)
- [ ] SEO 최적화 (Web)
- [ ] 데스크톱 특화 패턴 (메뉴, 다중 윈도우)

**실전 예시:**
```
- 모바일 + 웹 + 데스크톱 동시 지원
- SPA (Single Page Application) 구현
- Electron 대체 (Flutter Desktop)
- 크로스플랫폼 데이터 동기화
```

---

### 3.3 패키지 개발 & Pub.dev 배포

| 항목 | 내용 |
|------|------|
| **파일 경로** | `infrastructure/PackageDevelopment.md` |
| **난이도** | ★★ |
| **학습 시간** | 6-8시간 |
| **선행 학습** | ModularArchitecture, CICD (심화) |

**핵심 개념:**
- Pure Dart Package
- Flutter Plugin
- Federated Plugin Architecture

**주요 학습 내용:**
- [ ] 패키지 구조 및 pubspec.yaml 설정
- [ ] Dart 패키지 만들기 (알고리즘, 유틸)
- [ ] Flutter Plugin 만들기 (플랫폼 채널)
- [ ] Federated Plugin으로 플랫폼 지원 확장
- [ ] 문서작성 및 Example 구성
- [ ] 테스트 커버리지 (Test, Integration Test)
- [ ] Pub.dev에 배포 및 관리
- [ ] Semantic Versioning

**실전 예시:**
```
- 자신의 유틸리티 라이브러리 공개
- 회사 자체 디자인 시스템 패키지
- 플랫폼 기능 래퍼 (Native Bridge)
- 오픈소스 기여
```

---

### 3.4 GraphQL 통합

| 항목 | 내용 |
|------|------|
| **파일 경로** | `networking/GraphQL.md` |
| **난이도** | ★★★ |
| **학습 시간** | 9-11시간 |
| **선행 학습** | Networking_Dio, AdvancedPatterns |

**핵심 패키지:**
- `graphql_flutter`
- `ferry`
- `built_value` (또는 `freezed`)
- `gql` (GraphQL 코어)

**주요 학습 내용:**
- [ ] GraphQL 기초 개념
- [ ] graphql_flutter의 GraphQL Client 설정
- [ ] Query, Mutation, Subscription
- [ ] Code generation으로 타입 안전성 확보
- [ ] 캐싱 전략 및 최적화
- [ ] Error handling 및 Retry 로직
- [ ] Real-time 데이터 (Subscription)
- [ ] Fragment와 복잡한 쿼리

**실전 예시:**
```
- Modern API 통합 (Shopify, GitHub, Twitter)
- 실시간 데이터 구독 (Subscription)
- 타입 안전한 API 호출
- 캐싱으로 성능 최적화
```

---

## 🎯 추천 학습 순서

### 즉시 시작 추천 (다음 1-2개월)

```
1. Riverpod (상태관리의 다른 관점)
   ↓
2. WebSocket & 실시간 통신 (실무 필수)
   ↓
3. Firebase 통합 (대부분의 프로젝트에서 필요)
```

### 프로젝트에 맞게 선택 (2-3개월)

| 프로젝트 타입 | 추천 순서 |
|-----------|---------|
| **SNS/채팅 앱** | WebSocket → Firebase → Deep Linking → Camera & Media |
| **O2O (배달/택시)** | Firebase → Maps & Geolocation → WebSocket |
| **콘텐츠 앱** | Deep Linking → Camera & Media → Custom Painting |
| **크로스플랫폼 서비스** | Riverpod → Firebase → Web & Desktop |
| **패키지/라이브러리 개발** | Package Development → GraphQL (if API) |

### 심화 학습 (선택사항, 필요시)

```
4-5개월: Isolate & 백그라운드 처리 (성능 최적화 필요 시)
5-6개월: Web & Desktop 확장 (멀티플랫폼 전략)
6개월+: GraphQL, Package Development (프로젝트 특성에 따라)
```

---

## 📁 디렉토리 구조 업데이트

현재 디렉토리 구조에 새로운 주제들을 추가하면:

```
flutter-study/
├── core/
│   ├── Architecture.md
│   ├── Bloc.md
│   ├── BlocUiEffect.md
│   ├── Freezed.md
│   ├── Fpdart.md
│   ├── ModularArchitecture.md
│   ├── AdvancedStateManagement.md
│   ├── PlatformIntegration.md
│   └── Riverpod.md                    ✨ NEW
│   └── Isolates.md                    ✨ NEW
│
├── infrastructure/
│   ├── DI.md
│   ├── Environment.md
│   ├── LocalStorage.md
│   ├── CICD.md
│   ├── StoreSubmission.md
│   ├── Firebase.md                    ✨ NEW
│   ├── FlutterMultiPlatform.md        ✨ NEW
│   └── PackageDevelopment.md          ✨ NEW
│
├── networking/
│   ├── Networking_Dio.md
│   ├── Networking_Retrofit.md
│   ├── WebSocket.md                   ✨ NEW
│   └── GraphQL.md                     ✨ NEW
│
├── features/
│   ├── Navigation.md
│   ├── Localization.md
│   ├── Permission.md
│   ├── PushNotification.md
│   ├── DeepLinking.md                 ✨ NEW
│   └── MapsGeolocation.md             ✨ NEW
│   └── CameraMedia.md                 ✨ NEW
│
├── patterns/
│   ├── Analytics.md
│   ├── ImageHandling.md
│   ├── Pagination.md
│   ├── FormValidation.md
│   ├── InAppPurchase.md
│   ├── Animation.md
│   ├── OfflineSupport.md
│   ├── AdvancedPatterns.md
│   └── CustomPainting.md              ✨ NEW
│
├── system/
│   ├── ErrorHandling.md
│   ├── AppLifecycle.md
│   ├── Testing.md
│   ├── Performance.md
│   ├── Security.md
│   ├── Accessibility.md
│   ├── Logging.md
│   ├── Monitoring.md
│   ├── Security.md (통합)
│   └── ProductionOperations.md
│
├── README.md
├── NEXT_ROADMAP.md                    ✨ THIS FILE
└── ...
```

---

## 📊 학습 진도 계획표

| Phase | 주제 수 | 예상 기간 | 누적 문서 | 상태 |
|-------|-------|---------|---------|------|
| **완료** | 41개 | 3-4개월 | 41개 | ✅ |
| **Phase 1** | 3개 | 1-2개월 | 44개 | 🔵 다음 |
| **Phase 2** | 4개 | 2-3개월 | 48개 | 🟡 중기 |
| **Phase 3** | 4개 | 선택사항 | 52개 | ⚪ 심화 |

### 예상 학습 시간 (시간/명)

| Phase | 총 시간 | 주당 학습 (15h) | 예상 기간 |
|-------|-------|-------------|---------|
| Phase 1 | 24-30h | 2주 | 1.5-2개월 |
| Phase 2 | 35-43h | 2-3주 | 2.5-3개월 |
| Phase 3 | 33-41h | 2-3주 | 2.5-3개월 |
| **합계** | 92-114h | - | **6-8개월** |

---

## 💡 단계별 학습 팁

### Phase 1 학습 시 주의사항

1. **Riverpod**: 기존 Bloc 지식을 활용하되, Provider 패턴의 차이를 명확히 이해
2. **WebSocket**: 연결 끊김, 재연결, 타임아웃 등 예외 상황을 반드시 다룰 것
3. **Firebase**: 보안 규칙(Security Rules) 설정에 시간을 충분히 할당

### Phase 2 학습 시 주의사항

1. **Deep Linking**: 앱 설치 상태에 따른 다양한 시나리오 테스트
2. **Maps**: 플랫폼별 API 키 설정 및 권한 처리 세심히
3. **Camera**: 디바이스별 성능 차이 및 메모리 누수 주의
4. **Custom Painting**: 애니메이션 성능 최적화 필수 (shouldRepaint)

### Phase 3 학습 시 주의사항

1. **Isolate**: 네트워크 요청, 파일 I/O는 Isolate에서 수행 권장
2. **Web & Desktop**: 각 플랫폼의 제약사항과 특화 기능 학습 필수
3. **Package Development**: 충분한 테스트와 문서화가 배포 전 필수
4. **GraphQL**: REST vs GraphQL 트레이드오프 이해 필수

---

## 🔗 관련 자료 및 참고

### 공식 문서
- [Riverpod Docs](https://riverpod.dev)
- [Firebase for Flutter](https://firebase.flutter.dev)
- [go_router Documentation](https://pub.dev/packages/go_router)
- [Google Maps for Flutter](https://pub.dev/packages/google_maps_flutter)

### 커뮤니티
- [Flutter Official](https://flutter.dev)
- [Pub.dev](https://pub.dev)
- [Stack Overflow - flutter 태그](https://stackoverflow.com/questions/tagged/flutter)

---

## 📝 이전 문서와의 관계

### 기존 학습을 기반으로

| 새 주제 | 의존하는 기존 문서 | 관계 |
|--------|----------------|------|
| **Riverpod** | Architecture, AdvancedStateManagement | Bloc의 대안 패턴 |
| **WebSocket** | Networking_Dio, Networking_Retrofit | 네트워킹 심화 |
| **Firebase** | DI, Environment, Security | 백엔드 통합 |
| **Deep Linking** | Navigation | 라우팅 심화 |
| **Maps** | Permission, PlatformIntegration | 기능 확장 |
| **Camera** | Permission, ImageHandling | 미디어 처리 심화 |
| **Custom Painting** | Animation, Performance | 그래픽 심화 |
| **Isolate** | AppLifecycle, Performance | 성능 최적화 심화 |
| **Web & Desktop** | PlatformIntegration, CICD (심화) | 크로스플랫폼 확장 |
| **Package Dev** | ModularArchitecture, CICD (심화) | 오픈소스 기여 |
| **GraphQL** | Networking_Dio, AdvancedPatterns | API 방식 변경 |

---

## 🎓 마지막 체크리스트

Phase 1 시작 전 확인사항:

- [ ] 기존 41개 문서의 핵심 내용 복습 완료
- [ ] Bloc 패턴에 대한 확실한 이해
- [ ] 기본 네트워킹 (HTTP) 지식 확보
- [ ] State management의 여러 패턴 비교 이해

---

**마지막 업데이트:** 2026년 2월 6일
**총 추천 주제:** 13개 (Phase 1: 3, Phase 2: 4, Phase 3: 4, 예비: 2)
**예상 완성 시점:** 2026년 8월 - 10월

---

> 💬 **피드백 및 조정**
>
> 이 로드맵은 현재의 학습 진도와 업계 트렌드를 기반으로 작성되었습니다.
> 프로젝트 특성이나 팀의 필요에 따라 주제 순서나 우선순위를 조정하세요.
> 완료한 각 문서에 대해 실제 프로젝트에 적용하는 경험을 병행하면 더욱 효과적입니다.
