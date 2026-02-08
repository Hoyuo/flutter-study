# Flutter 팀 협업 가이드

> **난이도**: 고급 | **카테고리**: system
> **선행 학습**: [Architecture](../core/Architecture.md) | **예상 학습 시간**: 2h

> 코드 컨벤션, PR 리뷰, 아키텍처 의사결정 등 팀 생산성을 높이는 협업 전략을 학습합니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - 팀 코드 컨벤션과 린트 규칙을 설정하여 일관된 코드 품질을 유지할 수 있습니다
> - 효과적인 PR 리뷰 프로세스와 Git 브랜치 전략으로 협업 효율을 높일 수 있습니다
> - ADR(아키텍처 의사결정 기록)과 문서화로 팀의 기술 부채를 관리할 수 있습니다

---

## 목차

1. [코드 컨벤션](#1-코드-컨벤션)
2. [Lint 규칙 설정](#2-lint-규칙-설정)
3. [프로젝트 구조 컨벤션](#3-프로젝트-구조-컨벤션)
4. [Git 브랜치 전략](#4-git-브랜치-전략)
5. [Commit 메시지 컨벤션](#5-commit-메시지-컨벤션)
6. [Pull Request 가이드](#6-pull-request-가이드)
7. [코드 리뷰 체크리스트](#7-코드-리뷰-체크리스트)
8. [아키텍처 의사결정 기록 (ADR)](#8-아키텍처-의사결정-기록-adr)
9. [코드 소유권 (CODEOWNERS)](#9-코드-소유권-codeowners)
10. [문서화 전략](#10-문서화-전략)
11. [온보딩 프로세스](#11-온보딩-프로세스)
12. [기술 부채 관리](#12-기술-부채-관리)
13. [팀 도구와 자동화](#13-팀-도구와-자동화)
14. [회고와 개선](#14-회고와-개선)

---

## 1. 코드 컨벤션

### 1.1 Dart 공식 스타일 가이드

Flutter 팀은 [Dart 공식 스타일 가이드](https://dart.dev/guides/language/effective-dart)를 따릅니다.

#### 핵심 원칙

| 원칙 | 설명 | 예시 |
|------|------|------|
| **DO** | 반드시 따라야 할 규칙 | 클래스명은 UpperCamelCase |
| **DON'T** | 절대 하지 말아야 할 것 | 불필요한 `new` 키워드 사용 금지 |
| **PREFER** | 권장 사항 | 함수형 위젯 선호 |
| **AVOID** | 피해야 할 패턴 | 중첩된 삼항 연산자 피하기 |
| **CONSIDER** | 상황에 따라 고려 | 복잡한 로직은 별도 함수로 분리 고려 |

### 1.2 네이밍 컨벤션

```dart
// ✅ 클래스: UpperCamelCase
class UserProfile {}
class HomeBloc {}

// ✅ 함수, 변수: lowerCamelCase
void fetchUserData() {}
final userName = 'John';

// ✅ 상수: lowerCamelCase
const maxRetryCount = 3;
const apiBaseUrl = 'https://api.example.com';

// ✅ 파일명: snake_case
// user_profile.dart
// home_bloc.dart

// ✅ 라이브러리명: snake_case
// import 'package:my_app/user_profile.dart';

// ❌ 피해야 할 네이밍
class user_profile {}  // 클래스는 UpperCamelCase
void FetchUserData() {}  // 함수는 lowerCamelCase
const MAX_RETRY_COUNT = 3;  // 상수도 lowerCamelCase (Dart 스타일)
```

### 1.3 클래스 구조 순서

```dart
class UserProfileScreen extends StatefulWidget {
  // 1. Static 상수
  static const routeName = '/user-profile';

  // 2. 생성자 파라미터 (final)
  final String userId;
  final VoidCallback? onUpdate;

  // 3. 생성자
  const UserProfileScreen({
    super.key,
    required this.userId,
    this.onUpdate,
  });

  // 4. 오버라이드 메서드
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // 1. Private 변수
  late final TextEditingController _nameController;
  bool _isLoading = false;

  // 2. 생명주기 메서드
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 3. Build 메서드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // 4. Private 빌드 메서드
  AppBar _buildAppBar() {
    return AppBar(title: const Text('프로필'));
  }

  Widget _buildBody() {
    if (_isLoading) return const CircularProgressIndicator();
    return _buildForm();
  }

  Widget _buildForm() {
    return Column(children: []);
  }

  // 5. 이벤트 핸들러
  void _onSavePressed() {
    // ...
  }

  // 6. Private 유틸리티 메서드
  bool _isValidName(String name) {
    return name.isNotEmpty;
  }
}
```

### 1.4 주석 스타일

```dart
/// 사용자 프로필 정보를 나타내는 클래스
///
/// 이 클래스는 서버에서 받은 사용자 데이터를 담습니다.
/// [fromJson] 팩토리로 JSON에서 인스턴스를 생성할 수 있습니다.
class UserProfile {
  /// 사용자 고유 ID
  final String id;

  /// 사용자 이름 (최대 50자)
  final String name;

  /// 프로필 이미지 URL (선택사항)
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  /// JSON에서 UserProfile 인스턴스 생성
  ///
  /// 예시:
  /// ```dart
  /// final profile = UserProfile.fromJson({
  ///   'id': '123',
  ///   'name': 'John Doe',
  /// });
  /// ```
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

// 일반 주석은 구현 세부사항 설명
void _fetchUserData() {
  // API 호출 전 로딩 상태 표시
  setState(() => _isLoading = true);

  // TODO(username): 에러 핸들링 추가 필요
  // FIXME: 네트워크 타임아웃이 너무 짧음
  // HACK: 임시 하드코딩, API 완성되면 제거
}
```

---

## 2. Lint 규칙 설정

### 2.1 flutter_lints 기본 설정

```yaml
# analysis_options.yaml
include: package:lints/recommended.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.mocks.dart"

  errors:
    # 경고를 에러로 승격
    invalid_annotation_target: ignore

  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    # 추가 권장 규칙
    - always_declare_return_types
    - always_put_required_named_parameters_first
    - avoid_print
    - avoid_unnecessary_containers
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - prefer_final_fields
    - prefer_final_locals
    - sort_constructors_first
    - sort_unnamed_constructors_first
    - unawaited_futures
    - use_key_in_widget_constructors
```

### 2.2 very_good_analysis (엄격한 규칙)

```yaml
# pubspec.yaml
dev_dependencies:
  very_good_analysis: ^10.1.0

# analysis_options.yaml
include: package:very_good_analysis/analysis_options.yaml

linter:
  rules:
    # Very Good Analysis 기본 + 추가 규칙
    public_member_api_docs: false  # 팀 정책에 따라 조정
    lines_longer_than_80_chars: false  # 120자로 완화
```

### 2.3 커스텀 Lint 규칙

```yaml
# analysis_options.yaml
analyzer:
  errors:
    # 미사용 import를 에러로 처리
    unused_import: error

    # 미사용 로컬 변수를 에러로 처리
    unused_local_variable: error

    # Deprecated API 사용 시 에러
    deprecated_member_use: error

    # 타입 추론 실패 시 경고
    inference_failure_on_function_return_type: warning

linter:
  rules:
    # Bloc 관련
    - avoid_print  # debugPrint 사용 권장

    # 성능
    - avoid_slow_async_io
    - avoid_unnecessary_containers

    # 가독성
    - prefer_expression_function_bodies  # 짧은 함수는 => 사용
    - prefer_single_quotes  # 문자열은 작은따옴표

    # 안전성
    - always_use_package_imports  # 상대 경로 대신 package: 사용
    - avoid_dynamic_calls
    - close_sinks

    # 테스트
    - test_types_in_equals
```

### 2.4 팀별 규칙 예외 처리

```dart
// 파일 단위 무시
// ignore_for_file: avoid_print

// 한 줄 무시
print('Debug message');  // ignore: avoid_print

// 여러 줄 무시
// ignore: prefer_const_constructors
Widget build(BuildContext context) {
  return Container();
}

// 특정 규칙만 선택적 무시
// 단, 주석으로 이유 설명 필수
// ignore: avoid_dynamic_calls
// Legacy API 호환성을 위한 예외 케이스
final dynamic legacyApi = getLegacyService();
legacyApi.call();  // ignore: avoid_dynamic_calls
```

---

## 3. 프로젝트 구조 컨벤션

### 3.1 Feature-First 구조

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
├── core/
│   ├── di/
│   │   └── injection.dart
│   ├── errors/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── network/
│   │   └── dio_client.dart
│   └── utils/
│       ├── logger.dart
│       └── validators.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_dto.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       └── logout_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   └── signup_page.dart
│   │       └── widgets/
│   │           └── login_form.dart
│   └── home/
│       └── (동일 구조)
└── shared/
    ├── widgets/
    │   ├── loading_indicator.dart
    │   └── error_view.dart
    └── constants/
        └── app_constants.dart
```

### 3.2 파일 네이밍 규칙

| 파일 유형 | 네이밍 규칙 | 예시 |
|----------|------------|------|
| **Page/Screen** | `{name}_page.dart` 또는 `{name}_screen.dart` | `login_page.dart` |
| **Widget** | `{name}_widget.dart` 또는 `{name}.dart` | `user_card.dart` |
| **Bloc** | `{name}_bloc.dart` | `auth_bloc.dart` |
| **Event** | `{name}_event.dart` | `auth_event.dart` |
| **State** | `{name}_state.dart` | `auth_state.dart` |
| **Repository** | `{name}_repository.dart` | `auth_repository.dart` |
| **Repository Impl** | `{name}_repository_impl.dart` | `auth_repository_impl.dart` |
| **DataSource** | `{name}_datasource.dart` | `auth_remote_datasource.dart` |
| **UseCase** | `{action}_{entity}_usecase.dart` | `login_user_usecase.dart` |
| **Entity** | `{name}.dart` | `user.dart` |
| **DTO/Model** | `{name}_dto.dart` 또는 `{name}_model.dart` | `user_dto.dart` |

### 3.3 Import 순서

```dart
// 1. Dart 코어 라이브러리
import 'dart:async';
import 'dart:io';

// 2. Flutter 프레임워크
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. 서드파티 패키지
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// 4. 내부 패키지 (절대 경로)
import 'package:my_app/core/di/injection.dart';
import 'package:my_app/features/auth/domain/domain.dart';

// 5. 상대 경로 (같은 feature 내)
import '../bloc/auth_bloc.dart';
import 'login_form.dart';

// 빈 줄로 구분
// 코드 시작
```

---

## 4. Git 브랜치 전략

### 4.1 GitFlow 전략

```
main (production)
  ↑
develop (integration)
  ↑
  ├── feature/login-screen
  ├── feature/user-profile
  ├── bugfix/crash-on-logout
  └── hotfix/critical-payment-bug
```

**브랜치 유형:**

| 브랜치 | 목적 | 생성 위치 | 병합 대상 |
|--------|------|----------|----------|
| `main` | 프로덕션 배포 | - | - |
| `develop` | 개발 통합 | `main` | `main` |
| `feature/*` | 새 기능 개발 | `develop` | `develop` |
| `bugfix/*` | 버그 수정 | `develop` | `develop` |
| `hotfix/*` | 긴급 수정 | `main` | `main`, `develop` |
| `release/*` | 릴리즈 준비 | `develop` | `main`, `develop` |

### 4.2 브랜치 네이밍

```bash
# Feature
feature/login-screen
feature/push-notification

# Bugfix
bugfix/login-crash
bugfix/memory-leak

# Hotfix
hotfix/critical-security-patch
hotfix/payment-failure

# Release
release/1.2.0
release/2.0.0-rc1

# ❌ 피해야 할 네이밍
feature-login  # '/' 사용
FEATURE/LOGIN  # 소문자 사용
feature/add-login-screen-with-email-and-password  # 너무 김
```

### 4.3 브랜치 생성 및 작업 흐름

```bash
# 1. develop 브랜치에서 최신 코드 pull
git checkout develop
git pull origin develop

# 2. feature 브랜치 생성
git checkout -b feature/user-profile

# 3. 작업 후 커밋
git add .
git commit -m "feat: add user profile screen"

# 4. develop 최신화 (충돌 방지)
git checkout develop
git pull origin develop
git checkout feature/user-profile
git rebase develop

# 5. 원격 브랜치에 푸시
git push origin feature/user-profile

# 6. PR 생성 (GitHub/GitLab/Bitbucket)
# develop ← feature/user-profile

# 7. 리뷰 완료 후 Squash and Merge
# 브랜치 삭제
git branch -d feature/user-profile
git push origin --delete feature/user-profile
```

### 4.4 Trunk-Based Development (대안)

```
main (always deployable)
  ↑
  ├── short-lived-branch-1 (1-2일)
  ├── short-lived-branch-2
  └── short-lived-branch-3
```

**특징:**
- 짧은 수명의 브랜치 (1-2일)
- 빠른 통합 (하루 여러 번 merge)
- Feature Toggle로 미완성 기능 숨김
- CI/CD 파이프라인 필수

---

## 5. Commit 메시지 컨벤션

### 5.1 Conventional Commits

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type:**

| Type | 설명 | 예시 |
|------|------|------|
| `feat` | 새 기능 | `feat: add user login` |
| `fix` | 버그 수정 | `fix: resolve crash on logout` |
| `docs` | 문서 변경 | `docs: update README` |
| `style` | 코드 포맷 (로직 변경 없음) | `style: format code` |
| `refactor` | 리팩토링 | `refactor: extract login logic` |
| `test` | 테스트 추가/수정 | `test: add login bloc test` |
| `chore` | 빌드, 설정 변경 | `chore: update dependencies` |
| `perf` | 성능 개선 | `perf: optimize image loading` |
| `ci` | CI 설정 변경 | `ci: add GitHub Actions` |
| `build` | 빌드 시스템 변경 | `build: update Gradle` |

### 5.2 좋은 커밋 메시지 예시

```bash
# ✅ 좋은 예시
feat(auth): add email validation to login form

- Add regex pattern for email validation
- Show error message for invalid email format
- Add unit tests for validator

Closes #123

# ✅ 간단한 변경
fix: resolve null pointer exception in UserProfile

# ✅ Breaking Change
feat!: migrate to Bloc v9.0

BREAKING CHANGE: on<Event> syntax changed
See migration guide: docs/migration.md

# ❌ 나쁜 예시
update  # 무엇을 업데이트했는지 불명확
fixed bug  # 어떤 버그인지 설명 없음
WIP  # 작업 중인 코드는 커밋하지 않음
```

### 5.3 Commitlint 자동화

```yaml
# .commitlintrc.yaml
rules:
  type-enum:
    - 2
    - always
    - [feat, fix, docs, style, refactor, test, chore, perf, ci, build]
  type-case: [2, always, lowerCase]
  subject-empty: [2, never]
  subject-full-stop: [2, never, '.']
  subject-max-length: [2, always, 100]
```

---

## 6. Pull Request 가이드

### 6.1 PR 템플릿

```markdown
## 📋 변경 사항

### 작업 내용
- [ ] 로그인 화면 UI 구현
- [ ] 이메일 유효성 검사 추가
- [ ] Bloc 상태 관리 연동

### 변경 유형
- [ ] 새 기능 (feature)
- [ ] 버그 수정 (bugfix)
- [ ] 리팩토링 (refactor)
- [ ] 문서 (docs)
- [ ] 기타: ___________

## 🔗 관련 이슈

Closes #123
Related to #456

## 📸 스크린샷 (UI 변경 시)

| Before | After |
|--------|-------|
| (스크린샷) | (스크린샷) |

## ✅ 체크리스트

- [ ] 코드가 린트 규칙을 통과했나요?
- [ ] 테스트를 추가/수정했나요?
- [ ] 문서를 업데이트했나요?
- [ ] Breaking Change가 있나요?

## 🧪 테스트 방법

1. 앱 실행
2. 로그인 화면으로 이동
3. 잘못된 이메일 입력
4. 에러 메시지 확인

## 📝 리뷰어에게

(특별히 확인이 필요한 부분이나 고민되는 부분을 작성)
```

### 6.2 좋은 PR 작성법

#### DO (이렇게 하세요)

| 항목 | 설명 |
|------|------|
| **작은 PR** | 300줄 이하, 한 가지 목적 |
| **명확한 제목** | `feat(auth): add login screen with email validation` |
| **스크린샷** | UI 변경 시 Before/After 첨부 |
| **테스트 포함** | 새 기능은 테스트 필수 |
| **셀프 리뷰** | PR 생성 전 Diff 확인 |

#### DON'T (하지 마세요)

```markdown
# ❌ 나쁜 PR
- 제목: "Update"
- 설명: "코드 수정"
- 2000줄 변경
- 여러 기능 동시 작업
- 테스트 없음
```

### 6.3 PR 크기 가이드

| 크기 | 줄 수 | 리뷰 시간 | 전략 |
|------|------|-----------|------|
| **XS** | 0-50 | 5분 | 즉시 리뷰 |
| **S** | 51-200 | 15분 | 우선 리뷰 |
| **M** | 201-400 | 30분 | 하루 안에 리뷰 |
| **L** | 401-800 | 1시간 | 분할 고려 |
| **XL** | 800+ | 2시간+ | 반드시 분할 |

---

## 7. 코드 리뷰 체크리스트

### 7.1 리뷰어 체크리스트

#### 기능 (Functionality)
- [ ] 요구사항을 정확히 구현했는가?
- [ ] 엣지 케이스를 처리했는가?
- [ ] 에러 핸들링이 적절한가?

#### 코드 품질 (Code Quality)
- [ ] 코드가 읽기 쉬운가?
- [ ] 변수/함수 이름이 명확한가?
- [ ] 중복 코드가 없는가?
- [ ] 복잡한 로직에 주석이 있는가?

#### 아키텍처 (Architecture)
- [ ] Clean Architecture 계층을 준수하는가?
- [ ] SOLID 원칙을 따르는가?
- [ ] 의존성 방향이 올바른가?

#### 성능 (Performance)
- [ ] 불필요한 rebuild가 없는가?
- [ ] 메모리 누수가 없는가? (dispose 호출)
- [ ] 네트워크 호출이 최적화되었는가?

#### 테스트 (Testing)
- [ ] 테스트가 충분한가?
- [ ] 테스트가 실패하지 않는가?
- [ ] 엣지 케이스 테스트가 있는가?

#### 보안 (Security)
- [ ] API 키가 하드코딩되지 않았는가?
- [ ] 민감한 정보를 로그에 출력하지 않는가?
- [ ] 입력 검증이 충분한가?

### 7.2 리뷰 코멘트 작성법

```dart
// ❌ 나쁜 리뷰 코멘트
// "이거 이상한데요?"
// "다시 짜세요"

// ✅ 좋은 리뷰 코멘트
// "이 조건문이 복잡해 보입니다.
//  early return 패턴을 사용하면 가독성이 좋아질 것 같아요.
//  예시:
//  if (!isValid) return;
//  // 나머지 로직"

// ✅ 제안형 코멘트
// "Optional: 이 위젯을 별도 파일로 분리하는 것도 고려해보세요.
//  현재는 괜찮지만, 나중에 재사용할 가능성이 있어 보입니다."

// ✅ 질문형 코멘트
// "이 부분이 null이 될 수 있을까요?
//  null 체크를 추가하는 게 안전할 것 같은데, 어떻게 생각하시나요?"

// ✅ 칭찬 코멘트
// "이 에러 핸들링 방식이 깔끔하네요! 👍"
```

### 7.3 리뷰 레벨

| 레벨 | 의미 | 액션 |
|------|------|------|
| **🟢 Approve** | 승인 (변경 불필요) | Merge 가능 |
| **🟡 Comment** | 제안 (선택사항) | 작성자 판단 |
| **🟠 Request Changes** | 수정 필요 (권장) | 수정 후 재리뷰 |
| **🔴 Block** | 반드시 수정 | 수정 전까지 Merge 불가 |

---

## 8. 아키텍처 의사결정 기록 (ADR)

### 8.1 ADR이란?

Architecture Decision Record는 중요한 아키텍처 결정을 문서화하는 방법입니다.

**장점:**
- 의사결정 과정 투명화
- 새 팀원 온보딩 용이
- 과거 결정 이유 추적 가능

### 8.2 ADR 템플릿

```markdown
# ADR-001: Bloc 패턴 도입

## 상태 (Status)

Accepted (제안됨 / 승인됨 / 거부됨 / 대체됨)

## 컨텍스트 (Context)

우리 팀은 상태 관리 솔루션을 선택해야 합니다.
현재 앱은 StatefulWidget으로만 관리하고 있어 복잡도가 증가하고 있습니다.

고려한 옵션:
- Provider
- Bloc
- Riverpod
- GetX

## 결정 (Decision)

**Bloc** 패턴을 상태 관리 솔루션으로 채택합니다.

이유:
- 명확한 단방향 데이터 흐름
- 테스트 용이성 (bloc_test 패키지)
- 공식 문서와 커뮤니티 지원
- 팀원의 기존 경험

## 결과 (Consequences)

### 긍정적
- 상태 변화 추적 용이
- 비즈니스 로직과 UI 분리
- 테스트 커버리지 향상

### 부정적
- 초기 학습 곡선
- 보일러플레이트 코드 증가
- Freezed와 함께 사용 시 코드 생성 필요

## 대안 (Alternatives)

### Riverpod
- 장점: 컴파일 타임 안전성, Provider 개선
- 단점: 팀 경험 부족, 생태계가 Bloc보다 작음

### GetX
- 장점: 간결한 코드, 빠른 개발
- 단점: 너무 많은 기능, 테스트 어려움, 커뮤니티 논란

## 참고 자료

- [Bloc 공식 문서](https://bloclibrary.dev)
- 팀 내부 Bloc 스터디 자료: `docs/bloc_study.md`

---
Date: 2024-01-15
Author: @johndoe
Reviewers: @janedoe, @bobsmith
```

### 8.3 ADR 파일 관리

```
docs/
└── architecture/
    ├── adr/
    │   ├── 001-bloc-pattern.md
    │   ├── 002-clean-architecture.md
    │   ├── 003-dio-for-networking.md
    │   ├── 004-drift-for-database.md
    │   └── README.md
    └── diagrams/
        └── architecture-overview.png
```

---

## 9. 코드 소유권 (CODEOWNERS)

### 9.1 CODEOWNERS 파일

```bash
# .github/CODEOWNERS

# 전체 리포지토리 기본 소유자
* @team-leads

# 특정 디렉토리 소유자
/lib/features/auth/ @auth-team
/lib/features/payment/ @payment-team
/lib/core/network/ @backend-team

# 특정 파일 타입
*.dart @flutter-team
*.yaml @devops-team

# 문서
/docs/ @tech-writers
README.md @tech-writers

# CI/CD
/.github/workflows/ @devops-team
/android/ @android-team
/ios/ @ios-team

# 중요 파일 (2명 이상 승인 필요)
/lib/core/di/injection.dart @team-leads @senior-devs
```

### 9.2 팀 구조 예시

```
Flutter 팀 (10명)
├── Team Lead (1)
├── Senior Developers (2)
├── Auth Team (2)
├── Payment Team (2)
├── UI/UX Team (2)
└── DevOps (1)
```

---

## 10. 문서화 전략

### 10.1 필수 문서

```
프로젝트 루트/
├── README.md              # 프로젝트 개요, 시작 가이드
├── CONTRIBUTING.md        # 기여 가이드
├── CHANGELOG.md           # 버전별 변경 이력
├── docs/
│   ├── getting-started.md  # 개발 환경 설정
│   ├── architecture.md     # 아키텍처 설명
│   ├── coding-style.md     # 코드 스타일 가이드
│   ├── testing.md          # 테스트 전략
│   ├── deployment.md       # 배포 프로세스
│   └── troubleshooting.md  # 자주 발생하는 문제 해결
```

### 10.2 README 템플릿

```markdown
# My Flutter App

[![CI](https://github.com/org/repo/workflows/CI/badge.svg)](...)
[![codecov](https://codecov.io/gh/org/repo/branch/main/graph/badge.svg)](...)

간단한 앱 설명을 여기에 작성합니다.

## 📱 스크린샷

<img src="screenshots/home.png" width="300"> <img src="screenshots/profile.png" width="300">

## ✨ 주요 기능

- ✅ 사용자 인증 (로그인/회원가입)
- ✅ 실시간 채팅
- ✅ 푸시 알림

## 🏗️ 아키텍처

- Clean Architecture
- Bloc 패턴
- Drift (로컬 데이터베이스)

자세한 내용: [docs/architecture.md](docs/architecture.md)

## 🚀 시작하기

### 사전 요구사항

- Flutter 3.19.0 이상
- Dart 3.3.0 이상
- FVM (권장)

### 설치

\`\`\`bash
# 1. 리포지토리 클론
git clone https://github.com/org/my-flutter-app.git
cd my-flutter-app

# 2. FVM 설정 (선택)
fvm use 3.19.0

# 3. 의존성 설치
fvm flutter pub get

# 4. 코드 생성
fvm dart run build_runner build

# 5. 앱 실행
fvm flutter run
\`\`\`

### 환경 변수 설정

\`\`\`bash
cp .env.example .env
# .env 파일을 열어 API 키 등을 설정
\`\`\`

## 🧪 테스트

\`\`\`bash
# 전체 테스트
fvm flutter test

# 커버리지 포함
fvm flutter test --coverage
\`\`\`

## 📦 빌드

\`\`\`bash
# Android APK
fvm flutter build apk --release

# iOS IPA
fvm flutter build ipa --release
\`\`\`

## 🤝 기여하기

[CONTRIBUTING.md](CONTRIBUTING.md)를 참조하세요.

## 📄 라이선스

MIT License - [LICENSE](LICENSE) 파일 참조

## 👥 팀

- [@johndoe](https://github.com/johndoe) - Team Lead
- [@janedoe](https://github.com/janedoe) - Senior Developer
```

### 10.3 코드 내 문서화

```dart
/// 사용자 인증을 담당하는 Repository
///
/// 이 인터페이스는 데이터 레이어를 추상화하여
/// Domain 레이어에서 구체적인 구현에 의존하지 않도록 합니다.
///
/// 구현체:
/// - [AuthRepositoryImpl]: 실제 구현
/// - [MockAuthRepository]: 테스트용 Mock
abstract class AuthRepository {
  /// 사용자 로그인
  ///
  /// [email]과 [password]로 로그인을 시도합니다.
  ///
  /// 반환값:
  /// - Success: [User] 엔티티
  /// - Failure: [AuthFailure] (네트워크 오류, 인증 실패 등)
  ///
  /// 예시:
  /// ```dart
  /// final result = await authRepository.login(
  ///   'user@example.com',
  ///   'password123',
  /// );
  ///
  /// result.fold(
  ///   (failure) => print('Login failed: $failure'),
  ///   (user) => print('Welcome ${user.name}'),
  /// );
  /// ```
  Future<Either<AuthFailure, User>> login(String email, String password);
}
```

---

## 11. 온보딩 프로세스

### 11.1 신규 팀원 체크리스트

**Week 1: 환경 설정**
- [ ] 개발 환경 설정 (Flutter, Android Studio, Xcode)
- [ ] Git 계정 설정 및 SSH 키 등록
- [ ] 리포지토리 클론 및 빌드 성공
- [ ] Slack/Discord 등 커뮤니케이션 도구 가입
- [ ] Jira/Linear 등 이슈 트래커 접근 권한

**Week 2: 코드베이스 이해**
- [ ] README.md 및 docs/ 폴더 모든 문서 읽기
- [ ] 아키텍처 다이어그램 이해
- [ ] 주요 Feature 코드 리뷰
- [ ] 테스트 코드 실행 및 이해
- [ ] 첫 PR: 간단한 버그 수정 또는 문서 개선

**Week 3-4: 실전 작업**
- [ ] 첫 Feature 개발 (멘토 배정)
- [ ] 코드 리뷰 참여 (리뷰어 역할)
- [ ] 팀 회의 참석 (데일리 스탠드업, 스프린트 플래닝)

### 11.2 온보딩 문서

```markdown
# 신규 팀원 온보딩 가이드

## 👋 환영합니다!

### 1일차: 환경 설정

#### Flutter 설치
\`\`\`bash
# FVM 설치
brew tap leoafarias/fvm
brew install fvm

# Flutter 3.19.0 설치
fvm install 3.19.0
fvm use 3.19.0
\`\`\`

#### 프로젝트 클론
\`\`\`bash
git clone git@github.com:org/my-app.git
cd my-app
fvm flutter pub get
\`\`\`

#### 환경 변수 설정
1. `.env.example`을 `.env`로 복사
2. Slack에서 API 키 요청
3. `.env` 파일에 키 입력

### 2-3일차: 코드베이스 탐험

권장 읽기 순서:
1. `README.md`
2. `docs/architecture.md`
3. `lib/features/auth/` (가장 간단한 Feature)
4. `lib/core/` (공통 코드)

### 첫 주: 첫 PR

간단한 이슈를 배정받아 PR을 작성해보세요.
- Good First Issue 라벨이 붙은 이슈 추천
- 멘토: @senior-dev

### 질문하기

- 궁금한 점은 언제든지 Slack #dev 채널에 질문하세요!
- 1:1 멘토링: 매주 금요일 오후 2시
```

---

## 12. 기술 부채 관리

### 12.1 기술 부채 추적

```markdown
# Technical Debt Tracker

## 🔴 Critical (즉시 해결 필요)

### 1. 메모리 누수 (auth/login_page.dart)
- **문제**: Stream dispose 누락
- **영향**: 앱 크래시 가능성
- **담당자**: @johndoe
- **예상 시간**: 2시간
- **이슈**: #456

## 🟠 High (이번 스프린트)

### 2. 레거시 API 제거
- **문제**: v1 API 여전히 사용 중 (v2로 마이그레이션 필요)
- **영향**: 보안 취약점
- **담당자**: @backend-team
- **예상 시간**: 1주
- **이슈**: #234

## 🟡 Medium (다음 스프린트)

### 3. 테스트 커버리지 부족
- **문제**: payment 모듈 테스트 없음
- **영향**: 배포 시 불안정
- **담당자**: @payment-team
- **예상 시간**: 3일

## 🟢 Low (백로그)

### 4. 중복 코드 리팩토링
- **문제**: 여러 Feature에 중복된 날짜 포맷 로직
- **영향**: 유지보수성 저하
- **담당자**: TBD
- **예상 시간**: 1일
```

### 12.2 기술 부채 회의

**주기:** 월 1회
**참석자:** Tech Lead, Senior Developers

**의제:**
1. 새로 발견된 기술 부채 리뷰
2. 우선순위 재조정
3. 해결 계획 수립
4. 스프린트에 일정 % 할당 (예: 20%)

---

## 13. 팀 도구와 자동화

### 13.1 CI/CD 파이프라인

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: dart format --set-exit-if-changed .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v4

  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --debug
```

### 13.2 자동화 도구

| 도구 | 목적 | 설정 |
|------|------|------|
| **Husky** | Git Hooks | Pre-commit: lint, format |
| **Lefthook** | Git Hooks (대안) | Pre-push: test |
| **Danger** | PR 자동 리뷰 | 파일 크기, 테스트 누락 체크 |
| **Renovate** | 의존성 자동 업데이트 | 주간 자동 PR 생성 |
| **Codecov** | 커버리지 추적 | PR에 커버리지 리포트 |

### 13.3 Melos로 모노레포 관리

```yaml
# melos.yaml
name: my_flutter_app
repository: https://github.com/org/my-app

packages:
  - features/*
  - core/*

scripts:
  test:
    run: melos exec -- flutter test
    description: Run tests in all packages

  analyze:
    run: melos exec -- flutter analyze
    description: Analyze all packages

  format:
    run: melos exec -- dart format .
    description: Format all packages

  clean:
    run: melos exec -- flutter clean
    description: Clean all packages
```

---

## 14. 회고와 개선

### 14.1 스프린트 회고

**주기:** 스프린트 종료 시 (2주마다)
**형식:** Keep, Problem, Try

```markdown
# 스프린트 12 회고 (2024-01-01 ~ 2024-01-14)

## 😊 Keep (계속할 것)
- Daily Standup이 효과적이었음
- 페어 프로그래밍으로 버그 조기 발견
- Code Review 속도 빨라짐 (평균 4시간)

## 😞 Problem (문제점)
- 테스트 커버리지가 낮음 (50%)
- PR이 너무 커서 리뷰 어려움 (평균 500줄)
- 문서 업데이트 누락

## 💡 Try (시도할 것)
- 다음 스프린트: 테스트 작성 시간 20% 할당
- PR 크기 가이드라인 재공지 (300줄 이하)
- PR 템플릿에 문서 업데이트 체크리스트 추가

## 📊 메트릭
- 완료한 스토리 포인트: 42
- 평균 PR 리뷰 시간: 4시간
- 테스트 커버리지: 50% → 목표 70%
- 배포 횟수: 3회
```

### 14.2 개선 실험

```markdown
# 실험: 페어 프로그래밍 도입

## 가설
페어 프로그래밍을 도입하면 코드 품질이 향상되고
버그가 줄어들 것이다.

## 실험 방법
- 기간: 2주
- 대상: 복잡한 Feature 2개
- 측정: 버그 수, 코드 리뷰 시간, 팀 만족도

## 결과 (2주 후)
- ✅ 버그 50% 감소
- ✅ 코드 리뷰 시간 30% 감소
- ❌ 개발 속도 20% 감소
- 팀 만족도: 4.2/5

## 결론
복잡한 기능에는 페어 프로그래밍 권장
단순 작업은 개인 작업 유지
```

---

## 참고 자료

- [Dart Style Guide](https://dart.dev/guides/language/effective-dart)
- [Flutter Best Practices](https://docs.flutter.dev/development/best-practices)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Architecture Decision Records](https://adr.github.io/)

---

## 실습 과제

### 과제 1: 코드 컨벤션 적용

기존 레거시 코드를 팀 코드 컨벤션에 맞게 리팩토링하세요.

1. `analysis_options.yaml` 설정
2. 린트 규칙 통과하도록 수정
3. Import 순서 정리
4. 클래스 구조 순서 재배치

### 과제 2: PR 작성 연습

다음 시나리오로 PR을 작성하세요.

1. PR 템플릿 작성
2. 로그인 화면 UI 개선 (스크린샷 포함)
3. 관련 테스트 추가
4. 체크리스트 완성

### 과제 3: ADR 작성

팀에서 결정해야 할 아키텍처 이슈를 선택하고 ADR을 작성하세요.

예시 주제:
- 상태 관리 솔루션 선택
- 로컬 데이터베이스 선택
- 네트워킹 라이브러리 선택

---

## Self-Check

- [ ] Dart 공식 스타일 가이드의 주요 네이밍 규칙을 설명할 수 있는가?
- [ ] `analysis_options.yaml`에서 커스텀 린트 규칙을 설정할 수 있는가?
- [ ] Feature-First 프로젝트 구조와 각 계층의 역할을 설명할 수 있는가?
- [ ] GitFlow와 Trunk-Based Development의 차이를 설명하고 팀에 맞는 전략을 선택할 수 있는가?
- [ ] Conventional Commits 규칙을 따라 명확한 커밋 메시지를 작성할 수 있는가?
- [ ] 좋은 PR을 작성하기 위한 체크리스트를 설명하고 적용할 수 있는가?
- [ ] 효과적인 코드 리뷰 코멘트를 작성할 수 있는가? (제안형, 질문형)
- [ ] ADR(아키텍처 의사결정 기록)의 목적과 작성 방법을 설명할 수 있는가?
- [ ] CODEOWNERS 파일로 코드 소유권을 관리하는 방법을 설명할 수 있는가?
- [ ] 기술 부채를 추적하고 우선순위를 정하는 프로세스를 설명할 수 있는가?
