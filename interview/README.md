# Flutter 면접 준비 자료

> **마지막 업데이트**: 2026-02-08 | **Flutter 3.38** | **Dart 3.10**
> **대상**: SWE L4 (Mid-Level) ~ L6 (Staff/Principal)
> **포지션**: 모바일 엔지니어 + 시스템 설계

---

## 개요

이 디렉토리는 flutter-study 저장소의 63개 문서를 기반으로 한 면접 준비 자료입니다.
Q&A 문답집과 토픽별 치트시트 두 가지 형태로 구성되어 있습니다.

### 자료 구성

| 유형 | 파일 | 내용 | 대상 레벨 |
|------|------|------|-----------|
| **Q&A 문답집** | `QnA_L4_MidLevel.md` | Dart/Flutter 기본기, 상태 관리, 아키텍처 기초 | L4 (2-4년) |
| **Q&A 문답집** | `QnA_L5_Senior.md` | 아키텍처 설계, 시스템 디자인, 성능/보안, 팀 리딩 | L5 (4-7년) |
| **Q&A 문답집** | `QnA_L6_Staff.md` | 기술 전략, 대규모 시스템, 조직 리더십, 기술 동향 | L6 (7년+) |
| **치트시트** | `CheatSheet_DartFlutter.md` | Dart 언어 + Flutter Widget + 상태 관리 + 렌더링 요약 | L4~L6 |
| **치트시트** | `CheatSheet_SystemDesign.md` | 아키텍처 패턴 + 시스템 설계 문제 + 모바일 설계 요약 | L5~L6 |
| **치트시트** | `CheatSheet_Production.md` | 테스트 + 보안 + CI/CD + 프로덕션 운영 요약 | L4~L6 |

---

## 레벨별 활용 가이드

### L4 (Mid-Level) — 구현력 중심

```
면접 초점: "이 기능을 어떻게 구현하시겠습니까?"
```

**준비 순서:**
1. `CheatSheet_DartFlutter.md` — Dart/Flutter 핵심 문법 복습
2. `QnA_L4_MidLevel.md` — 예상 질문 전체 리뷰
3. `CheatSheet_Production.md` — 테스트/보안 기초 복습

**핵심 준비 영역:**
- Dart 비동기 패턴 (Future, Stream, async/await)
- Widget 생명주기와 State 관리
- Bloc 패턴 (Event → State 흐름)
- Clean Architecture 3계층 설명
- 단위 테스트 작성 (blocTest, mocktail)

### L5 (Senior) — 설계력 + 트레이드오프 분석

```
면접 초점: "왜 그 설계를 선택했고, 다른 옵션과 비교하면 어떻습니까?"
```

**준비 순서:**
1. `QnA_L5_Senior.md` — 아키텍처/시스템 설계 질문 집중
2. `CheatSheet_SystemDesign.md` — 시스템 설계 프레임워크 숙지
3. `CheatSheet_Production.md` — CI/CD, 보안, 운영 심화
4. `QnA_L4_MidLevel.md` — 기본기 빠르게 복습

**핵심 준비 영역:**
- 시스템 설계 답변 프레임워크 (요구사항 → 아키텍처 → 상세 설계 → 트레이드오프)
- 모바일 특화 설계 문제 (채팅, 피드, 오프라인, 결제)
- 성능 최적화 경험과 측정 방법
- 팀 리딩 경험 (코드 리뷰, 온보딩, 기술 의사결정)

### L6 (Staff/Principal) — 기술 전략 + 조직 영향력

```
면접 초점: "기술 전략을 어떻게 수립하고 조직에 영향을 미쳤습니까?"
```

**준비 순서:**
1. `QnA_L6_Staff.md` — 전략적 질문 집중
2. `CheatSheet_SystemDesign.md` — 대규모 시스템 설계 복습
3. `QnA_L5_Senior.md` — 시스템 설계 기본 복습

**핵심 준비 영역:**
- 기술 선택 의사결정 프레임워크 (Flutter vs Native vs RN)
- 대규모 시스템 설계 (백만 DAU, 멀티 디바이스, 글로벌)
- 조직 설계 (챕터/길드, 멘토링, 면접 프로세스)
- 기술 전략 (기술 부채, 마이그레이션, 생태계 방향성)

---

## 면접 유형별 활용

### 코딩 면접

| 준비 자료 | 활용 |
|-----------|------|
| `CheatSheet_DartFlutter.md` 1~2장 | Dart 문법, 비동기 패턴 빠른 복습 |
| `QnA_L4_MidLevel.md` 카테고리 1~3 | Dart, Widget, 상태 관리 코딩 문제 대비 |

### 시스템 설계 면접

| 준비 자료 | 활용 |
|-----------|------|
| `CheatSheet_SystemDesign.md` 전체 | 설계 프레임워크 + 대표 문제 5개 숙지 |
| `QnA_L5_Senior.md` 카테고리 3 | 시스템 설계 질문 예행연습 |
| `QnA_L6_Staff.md` 카테고리 2 | 대규모 시스템 설계 심화 |

### 행동 면접 (Behavioral)

| 준비 자료 | 활용 |
|-----------|------|
| `QnA_L5_Senior.md` 카테고리 6 | 팀 리딩, 코드 리뷰, 기술 부채 경험 |
| `QnA_L6_Staff.md` 카테고리 4 | 조직 영향력, 멘토링, 인시던트 관리 경험 |

---

## 학습 문서 참조

이 면접 자료의 모든 답변은 flutter-study 저장소의 63개 문서에 기반합니다.
각 Q&A 항목에 관련 문서 링크가 포함되어 있으니, 깊이 있는 학습이 필요하면 해당 문서를 참고하세요.

| 카테고리 | 문서 수 | 핵심 문서 |
|---------|---------|----------|
| Fundamentals | 5개 | DartAdvanced, WidgetFundamentals |
| Core | 7개 | Architecture, Bloc, Freezed, Fpdart |
| Advanced | 6개 | ModularArchitecture, AdvancedPatterns, WhiteLabelArchitecture |
| Infrastructure | 13개 | CICD, PlatformIntegration, VersionMigration |
| Features | 16개 | Authentication, WebView, Navigation |
| System | 11개 | Testing, Performance, Security, ProductionOperations |

---

## 레벨별 난이도 표시

문서 내에서 각 항목의 난이도를 다음과 같이 표시합니다:

| 표시 | 레벨 | 의미 |
|------|------|------|
| 🟢 | L4 | Mid-Level 필수 — 기본기, 구현력 |
| 🟡 | L5 | Senior 필수 — 설계력, 트레이드오프 |
| 🔴 | L6 | Staff 필수 — 전략, 조직 영향력 |

---

**면접 성공을 기원합니다!** 🎯
