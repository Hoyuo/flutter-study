# Bloc 단위 테스트 작성 완료 보고서

## 작업 완료 내역

### 1. 테스트 의존성 추가
모든 패키지의 `pubspec.yaml`에 다음 의존성을 추가했습니다:
```yaml
dev_dependencies:
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
```

적용된 패키지:
- ✅ auth
- ✅ diary
- ✅ weather
- ✅ settings

### 2. 테스트 파일 작성

#### AuthBloc 테스트
**위치**: `packages/auth/test/presentation/bloc/auth_bloc_test.dart`

**테스트 커버리지**:
- ✅ 초기 상태 확인
- ✅ 로그인 성공/실패
- ✅ 회원가입 성공/실패
- ✅ 로그아웃 성공/실패
- ✅ 인증 상태 확인 (사용자 있음/없음)

**Mock 클래스**:
- MockSignInWithEmailUseCase
- MockSignUpUseCase
- MockSignOutUseCase
- MockGetCurrentUserUseCase

#### DiaryBloc 테스트
**위치**: `packages/diary/test/presentation/bloc/diary_bloc_test.dart`

**테스트 커버리지**:
- ✅ 초기 상태 확인
- ✅ 일기 목록 로드 성공/실패
- ✅ 특정 일기 로드 성공
- ✅ 일기 생성 성공/실패
- ✅ 일기 수정 성공
- ✅ 일기 삭제 성공
- ✅ 키워드 검색 성공/빈 키워드 처리
- ✅ 페이지네이션 (추가 로드, 마지막 페이지 확인)
- ✅ 태그 필터링
- ✅ 필터 초기화 및 재로드

**Mock 클래스**:
- MockGetDiariesUseCase
- MockGetDiaryByIdUseCase
- MockCreateDiaryUseCase
- MockUpdateDiaryUseCase
- MockDeleteDiaryUseCase
- MockSearchDiariesUseCase

#### WeatherBloc 테스트
**위치**: `packages/weather/test/presentation/bloc/weather_bloc_test.dart`

**테스트 커버리지**:
- ✅ 초기 상태 확인
- ✅ 날씨 조회 성공
- ✅ 날씨 조회 실패 (네트워크 오류, API 오류)
- ✅ 날씨 새로고침 성공/실패
- ✅ 현재 날씨 정보 없을 때 새로고침 무시
- ✅ 날씨 정보 초기화
- ✅ 다양한 시나리오 (연속된 조회, 조회 후 초기화)

**Mock 클래스**:
- MockGetCurrentWeatherUseCase

#### SettingsBloc 테스트
**위치**: `packages/settings/test/presentation/bloc/settings_bloc_test.dart`

**테스트 커버리지**:
- ✅ 초기 상태 확인
- ✅ 설정 로드 성공/실패
- ✅ 테마 모드 업데이트 성공/실패/현재 설정 없음
- ✅ 언어 업데이트 성공
- ✅ 생체인증 토글 (활성화/비활성화)
- ✅ 푸시 알림 토글 (활성화/비활성화)
- ✅ 설정 초기화 성공/실패
- ✅ 다양한 시나리오 (연속된 설정 변경)

**Mock 클래스**:
- MockGetSettingsUseCase
- MockUpdateSettingsUseCase

## 현재 상태 및 해결 필요한 문제

### ⚠️ AuthBloc 패키지
**문제**: AuthBloc이 존재하지 않는 파일을 import하고 있습니다.

**오류**:
```
lib/presentation/bloc/auth_bloc.dart:2:8: Error: Error when reading 'lib/domain/usecases/sign_in_usecase.dart': No such file or directory
```

**해결 방법**: AuthBloc의 import를 다음과 같이 수정해야 합니다.
```dart
// 현재 (잘못됨)
import 'package:auth/domain/usecases/sign_in_usecase.dart';
import 'package:auth/domain/usecases/sign_up_usecase.dart';

// 수정 필요 (올바름)
import 'package:auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:auth/domain/usecases/sign_up_usecase.dart';

// 그리고 타입 이름도 변경
// SignInUseCase -> SignInWithEmailUseCase
```

**테스트 코드는 올바른 클래스를 사용하고 있으므로 AuthBloc만 수정하면 됩니다.**

### ⚠️ Core 패키지
**문제**: `local_auth` 패키지 의존성이 누락되었습니다.

**오류**:
```
Error: Couldn't resolve the package 'local_auth' in 'package:local_auth/local_auth.dart'.
```

**해결 방법**: `packages/core/pubspec.yaml`에 다음 의존성 추가:
```yaml
dependencies:
  local_auth: ^2.3.0
```

### ⚠️ Weather 패키지
**문제**: `retrofit`와 `retrofit_generator` 버전 호환성 문제

**오류**:
```
The type 'Parser' is not exhaustively matched by the switch cases since it doesn't match 'Parser.DartMappable'.
```

**해결 방법**: pubspec.yaml에서 retrofit 관련 패키지 버전을 맞춥니다:
```yaml
dependencies:
  retrofit: ^4.4.1

dev_dependencies:
  retrofit_generator: ^9.1.4
```

## 테스트 실행 방법

Freezed 코드를 먼저 생성해야 합니다:

```bash
# 각 패키지에서 실행
cd packages/auth
flutter pub run build_runner build --delete-conflicting-outputs

cd ../diary
flutter pub run build_runner build --delete-conflicting-outputs

cd ../weather
flutter pub run build_runner build --delete-conflicting-outputs

cd ../settings
flutter pub run build_runner build --delete-conflicting-outputs
```

테스트 실행:

```bash
# 특정 패키지 테스트
cd packages/auth
flutter test test/presentation/bloc/auth_bloc_test.dart

# 또는 모든 테스트 실행
flutter test
```

## 테스트 패턴 및 베스트 프랙티스

### 1. Mock 설정
```dart
// Mock 클래스 정의
class MockSignInWithEmailUseCase extends Mock
    implements SignInWithEmailUseCase {}

// setUp에서 초기화
setUp(() {
  mockUseCase = MockSignInWithEmailUseCase();
  bloc = AuthBloc(signInUseCase: mockUseCase);
});

// tearDown에서 정리
tearDown(() => bloc.close());
```

### 2. BlocTest 사용
```dart
blocTest<AuthBloc, AuthState>(
  '로그인 성공 시 authenticated 상태로 변경',
  build: () {
    // Mock 설정
    when(() => mockSignInUseCase(...)).thenAnswer(...);
    return bloc;
  },
  act: (bloc) => bloc.add(AuthEvent.signInRequested(...)),
  expect: () => [
    // 예상되는 상태 변화들
    isA<AuthState>().having(...),
    isA<AuthState>().having(...),
  ],
  verify: (_) {
    // usecase가 올바르게 호출되었는지 검증
    verify(() => mockSignInUseCase(...)).called(1);
  },
);
```

### 3. Fake 클래스 등록
```dart
// mocktail에서 any() matcher 사용 시 필요
class FakeGetDiariesParams extends Fake implements GetDiariesParams {}

setUpAll(() {
  registerFallbackValue(FakeGetDiariesParams());
});
```

## 다음 단계

1. **AuthBloc 수정**: import 경로 및 타입 이름 수정
2. **Core 패키지**: `local_auth` 의존성 추가
3. **Weather 패키지**: retrofit 버전 호환성 문제 해결
4. **테스트 실행**: 모든 패키지의 테스트가 통과하는지 확인
5. **통합 테스트**: 전체 앱의 통합 테스트 작성 고려

## 참고 자료

- [bloc_test 공식 문서](https://pub.dev/packages/bloc_test)
- [mocktail 공식 문서](https://pub.dev/packages/mocktail)
- [Freezed 공식 문서](https://pub.dev/packages/freezed)
- [Flutter 테스트 베스트 프랙티스](https://docs.flutter.dev/testing)
