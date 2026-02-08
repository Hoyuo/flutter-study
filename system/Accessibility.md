# Flutter 접근성(Accessibility) 가이드

> **마지막 업데이트**: 2026-02-08 | **Flutter 3.38** | **Dart 3.10**
> **난이도**: 중급 | **카테고리**: system
> **선행 학습**: [WidgetFundamentals](../fundamentals/WidgetFundamentals.md) | **예상 학습 시간**: 1.5h

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Semantics 위젯으로 스크린 리더 지원을 구현할 수 있다
> - 접근성 테스트를 수행하고 WCAG 기준을 충족할 수 있다
> - 다양한 사용자를 위한 포용적 UI를 설계할 수 있다

## 개요

접근성은 모든 사용자가 앱을 사용할 수 있도록 설계하는 것입니다. 시각 장애인, 청각 장애인, 운동 능력 제한 등 다양한 사용자를 지원해야 합니다. Flutter는 강력한 접근성 기능을 제공하여 포용적인 앱을 만들 수 있습니다.

### 접근성의 중요성

- **포용성**: 모든 사용자가 앱 기능을 이용할 수 있어야 합니다
- **법적 준수**: WCAG, ADA 등의 접근성 표준 준수 필요
- **사용성 향상**: 접근성 개선은 모든 사용자의 경험을 개선합니다
- **시장 확대**: 더 많은 사용자층에게 도달할 수 있습니다

### WCAG 2.1 가이드라인

WCAG(Web Content Accessibility Guidelines)는 모든 디지털 콘텐츠의 접근성 기준입니다.

| 원칙 | 설명 | 예시 |
|------|------|------|
| **인식 가능성** | 모든 사용자가 콘텐츠를 인식할 수 있어야 함 | 텍스트 대체, 색상 대비 충분 |
| **조작 가능성** | 모든 기능을 다양한 방식으로 조작할 수 있어야 함 | 터치 영역 크기, 키보드 지원 |
| **이해 가능성** | 콘텐츠와 조작이 명확해야 함 | 명확한 레이블, 일관된 UI |
| **견고성** | 다양한 보조 기술과 호환되어야 함 | 시맨틱 정보 제공 |

### 플랫폼별 접근성 서비스

#### Android - TalkBack

TalkBack은 Android의 내장 스크린 리더로 시각 장애인을 위해 화면 내용을 읽어줍니다.

```
- 활성화: 설정 > 접근성 > TalkBack
- 제스처: 1손가락 위아래 스와이프로 탐색
- 음성 피드백: 모든 UI 요소를 음성으로 안내
```

#### iOS - VoiceOver

VoiceOver는 iOS의 스크린 리더로 음성 안내를 제공합니다.

```
- 활성화: 설정 > 접근성 > VoiceOver
- 제스처: 1손가락 좌우 스와이프로 탐색
- 음성 피드백: 특성화된 발음 제공
```

---

## 시맨틱 접근성 설정

시맨틱(Semantics)은 UI 요소의 의미를 기계가 읽을 수 있게 하는 핵심입니다. Flutter의 Semantics 위젯을 사용하여 화면 리더가 올바르게 인식하도록 해야 합니다.

### Semantics 위젯 기본 사용

```dart
// lib/core/accessibility/semantic_widgets.dart
import 'package:flutter/material.dart';

/// 의미 있는 버튼
class SemanticButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool enabled;

  const SemanticButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tooltip,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,  // 버튼 역할 정의
      enabled: enabled,  // 활성 상태
      onTap: enabled ? onPressed : null,  // 활성 시만 탭 가능
      label: label,  // 스크린 리더용 라벨
      hint: tooltip,  // 추가 설명
      child: Tooltip(
        message: tooltip ?? label,
        child: GestureDetector(
          onTap: enabled ? onPressed : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: enabled ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 사용 예시
SemanticButton(
  label: '저장',
  tooltip: '모든 변경사항을 저장합니다',
  onPressed: () => save(),
)
```

### MergeSemantics와 ExcludeSemantics

중복된 시맨틱 정보를 제거하거나 병합해야 할 경우가 있습니다.

```dart
/// MergeSemantics: 자식의 시맨틱을 부모와 병합
class CardWithSemantics extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const CardWithSemantics({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: GestureDetector(
        onTap: onTap,
        child: Semantics(
          button: true,
          enabled: true,
          onTap: onTap,
          label: title,
          hint: description,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(description),
                  const SizedBox(height: 16),
                  // 내부 버튼들의 시맨틱은 유지됨
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('상세보기'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ExcludeSemantics: 불필요한 시맨틱 정보 제외
class ImageWithCaption extends StatelessWidget {
  final String imagePath;
  final String semanticLabel;

  const ImageWithCaption({
    super.key,
    required this.imagePath,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          image: true,
          label: semanticLabel,
          child: Image.asset(imagePath),
        ),
        // 캡션은 스크린 리더에서 제외 (이미지 라벨로 충분)
        ExcludeSemantics(
          child: Text(
            semanticLabel,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
```

### 커스텀 시맨틱 액션

사용자 정의 작업을 시맨틱으로 표현할 수 있습니다.

```dart
import 'package:flutter/services.dart';

/// 커스텀 액션이 있는 슬라이더
class AccessibleSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String label;
  final double min;
  final double max;

  const AccessibleSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.min = 0,
    this.max = 100,
  });

  @override
  State<AccessibleSlider> createState() => _AccessibleSliderState();
}

class _AccessibleSliderState extends State<AccessibleSlider> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _increase() {
    final newValue = (widget.value + 5).clamp(widget.min, widget.max);
    widget.onChanged(newValue);
  }

  void _decrease() {
    final newValue = (widget.value - 5).clamp(widget.min, widget.max);
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      label: widget.label,
      onIncrease: widget.value < widget.max ? _increase : null,
      onDecrease: widget.value > widget.min ? _decrease : null,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _increase();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _decrease();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Slider(
          value: widget.value,
          min: widget.min,
          max: widget.max,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
```

---

## 스크린 리더 지원

스크린 리더 사용자가 앱을 쉽게 사용할 수 있도록 텍스트 정보와 읽기 순서를 올바르게 제공해야 합니다.

### 라벨링 전략

모든 UI 요소에 명확한 라벨을 제공해야 합니다.

```dart
/// 라벨이 있는 입력 필드
class LabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 시각적 라벨
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Semantics(
          textField: true,
          enabled: true,
          label: label,
          hint: hint,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              helperText: errorText != null ? null : '선택사항',
              errorText: errorText,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.all(12),
            ),
            semanticCounterText: errorText,  // 에러 메시지도 스크린 리더로 읽음
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,  // 동적 콘텐츠 알림
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// 사용 예시
LabeledTextField(
  label: '이메일',
  hint: 'your@email.com',
  controller: _emailController,
  errorText: _emailError,
)
```

### 읽기 순서 제어

Semantics.sortKey를 사용하여 스크린 리더가 읽는 순서를 제어합니다.

```dart
/// 읽기 순서가 정의된 폼
class AccessibleForm extends StatelessWidget {
  const AccessibleForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 첫 번째 읽음
        Semantics(
          sortKey: const OrdinalSortKey(0),
          child: TextFormField(
            decoration: const InputDecoration(labelText: '이름'),
          ),
        ),
        const SizedBox(height: 16),
        // 두 번째 읽음
        Semantics(
          sortKey: const OrdinalSortKey(1),
          child: TextFormField(
            decoration: const InputDecoration(labelText: '이메일'),
          ),
        ),
        const SizedBox(height: 16),
        // 세 번째 읽음
        Semantics(
          sortKey: const OrdinalSortKey(2),
          child: ElevatedButton(
            onPressed: () {},
            child: const Text('제출'),
          ),
        ),
      ],
    );
  }
}
```

### 동적 콘텐츠 알림

동적으로 변경되는 콘텐츠는 스크린 리더 사용자에게 즉시 알려야 합니다.

```dart
/// 로딩 상태를 알리는 위젯
class AccessibleLoadingIndicator extends StatelessWidget {
  final bool isLoading;
  final String loadingMessage;

  const AccessibleLoadingIndicator({
    super.key,
    required this.isLoading,
    required this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,  // 즉시 알림
      enabled: isLoading,
      label: isLoading ? loadingMessage : '로드 완료',
      child: isLoading
          ? const SizedBox(
              width: 50,
              height: 50,
              child: const CircularProgressIndicator(),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// 검색 결과 알림
class SearchResultsAnnouncement extends StatefulWidget {
  final List<String> results;

  const SearchResultsAnnouncement({
    super.key,
    required this.results,
  });

  @override
  State<SearchResultsAnnouncement> createState() =>
      _SearchResultsAnnouncementState();
}

class _SearchResultsAnnouncementState extends State<SearchResultsAnnouncement> {
  @override
  void didUpdateWidget(SearchResultsAnnouncement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.results.length != oldWidget.results.length) {
      // 결과 개수 변경 시 즉시 알림
      SemanticsService.announce(
        '${widget.results.length}개의 결과를 찾았습니다',
        textDirection: TextDirection.ltr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '${widget.results.length}개의 검색 결과',
      child: ListView.builder(
        itemCount: widget.results.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(widget.results[index]),
        ),
      ),
    );
  }
}
```

---

## 시각적 접근성

색상, 글꼴, 대비를 통해 시각 장애인도 앱을 사용할 수 있어야 합니다.

### 색상 대비 확보

텍스트와 배경의 색상 대비는 WCAG AA 기준 최소 4.5:1 이상이어야 합니다.

```dart
import 'dart:math';

/// 색상 대비를 확인하는 유틸리티
class AccessibilityColorUtils {
  /// 상대 휘도 계산 (WCAG)
  static double _getRelativeLuminance(Color color) {
    final r = _getLinearRGB(color.r);
    final g = _getLinearRGB(color.g);
    final b = _getLinearRGB(color.b);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _getLinearRGB(double value) {
    if (value <= 0.03928) {
      return value / 12.92;
    }
    return pow((value + 0.055) / 1.055, 2.0).toDouble();
  }

  /// 색상 대비 비율 계산
  static double getContrastRatio(Color foreground, Color background) {
    final l1 = _getRelativeLuminance(foreground);
    final l2 = _getRelativeLuminance(background);

    final lighter = max(l1, l2);
    final darker = min(l1, l2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// WCAG AA 기준 확인 (4.5:1)
  static bool meetsAAContrast(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 4.5;
  }

  /// WCAG AAA 기준 확인 (7:1)
  static bool meetsAAAContrast(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 7.0;
  }
}

/// 접근성이 보장된 텍스트
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color foreground;
  final Color background;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.foreground = Colors.black,
    this.background = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    assert(
      AccessibilityColorUtils.meetsAAContrast(foreground, background),
      'Color contrast ratio does not meet WCAG AA standards (4.5:1)',
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(color: foreground),
    );
  }
}
```

### 폰트 크기 조절 (TextScaler API)

사용자가 기기에서 설정한 텍스트 크기를 존중해야 합니다. Flutter 3.16부터 `textScaleFactor`가 deprecated되고 `TextScaler` API를 사용합니다.

```dart
/// 사용자의 텍스트 크기 설정을 존중하는 텍스트 (Flutter 3.16+)
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final double? maxScale;  // 최대 배율 (너무 크면 레이아웃 깨짐)

  const ResponsiveText(
    this.text, {
    super.key,
    this.baseStyle,
    this.maxScale = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    // Flutter 3.16+: MediaQuery.textScalerOf() 사용
    final textScaler = MediaQuery.textScalerOf(context);

    // TextScaler를 직접 사용하여 폰트 크기 조정
    final baseFontSize = baseStyle?.fontSize ?? 14.0;

    // maxScale 제한이 있으면 clamp된 TextScaler 생성
    final effectiveScaler = maxScale != null
        ? textScaler.clamp(maxScaleFactor: maxScale!)
        : textScaler;

    return Text(
      text,
      style: (baseStyle ?? const TextStyle()).copyWith(
        fontSize: baseFontSize,
      ),
      // Text 위젯이 자동으로 textScaler를 적용
      textScaler: effectiveScaler,
    );
  }
}

/// 텍스트 크기 조절을 고려한 레이아웃
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // Flutter 3.16+: MediaQuery.textScalerOf() 사용
    final textScaler = MediaQuery.textScalerOf(context);

    // scale 함수로 배율 확인 (14pt 기준)
    final scaledSize = textScaler.scale(14.0);
    final isLargeText = scaledSize > 18.0;  // 1.3배 이상

    return isLargeText
        ? Column(
            children: [
              Container(
                color: Colors.blue,
                padding: const EdgeInsets.all(16),
                child: const Text('콘텐츠 1'),
              ),
              Container(
                color: Colors.green,
                padding: const EdgeInsets.all(16),
                child: const Text('콘텐츠 2'),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: Container(
                  color: Colors.blue,
                  padding: const EdgeInsets.all(16),
                  child: const Text('콘텐츠 1'),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.green,
                  padding: const EdgeInsets.all(16),
                  child: const Text('콘텐츠 2'),
                ),
              ),
            ],
          );
  }
}

/// MediaQueryData를 사용하여 텍스트 크기 제한하기
class ClampedTextScaleExample extends StatelessWidget {
  const ClampedTextScaleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      // 텍스트 크기를 최대 1.5배로 제한
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(context).clamp(
          maxScaleFactor: 1.5,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('텍스트 크기 제한'),
        ),
        body: const Center(
          child: Text(
            '이 텍스트는 최대 1.5배까지만 커집니다',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
```

### 고대비 모드 지원

일부 사용자는 고대비 모드를 사용하므로 이를 지원해야 합니다.

```dart
/// 고대비 모드 지원하는 테마 구성
class AccessibleTheme {
  static ThemeData getTheme(BuildContext context, {bool highContrast = false}) {
    if (highContrast) {
      return ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.black,
        primaryColorLight: Colors.grey[400],
        primaryColorDark: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.black, fontSize: 14),
          labelLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      );
    }

    // 표준 테마
    return ThemeData.light();
  }
}

/// 고대비 모드를 고려한 아이콘
class AccessibleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final String semanticLabel;

  const AccessibleIcon(
    this.icon, {
    super.key,
    this.size = 24,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.of(context).highContrast;

    return Semantics(
      image: true,
      label: semanticLabel,
      child: Icon(
        icon,
        size: size,
        color: highContrast ? Colors.black : null,
      ),
    );
  }
}
```

### Flutter 3.16+ TextScaler 마이그레이션 가이드

Flutter 3.16부터 `textScaleFactor`가 deprecated되었습니다. 다음과 같이 마이그레이션하세요.

#### 변경 전 (Deprecated)

```dart
// ❌ Deprecated: textScaleFactorOf
final textScaleFactor = MediaQuery.textScaleFactorOf(context);
final fontSize = 14.0 * textScaleFactor;

// ❌ Deprecated: MediaQueryData.textScaleFactor
final data = MediaQuery.of(context);
final scaleFactor = data.textScaleFactor;

// ❌ Deprecated: copyWith에서 textScaleFactor 사용
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaleFactor: 1.5,  // deprecated
  ),
  child: child,
);
```

#### 변경 후 (Flutter 3.16+)

```dart
// ✅ 권장: textScalerOf 사용
final textScaler = MediaQuery.textScalerOf(context);
final fontSize = textScaler.scale(14.0);

// ✅ 권장: MediaQueryData.textScaler
final data = MediaQuery.of(context);
final textScaler = data.textScaler;

// ✅ 권장: copyWith에서 textScaler 사용
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: TextScaler.linear(1.5),
  ),
  child: child,
);

// ✅ 권장: Text 위젯에 직접 textScaler 전달
Text(
  'Hello',
  style: TextStyle(fontSize: 14),
  textScaler: TextScaler.linear(1.5),
);

// ✅ 권장: 최대/최소 크기 제한
final clampedScaler = textScaler.clamp(
  minScaleFactor: 0.8,
  maxScaleFactor: 2.0,
);
```

#### TextScaler API 주요 메서드

```dart
/// TextScaler 인터페이스
abstract class TextScaler {
  // 선형 배율 생성
  factory TextScaler.linear(double scaleFactor);

  // 배율 없음 (1.0)
  static const TextScaler noScaling = _LinearTextScaler(1.0);

  // 폰트 크기 조정
  double scale(double fontSize);

  // 최대/최소 제한
  TextScaler clamp({
    double minScaleFactor = 0.0,
    double maxScaleFactor = double.infinity,
  });
}

/// 사용 예시
void textScalerExamples(BuildContext context) {
  final scaler = MediaQuery.textScalerOf(context);

  // 1. 배율 적용
  final scaled14 = scaler.scale(14.0);  // 14 * 사용자 설정 배율

  // 2. 제한된 배율
  final clamped = scaler.clamp(maxScaleFactor: 1.5);
  final limited = clamped.scale(20.0);  // 최대 30.0 (20 * 1.5)

  // 3. 고정 배율
  final fixed = TextScaler.linear(2.0);
  final doubled = fixed.scale(16.0);  // 항상 32.0

  // 4. 배율 비활성화
  final noScale = TextScaler.noScaling;
  final unchanged = noScale.scale(18.0);  // 항상 18.0
}
```

#### 실전 마이그레이션 패턴

```dart
// 패턴 1: 조건부 레이아웃 변경
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    // ❌ 이전 방식
    // final isLarge = textScaler.textScaleFactor > 1.5;

    // ✅ 새 방식: 기준 크기로 판단
    final baseSize = 16.0;
    final scaledSize = textScaler.scale(baseSize);
    final isLarge = scaledSize > baseSize * 1.5;

    return isLarge ? _buildVertical() : _buildHorizontal();
  }

  Widget _buildVertical() => Column(children: []);
  Widget _buildHorizontal() => Row(children: []);
}

// 패턴 2: 커스텀 위젯에서 텍스트 크기 제한
class LimitedTextScale extends StatelessWidget {
  final Widget child;

  const LimitedTextScale({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        // ✅ 텍스트 크기를 0.8~2.0 범위로 제한
        textScaler: MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 0.8,
          maxScaleFactor: 2.0,
        ),
      ),
      child: child,
    );
  }
}

// 패턴 3: 동적 간격 조정
class ScaledSpacing extends StatelessWidget {
  const ScaledSpacing({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    // 텍스트 크기에 비례하여 간격 조정
    final baseSpacing = 8.0;
    final spacing = textScaler.scale(baseSpacing);

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: const Text('확장 가능한 콘텐츠'),
    );
  }
}
```

---

## 모터 접근성

운동 능력이 제한된 사용자도 앱을 사용할 수 있도록 터치 영역을 크게 하고 대체 수단을 제공해야 합니다.

### 터치 영역 최소 크기 (48x48 dp)

```dart
/// 접근 가능한 터치 영역을 가진 버튼
class AccessibleButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final double? width;
  final double? height;

  const AccessibleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 56,  // 최소 48 dp
    this.height = 56,  // 최소 48 dp
  });

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton> {
  @override
  Widget build(BuildContext context) {
    assert(
      (widget.width ?? 0) >= 48 && (widget.height ?? 0) >= 48,
      'Touch target size should be at least 48x48 dp for accessibility',
    );

    return Semantics(
      button: true,
      onTap: widget.onPressed,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// 버튼들 사이에 충분한 간격
class AccessibleButtonRow extends StatelessWidget {
  final List<String> labels;
  final List<VoidCallback> callbacks;

  const AccessibleButtonRow({
    super.key,
    required this.labels,
    required this.callbacks,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int i = 0; i < labels.length; i++)
          SizedBox(
            width: 48,
            height: 48,
            child: AccessibleButton(
              label: labels[i],
              onPressed: callbacks[i],
              width: 48,
              height: 48,
            ),
          ),
      ],
    );
  }
}
```

### 제스처 대안 제공

복잡한 제스처 대신 기본적인 탭과 키보드 입력으로도 조작할 수 있어야 합니다.

```dart
/// 드래그 또는 버튼으로 조절 가능한 슬라이더
class AccessibleAdjustableSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final String label;

  const AccessibleAdjustableSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.min = 0,
    this.max = 100,
  });

  @override
  State<AccessibleAdjustableSlider> createState() =>
      _AccessibleAdjustableSliderState();
}

class _AccessibleAdjustableSliderState extends State<AccessibleAdjustableSlider> {
  void _increase() {
    final newValue = (widget.value + 5).clamp(widget.min, widget.max);
    widget.onChanged(newValue);
  }

  void _decrease() {
    final newValue = (widget.value - 5).clamp(widget.min, widget.max);
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            widget.label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 드래그로 조절
          Slider(
            value: widget.value,
            min: widget.min,
            max: widget.max,
            onChanged: widget.onChanged,
          ),
          const SizedBox(height: 16),
          // 버튼으로도 조절 (대체 수단)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AccessibleButton(
                label: '-',
                onPressed: _decrease,
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: Text(
                  widget.value.toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 16),
              AccessibleButton(
                label: '+',
                onPressed: _increase,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 키보드 내비게이션

모든 기능을 키보드로도 접근할 수 있어야 합니다.

```dart
/// 키보드 내비게이션을 지원하는 메뉴
class KeyboardNavigableMenu extends StatefulWidget {
  final List<String> items;
  final ValueChanged<int> onSelected;

  const KeyboardNavigableMenu({
    super.key,
    required this.items,
    required this.onSelected,
  });

  @override
  State<KeyboardNavigableMenu> createState() => _KeyboardNavigableMenuState();
}

class _KeyboardNavigableMenuState extends State<KeyboardNavigableMenu> {
  late List<FocusNode> _focusNodes;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(
      widget.items.length,
      (index) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _selectItem(int index) {
    setState(() => _selectedIndex = index);
    widget.onSelected(index);
    _focusNodes[index].requestFocus();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        final nextIndex = (_selectedIndex + 1) % widget.items.length;
        _selectItem(nextIndex);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        final prevIndex =
            (_selectedIndex - 1 + widget.items.length) % widget.items.length;
        _selectItem(prevIndex);
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        widget.onSelected(_selectedIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.ignored;
      },
      child: Column(
        children: [
          for (int i = 0; i < widget.items.length; i++)
            Focus(
              focusNode: _focusNodes[i],
              onKeyEvent: (node, event) {
                _handleKeyEvent(event);
                return KeyEventResult.handled;
              },
              child: GestureDetector(
                onTap: () => _selectItem(i),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  color: _selectedIndex == i ? Colors.blue : Colors.grey[200],
                  alignment: Alignment.center,
                  child: Text(
                    widget.items[i],
                    style: TextStyle(
                      color: _selectedIndex == i ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## 접근성 테스트

앱의 접근성을 효과적으로 테스트해야 합니다.

### Flutter 접근성 검사기 (Semantic Debugger)

```dart
/// main.dart에서 Semantic Debugger 활성화
void main() {
  // 개발 중에만 활성화
  if (kDebugMode) {
    debugPrintSemantics = true;  // 시맨틱 트리 출력
  }

  runApp(const MyApp());
}

// 사용:
// flutter run과 'S' 키 누르면 시맨틱 트리 출력
```

### 자동화 테스트

```dart
// test/accessibility_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Accessibility Tests', () {
    testWidgets('Button has semantic label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Semantics(
              button: true,
              label: '저장',
              onTap: () {},
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('저장'),
              ),
            ),
          ),
        ),
      );

      // Semantics가 올바르게 설정되었는지 확인
      expect(
        find.bySemanticsLabel('저장'),
        findsOneWidget,
      );
    });

    testWidgets('Touch target size is at least 48x48', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 48,
              height: 48,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('버튼'),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(ElevatedButton));
      expect(size.width >= 48 && size.height >= 48, true);
    });

    testWidgets('Text color contrast meets WCAG AA', (WidgetTester tester) async {
      const foreground = Color.fromARGB(255, 0, 0, 0);  // 검정
      const background = Color.fromARGB(255, 255, 255, 255);  // 흰색

      final contrast = AccessibilityColorUtils.getContrastRatio(
        foreground,
        background,
      );

      expect(contrast >= 4.5, true);  // WCAG AA
    });

    testWidgets('TextField has semantic label', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Semantics(
              textField: true,
              label: '이메일 입력',
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '이메일',
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('이메일 입력'),
        findsOneWidget,
      );

      controller.dispose();
    });
  });
}
```

### 수동 테스트 체크리스트

```dart
// accessibility_checklist.md
/*

## 시각적 접근성
- [ ] 모든 텍스트와 배경의 색상 대비가 4.5:1 이상
- [ ] 색상만으로 정보 전달하지 않음 (아이콘/텍스트도 포함)
- [ ] 폰트 크기를 1.5배로 확대해도 UI가 정상 작동
- [ ] 스크린 리더로 읽을 때 명확한 정보 제공

## 모터 접근성
- [ ] 모든 터치 타겟이 최소 48x48 dp
- [ ] 터치 타겟 간 최소 8 dp 간격
- [ ] 키보드만으로 모든 기능 접근 가능
- [ ] 버튼과 폼 필드에 포커스 표시 명확

## 스크린 리더 지원
- [ ] 모든 버튼에 의미 있는 라벨 있음
- [ ] 이미지에 대체 텍스트 있음
- [ ] 폼 필드와 레이블이 연결됨
- [ ] 동적 콘텐츠 변경 시 스크린 리더 알림

## 플랫폼별 테스트
- [ ] iOS: VoiceOver로 완전히 탐색 가능
- [ ] Android: TalkBack으로 완전히 탐색 가능
- [ ] 시스템 텍스트 크기 변경 시 레이아웃 유지

*/
```

---

## 일반적인 위젯의 접근성

### Button

```dart
/// 접근성이 있는 버튼
class AccessibleElevatedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final String? tooltip;

  const AccessibleElevatedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? label,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        onTap: onPressed,
        label: label,
        hint: tooltip,
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }
}
```

### TextField

```dart
/// 접근성이 있는 텍스트 필드
class AccessibleTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? helperText;
  final String? errorText;
  final TextInputType keyboardType;

  const AccessibleTextField({
    super.key,
    required this.label,
    required this.controller,
    this.helperText,
    this.errorText,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Semantics(
          textField: true,
          enabled: true,
          label: label,
          hint: helperText,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: helperText,
              errorText: errorText,
              helperText: errorText != null ? null : helperText,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (errorText != null)
          Semantics(
            liveRegion: true,
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
```

### Image

```dart
/// 접근성이 있는 이미지
class AccessibleImage extends StatelessWidget {
  final String imagePath;
  final String semanticLabel;
  final double? width;
  final double? height;

  const AccessibleImage({
    super.key,
    required this.imagePath,
    required this.semanticLabel,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      enabled: true,
      child: Image.asset(
        imagePath,
        width: width,
        height: height,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
```

### 리스트와 그리드

```dart
/// 접근성이 있는 리스트
class AccessibleListView extends StatelessWidget {
  final List<String> items;
  final ValueChanged<int> onItemTap;

  const AccessibleListView({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '리스트',
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Semantics(
            button: true,
            enabled: true,
            onTap: () => onItemTap(index),
            label: items[index],
            customSemanticsActions: {
              CustomSemanticsAction(label: '활성화'): () {
                onItemTap(index);
              },
            },
            child: GestureDetector(
              onTap: () => onItemTap(index),
              child: Container(
                height: 56,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: Text(items[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 접근성이 있는 그리드
class AccessibleGridView extends StatelessWidget {
  final List<String> items;
  final ValueChanged<int> onItemTap;

  const AccessibleGridView({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '그리드',
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Semantics(
            button: true,
            enabled: true,
            onTap: () => onItemTap(index),
            label: items[index],
            child: GestureDetector(
              onTap: () => onItemTap(index),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(items[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### 다이얼로그와 바텀시트

```dart
/// 접근성이 있는 다이얼로그
class AccessibleDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AccessibleDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Semantics(
        customSemanticsActions: {
          CustomSemanticsAction(label: '닫기'): () {
            Navigator.pop(context);
          },
        },
        child: Text(title),
      ),
      content: Semantics(
        liveRegion: true,
        child: Text(message),
      ),
      actions: [
        if (cancelLabel != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onCancel?.call();
            },
            child: Semantics(
              button: true,
              enabled: true,
              onTap: () {
                Navigator.pop(context);
                onCancel?.call();
              },
              label: cancelLabel,
              child: Text(cancelLabel!),
            ),
          ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Semantics(
            button: true,
            enabled: true,
            onTap: () {
              Navigator.pop(context);
              onConfirm();
            },
            label: confirmLabel,
            child: Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}

/// 접근성이 있는 바텀시트
Future<void> showAccessibleBottomSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  required ValueChanged<int> onSelected,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                container: true,
                label: title,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  return Semantics(
                    button: true,
                    enabled: true,
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(index);
                    },
                    label: options[index],
                    child: ListTile(
                      title: Text(options[index]),
                      onTap: () {
                        Navigator.pop(context);
                        onSelected(index);
                      },
                      minLeadingWidth: 0,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
```

---

## 체크리스트

### 시맨틱 설정
- [ ] 모든 상호작용 요소에 Semantics 위젯 추가
- [ ] 버튼에 label 정의
- [ ] 이미지에 semanticLabel 정의
- [ ] 폼 필드에 라벨 연결
- [ ] MergeSemantics/ExcludeSemantics 적절히 사용

### 시각적 접근성
- [ ] 색상 대비 4.5:1 이상 (WCAG AA)
- [ ] 색상만으로 정보 전달하지 않음
- [ ] 폰트 크기 조절 (MediaQuery.textScalerOf + TextScaler API)
- [ ] 고대비 모드 지원
- [ ] Flutter 3.16+ TextScaler API로 마이그레이션 완료

### 모터 접근성
- [ ] 터치 영역 최소 48x48 dp
- [ ] 터치 타겟 간 최소 8 dp 간격
- [ ] 키보드 내비게이션 지원
- [ ] 복잡한 제스처 대신 기본 탭 지원

### 스크린 리더 지원
- [ ] 동적 콘텐츠 변경 시 SemanticsService.announce() 호출
- [ ] 읽기 순서 올바르게 설정 (sortKey)
- [ ] liveRegion으로 중요한 업데이트 알림
- [ ] 충분한 시간 읽음이 가능하도록

### 테스트
- [ ] VoiceOver (iOS) 전체 탐색 테스트
- [ ] TalkBack (Android) 전체 탐색 테스트
- [ ] 접근성 자동화 테스트 작성
- [ ] 수동 테스트 체크리스트 완료
- [ ] 높은 텍스트 크기에서 레이아웃 테스트

### 문서화
- [ ] 접근성 관련 설정 문서화
- [ ] 접근성 테스트 방법 문서화
- [ ] 팀 접근성 가이드라인 공유

---

## 실습 과제

### 과제 1: 스크린 리더 지원
기존 화면에 Semantics 위젯을 추가하여 TalkBack(Android)/VoiceOver(iOS)로 모든 요소를 탐색할 수 있도록 개선하세요.

### 과제 2: 색상 대비 검증
앱의 주요 화면에서 WCAG AA 기준(4.5:1) 이상의 색상 대비를 확인하고 미달 항목을 수정하세요.

## Self-Check

- [ ] 모든 인터랙티브 요소에 Semantics 라벨이 있는가?
- [ ] 스크린 리더로 앱을 탐색하며 테스트했는가?
- [ ] 최소 터치 타겟 크기(48x48dp)를 준수하는가?
- [ ] 색상만으로 정보를 전달하지 않는가(색맹 대응)?
