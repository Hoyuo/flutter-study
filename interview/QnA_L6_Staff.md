# Flutter 면접 Q&A — L6 Staff/Principal

> **대상**: SWE L6 (Staff/Principal, 7년+ 경력)
> **포지션**: 모바일 엔지니어 + 시스템 설계
> **마지막 업데이트**: 2026-02-08 | **Flutter 3.38** | **Dart 3.10**
> **문항 수**: 28개

---

## 목차

1. [기술 전략 (6문항)](#1-기술-전략)
2. [대규모 시스템 설계 (8문항)](#2-대규모-시스템-설계)
3. [성능 & 안정성 (5문항)](#3-성능--안정성)
4. [조직 & 리더십 (6문항)](#4-조직--리더십)
5. [최신 기술 동향 (3문항)](#5-최신-기술-동향)

---

## 1. 기술 전략

### Q1. 신규 프로젝트에서 Flutter vs Native vs React Native 중 무엇을 선택할 것인가? 의사결정 프레임워크를 제시하라.

**핵심 키워드**: 기술 선택 의사결정, 조직 역량, TCO, 생태계 성숙도

**모범 답변**:

기술 선택은 4단계 프레임워크로 접근합니다.

**1단계: 비즈니스 제약 조건**
- Time-to-Market: 6개월 내 출시 → Flutter/RN 유리 (개발 속도 30-40% 향상)
- 플랫폼 커버리지: iOS+Android만? Web/Desktop 필요? → Flutter 단일 코드베이스
- 네이티브 의존성: AR/VR, HealthKit, 복잡한 센서 → Native 또는 하이브리드

**2단계: 조직 역량**
- 현재 팀 구성: iOS 3명, Android 2명 → 통합 vs 분리 팀 전략
- 채용 시장: Flutter 주니어 풍부, Native 시니어 부족 (2026년 기준)
- 5년 TCO: 2개 코드베이스(Native) vs 1개(Flutter) → 유지보수 비용 50% 절감

**3단계: 기술 리스크**
- Flutter: Impeller 성숙, Macros 도입 예정, Google 지원 강력
- RN: 신규 아키텍처 전환기, 커뮤니티 의존도 높음
- Native: 플랫폼 종속, 하지만 최고 성능 보장

**4단계: 출구 전략**
- Flutter→Native: 높은 비용 (전면 재작성)
- Native→Flutter: 점진적 마이그레이션 가능 (Add-to-App)
- 하이브리드 전략: 핵심 기능 Native, 나머지 Flutter

**평가 기준**:
- ✅ 좋은 답변: 정량적 데이터(TCO, 개발 속도), 출구 전략, 조직 영향 분석
- ❌ 나쁜 답변: "Flutter가 빠르고 좋음", 기술 스택만 비교

**꼬리 질문**: Flutter 선택 후 3년차에 성능 문제 발생 시 어떻게 대응할 것인가?

**참고 문서**: [L5 Architecture](./QnA_L5_Senior.md#q6), [Best Practices](../Best_Practices.md)

---

### Q2. 모노레포 vs 멀티레포 전략을 어떻게 결정할 것인가? 50+명 팀에서의 고려사항은?

**핵심 키워드**: 모노레포, Melos, 빌드 시스템, 팀 스케일링

**모범 답변**:

**모노레포 선택 기준** (Google, Uber 사례):
- 강한 결합: 공통 디자인 시스템, 공유 비즈니스 로직 (70%+ 코드 재사용)
- 원자적 변경: API 계약 변경 시 클라이언트 동시 업데이트 필요
- 도구 통합: Melos로 `melos bootstrap`, `melos run test:all` 한 번에 실행

**멀티레포 선택 기준**:
- 약한 결합: 독립 앱(B2C, B2B, 관리자), 릴리스 주기 다름
- 팀 자율성: 각 팀이 기술 스택, CI/CD 독립 운영
- 보안 격리: 민감한 금융 앱 vs 일반 커머스 앱

**50+명 팀 고려사항**:
- CI 병목: 모노레포면 incremental build (Bazel, Buck2) 필수
- 코드 소유권: CODEOWNERS 파일로 자동 리뷰어 지정
- 의존성 지옥: `dependency_overrides` 남발 방지 → 명확한 버전 정책
- 빌드 시간: 전체 빌드 30분+ → 캐시 전략, 선택적 테스트

**평가 기준**:
- ✅ 좋은 답변: 팀 크기별 전환점, CI 성능 데이터, 마이그레이션 전략
- ❌ 나쁜 답변: "모노레포가 트렌드", 실무 경험 없는 이론

**꼬리 질문**: 모노레포에서 한 팀의 커밋이 전체 빌드를 깨뜨렸다. 어떻게 대응하나?

**참고 문서**: [Monorepo 가이드](../Advanced/Monorepo_Management.md)

---

### Q3. White-Label 또는 Multi-Tenant 앱 아키텍처를 설계하라. 50개 이상의 브랜드를 지원해야 한다.

**핵심 키워드**: White-Label, Feature Toggle, Build Flavor, 런타임 설정

**모범 답변**:

**아키텍처 선택: 빌드타임 vs 런타임**

**1) 빌드타임 설정** (강한 차별화):
- 각 브랜드별 `flavor`: `brand_a_prod`, `brand_b_prod`
- 장점: 완전한 커스터마이징 (네이티브 플러그인, 앱 아이콘)
- 단점: 50개 브랜드 = 50개 빌드, CI 시간 폭발

**2) 런타임 설정** (약한 차별화):
- 단일 앱, 첫 화면에서 브랜드 선택 또는 딥링크로 자동 설정
- `TenantConfig.yaml` 원격 다운로드 → 색상, 로고, 기능 토글
- 장점: 단일 빌드, A/B 테스트 쉬움
- 단점: 번들 크기 증가, 모든 브랜드 코드 포함

**하이브리드 전략** (추천):
- 핵심 10개 브랜드: 빌드타임 flavor (완전한 네이티브 통합)
- 나머지 40개: 런타임 설정 (경량 브랜딩만)

**구현 패턴**:
```dart
// lib/config/tenant_provider.dart
class TenantConfig {
  final String brandId;
  final ThemeData theme;
  final Map<String, bool> featureFlags;

  factory TenantConfig.fromRemote(String brandId) {
    // Firebase Remote Config 또는 자체 서버
  }
}
```

**평가 기준**:
- ✅ 좋은 답변: 빌드타임/런타임 트레이드오프, CI 비용 계산, 실제 사례
- ❌ 나쁜 답변: "flavor 50개 만들면 됨", 유지보수 비용 무시

**꼬리 질문**: 브랜드 A는 결제 기능 필요, 브랜드 B는 불필요. 어떻게 조건부 빌드하나?

**참고 문서**: [Configuration](../Advanced/Configuration_Management.md)

---

### Q4. 기술 부채 상환 전략을 수립하라. 레거시 코드가 50%, 신규 기능 압박이 심한 상황이다.

**핵심 키워드**: 기술 부채, 리팩토링 우선순위, 비즈니스 밸런스

**모범 답변**:

**1단계: 부채 측정 (정량화)**
- 핫스팟 분석: Git 히스토리에서 자주 수정되는 파일 (Churn Rate)
- 복잡도: Dart Code Metrics → Cyclomatic Complexity > 10인 함수
- 버그 밀도: Crashlytics에서 특정 모듈 크래시 80%
- 빌드 시간: `flutter build` 5분 → 1분 목표

**2단계: ROI 기반 우선순위**
- High Impact + Low Effort: `StatefulWidget` → `Riverpod` 마이그레이션 (2주)
- High Impact + High Effort: 레거시 API 레이어 재설계 (3개월) → 쿼터별 할당
- Low Impact: 무시 (Sunk Cost)

**3단계: 20% 룰 + 보이스카우트**
- 매 스프린트 20%를 리팩토링에 할당 (Google 사례)
- 보이스카우트 룰: 신규 기능 개발 시 건드린 레거시 코드 개선 (작은 개선)

**4단계: 전략적 재작성**
- Strangler Fig Pattern: 레거시 모듈 옆에 신규 모듈 구축 → 점진적 교체
- API 우선: 백엔드 계약 먼저 현대화 → 프론트 자연스럽게 따라옴

**평가 기준**:
- ✅ 좋은 답변: 측정 지표, ROI 계산, 점진적 접근, 비즈니스 임팩트 연결
- ❌ 나쁜 답변: "전부 재작성", 일정 무시, 측정 없는 리팩토링

**꼬리 질문**: 경영진이 "기능 개발만 하라"고 압박할 때 어떻게 설득하나?

**참고 문서**: [Refactoring](../Advanced/Refactoring_Strategies.md)

---

### Q5. Flutter의 미래 기술 (Impeller, Macros, WASM)을 평가하라. 각각 프로덕션 도입 시점은?

**핵심 키워드**: Impeller, Static Metaprogramming, WebAssembly, 기술 로드맵

**모범 답변**:

**1) Impeller (새 렌더링 엔진)**
- 현재 상태: iOS 안정화 (Flutter 3.10+), Android 베타 (3.38)
- 장점: jank 감소 (셰이더 프리컴파일), Metal/Vulkan 네이티브 활용
- 도입 시점: iOS 이미 프로덕션, Android 2026 Q3 안정화 예상
- 리스크: 일부 커스텀 페인터 호환성 이슈, 하지만 Skia 폴백 가능

**2) Static Metaprogramming (Macros)**
- 목표: `@JsonSerializable` 같은 코드 생성 → 컴파일타임 매크로로 전환
- 장점: `build_runner` 제거, 빌드 시간 50% 단축, IDE 통합
- 도입 시점: 2026 H2 실험적, 2027년 안정화 예상
- 준비: 현재 `json_serializable` 사용 중이면 자동 마이그레이션 경로 제공 예정

**3) WebAssembly (Flutter Web)**
- 현재: CanvasKit + WASM 실험적, JS interop 복잡
- 장점: 성능 향상 (60fps 애니메이션), 번들 크기 감소
- 도입 시점: 2027년 이후, 현재는 JS 컴파일이 더 안정적
- 리스크: 브라우저 호환성 (Safari 지원 늦음)

**도입 전략**:
- Impeller: 지금 iOS, Android는 Canary 테스트
- Macros: 2026 말 평가, 2027 도입
- WASM: 2028년까지 대기, Web 중요하면 별도 네이티브 앱 검토

**평가 기준**:
- ✅ 좋은 답변: 각 기술의 성숙도, 실제 벤치마크, 도입 리스크, 타임라인
- ❌ 나쁜 답변: "최신 기술 무조건 좋음", 안정성 무시

**꼬리 질문**: Impeller 도입 후 일부 UI가 깨졌다. 어떻게 롤백 전략을 세우나?

**참고 문서**: [Flutter Roadmap](https://github.com/flutter/flutter/wiki/Roadmap)

---

### Q6. 서드파티 패키지 vs 직접 구현 의사결정 프레임워크는? 예: 상태관리, 네트워킹, 분석.

**핵심 키워드**: Build vs Buy, 의존성 관리, 유지보수 비용

**모범 답변**:

**의사결정 매트릭스**:

| 기준 | 서드파티 우선 | 직접 구현 우선 |
|------|---------------|----------------|
| **범용성** | 일반적 문제 (HTTP 클라이언트) | 도메인 특화 (자사 결제 로직) |
| **복잡도** | 높음 (암호화, 인증) | 낮음 (간단한 유틸) |
| **유지보수** | 커뮤니티 활발 (dio, riverpod) | 방치된 패키지 (1년+ 업데이트 없음) |
| **라이선스** | MIT, BSD | GPL, 상용 제한 |
| **번들 크기** | 경량 (<100KB) | 거대 (1MB+ 패키지) |

**서드파티 평가 체크리스트**:
- Pub.dev 점수 130+, Likes 500+
- Flutter Favorite 뱃지 (Google 공식 추천)
- Null Safety 완전 지원, Flutter 3.x 호환
- GitHub: 최근 3개월 내 커밋, 이슈 응답 < 7일
- 의존성 트리 분석: `flutter pub deps --tree` → 간접 의존성 10개 이하

**직접 구현 케이스**:
- 핵심 비즈니스 로직 (경쟁 우위)
- 서드파티 없음 또는 품질 낮음
- 규제 요구사항 (금융, 의료) → 감사 가능성

**하이브리드 전략**:
- 래퍼 패턴: `http` → `app_network_client` (인터페이스 격리)
- 포크 전략: 방치된 패키지 포크 → 자체 유지보수 (비용 고려)

**평가 기준**:
- ✅ 좋은 답변: 정량적 평가 기준, 장기 유지보수 비용, 실제 사례
- ❌ 나쁜 답변: "무조건 서드파티", "무조건 직접", 맹목적 NIH 증후군

**꼬리 질문**: 핵심 패키지(예: state management)가 deprecated되었다. 어떻게 대응하나?

**참고 문서**: [Package Selection](../Best_Practices.md#패키지-선택)

---

## 2. 대규모 시스템 설계

### Q7. 백만 DAU를 가진 Flutter 앱의 전체 아키텍처를 설계하라. 모니터링, 배포, 장애 대응 전략 포함.

**핵심 키워드**: 대규모 시스템, 모니터링, 배포 전략, SLO

**모범 답변**:

**아키텍처 레이어**:

```
[Client Layer]
├─ Flutter App (Multi-flavor: dev/staging/prod)
├─ Offline-First (Drift + Sync Queue)
└─ Feature Flags (LaunchDarkly/Firebase)

[Network Layer]
├─ API Gateway (GraphQL Federation)
├─ CDN (이미지, 에셋 캐싱)
└─ Circuit Breaker (dio_retry, exponential backoff)

[Backend Layer]
├─ Microservices (gRPC/REST)
├─ Message Queue (Kafka)
└─ DB (Sharding by user_id)
```

**모니터링 스택**:
- 크래시: Firebase Crashlytics → Crash-free Rate 99.9% SLO
- 성능: Sentry Performance → P95 앱 시작 < 2초
- 분석: Amplitude → DAU, Retention, Funnel 실시간 대시보드
- 로그: Datadog → 서버/클라이언트 통합 추적 (Trace ID)

**배포 전략**:
- Staged Rollout: 1% → 10% → 50% → 100% (3일간)
- Canary Release: A/B 테스트 (Firebase Remote Config)
- 롤백: 스토어 승인 지연 → Shorebird OTA로 핫픽스

**장애 대응**:
- Incident Commander 지정 (on-call rotation)
- Runbook: 주요 장애 시나리오별 대응 절차 (5분 내 롤백)
- Postmortem: 근본 원인 분석 → 재발 방지 (blameless culture)

**평가 기준**:
- ✅ 좋은 답변: 구체적 수치 (SLO), 장애 시나리오, 실제 스택, 비용 최적화
- ❌ 나쁜 답변: "마이크로서비스 쓰면 됨", 모니터링 누락, 추상적 답변

**꼬리 질문**: 백엔드 장애로 API 응답 시간이 10초로 증가했다. 앱에서 어떻게 대응하나?

**참고 문서**: [Production Checklist](../Production_Checklist.md)

---

### Q8. 실시간 위치 추적 앱(배달, 라이드쉐어링)의 Flutter 아키텍처를 설계하라. 배터리 최적화 포함.

**핵심 키워드**: 위치 추적, 배터리 최적화, 실시간 동기화, 백그라운드 처리

**모범 답변**:

**위치 수집 전략**:
- Foreground: `geolocator` 1초 간격 (사용자 앱 활성화 중)
- Background: `workmanager` + 네이티브 위치 서비스 (5-10초 간격)
- Adaptive Interval: 속도 기반 (정지 중 30초, 이동 중 5초)

**배터리 최적화**:
- Geofencing: 특정 영역 진입 시만 추적 시작 (불필요한 GPS 끔)
- 센서 퓨전: GPS + 가속도계 → 실내에서 GPS 끄고 가속도계로 추정
- 배치 업로드: 위치 10개 모아서 한 번에 전송 (네트워크 웨이크업 최소화)
- Low Power Mode: iOS Background Modes 제한, Android Doze 고려

**실시간 동기화**:
- WebSocket (Socket.IO): 라이더 → 서버 → 고객 (양방향 통신)
- Debouncing: 위치 변화 < 10m → 전송 스킵
- Exponential Backoff: 네트워크 끊김 시 재연결 (1s → 2s → 4s)

**아키텍처**:
```dart
[UI Layer] MapWidget (google_maps_flutter)
      ↓
[BLoC] LocationTrackingBloc
      ↓
[Repository] LocationRepository
      ├─ RemoteDataSource (WebSocket)
      └─ LocalDataSource (SQLite 캐시)
```

**평가 기준**:
- ✅ 좋은 답변: 배터리 벤치마크 (mAh 소모), 실제 측정 데이터, 플랫폼 차이 이해
- ❌ 나쁜 답변: "1초마다 GPS", 배터리 무시, Background 제약 모름

**꼬리 질문**: iOS에서 백그라운드 위치 추적이 1시간 후 중단되었다. 원인과 해결책은?

**참고 문서**: [Location Tracking](../Advanced/Location_Tracking.md)

---

### Q9. 오프라인 우선 + 멀티디바이스 동기화 앱을 설계하라. 충돌 해결 전략 포함. (예: 노트 앱, 협업 도구)

**핵심 키워드**: Offline-First, CRDT, Conflict Resolution, Optimistic UI

**모범 답변**:

**오프라인 우선 아키텍처**:
- Local DB: Drift (SQLite) → 단일 진실 공급원
- Sync Queue: 오프라인 작업 큐 → 온라인 복귀 시 순차 실행
- Optimistic UI: 로컬 먼저 반영 → 서버 실패 시 롤백

**동기화 전략**:
- Last Write Wins (LWW): 간단, 하지만 데이터 손실 가능
- Operational Transformation (OT): Google Docs 방식, 복잡
- CRDT (Conflict-free Replicated Data Types): Yjs, Automerge 활용

**CRDT 예시 (노트 앱)**:
```dart
class Note {
  final String id;
  final CRDTText content; // Y.Text (Yjs)
  final HLCTimestamp updatedAt; // Hybrid Logical Clock
}

// 충돌 자동 해결: 사용자 A, B가 동시 편집 → 자동 병합
```

**충돌 해결 전략**:
- 자동 병합: 텍스트 (CRDT), 리스트 (OT)
- Manual Resolution: 중요 필드 (금액, 상태) → UI로 사용자 선택
- Vector Clock: 인과 관계 추적 → "어떤 변경이 최신?"

**멀티디바이스 고려사항**:
- 디바이스 등록: `device_id` (UUID), 디바이스별 동기화 커서
- Push Notification: 다른 디바이스 변경 시 실시간 동기화 트리거
- 대역폭 최적화: Delta Sync (변경된 부분만 전송)

**평가 기준**:
- ✅ 좋은 답변: CRDT 이해, 충돌 시나리오 구체적, 실제 라이브러리 활용
- ❌ 나쁜 답변: "서버 타임스탬프로 덮어쓰기", 충돌 무시

**꼬리 질문**: 사용자 A가 오프라인 3일간 작업, B는 온라인으로 작업. 동기화 시 어떻게 처리?

**참고 문서**: [Offline Sync](../Advanced/Offline_Sync.md)

---

### Q10. 50+명의 엔지니어가 작업하는 대규모 Flutter 코드베이스 관리 전략은? 빌드 속도, 모듈화, 테스트 전략 포함.

**핵심 키워드**: 코드베이스 스케일링, 모듈화, CI 최적화, 코드 소유권

**모범 답변**:

**모듈화 전략**:
- Feature Module: `features/auth/`, `features/payment/` (각 팀 소유)
- Core Module: `core/networking/`, `core/design_system/`
- 의존성 규칙: Feature → Core (O), Feature → Feature (X)

**빌드 속도 최적화**:
- Incremental Build: 변경된 모듈만 재빌드 (Bazel/Buck2)
- CI 캐시: Gradle/Pub 캐시 재사용 → 빌드 시간 70% 단축
- 병렬화: `flutter test --concurrency=4`, M1 Mac 활용
- 현실적 목표: 전체 빌드 15분 → 5분, PR 빌드 2분

**코드 소유권**:
- CODEOWNERS: `features/payment/** @payment-team`
- Auto-assign: PR 생성 시 자동으로 해당 팀 리뷰어 지정
- 브랜치 보호: `main` 직접 푸시 금지, PR + 2명 승인 필수

**테스트 전략**:
- Unit Test: 80% 커버리지 (비즈니스 로직)
- Widget Test: 주요 UI 플로우 (로그인, 결제)
- Integration Test: E2E (Patrol), 매일 야간 실행
- Golden Test: UI 회귀 방지 (Flutter 3.10+ 안정화)

**CI/CD**:
- GitHub Actions: PR당 15분 제한 → 선택적 테스트 (changed files만)
- Merge Queue: Bors 또는 GitHub Merge Queue → 동시 병합 방지

**평가 기준**:
- ✅ 좋은 답변: 구체적 수치 (빌드 시간), 모듈 경계, 실제 도구, 팀 워크플로우
- ❌ 나쁜 답변: "모듈화하면 됨", 빌드 성능 무시, 추상적 답변

**꼬리 질문**: 한 팀의 PR이 다른 팀 테스트를 깨뜨렸다. 어떻게 방지하나?

**참고 문서**: [Monorepo Management](../Advanced/Monorepo_Management.md)

---

### Q11. 마이크로서비스 환경에서 Flutter 앱과 백엔드 API 계약을 어떻게 관리하나? OpenAPI, GraphQL, gRPC 각각의 전략.

**핵심 키워드**: API 계약, Code Generation, 버전 관리, Schema Evolution

**모범 답변**:

**1) OpenAPI (REST)**
- Schema First: `openapi.yaml` 작성 → `openapi-generator-dart` 실행
- 자동 생성: `UserApi`, `UserModel`, `ApiClient` (타입 안전)
- 버전 관리: `/v1/users`, `/v2/users` → 클라이언트가 선택
- 단점: 과도한 엔드포인트 (N+1 문제)

**2) GraphQL**
- Schema: `schema.graphql` → `graphql_codegen` → Dart 클래스
- 장점: 단일 엔드포인트, 클라이언트가 필요한 필드만 요청
- 캐싱: `graphql_flutter` + Normalize Cache (Apollo 스타일)
- 단점: 복잡한 쿼리 → 서버 부하, N+1 해결 필요 (DataLoader)

**3) gRPC**
- Proto 정의: `user.proto` → `protoc` → Dart 클래스
- 장점: 타입 안전, 양방향 스트리밍, 작은 바이너리
- 단점: 웹 지원 약함 (gRPC-Web 필요), 디버깅 어려움
- 사용 사례: 내부 서비스, 실시간 통신 (채팅, 위치)

**계약 관리 전략**:
- Contract Testing: Pact (소비자 주도 계약)
- Breaking Change 탐지: CI에서 스키마 diff 검사
- Backward Compatibility: 새 필드는 Optional, 삭제는 Deprecation 먼저
- Schema Registry: Confluent Schema Registry (gRPC), Apollo Studio (GraphQL)

**평가 기준**:
- ✅ 좋은 답변: 각 프로토콜 장단점, 코드 생성 자동화, 버전 전략, 실제 경험
- ❌ 나쁜 답변: "GraphQL이 최신", 계약 관리 무시, 수동 모델 작성

**꼬리 질문**: 백엔드가 필드 이름을 변경했는데 앱이 크래시한다. 어떻게 방지하나?

**참고 문서**: [API Integration](../Advanced/API_Integration.md)

---

### Q12. 레거시 Native 앱(iOS/Android)을 Flutter로 마이그레이션하는 전략을 수립하라. 단계별 계획과 리스크 관리 포함.

**핵심 키워드**: Add-to-App, Incremental Migration, 리스크 관리

**모범 답변**:

**마이그레이션 전략: Strangler Fig Pattern**

**1단계: 준비 (1-2개월)**
- 현황 분석: 화면 수, Native 의존성 (카메라, Bluetooth), 코드 복잡도
- ROI 계산: 유지보수 비용 vs 마이그레이션 비용 (2-3년 시뮬레이션)
- PoC: 간단한 화면 1개를 Flutter로 재구현 → 성능 테스트

**2단계: Add-to-App 도입 (3-6개월)**
- 신규 기능: Flutter로만 개발 (예: 새 설정 화면)
- 기존 화면: Native → Flutter 점진적 교체 (우선순위: 단순 → 복잡)
- 하이브리드 네비게이션: `FlutterViewController` (iOS), `FlutterActivity` (Android)

**3단계: 핵심 기능 마이그레이션 (6-12개월)**
- 공통 UI: Native Design System → Flutter Design System 재구축
- 상태 관리 통합: Native ↔ Flutter 데이터 공유 (MethodChannel, Pigeon)
- 점진적 교체: 화면 단위로 릴리스 → 사용자 피드백 수집

**4단계: 완전 전환 (12-18개월)**
- Native 코드 최소화: 플랫폼 채널만 남김 (예: 생체 인증)
- 단일 코드베이스: Flutter 100%, Native는 얇은 래퍼

**리스크 관리**:
- 롤백 전략: Feature Flag로 Native/Flutter 전환 가능
- 성능 모니터링: 화면 전환 시간, 메모리 사용량 비교
- 팀 교육: 2주 Flutter Bootcamp, 페어 프로그래밍

**평가 기준**:
- ✅ 좋은 답변: 단계별 일정, ROI 분석, 롤백 전략, 실제 사례
- ❌ 나쁜 답변: "전부 재작성", 리스크 무시, 일정 비현실적

**꼬리 질문**: 마이그레이션 중 Native 팀의 반발이 심하다. 어떻게 설득하나?

**참고 문서**: [Add-to-App](../Advanced/Add_to_App.md)

---

### Q13. Server-Driven UI를 Flutter에서 구현하라. 앱 업데이트 없이 UI를 변경할 수 있어야 한다.

**핵심 키워드**: Server-Driven UI, Dynamic Rendering, JSON Schema

**모범 답변**:

**아키텍처**:

```
[Server]
├─ UI Schema (JSON): 버튼 위치, 색상, 텍스트
├─ Feature Flags: A/B 테스트, 점진적 롤아웃
└─ CDN 캐싱: 스키마 캐시 (변경 시 Purge)

[Flutter App]
├─ Schema Parser: JSON → Widget Tree
├─ Component Registry: 사전 정의된 위젯 (Button, Card)
└─ Fallback: 파싱 실패 시 기본 UI
```

**JSON Schema 예시**:
```json
{
  "type": "Column",
  "children": [
    {
      "type": "Text",
      "data": "Welcome",
      "style": {"fontSize": 24, "color": "#FF5733"}
    },
    {
      "type": "ElevatedButton",
      "text": "Get Started",
      "onPressed": {"action": "navigate", "route": "/home"}
    }
  ]
}
```

**구현 패턴**:
```dart
abstract class DynamicWidget {
  Widget build(Map<String, dynamic> json);
}

class DynamicText extends DynamicWidget {
  Widget build(Map json) => Text(json['data'], style: parseStyle(json['style']));
}
```

**제약 사항**:
- 복잡한 로직 불가: 조건문, 반복문 제한적 (서버에서 처리)
- 보안: JSON 검증 필수 (악의적 스키마 차단)
- 성능: 파싱 오버헤드 (캐싱으로 완화)

**사용 사례**:
- 홈 화면 배너, 프로모션 레이아웃
- A/B 테스트 (버튼 색상, 위치)
- 긴급 공지 (스토어 리뷰 지연 없이 배포)

**평가 기준**:
- ✅ 좋은 답변: 스키마 설계, 보안 고려, 성능 최적화, 실제 사례
- ❌ 나쁜 답변: "eval() 사용", 보안 무시, 복잡도 과도

**꼬리 질문**: 악의적인 JSON으로 무한 루프 위젯이 생성되었다. 어떻게 방지하나?

**참고 문서**: [Server-Driven UI](../Advanced/Server_Driven_UI.md)

---

### Q14. 금융 앱의 보안 아키텍처를 설계하라. 루팅/탈옥 탐지, 인증서 핀닝, 데이터 암호화 포함.

**핵심 키워드**: 앱 보안, 루팅 탐지, Certificate Pinning, 암호화

**모범 답변**:

**1) 루팅/탈옥 탐지**
- `flutter_jailbreak_detection`: 루팅 탐지 → 앱 종료 또는 제한 모드
- 우회 방지: 서버 검증 병행 (SafetyNet Attestation API, DeviceCheck)
- 비즈니스 로직: 루팅 기기에서 송금 차단, 조회만 허용

**2) 인증서 핀닝 (Certificate Pinning)**
- `dio` + 인증서 핀닝: 중간자 공격 (MITM) 방지
```dart
(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
  client.badCertificateCallback = (cert, host, port) {
    return cert.pem == expectedCertificate; // 고정된 인증서만 허용
  };
};
```
- 리스크: 인증서 갱신 시 앱 업데이트 필요 → Shorebird OTA로 해결

**3) 데이터 암호화**
- 저장: `flutter_secure_storage` (Keychain/Keystore) → 토큰, 비밀번호
- 전송: TLS 1.3, AES-256 추가 암호화 (민감 필드)
- 메모리: 민감 데이터 사용 후 즉시 `clear()` (GC 의존 금지)

**4) 코드 난독화**
- `flutter build --obfuscate --split-debug-info=./debug-info`
- ProGuard (Android), Bitcode (iOS): 리버스 엔지니어링 방지

**5) 런타임 보호**
- 화면 캡처 방지: `WidgetsBindingObserver` + 네이티브 플래그
- 디버거 탐지: `kReleaseMode` 검증, 프로덕션에서 디버거 차단

**평가 기준**:
- ✅ 좋은 답변: 다층 방어, 실제 라이브러리, 규제 준수 (PCI-DSS, GDPR)
- ❌ 나쁜 답변: "암호화만 하면 됨", 루팅 탐지 누락, 단일 방어선

**꼬리 질문**: 인증서 핀닝으로 앱이 작동 안 하는 신고가 들어왔다. 원인과 대응은?

**참고 문서**: [Security Best Practices](../Best_Practices.md#보안)

---

## 3. 성능 & 안정성

### Q15. 앱의 SLO(Service Level Objective)를 어떻게 정의하고 모니터링하나? 주요 지표와 알람 전략 포함.

**핵심 키워드**: SLO, SLI, 에러 버짓, 알람 전략

**모범 답변**:

**주요 SLI/SLO 정의**:

| 지표 | SLI | SLO | 측정 도구 |
|------|-----|-----|-----------|
| **가용성** | 성공 요청 / 전체 요청 | 99.9% | Firebase Crashlytics |
| **성능** | P95 앱 시작 시간 | < 2초 | Sentry Performance |
| **안정성** | Crash-free Rate | 99.95% | Crashlytics |
| **응답성** | API P95 응답 시간 | < 500ms | APM (Datadog) |

**에러 버짓** (Error Budget):
- SLO 99.9% → 월 0.1% 에러 허용 (43분)
- 버짓 소진 → 신규 기능 개발 중단, 안정화 집중
- 버짓 남음 → 공격적인 실험 가능

**알람 전략**:
- Critical: Crash-free < 99.5% → 즉시 on-call 호출 (PagerDuty)
- Warning: P95 앱 시작 > 3초 → Slack 알림
- 노이즈 방지: 5분 내 3회 연속 위반 시만 알람 (false positive 제거)

**모니터링 대시보드**:
- Grafana: 실시간 SLO 달성률, 에러 버짓 소진율
- Weekly Review: SLO 미달 원인 분석 → Postmortem

**평가 기준**:
- ✅ 좋은 답변: 구체적 수치, 에러 버짓 전략, 실제 도구, 조직 프로세스
- ❌ 나쁜 답변: "빠르면 좋음", 측정 없음, SLO와 SLA 혼동

**꼬리 질문**: SLO를 3개월 연속 달성했다. 이제 어떻게 하나?

**참고 문서**: [Production Checklist](../Production_Checklist.md)

---

### Q16. Crash-free Rate 99.9%를 달성하기 위한 전략은? 크래시 트리아지, 우선순위, 수정 프로세스 포함.

**핵심 키워드**: Crash-free Rate, 트리아지, Crashlytics, 우선순위

**모범 답변**:

**1단계: 크래시 수집**
- Firebase Crashlytics: 자동 수집, 스택 트레이스, 디바이스 정보
- 커스텀 로그: `FirebaseCrashlytics.instance.log()` → 재현 경로 추적
- 유저 동의: GDPR 준수, 익명화 데이터

**2단계: 트리아지 (매일 오전 10시)**
- P0 (Critical): 앱 실행 불가, 결제 실패 → 24시간 내 핫픽스
- P1 (High): 주요 기능 크래시 (로그인, 장바구니) → 1주 내 수정
- P2 (Medium): 부가 기능 크래시 → 다음 릴리스
- P3 (Low): 1% 미만 영향, 특정 디바이스 → 백로그

**3단계: 우선순위 계산**
```
Priority Score = Affected Users × Frequency × Severity
```
- 예: 1000명, 하루 10회, Critical → 10,000점 → P0

**4단계: 수정 프로세스**
- 재현: 스택 트레이스 → 로컬 재현 → 단위 테스트 작성
- 수정: Null Safety 활용, 방어적 프로그래밍 (`?.`, `??`)
- 검증: 테스트 + Staging 배포 → 모니터링 3일

**5단계: 재발 방지**
- 근본 원인: Null 체크 누락 → Lint 룰 추가 (`avoid_nullable_fields`)
- Regression Test: 크래시 케이스를 자동 테스트로 추가

**목표 달성 전략**:
- 99.9% = 1000명 중 1명 크래시 → 월 100만 DAU면 1000명 허용
- 롱테일 크래시: 상위 10개 크래시가 전체의 80% → 집중 수정

**평가 기준**:
- ✅ 좋은 답변: 트리아지 프로세스, 우선순위 공식, 재발 방지, 실제 사례
- ❌ 나쁜 답변: "모든 크래시 수정", 우선순위 없음, 프로세스 부재

**꼬리 질문**: Android 4.4 디바이스에서만 크래시가 발생한다. 어떻게 대응하나?

**참고 문서**: [Crash Management](../Production_Checklist.md#crash-management)

---

### Q17. 성능 버짓(Performance Budget)을 정의하고 CI에서 자동 검증하는 시스템을 설계하라.

**핵심 키워드**: Performance Budget, CI 통합, 자동화, 회귀 방지

**모범 답변**:

**성능 버짓 정의**:

| 지표 | 목표 | 측정 방법 |
|------|------|-----------|
| 앱 번들 크기 | < 30MB (Android APK) | `flutter build apk --analyze-size` |
| 앱 시작 시간 | < 2초 (P95) | `flutter run --profile` + Timeline |
| 프레임 드롭 | < 1% (60fps) | `PerformanceOverlay` |
| 메모리 사용 | < 200MB (평균) | DevTools Memory Profiler |

**CI 자동 검증** (GitHub Actions):
```yaml
- name: Performance Budget Check
  run: |
    flutter build apk --analyze-size --target-platform android-arm64
    SIZE=$(stat -c%s build/app/outputs/apk/release/app-release.apk)
    if [ $SIZE -gt 31457280 ]; then # 30MB
      echo "APK size exceeds budget: $SIZE bytes"
      exit 1
    fi
```

**프로파일링 자동화**:
- `flutter drive --profile` → JSON 출력
- `performance_test.dart`: 앱 시작 시간, 스크롤 성능 측정
- CI에서 회귀 탐지: 이전 빌드 대비 10% 느려지면 PR 차단

**번들 크기 분석**:
- `--analyze-size` → size analysis JSON
- Treemap 시각화 → 어떤 패키지가 크기를 차지하는지 파악
- 큰 패키지: 지연 로딩 (`deferred import`)

**알람**:
- Slack: 번들 크기 1% 증가마다 알림
- Dashboard: 일별 번들 크기 그래프 (트렌드 파악)

**평가 기준**:
- ✅ 좋은 답변: 자동화, CI 통합, 구체적 임계값, 시각화, 실제 스크립트
- ❌ 나쁜 답변: "수동으로 체크", 임계값 없음, 회귀 탐지 누락

**꼬리 질문**: 한 PR이 번들 크기를 5MB 증가시켰다. 어떻게 원인을 찾고 해결하나?

**참고 문서**: [Performance Optimization](../Advanced/Performance_Optimization.md)

---

### Q18. Over-The-Air (OTA) 업데이트 시스템을 설계하라. Shorebird 또는 자체 구현 전략 포함.

**핵심 키워드**: OTA Update, Shorebird, CodePush, 긴급 패치

**모범 답변**:

**OTA 필요성**:
- 스토어 리뷰 지연 (iOS 1-2일, Android 수시간) → 긴급 버그 수정 불가
- 빠른 실험: A/B 테스트, Feature Flag 변경 즉시 반영

**1) Shorebird (추천)**
- Dart 코드 변경만 지원 (네이티브, 에셋 변경 불가)
- 배포: `shorebird release android` → CDN 업로드
- 클라이언트: 앱 시작 시 자동 다운로드 → 다음 실행 시 적용
- 장점: 간단, Flutter 공식 지원 (2025년 안정화)
- 단점: iOS 심사 정책 주의 (기능 변경 금지)

**2) 자체 구현 (고급)**
- Diff 패치: `bsdiff`로 바이너리 차이만 다운로드 (수 MB → 수백 KB)
- 검증: SHA-256 해시, 코드 사인 → 변조 방지
- 롤백: 패치 실패 시 이전 버전 복구
- 구현 복잡도: 높음, 3-6개월 개발 필요

**OTA 정책**:
- 긴급 패치: 크래시 수정, 보안 패치만
- 기능 변경: 스토어 업데이트 (Apple 규정 준수)
- Staged Rollout: 1% → 10% → 100% (3일간)

**리스크 관리**:
- Kill Switch: 서버에서 OTA 비활성화 (패치 버그 발견 시)
- 강제 업데이트: 심각한 보안 취약점 → 구버전 차단

**평가 기준**:
- ✅ 좋은 답변: Shorebird 이해, iOS 정책 인식, 롤백 전략, 실제 사례
- ❌ 나쁜 답변: "무조건 OTA", 플랫폼 정책 무시, 리스크 무시

**꼬리 질문**: OTA 패치 후 크래시가 급증했다. 어떻게 긴급 대응하나?

**참고 문서**: [OTA Updates](../Advanced/OTA_Updates.md)

---

### Q19. Canary Release와 Blue-Green Deployment를 Flutter 앱에서 어떻게 구현하나?

**핵심 키워드**: Canary Release, Blue-Green, Staged Rollout, Feature Flag

**모범 답변**:

**1) Canary Release** (점진적 롤아웃):
- 개념: 신규 버전을 1% 사용자에게 먼저 배포 → 모니터링 → 점진적 확대
- 구현: Google Play Console "단계별 출시" (Staged Rollout)
  - 1% (1일) → 크래시 모니터링
  - 10% (2일) → 성능 지표 확인
  - 50% (3일) → 사용자 피드백
  - 100% (4일) → 전체 배포
- 롤백: 문제 발견 시 "출시 중지" → 이전 버전 유지

**2) Blue-Green Deployment** (서버 전환):
- 개념: 2개 버전 (Blue: 구버전, Green: 신버전) 동시 운영 → 즉시 전환
- Flutter 앱에서 구현:
  - Remote Config: `app_version_routing` → `blue` 또는 `green`
  - API 엔드포인트 분리: `api.blue.example.com`, `api.green.example.com`
  - 클라이언트: Remote Config 읽고 해당 API 호출
- 전환: 문제 없으면 Green으로 100% 트래픽 이동 → Blue 종료

**3) Feature Flag 활용**:
- LaunchDarkly, Firebase Remote Config
- 예: 새 결제 시스템 → 10% 사용자에게만 활성화
```dart
final isNewPaymentEnabled = await remoteConfig.getBool('new_payment');
if (isNewPaymentEnabled) {
  Navigator.push(NewPaymentScreen());
} else {
  Navigator.push(OldPaymentScreen());
}
```

**모니터링**:
- Canary 그룹 vs 기존 그룹 비교
  - Crash-free Rate, 앱 시작 시간, 전환율
- 자동 롤백: Crash-free < 99.5% → 자동 출시 중지

**평가 기준**:
- ✅ 좋은 답변: 실제 도구, 모니터링 지표, 자동 롤백, Blue-Green 서버 통합
- ❌ 나쁜 답변: "한 번에 배포", 모니터링 없음, 롤백 전략 부재

**꼬리 질문**: Canary 1% 사용자에게서 크래시가 발생했는데 나머지 99%는 문제없다. 어떻게 대응?

**참고 문서**: [Deployment Strategies](../Advanced/Deployment_Strategies.md)

---

## 4. 조직 & 리더십

### Q20. 모바일 챕터 또는 길드를 어떻게 운영하나? 목표, 활동, 성과 측정 포함.

**핵심 키워드**: 챕터, 길드, 기술 리더십, 커뮤니티

**모범 답변**:

**챕터 vs 길드**:
- 챕터 (Chapter): 직무별 그룹 (Flutter 챕터, iOS 챕터) → 기술 표준, 채용
- 길드 (Guild): 관심사 그룹 (접근성 길드, 성능 길드) → 횡단 협업

**Flutter 챕터 운영**:

**목표**:
- 기술 표준화: 아키텍처, 코드 리뷰 가이드, 패키지 선택 기준
- 역량 향상: 주니어 멘토링, 지식 공유
- 채용 강화: 면접 프로세스, 온보딩 가이드

**활동**:
- 주간 세션 (1시간):
  - Tech Talk: 신규 패키지 소개 (Riverpod 2.0)
  - Code Review: 실제 PR 리뷰 (라이브)
  - Architecture Decision Record (ADR): 주요 의사결정 문서화
- RFC (Request for Comments): 새 아키텍처 제안 → 챕터 토론 → 합의
- Hackathon (분기별): 기술 부채 상환, 실험적 프로젝트

**성과 측정**:
- KPI: 코드 리뷰 시간 감소 (3시간 → 1시간), Onboarding 기간 단축 (4주 → 2주)
- NPS: 챕터 만족도 (분기별 설문)
- 기술 블로그: 월 2개 이상 기술 아티클 발행

**평가 기준**:
- ✅ 좋은 답변: 구체적 활동, KPI, 실제 운영 경험, 조직 임팩트
- ❌ 나쁜 답변: "그냥 모임", 목표 없음, 성과 측정 부재

**꼬리 질문**: 챕터 참여율이 50%로 떨어졌다. 어떻게 개선하나?

**참고 문서**: [Team Organization](../Best_Practices.md#팀-조직)

---

### Q21. 코드 리뷰 문화를 어떻게 정착시키나? 리뷰 가이드, 툴, 프로세스 포함.

**핵심 키워드**: 코드 리뷰, 리뷰어 가이드, 자동화, 건설적 피드백

**모범 답변**:

**코드 리뷰 원칙**:
- 목적: 버그 발견 (30%), 지식 공유 (40%), 코드 품질 (30%)
- 톤: 건설적, 질문 형식 ("왜 X 대신 Y를 사용하셨나요?")
- 시간: PR 올린 후 4시간 내 1차 리뷰 (SLA)

**리뷰 가이드**:
1. **자동화 먼저**: CI에서 Lint, Test, Format 검증 → 리뷰어는 로직에 집중
2. **크기 제한**: PR은 300줄 이하 (큰 PR은 리뷰 품질 저하)
3. **리뷰 체크리스트**:
   - 비즈니스 로직 정확성
   - 에러 핸들링 (null, 네트워크 실패)
   - 테스트 커버리지 (새 코드 80%+)
   - 성능 (N+1 쿼리, 메모리 릭)
   - 보안 (하드코딩된 토큰, SQL 인젝션)

**도구**:
- Danger: 자동 코멘트 (PR 크기 경고, 테스트 누락 알림)
- CODEOWNERS: 자동 리뷰어 지정
- GitHub Suggestions: 코드 제안 → 원클릭 적용

**문화 정착**:
- 리뷰어 로테이션: 매주 다른 사람 리뷰 → 지식 전파
- Pair Review: 복잡한 PR은 2명 리뷰어
- 리뷰 감사: 월별 Best Review 선정 → 포상

**평가 기준**:
- ✅ 좋은 답변: 구체적 가이드, 자동화, 문화적 측면, 실제 도구
- ❌ 나쁜 답변: "열심히 리뷰", 프로세스 없음, 톤 무시

**꼬리 질문**: 시니어가 주니어 PR에 과도하게 nitpicking한다는 불만이 있다. 어떻게 중재하나?

**참고 문서**: [Code Review Guide](../Best_Practices.md#코드-리뷰)

---

### Q22. 주니어 엔지니어를 어떻게 멘토링하고 성장시키나? 온보딩, 성장 경로, 피드백 포함.

**핵심 키워드**: 멘토링, 온보딩, 성장 경로, 1-on-1

**모범 답변**:

**온보딩 (첫 2주)**:
- Day 1: 개발 환경 세팅 (자동화 스크립트), 코드베이스 투어
- Week 1: "Good First Issue" 해결 → PR 제출 → 리뷰 경험
- Week 2: 작은 기능 개발 (테스트 포함) → 프로덕션 배포 경험

**성장 경로 (6개월)**:
- Month 1-2: 단순 버그 수정, UI 개선 (자신감 구축)
- Month 3-4: 중간 복잡도 기능 (상태 관리, API 통합)
- Month 5-6: 설계 참여 (RFC 작성), 코드 리뷰어 역할

**멘토링 활동**:
- 페어 프로그래밍 (주 2회): 복잡한 문제를 함께 해결
- 코드 리뷰: 설명형 코멘트 ("이렇게 하면 X 문제 해결")
- 1-on-1 (격주): 커리어 목표, 기술 관심사, 피드백

**피드백 프레임워크 (SBI 모델)**:
- Situation: "어제 PR 리뷰에서"
- Behavior: "에러 핸들링이 누락되었습니다"
- Impact: "프로덕션에서 크래시가 발생할 수 있습니다"

**성장 측정**:
- PR 품질: 리뷰 코멘트 수 감소 (20개 → 5개)
- 자율성: 티켓 완료 시간 단축 (5일 → 2일)
- 기술 블로그: 분기 1개 작성 (지식 공유)

**평가 기준**:
- ✅ 좋은 답변: 구조적 프로그램, 성장 측정, 심리적 안전, 실제 경험
- ❌ 나쁜 답변: "알아서 배워", 방치, 피드백 없음

**꼬리 질문**: 주니어가 3개월째 성장이 정체되었다. 어떻게 진단하고 돕나?

**참고 문서**: [Mentoring Guide](../Best_Practices.md#멘토링)

---

### Q23. 프로덕션 인시던트 발생 시 대응 프로세스는? Incident Commander, Postmortem 포함.

**핵심 키워드**: 인시던트 대응, On-Call, Postmortem, Blameless Culture

**모범 답변**:

**인시던트 레벨**:
- SEV-1 (Critical): 전체 서비스 다운, 데이터 유실 → 즉시 대응
- SEV-2 (High): 주요 기능 장애 (결제 실패) → 1시간 내 대응
- SEV-3 (Medium): 부분 장애, 성능 저하 → 업무 시간 내 대응

**대응 프로세스** (SEV-1 기준):

**1단계: 탐지 (0-5분)**
- 자동 알람: PagerDuty → On-Call 엔지니어 호출
- 수동 신고: 고객 지원팀 → Slack #incidents

**2단계: 대응 (5-30분)**
- Incident Commander (IC) 지정: 온콜 엔지니어 또는 시니어
- War Room: Zoom 회의 + Slack 채널 (#incident-2026-02-08)
- 역할 분담: IC (조율), Engineer (수정), Comms (공지)

**3단계: 완화 (30분-2시간)**
- 즉시 조치: 롤백, Feature Flag 끄기, 트래픽 차단
- 근본 수정: 코드 패치, 데이터 복구
- 검증: 모니터링 30분, 사용자 피드백 확인

**4단계: 복구 후 (2시간-1주)**
- Postmortem (24시간 내):
  - Timeline: 탐지 → 대응 → 해결
  - 근본 원인: 5 Whys 분석
  - Action Items: 재발 방지 (담당자, 마감일 지정)
- Blameless Culture: 개인 비난 금지, 시스템 개선 집중

**예시 Postmortem**:
- 인시던트: API 서버 다운 → 앱 크래시 급증
- 근본 원인: 배포 시 DB 마이그레이션 실패
- 재발 방지: Staging에서 마이그레이션 필수 검증, 자동 롤백

**평가 기준**:
- ✅ 좋은 답변: 명확한 프로세스, 역할 분담, Blameless, 실제 사례
- ❌ 나쁜 답변: "급하게 고침", 책임 전가, Postmortem 생략

**꼬리 질문**: Postmortem에서 "개발자가 테스트를 안 했다"는 비난이 나왔다. 어떻게 중재?

**참고 문서**: [Incident Response](../Best_Practices.md#인시던트-대응)

---

### Q24. 기술 면접 프로세스를 어떻게 설계하고 개선하나? 면접 단계, 평가 기준, 편향 제거 포함.

**핵심 키워드**: 채용, 기술 면접, 평가 루브릭, 편향 제거

**모범 답변**:

**면접 프로세스 (4단계)**:

**1) 코딩 테스트 (1시간)**
- 문제: 중간 난이도 (LeetCode Medium) + Flutter 위젯 구현
- 평가: 알고리즘, 코드 품질, Dart 숙련도
- 도구: HackerRank, 자체 플랫폼

**2) 시스템 설계 (1시간)**
- 문제: "인스타그램 피드 설계", "오프라인 우선 노트 앱"
- 평가: 아키텍처, 트레이드오프 이해, 확장성
- 루브릭: 요구사항 분석 (25%), 설계 (50%), 질문 대응 (25%)

**3) 행동 면접 (45분)**
- STAR 기법: Situation, Task, Action, Result
- 질문: "팀 충돌 해결 경험", "기술 부채 상황 전략"
- 평가: 커뮤니케이션, 협업, 리더십

**4) 문화 적합성 (30분)**
- 회사 가치 정렬, 동기 부여 요인
- 양방향: 후보자 질문 → 회사 투명성

**평가 루브릭**:
- 각 항목 1-5점, 총점 15점 이상 합격
- Hire: 15-20점, Maybe: 10-14점, No Hire: <10점
- 모든 면접관 독립 평가 → 토론 (편향 감소)

**편향 제거**:
- 표준화된 질문: 모든 후보자 동일 문제
- 다양한 면접관: 성별, 연차, 배경 균형
- 블라인드 채점: 이름, 학력 숨김 (초기 평가)

**개선 사이클**:
- 월간 리뷰: 합격률, 면접관 피드백, 후보자 경험
- A/B 테스트: 새 면접 문제 효과 측정

**평가 기준**:
- ✅ 좋은 답변: 구조화된 프로세스, 루브릭, 편향 인식, 데이터 기반 개선
- ❌ 나쁜 답변: "느낌으로 평가", 표준 없음, 편향 무시

**꼬리 질문**: 면접관마다 평가가 극명하게 갈린다. 어떻게 조율하나?

**참고 문서**: [Interview Guide](../Best_Practices.md#채용)

---

### Q25. 모바일 팀의 기술 브랜딩을 어떻게 구축하나? 기술 블로그, 컨퍼런스, 오픈소스 기여 포함.

**핵심 키워드**: 기술 브랜딩, 채용 마케팅, 오픈소스, 컨퍼런스

**모범 답변**:

**목표**:
- 채용 강화: 우수 인재가 지원하는 회사
- 영향력 확대: 업계 리더십 확보
- 팀 동기 부여: 외부 인정 → 내부 자긍심

**전략**:

**1) 기술 블로그**
- 주제: 실전 경험 (Flutter 대규모 마이그레이션, 성능 최적화)
- 빈도: 월 2개 (팀원 로테이션)
- 플랫폼: Medium, 자사 블로그, Dev.to
- 예시: "백만 DAU Flutter 앱의 CI/CD 전략"

**2) 컨퍼런스**
- 발표: FlutterCon, DroidCon, Mobile DevOps Summit
- 내부 세션: Flutter Meetup 주최 (분기별)
- 스폰서십: 커뮤니티 이벤트 지원 (브랜딩)

**3) 오픈소스**
- 패키지 공개: 내부 도구 → pub.dev (예: `company_design_system`)
- 기여: Flutter/Riverpod 이슈 수정, PR 제출
- 유지보수: Flutter Favorite 획득 목표

**4) 소셜 미디어**
- Twitter/LinkedIn: 기술 인사이트, 채용 공고
- YouTube: 기술 세션 녹화, 튜토리얼

**측정**:
- 채용: 지원자 수 20% 증가, "기술 블로그 보고 지원" 비율
- 브랜드 인지도: Google Analytics (블로그 방문자), 소셜 팔로워 수
- 커뮤니티: pub.dev Likes, GitHub Stars

**평가 기준**:
- ✅ 좋은 답변: 전략, 실행 계획, 측정 지표, 실제 사례
- ❌ 나쁜 답변: "블로그만 쓰면 됨", 목표 없음, 측정 부재

**꼬리 질문**: 팀원들이 "바빠서 블로그 못 쓴다"고 한다. 어떻게 독려하나?

**참고 문서**: [Tech Branding](../Best_Practices.md#기술-브랜딩)

---

## 5. 최신 기술 동향

### Q26. AI 코딩 어시스턴트(Copilot, Claude Code)를 팀에 어떻게 도입하고 활용하나? 생산성 측정, 코드 품질 영향 포함.

**핵심 키워드**: AI Coding, GitHub Copilot, 생산성, 코드 품질, 윤리

**모범 답변**:

**도입 전략**:

**1단계: 평가 (1개월)**
- Pilot 그룹: 시니어 3명 + 주니어 2명
- 도구: GitHub Copilot, Claude Code, Cursor
- 측정: 코딩 속도, PR 크기, 버그 밀도

**2단계: 가이드라인 수립**
- 허용: 보일러플레이트 (모델 클래스, 테스트 스캐폴딩)
- 주의: 비즈니스 로직 (리뷰 필수), 보안 코드 (수동 검증)
- 금지: 민감 데이터 포함 코드, 라이선스 불명확 코드

**3단계: 전사 롤아웃 (3개월)**
- 교육: AI 출력 검증 방법, Prompt Engineering
- 모니터링: 코드 품질 (Lint, Test 커버리지), 라이선스 스캔

**생산성 측정**:
- 코딩 속도: 30-40% 향상 (GitHub 연구)
- PR 크기: 20% 증가 (더 빠르게 구현)
- 리뷰 시간: 변화 없음 (품질 유지 위해)

**코드 품질 영향**:
- 장점: 일관된 스타일, 테스트 커버리지 증가
- 단점: 오래된 패턴 제안 (Riverpod 1.0 대신 Provider)
- 완화: 팀 컨텍스트 제공 (`.copilot-instructions.md`)

**윤리적 고려**:
- 라이선스 위반: AI 생성 코드 → 라이선스 스캐너 (Snyk)
- 의존성: AI 없이도 코딩 가능해야 (교육 병행)

**평가 기준**:
- ✅ 좋은 답변: 측정 데이터, 가이드라인, 품질 관리, 윤리 인식
- ❌ 나쁜 답변: "무조건 도입", 품질 무시, 맹목적 신뢰

**꼬리 질문**: AI가 생성한 코드에서 보안 취약점이 발견되었다. 어떻게 예방하나?

**참고 문서**: [AI Coding Guide](../Best_Practices.md#ai-코딩)

---

### Q27. Kotlin Multiplatform (KMP) vs Flutter, 2026년 기준 어느 것을 선택하나? 각각의 강점과 적합한 시나리오.

**핵심 키워드**: KMP, Flutter, 멀티플랫폼 비교, 기술 선택

**모범 답변**:

**Kotlin Multiplatform (KMP) 강점**:
- 네이티브 UI: iOS SwiftUI, Android Compose → 플랫폼별 최적 UX
- 기존 팀: Android 팀 강함 → Kotlin 재사용
- 로직 공유: 비즈니스 로직, 네트워킹만 공유 (50-70%)
- 성숙도: 2026년 기준 Stable, Jetpack Compose Multiplatform 안정화

**Flutter 강점**:
- UI 공유: 단일 코드베이스 → 90%+ 재사용
- 빠른 개발: Hot Reload, 풍부한 위젯
- 웹/데스크톱: 추가 비용 없이 확장
- 생태계: 더 큰 커뮤니티 (2026년 기준), 풍부한 패키지

**선택 기준**:

| 시나리오 | 추천 |
|----------|------|
| **플랫폼별 UI 중요** (금융, 게임) | KMP |
| **빠른 출시, 통일된 UX** (스타트업) | Flutter |
| **기존 Native 팀** (Android/iOS 전문가) | KMP |
| **통합 팀** (Full-stack, 크로스 플랫폼) | Flutter |
| **웹 필수** | Flutter |
| **성능 크리티컬** (AR, 센서) | KMP + Native |

**하이브리드 전략**:
- KMP로 로직 공유 + Native UI (초기)
- Flutter로 Admin 도구, 내부 앱 (빠른 개발)

**2026년 트렌드**:
- KMP: Compose Multiplatform 성숙, JetBrains 지원 강화
- Flutter: Impeller, Macros 도입 → 성능/개발자 경험 개선

**평가 기준**:
- ✅ 좋은 답변: 각 기술 장단점, 팀/비즈니스 맥락, 실제 사례, 트렌드 인식
- ❌ 나쁜 답변: "Flutter만 좋음", 맹목적 편향, 기술 이해 부족

**꼬리 질문**: KMP 선택 후 iOS 개발자가 "Kotlin 싫다"고 한다. 어떻게 대응?

**참고 문서**: [KMP vs Flutter](../Advanced/KMP_vs_Flutter.md)

---

### Q28. Flutter Web + WebAssembly의 현재 상태와 미래 전망은? 프로덕션 도입 시점과 전략.

**핵심 키워드**: Flutter Web, WebAssembly, WASM, 성능, 브라우저 호환성

**모범 답변**:

**현재 상태 (2026년 Q1)**:

**1) 렌더링 옵션**:
- CanvasKit: 고품질, 일관된 렌더링, 하지만 번들 크기 큼 (2MB+)
- HTML: 가벼움, SEO 친화적, 하지만 일부 위젯 제한
- Skwasm (실험적): CanvasKit + WASM → 성능 향상 30%

**2) WebAssembly 지원**:
- Dart → WASM 컴파일 실험적 (dart2wasm)
- 장점: 네이티브 수준 성능, 작은 번들 (JS 대비 20% 감소)
- 단점: 브라우저 호환성 (Safari 지원 늦음), JS interop 복잡

**3) 성능**:
- 첫 로딩: 느림 (3-5초, 네트워크 의존)
- 런타임: 60fps 가능, 하지만 복잡한 애니메이션은 JS보다 느림
- 최적화: Code Splitting, Lazy Loading (deferred import)

**프로덕션 도입 시점**:
- **지금 가능**: 내부 대시보드, Admin 패널 (트래픽 낮음)
- **2027년**: B2C 앱 (Skwasm 안정화 후)
- **2028년 이후**: 복잡한 SaaS (WASM + JS interop 성숙)

**도입 전략**:
- Progressive Web App (PWA): 오프라인 지원, 푸시 알림
- Hybrid: 랜딩 페이지 (Next.js) + 앱 (Flutter Web)
- 성능 측정: Lighthouse Score 90+ 목표

**대안 고려**:
- Flutter Web 성능 부족 → React/Vue + 네이티브 앱 분리
- SEO 중요 → Server-Side Rendering (현재 Flutter Web 미지원)

**평가 기준**:
- ✅ 좋은 답변: 현재 기술 상태, 제약사항, 도입 시점, 대안 고려
- ❌ 나쁜 답변: "WASM이면 완벽", 브라우저 호환성 무시, 성능 과대평가

**꼬리 질문**: Flutter Web 앱이 Safari에서만 느리다는 신고가 들어왔다. 원인과 해결책?

**참고 문서**: [Flutter Web Guide](../Advanced/Flutter_Web.md)

---

## 메타데이터

**난이도 분포**:
- 기술 전략: Staff 수준 의사결정, 조직 영향 분석
- 시스템 설계: 대규모 사용자, 멀티 디바이스, 복잡한 동기화
- 성능 & 안정성: SLO 기반 측정, 자동화, 프로덕션 운영
- 조직 & 리더십: 팀 빌딩, 문화 정착, 채용
- 최신 기술: 트렌드 평가, 도입 전략, 리스크 관리

**평가 포인트**:
- 정량적 데이터 (SLO, TCO, ROI)
- 실무 경험 (구체적 사례, 도구)
- 조직 영향력 (팀 스케일링, 문화)
- 리스크 관리 (롤백, 출구 전략)
- 비즈니스 이해 (기술 vs 비즈니스 밸런스)

**관련 문서**:
- [L4 Mid-level Q&A](./QnA_L4_MidLevel.md)
- [L5 Senior Q&A](./QnA_L5_Senior.md)
- [Best Practices](../Best_Practices.md)
- [Production Checklist](../Production_Checklist.md)
- [Advanced Topics](../Advanced/)

**추천 학습 경로**:
1. L4, L5 문서 복습 (기초 다지기)
2. 대규모 시스템 설계 (백만 DAU, 오프라인 동기화)
3. 조직 관리 (챕터, 멘토링, 인시던트)
4. 최신 기술 평가 (Impeller, WASM, KMP)
5. 실제 프로젝트 리딩 (6개월+ 경험)

---

**버전 히스토리**:
- 2026-02-08: 초판 작성 (Flutter 3.38, Dart 3.10 기준)
