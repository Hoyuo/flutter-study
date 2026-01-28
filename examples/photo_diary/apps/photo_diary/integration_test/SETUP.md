# Integration Test Setup - 완료 사항 및 다음 단계

## 생성된 파일

### 1. 테스트 파일
- ✅ `integration_test/app_test.dart` - 앱 주요 플로우 테스트
- ✅ `integration_test/accessibility_test.dart` - 접근성 테스트
- ✅ `test_driver/integration_test.dart` - 테스트 드라이버

### 2. 문서
- ✅ `integration_test/README.md` - 실행 방법 및 가이드

### 3. 의존성
- ✅ `pubspec.yaml`에 `integration_test` 추가 완료

## 다음 단계: UI 구현 시 필요한 작업

### 1. 위젯에 Key 추가

테스트에서 참조하는 위젯에 Key를 추가해야 합니다.

#### 로그인 화면 (LoginPage)
```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            key: const Key('email_field'),  // ← 추가 필요
            decoration: InputDecoration(labelText: '이메일'),
          ),
          TextField(
            key: const Key('password_field'),  // ← 추가 필요
            decoration: InputDecoration(labelText: '비밀번호'),
            obscureText: true,
          ),
          ElevatedButton(
            key: const Key('login_button'),  // ← 추가 필요
            onPressed: _handleLogin,
            child: Text('로그인'),
          ),
        ],
      ),
    );
  }
}
```

#### 일기 작성 화면 (DiaryEditPage)
```dart
class DiaryEditPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: const Key('save_button'),  // ← 추가 필요
            icon: Icon(Icons.save),
            onPressed: _handleSave,
          ),
        ],
      ),
      body: Column(
        children: [
          TextField(
            key: const Key('title_field'),  // ← 추가 필요
            decoration: InputDecoration(labelText: '제목'),
          ),
          TextField(
            key: const Key('content_field'),  // ← 추가 필요
            decoration: InputDecoration(labelText: '내용'),
            maxLines: 10,
          ),
        ],
      ),
    );
  }
}
```

### 2. AccessibilityUtils 유틸리티 클래스 생성

`accessibility_test.dart`에서 사용하는 유틸리티 클래스를 생성해야 합니다.

위치: `lib/core/utils/accessibility_utils.dart`

```dart
import 'dart:ui';

class AccessibilityUtils {
  /// WCAG AA 기준 색상 대비율 체크 (최소 4.5:1)
  static bool meetsAAContrast(Color foreground, Color background) {
    final contrastRatio = _calculateContrastRatio(foreground, background);
    return contrastRatio >= 4.5;
  }

  /// WCAG AAA 기준 색상 대비율 체크 (최소 7:1)
  static bool meetsAAAContrast(Color foreground, Color background) {
    final contrastRatio = _calculateContrastRatio(foreground, background);
    return contrastRatio >= 7.0;
  }

  /// 두 색상 간의 대비율 계산
  static double _calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = _relativeLuminance(color1);
    final luminance2 = _relativeLuminance(color2);

    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// 색상의 상대 휘도 계산
  static double _relativeLuminance(Color color) {
    final r = _adjustChannel(color.red / 255.0);
    final g = _adjustChannel(color.green / 255.0);
    final b = _adjustChannel(color.blue / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// 채널 값 조정
  static double _adjustChannel(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    }
    return ((channel + 0.055) / 1.055).pow(2.4);
  }
}
```

이후 `accessibility_test.dart`에 import 추가:
```dart
import 'package:photo_diary/core/utils/accessibility_utils.dart';
```

### 3. Semantics 추가

모든 UI 요소에 적절한 Semantics를 추가해야 합니다.

```dart
// 버튼에 Semantics 추가
Semantics(
  label: '로그인',
  button: true,
  child: ElevatedButton(
    key: const Key('login_button'),
    onPressed: _handleLogin,
    child: Text('로그인'),
  ),
)

// 이미지에 Semantics 추가
Semantics(
  label: '일기 사진',
  image: true,
  child: Image.network(imageUrl),
)

// 텍스트 필드에 Semantics 추가
Semantics(
  label: '이메일 입력',
  textField: true,
  child: TextField(
    key: const Key('email_field'),
    decoration: InputDecoration(labelText: '이메일'),
  ),
)
```

### 4. 테스트에서 참조하는 위젯 타입

다음 위젯들이 실제로 구현되어야 합니다:
- `LoginPage` - 로그인 화면
- `DiaryListPage` - 일기 목록 화면
- `DiaryEditPage` - 일기 작성/수정 화면
- `DiaryCard` - 일기 카드 위젯

### 5. 테스트 실행 전 체크리스트

- [ ] Firebase 초기화 코드가 `main.dart`에 있는지 확인
- [ ] 테스트용 Firebase 프로젝트 설정 (또는 에뮬레이터 사용)
- [ ] 위 4개 위젯 모두 구현 완료
- [ ] 모든 Key 추가 완료
- [ ] AccessibilityUtils 클래스 생성
- [ ] Semantics 추가 완료

## 테스트 실행

모든 설정이 완료되면:

```bash
# 통합 테스트 실행
flutter test integration_test

# 또는 특정 테스트만 실행
flutter test integration_test/app_test.dart
flutter test integration_test/accessibility_test.dart
```

## 현재 상태

- ✅ 테스트 파일 구조 생성 완료
- ✅ pubspec.yaml 설정 완료
- ⏳ UI 구현 대기 중 (위젯에 Key 추가 필요)
- ⏳ AccessibilityUtils 유틸리티 클래스 생성 필요
- ⏳ Semantics 추가 필요

## 참고사항

이 테스트 파일들은 **템플릿**입니다. 실제 앱의 UI가 구현되면:
1. 위젯 타입과 Key가 실제 구현과 일치하는지 확인
2. 테스트 시나리오가 실제 앱 플로우와 일치하는지 확인
3. 필요에 따라 테스트를 수정 및 추가

테스트는 앱이 성장함에 따라 계속 업데이트되어야 합니다.
