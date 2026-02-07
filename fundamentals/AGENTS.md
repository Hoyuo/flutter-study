<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-02-07 -->

# Fundamentals

## Purpose

Flutter와 Dart의 기초 개념을 다루는 문서 모음입니다. 언어 심화 문법, 위젯/렌더링 시스템, 레이아웃 메커니즘 등 Flutter 개발의 기반이 되는 핵심 지식을 제공합니다.

## Key Files

| File | Description |
|------|-------------|
| `DartAdvanced.md` | Dart 심화 문법 - Generics, Extension Methods, Mixin, Typedef, 고급 타입 시스템 |
| `WidgetFundamentals.md` | Widget/Element/RenderObject 트리 구조, 생명주기, BuildContext |
| `LayoutSystem.md` | Constraints 전파 시스템, Flex 레이아웃, Sliver, CustomMultiChildLayout |
| `FlutterInternals.md` | 렌더링 파이프라인, 프레임 스케줄링, Layer Tree, Rasterization |
| `DevToolsProfiling.md` | Flutter DevTools 활용, 성능 프로파일링, 메모리 분석, Widget Inspector |
| `DesignSystem.md` | 디자인 시스템, 테마 구성, 디자인 토큰, 색상 접근성, 컴포넌트 라이브러리 |

## For AI Agents

### Working In This Directory

- 이 카테고리는 Flutter 개발의 **기초 지식**을 다룸
- 다른 카테고리의 고급 패턴을 이해하기 위한 선행 학습 권장
- 코드 예제는 개념 이해를 돕기 위한 단순화된 형태 사용

### Learning Path

1. `DartAdvanced.md` → Dart 언어 심화 (필수 선행)
2. `WidgetFundamentals.md` → Widget 시스템 이해
3. `LayoutSystem.md` → 레이아웃 메커니즘
4. `FlutterInternals.md` → 내부 동작 원리
5. `DevToolsProfiling.md` → 디버깅 및 프로파일링
6. `DesignSystem.md` → 디자인 시스템 구축

### Common Patterns

```dart
// Generic Constraints
class Repository<T extends Entity> {
  Future<T> findById(String id);
}

// Extension Method
extension StringExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

// Widget Lifecycle
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

// Layout Builder
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return TabletLayout();
    }
    return MobileLayout();
  },
)
```

## Dependencies

### Internal

- `../core/Architecture.md` - 아키텍처 패턴과 연계
- `../system/Performance.md` - 성능 최적화 참조
- `../system/Accessibility.md` - 접근성 고려 (DesignSystem)

### External

- `flutter/material.dart` - Material Design
- `flutter/widgets.dart` - Widget Framework
- `devtools` - Flutter DevTools

<!-- MANUAL: -->
