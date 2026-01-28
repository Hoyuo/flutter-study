# Integration Tests

이 디렉토리에는 Photo Diary 앱의 통합 테스트가 포함되어 있습니다.

## 테스트 파일

- **app_test.dart**: 앱의 주요 플로우 테스트 (로그인, 일기 생성, 설정, 검색)
- **accessibility_test.dart**: 접근성 관련 테스트 (Semantics, 색상 대비, 키보드 네비게이션)

## 테스트 실행 방법

### 1. 모든 통합 테스트 실행

```bash
flutter test integration_test
```

### 2. 특정 테스트 파일 실행

```bash
# 앱 플로우 테스트
flutter test integration_test/app_test.dart

# 접근성 테스트
flutter test integration_test/accessibility_test.dart
```

### 3. 실제 기기 또는 에뮬레이터에서 실행

```bash
# Android
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart

# iOS
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d iPhone

# 특정 기기 지정
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d <device_id>
```

### 4. 기기 목록 확인

```bash
flutter devices
```

## 테스트 작성 가이드

### Key 기반 위젯 찾기

UI 요소에 Key를 추가하여 테스트에서 쉽게 찾을 수 있도록 합니다.

```dart
// 위젯에 Key 추가
TextField(
  key: const Key('email_field'),
  // ...
)

// 테스트에서 사용
await tester.enterText(
  find.byKey(const Key('email_field')),
  'test@test.com',
);
```

### pumpAndSettle 패턴

- `pumpAndSettle()`: 모든 애니메이션이 완료될 때까지 대기
- `pumpAndSettle(Duration)`: 지정된 시간 동안 대기 후 애니메이션 완료까지 대기

```dart
// 화면 전환 후 대기
await tester.tap(find.byKey(const Key('login_button')));
await tester.pumpAndSettle();

// 디바운스 대기
await tester.enterText(find.byType(TextField), '검색어');
await tester.pumpAndSettle(const Duration(milliseconds: 500));
```

### 한글 주석 사용

테스트 코드의 가독성을 높이기 위해 한글 주석을 적극 활용합니다.

```dart
testWidgets('로그인 플로우 테스트', (tester) async {
  // 로그인 화면으로 리다이렉트 확인
  expect(find.byType(LoginPage), findsOneWidget);

  // 이메일 입력
  await tester.enterText(
    find.byKey(const Key('email_field')),
    'test@test.com',
  );
});
```

## 주의사항

1. **Firebase 설정**: 통합 테스트 실행 전에 Firebase가 올바르게 설정되어 있어야 합니다.
2. **네트워크 상태**: 일부 테스트는 네트워크 연결이 필요할 수 있습니다.
3. **테스트 데이터**: 테스트용 계정과 데이터를 사용하세요.
4. **실행 시간**: 통합 테스트는 단위 테스트보다 실행 시간이 오래 걸립니다.

## 트러블슈팅

### 테스트가 타임아웃되는 경우

```dart
testWidgets('테스트 이름', (tester) async {
  // 타임아웃 시간 증가
}, timeout: const Timeout(Duration(minutes: 2)));
```

### 위젯을 찾을 수 없는 경우

```dart
// 위젯이 스크롤 영역에 있는 경우
await tester.scrollUntilVisible(
  find.byKey(const Key('target_widget')),
  500.0,
);
```

### 플랫폼별 동작 차이

```dart
if (Platform.isAndroid) {
  // Android 전용 테스트
} else if (Platform.isIOS) {
  // iOS 전용 테스트
}
```

## CI/CD 통합

GitHub Actions 등의 CI/CD 파이프라인에서 실행하려면:

```yaml
- name: Run integration tests
  run: flutter test integration_test
```

## 참고 자료

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Integration Test Package](https://pub.dev/packages/integration_test)
- [Flutter Driver](https://api.flutter.dev/flutter/flutter_driver/flutter_driver-library.html)
