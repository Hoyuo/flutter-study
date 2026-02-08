# Flutter Custom Painting & 그래픽 가이드

> **난이도**: 고급 | **카테고리**: features
> **선행 학습**: [FlutterInternals](../fundamentals/FlutterInternals.md)
> **예상 학습 시간**: 3h

> Flutter의 CustomPainter를 활용한 고급 그래픽 렌더링 패턴입니다. Canvas API를 통해 복잡한 도형, 차트, 애니메이션을 직접 그리는 방법을 다룹니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - CustomPainter와 Canvas API를 활용한 커스텀 그래픽을 구현할 수 있다
> - 복잡한 도형, 차트, 게이지 등 데이터 시각화를 구현할 수 있다
> - 그래픽 렌더링 성능 최적화와 애니메이션 적용 방법을 이해할 수 있다

## 목차
1. [개요](#1-개요)
2. [CustomPainter 기초](#2-custompainter-기초)
3. [Canvas 기본 도형](#3-canvas-기본-도형)
4. [Path 그리기](#4-path-그리기)
5. [Paint 속성](#5-paint-속성)
6. [텍스트 그리기](#6-텍스트-그리기)
7. [이미지 그리기](#7-이미지-그리기)
8. [커스텀 차트](#8-커스텀-차트)
9. [애니메이션 통합](#9-애니메이션-통합)
10. [터치 인터랙션](#10-터치-인터랙션)
11. [ClipPath & ShapeBorder](#11-clippath--shapeborder)
12. [Custom RenderObject](#12-custom-renderobject)
13. [성능 최적화](#13-성능-최적화)
14. [Best Practices](#14-best-practices)

---

## 1. 개요

### 1.1 CustomPainter란?

CustomPainter는 Flutter에서 저수준 그래픽 렌더링을 제공하는 추상 클래스입니다. Canvas API를 통해 픽셀 단위로 UI를 그릴 수 있습니다.

**주요 특징:**
- 완전한 렌더링 제어
- 고성능 그래픽 처리
- 복잡한 도형 및 애니메이션 지원
- 하드웨어 가속

### 1.2 Canvas API 개요

| API | 설명 | 용도 |
|-----|------|------|
| `drawRect()` | 사각형 그리기 | 박스, 버튼 배경 |
| `drawCircle()` | 원 그리기 | 아바타, 인디케이터 |
| `drawPath()` | 경로 그리기 | 복잡한 도형, 차트 |
| `drawImage()` | 이미지 렌더링 | 아이콘, 텍스처 |

> ⚠️ **경고**: `Canvas.drawText()`는 Flutter에서 존재하지 않습니다. 텍스트를 그리려면 `TextPainter.paint()`를 사용하세요. (섹션 6 참조)

### 1.3 사용 시나리오

```dart
// 일반 Widget으로 해결 가능
Container(
  width: 100,
  height: 100,
  decoration: BoxDecoration(
    color: Colors.blue,
    shape: BoxShape.circle,
  ),
);

// CustomPainter가 필요한 경우
// - 복잡한 경로 (베지어 곡선)
// - 실시간 차트 렌더링
// - 게임 그래픽
// - 커스텀 진행률 인디케이터
// - 손글씨/드로잉 앱
```

**프로젝트 구조:**

```
lib/
├── main.dart
├── core/
│   └── painters/
│       ├── base_painter.dart
│       └── animated_painter.dart
├── features/
│   ├── charts/
│   │   ├── presentation/
│   │   │   ├── painters/
│   │   │   │   ├── line_chart_painter.dart
│   │   │   │   ├── bar_chart_painter.dart
│   │   │   │   └── pie_chart_painter.dart
│   │   │   └── widgets/
│   │   │       └── chart_widget.dart
│   │   └── domain/
│   │       └── models/
│   │           └── chart_data.dart
│   └── drawing/
│       ├── presentation/
│       │   ├── painters/
│       │   │   └── canvas_painter.dart
│       │   ├── bloc/
│       │   │   ├── drawing_bloc.dart
│       │   │   ├── drawing_event.dart
│       │   │   └── drawing_state.dart
│       │   └── screens/
│       │       └── drawing_screen.dart
│       └── domain/
│           └── models/
│               └── stroke.dart
└── shared/
    └── widgets/
        └── custom_paint_wrapper.dart
```

---

## 2. CustomPainter 기초

### 2.1 기본 구조

```dart
// lib/core/painters/base_painter.dart

import 'package:flutter/material.dart';

/// 기본 CustomPainter 템플릿
class BasicPainter extends CustomPainter {
  final Color color;

  const BasicPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 그리기 로직
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 4,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant BasicPainter oldDelegate) {
    // 리페인트 필요 여부 결정
    return oldDelegate.color != color;
  }
}
```

### 2.2 CustomPaint Widget 사용

```dart
// lib/features/charts/presentation/widgets/chart_widget.dart

import 'package:flutter/material.dart';

class ChartWidget extends StatelessWidget {
  final List<double> data;

  const ChartWidget({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(300, 200), // 명시적 크기
      painter: LineChartPainter(data: data),
      child: Container(), // 선택적 자식
    );
  }
}

// 또는 크기를 부모로부터 상속
class ResponsiveChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 300,
      child: CustomPaint(
        painter: LineChartPainter(data: [1, 2, 3]),
      ),
    );
  }
}
```

### 2.3 shouldRepaint() 최적화

```dart
class OptimizedPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  const OptimizedPainter({
    required this.points,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 그리기 로직
  }

  @override
  bool shouldRepaint(covariant OptimizedPainter oldDelegate) {
    // 모든 속성 비교
    return oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.points.length != points.length ||
           !_pointsEqual(oldDelegate.points, points);
  }

  bool _pointsEqual(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
```

---

## 3. Canvas 기본 도형

### 3.1 사각형 (Rectangle)

```dart
// lib/core/painters/shape_painter.dart

class RectanglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // 1. Rect 객체로 그리기
    final rect = Rect.fromLTWH(10, 10, 100, 50);
    canvas.drawRect(rect, paint);

    // 2. Offset으로 그리기
    final rect2 = Rect.fromPoints(
      const Offset(10, 70),
      const Offset(110, 120),
    );
    canvas.drawRect(rect2, paint..color = Colors.red);

    // 3. 둥근 모서리
    final roundRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 130, 100, 50),
      const Radius.circular(10),
    );
    canvas.drawRRect(roundRect, paint..color = Colors.green);

    // 4. 테두리만
    canvas.drawRect(
      Rect.fromLTWH(10, 190, 100, 50),
      paint
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### 3.2 원 (Circle) & 타원 (Oval)

```dart
class CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue;

    // 1. 원 (중심점 + 반지름)
    canvas.drawCircle(
      Offset(size.width / 4, size.height / 4),
      50,
      paint,
    );

    // 2. 타원 (Rect 영역에 맞춤)
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width * 0.75, size.height / 4),
      width: 120,
      height: 80,
    );
    canvas.drawOval(ovalRect, paint..color = Colors.red);

    // 3. 도넛 (두 원으로 구현)
    final center = Offset(size.width / 2, size.height * 0.7);
    canvas.drawCircle(center, 60, paint..color = Colors.green);
    canvas.drawCircle(center, 40, paint..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### 3.3 선 (Line)

```dart
class LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round; // 끝 모양

    // 1. 단순 선
    canvas.drawLine(
      const Offset(10, 10),
      const Offset(200, 10),
      paint,
    );

    // 2. 점선
    paint.strokeWidth = 1;
    for (double x = 10; x < 200; x += 10) {
      canvas.drawLine(
        Offset(x, 30),
        Offset(x + 5, 30),
        paint,
      );
    }

    // 3. 다양한 StrokeCap
    final caps = [StrokeCap.butt, StrokeCap.round, StrokeCap.square];
    for (int i = 0; i < caps.length; i++) {
      canvas.drawLine(
        Offset(10, 50 + i * 30.0),
        Offset(200, 50 + i * 30.0),
        paint
          ..strokeWidth = 10
          ..strokeCap = caps[i],
      );
    }

    // 4. 여러 선 (drawPoints)
    final points = <Offset>[
      const Offset(10, 150),
      const Offset(50, 180),
      const Offset(90, 160),
      const Offset(130, 190),
      const Offset(170, 170),
    ];
    canvas.drawPoints(
      PointMode.polygon, // lines로 연결
      points,
      paint..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### 3.4 호 (Arc)

```dart
class ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 150,
      height: 150,
    );

    // 1. 호 그리기 (시작 각도, 스윕 각도)
    canvas.drawArc(
      rect,
      0, // 시작 (0 = 오른쪽)
      3.14, // 스윕 (파이 라디안)
      false, // useCenter (중심 포함 여부)
      paint,
    );

    // 2. 파이 차트 슬라이스
    canvas.drawArc(
      rect.shift(const Offset(0, 180)),
      -1.57, // -90도 (위쪽)
      1.57, // 90도 스윕
      true, // 중심 포함
      paint
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );

    // 3. 진행률 인디케이터 (270도)
    canvas.drawArc(
      rect.shift(const Offset(0, -180)),
      -1.57,
      4.71, // 270도
      false,
      paint
        ..color = Colors.green
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

---

## 4. Path 그리기

### 4.1 기본 Path 조작

```dart
// lib/features/drawing/domain/models/stroke.dart

import 'package:flutter/material.dart';

class DrawingPath {
  final Path path;
  final Paint paint;

  DrawingPath({
    required this.path,
    required this.paint,
  });
}

// lib/core/painters/path_painter.dart

class PathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // 1. 삼각형
    final trianglePath = Path()
      ..moveTo(size.width / 2, 10) // 시작점
      ..lineTo(size.width - 10, size.height / 3) // 직선
      ..lineTo(10, size.height / 3)
      ..close(); // 닫기

    canvas.drawPath(trianglePath, paint);

    // 2. 사각형 (addRect)
    final rectPath = Path()
      ..addRect(Rect.fromLTWH(10, size.height / 2, 100, 80));

    canvas.drawPath(rectPath, paint..color = Colors.red);

    // 3. 원 (addOval)
    final circlePath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width - 60, size.height * 0.7),
        radius: 40,
      ));

    canvas.drawPath(circlePath, paint..color = Colors.green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### 4.2 베지어 곡선

```dart
class BezierCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 1. Quadratic Bezier (제어점 1개)
    final quadPath = Path()
      ..moveTo(10, size.height / 4)
      ..quadraticBezierTo(
        size.width / 2, 10, // 제어점
        size.width - 10, size.height / 4, // 끝점
      );

    canvas.drawPath(quadPath, paint);

    // 제어점 표시
    canvas.drawCircle(
      Offset(size.width / 2, 10),
      5,
      paint
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );

    // 2. Cubic Bezier (제어점 2개)
    final cubicPath = Path()
      ..moveTo(10, size.height / 2)
      ..cubicTo(
        size.width / 3, size.height / 3, // 제어점 1
        size.width * 2 / 3, size.height * 2 / 3, // 제어점 2
        size.width - 10, size.height / 2, // 끝점
      );

    canvas.drawPath(cubicPath, paint..color = Colors.green);

    // 3. 부드러운 웨이브
    final wavePath = Path()..moveTo(0, size.height * 0.8);

    for (double x = 0; x <= size.width; x += size.width / 4) {
      wavePath.quadraticBezierTo(
        x + size.width / 8,
        size.height * 0.7,
        x + size.width / 4,
        size.height * 0.8,
      );
    }

    canvas.drawPath(wavePath, paint..color = Colors.purple);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### 4.3 복잡한 Path 연산

```dart
class AdvancedPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // 1. Path 합치기 (combine)
    final path1 = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 3, size.height / 3),
        radius: 50,
      ));

    final path2 = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width * 2 / 3, size.height / 3),
        radius: 50,
      ));

    final unionPath = Path.combine(
      PathOperation.union,
      path1,
      path2,
    );
    canvas.drawPath(unionPath, paint);

    // 2. Path 차집합
    final diffPath = Path.combine(
      PathOperation.difference,
      path1.shift(Offset(0, size.height / 2)),
      path2.shift(Offset(0, size.height / 2)),
    );
    canvas.drawPath(diffPath, paint..color = Colors.red);

    // 3. Path 교집합
    final intersectPath = Path.combine(
      PathOperation.intersect,
      path1.shift(Offset(0, size.height)),
      path2.shift(Offset(0, size.height)),
    );
    canvas.drawPath(intersectPath, paint..color = Colors.green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### 4.4 Path Metrics (경로 측정)

```dart
class PathMetricsPainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0

  const PathMetricsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // 복잡한 경로 생성
    final path = Path()
      ..moveTo(10, size.height / 2)
      ..cubicTo(
        size.width / 3, 10,
        size.width * 2 / 3, size.height - 10,
        size.width - 10, size.height / 2,
      );

    // PathMetrics로 경로 분석
    final pathMetrics = path.computeMetrics();
    final metric = pathMetrics.first;
    final length = metric.length;

    // progress만큼만 그리기
    final extractPath = metric.extractPath(0, length * progress);
    canvas.drawPath(extractPath, paint);

    // 현재 위치에 마커
    final tangent = metric.getTangentForOffset(length * progress);
    if (tangent != null) {
      canvas.drawCircle(
        tangent.position,
        8,
        paint
          ..color = Colors.red
          ..style = PaintingStyle.fill,
      );

      // 진행 방향 화살표
      final arrowPath = Path()
        ..moveTo(-10, -5)
        ..lineTo(0, 0)
        ..lineTo(-10, 5);

      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(tangent.angle);
      canvas.drawPath(arrowPath, paint..style = PaintingStyle.stroke);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PathMetricsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
```

---

## 5. Paint 속성

### 5.1 기본 속성

```dart
class PaintPropertiesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Color
    final paint1 = Paint()
      ..color = Colors.blue.withValues(alpha: 0.5) // 투명도
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(60, 60), 50, paint1);

    // 2. Stroke Width
    final paint2 = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawCircle(Offset(180, 60), 50, paint2);

    // 3. StrokeCap & StrokeJoin
    final paint3 = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(260, 30)
      ..lineTo(310, 90)
      ..lineTo(360, 30);
    canvas.drawPath(path, paint3);

    // 4. BlendMode
    final paint4 = Paint()
      ..color = Colors.yellow
      ..blendMode = BlendMode.multiply;

    canvas.drawCircle(Offset(60, 180), 50, paint4);
    canvas.drawCircle(Offset(100, 180), 50, paint4..color = Colors.cyan);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### 5.2 Shader (그라디언트)

```dart
class ShaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Linear Gradient
    final linearPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blue, Colors.purple, Colors.pink],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(10, 10, 150, 100));

    canvas.drawRect(Rect.fromLTWH(10, 10, 150, 100), linearPaint);

    // 2. Radial Gradient
    final radialPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment.center,
        radius: 0.5,
        colors: [Colors.yellow, Colors.orange, Colors.red],
      ).createShader(Rect.fromLTWH(180, 10, 150, 100));

    canvas.drawRect(Rect.fromLTWH(180, 10, 150, 100), radialPaint);

    // 3. Sweep Gradient (각도 그라디언트)
    final sweepPaint = Paint()
      ..shader = const SweepGradient(
        center: Alignment.center,
        colors: [
          Colors.red,
          Colors.yellow,
          Colors.green,
          Colors.cyan,
          Colors.blue,
          Colors.magenta,
          Colors.red,
        ],
      ).createShader(Rect.fromLTWH(95, 130, 150, 150));

    canvas.drawCircle(Offset(170, 205), 75, sweepPaint);

    // 4. TileMode (반복 모드)
    final tiledPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.purple, Colors.white],
        tileMode: TileMode.repeated,
      ).createShader(Rect.fromLTWH(10, 300, 320, 50));

    canvas.drawRect(Rect.fromLTWH(10, 300, 320, 50), tiledPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### 5.3 MaskFilter & ImageFilter

```dart
class FilterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. MaskFilter (블러)
    final blurPaint = Paint()
      ..color = Colors.blue
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(Offset(60, 60), 40, blurPaint);

    // 2. BlurStyle 비교
    final styles = [
      BlurStyle.normal,
      BlurStyle.solid,
      BlurStyle.outer,
      BlurStyle.inner,
    ];

    for (int i = 0; i < styles.length; i++) {
      canvas.drawCircle(
        Offset(60 + i * 90.0, 180),
        40,
        Paint()
          ..color = Colors.red
          ..maskFilter = MaskFilter.blur(styles[i], 5),
      );
    }

    // 3. ImageFilter (레이어 필터)
    canvas.saveLayer(
      Rect.fromLTWH(10, 260, 150, 100),
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: 5,
          sigmaY: 5,
        ),
    );

    canvas.drawRect(
      Rect.fromLTWH(10, 260, 150, 100),
      Paint()..color = Colors.green,
    );

    canvas.restore();

    // 4. ColorFilter
    final colorFilterPaint = Paint()
      ..color = Colors.purple
      ..colorFilter = const ColorFilter.mode(
        Colors.red,
        BlendMode.modulate,
      );

    canvas.drawCircle(Offset(250, 310), 40, colorFilterPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### 5.4 BlendMode 종류

```dart
class BlendModePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blendModes = [
      BlendMode.clear,
      BlendMode.src,
      BlendMode.dst,
      BlendMode.srcOver,
      BlendMode.dstOver,
      BlendMode.srcIn,
      BlendMode.dstIn,
      BlendMode.srcOut,
      BlendMode.dstOut,
      BlendMode.srcATop,
      BlendMode.dstATop,
      BlendMode.xor,
      BlendMode.plus,
      BlendMode.modulate,
      BlendMode.screen,
      BlendMode.overlay,
      BlendMode.multiply,
      BlendMode.difference,
    ];

    const cellSize = 80.0;
    const padding = 10.0;

    for (int i = 0; i < blendModes.length; i++) {
      final row = i ~/ 4;
      final col = i % 4;
      final x = padding + col * (cellSize + padding);
      final y = padding + row * (cellSize + padding);

      // 배경 (빨강)
      canvas.drawRect(
        Rect.fromLTWH(x, y, cellSize, cellSize),
        Paint()..color = Colors.red.withValues(alpha: 0.7),
      );

      // 전경 (파랑) - BlendMode 적용
      canvas.drawCircle(
        Offset(x + cellSize / 2, y + cellSize / 2),
        cellSize / 3,
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.7)
          ..blendMode = blendModes[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

---

## 6. 텍스트 그리기

### 6.1 TextPainter 기본

```dart
// lib/core/painters/text_painter_util.dart

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class TextDrawHelper {
  static void drawText({
    required Canvas canvas,
    required String text,
    required Offset position,
    required TextStyle style,
    TextAlign align = TextAlign.left,
    double maxWidth = double.infinity,
  }) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: align,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: maxWidth);
    textPainter.paint(canvas, position);
  }

  static Size measureText(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.size;
  }
}

// lib/core/painters/text_demo_painter.dart

class TextDemoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. 기본 텍스트
    TextDrawHelper.drawText(
      canvas: canvas,
      text: 'Hello, Flutter!',
      position: const Offset(10, 10),
      style: const TextStyle(
        color: Colors.black,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );

    // 2. 스타일 적용
    TextDrawHelper.drawText(
      canvas: canvas,
      text: 'Styled Text',
      position: const Offset(10, 50),
      style: const TextStyle(
        color: Colors.blue,
        fontSize: 20,
        fontStyle: FontStyle.italic,
        decoration: TextDecoration.underline,
        decorationColor: Colors.red,
        decorationThickness: 2,
      ),
    );

    // 3. 그림자
    TextDrawHelper.drawText(
      canvas: canvas,
      text: 'Shadow Text',
      position: const Offset(10, 90),
      style: const TextStyle(
        color: Colors.purple,
        fontSize: 22,
        shadows: [
          Shadow(
            color: Colors.black54,
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );

    // 4. 배경색
    final textSpan = const TextSpan(
      text: 'Background',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        backgroundColor: Colors.orange,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 130));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### 6.2 Rich Text (다중 스타일)

```dart
class RichTextPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
      ),
      children: [
        const TextSpan(text: 'This is '),
        const TextSpan(
          text: 'bold',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: ' and '),
        const TextSpan(
          text: 'italic',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.blue,
          ),
        ),
        const TextSpan(text: ' text with '),
        const TextSpan(
          text: 'colors',
          style: TextStyle(
            color: Colors.red,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const TextSpan(text: '.'),
      ],
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    textPainter.layout(maxWidth: size.width - 20);
    textPainter.paint(canvas, const Offset(10, 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### 6.3 텍스트 정렬 & 줄바꿈

```dart
class TextAlignmentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const maxWidth = 300.0;
    const longText = 'This is a very long text that will be wrapped '
        'across multiple lines to demonstrate text alignment options.';

    final alignments = [
      TextAlign.left,
      TextAlign.center,
      TextAlign.right,
      TextAlign.justify,
    ];

    final labels = ['Left', 'Center', 'Right', 'Justify'];

    for (int i = 0; i < alignments.length; i++) {
      final y = 20.0 + i * 120.0;

      // 레이블
      TextDrawHelper.drawText(
        canvas: canvas,
        text: labels[i],
        position: Offset(10, y),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      );

      // 정렬된 텍스트
      final textPainter = TextPainter(
        text: const TextSpan(
          text: longText,
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
        textAlign: alignments[i],
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: maxWidth);
      textPainter.paint(canvas, Offset(10, y + 25));

      // 경계 표시
      canvas.drawRect(
        Rect.fromLTWH(10, y + 25, maxWidth, textPainter.height),
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### 6.4 회전 & 변환 텍스트

```dart
class TransformedTextPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. 회전 텍스트
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (3.14159 / 180); // 30도씩

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      TextDrawHelper.drawText(
        canvas: canvas,
        text: '${i + 1}',
        position: const Offset(-10, -100),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );

      canvas.restore();
    }

    // 2. 스케일 텍스트
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(2.0, 1.0); // 가로 2배 확대

    TextDrawHelper.drawText(
      canvas: canvas,
      text: 'Scaled',
      position: const Offset(-30, -20),
      style: const TextStyle(fontSize: 16, color: Colors.red),
    );

    canvas.restore();

    // 3. 경로를 따라 텍스트
    final path = Path()
      ..addArc(
        Rect.fromCenter(center: center, width: 200, height: 200),
        -3.14159 / 2,
        3.14159,
      );

    const text = 'Text along a path';
    final pathMetrics = path.computeMetrics().first;
    final length = pathMetrics.length;

    for (int i = 0; i < text.length; i++) {
      final distance = (i / text.length) * length;
      final tangent = pathMetrics.getTangentForOffset(distance);

      if (tangent != null) {
        canvas.save();
        canvas.translate(tangent.position.dx, tangent.position.dy);
        canvas.rotate(tangent.angle);

        TextDrawHelper.drawText(
          canvas: canvas,
          text: text[i],
          position: const Offset(-5, -10),
          style: const TextStyle(fontSize: 14, color: Colors.blue),
        );

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

---

## 7. 이미지 그리기

### 7.1 이미지 로딩 & 렌더링

```dart
// lib/core/painters/image_painter.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImagePainter extends CustomPainter {
  final ui.Image? image;

  const ImagePainter({this.image});

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;

    final paint = Paint()..filterQuality = FilterQuality.high;

    // 1. 원본 크기로 그리기
    canvas.drawImage(image!, const Offset(10, 10), paint);

    // 2. Rect 영역에 맞춰 그리기
    final destRect = Rect.fromLTWH(
      size.width / 2,
      10,
      size.width / 2 - 20,
      size.height / 2 - 20,
    );

    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
      destRect,
      paint,
    );

    // 3. 이미지 일부만 그리기 (Crop)
    final srcRect = Rect.fromLTWH(
      image!.width * 0.25,
      image!.height * 0.25,
      image!.width * 0.5,
      image!.height * 0.5,
    );

    final cropDestRect = Rect.fromLTWH(
      10,
      size.height / 2,
      size.width / 3,
      size.height / 2 - 20,
    );

    canvas.drawImageRect(image!, srcRect, cropDestRect, paint);

    // 4. 투명도 적용
    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
      Rect.fromLTWH(
        size.width * 2 / 3,
        size.height / 2,
        size.width / 3 - 20,
        size.height / 2 - 20,
      ),
      paint..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant ImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}

// 이미지 로딩 헬퍼
class ImageLoader {
  static Future<ui.Image> loadAssetImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodecFromBuffer(await ui.ImmutableBuffer.fromUint8List(data.buffer.asUint8List()));
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<ui.Image> loadNetworkImage(String url) async {
    final completer = Completer<ui.Image>();
    final imageStream = NetworkImage(url).resolve(ImageConfiguration.empty);

    imageStream.addListener(ImageStreamListener((info, _) {
      completer.complete(info.image);
    }));

    return completer.future;
  }
}

// 사용 예시
class ImagePaintWidget extends StatefulWidget {
  @override
  State<ImagePaintWidget> createState() => _ImagePaintWidgetState();
}

class _ImagePaintWidgetState extends State<ImagePaintWidget> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final image = await ImageLoader.loadAssetImage('assets/images/sample.png');
    setState(() => _image = image);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(400, 600),
      painter: ImagePainter(image: _image),
    );
  }
}
```

### 7.2 이미지 필터 & 합성

```dart
class ImageFilterPainter extends CustomPainter {
  final ui.Image? image;

  const ImageFilterPainter({this.image});

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;

    final destRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Grayscale
    canvas.save();
    canvas.translate(0, 0);
    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width / 2, size.height / 2),
      Paint()
        ..colorFilter = const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
    );
    canvas.restore();

    // 2. Sepia
    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height / 2),
      Paint()
        ..colorFilter = const ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]),
    );

    // 3. Blur
    canvas.saveLayer(
      Rect.fromLTWH(0, size.height / 2, size.width / 2, size.height / 2),
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
    );
    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
      Rect.fromLTWH(0, size.height / 2, size.width / 2, size.height / 2),
      Paint(),
    );
    canvas.restore();

    // 4. BlendMode
    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
      Rect.fromLTWH(size.width / 2, size.height / 2, size.width / 2, size.height / 2),
      Paint()..blendMode = BlendMode.multiply,
    );
  }

  @override
  bool shouldRepaint(covariant ImageFilterPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
```

---

## 8. 커스텀 차트

### 8.1 라인 차트

```dart
// lib/features/charts/domain/models/chart_data.dart

class ChartDataPoint {
  final double x;
  final double y;
  final String? label;

  const ChartDataPoint({
    required this.x,
    required this.y,
    this.label,
  });
}

// lib/features/charts/presentation/painters/line_chart_painter.dart

class LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final Color lineColor;
  final double strokeWidth;
  final bool showDots;
  final bool showGrid;

  const LineChartPainter({
    required this.data,
    this.lineColor = Colors.blue,
    this.strokeWidth = 2.0,
    this.showDots = true,
    this.showGrid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // 데이터 범위 계산
    final minX = data.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    final maxX = data.map((p) => p.x).reduce((a, b) => a > b ? a : b);
    final minY = data.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final maxY = data.map((p) => p.y).reduce((a, b) => a > b ? a : b);

    // 좌표 변환 함수
    Offset dataToCanvas(double x, double y) {
      final normalizedX = (x - minX) / (maxX - minX);
      final normalizedY = 1 - (y - minY) / (maxY - minY);

      return Offset(
        padding + normalizedX * chartWidth,
        padding + normalizedY * chartHeight,
      );
    }

    // 그리드 그리기
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.3)
        ..strokeWidth = 1;

      for (int i = 0; i <= 5; i++) {
        final y = padding + (i / 5) * chartHeight;
        canvas.drawLine(
          Offset(padding, y),
          Offset(size.width - padding, y),
          gridPaint,
        );

        // Y축 레이블
        final value = maxY - (i / 5) * (maxY - minY);
        TextDrawHelper.drawText(
          canvas: canvas,
          text: value.toStringAsFixed(1),
          position: Offset(5, y - 8),
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        );
      }
    }

    // 라인 그리기
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final points = data.map((p) => dataToCanvas(p.x, p.y)).toList();

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    canvas.drawPath(path, linePaint);

    // 점 그리기
    if (showDots) {
      final dotPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;

      for (final point in points) {
        canvas.drawCircle(point, 4, dotPaint);
        canvas.drawCircle(
          point,
          6,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // 축 그리기
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    // Y축
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );

    // X축
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
           oldDelegate.lineColor != lineColor ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.showDots != showDots ||
           oldDelegate.showGrid != showGrid;
  }
}
```

### 8.2 바 차트

```dart
// lib/features/charts/presentation/painters/bar_chart_painter.dart

class BarChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final Color barColor;
  final double barWidthRatio; // 0.0 ~ 1.0

  const BarChartPainter({
    required this.data,
    this.barColor = Colors.blue,
    this.barWidthRatio = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    final maxY = data.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final barWidth = (chartWidth / data.length) * barWidthRatio;
    final barSpacing = chartWidth / data.length;

    // 그리드
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      final y = padding + (i / 5) * chartHeight;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );

      // Y축 레이블
      final value = maxY * (1 - i / 5);
      TextDrawHelper.drawText(
        canvas: canvas,
        text: value.toStringAsFixed(0),
        position: Offset(5, y - 8),
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      );
    }

    // 바 그리기
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = padding + i * barSpacing + (barSpacing - barWidth) / 2;
      final barHeight = (point.y / maxY) * chartHeight;
      final y = size.height - padding - barHeight;

      // 바
      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            barColor.withValues(alpha: 0.8),
            barColor,
          ],
        ).createShader(rect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        barPaint,
      );

      // 값 표시
      TextDrawHelper.drawText(
        canvas: canvas,
        text: point.y.toStringAsFixed(1),
        position: Offset(x + barWidth / 2 - 15, y - 20),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );

      // X축 레이블
      if (point.label != null) {
        TextDrawHelper.drawText(
          canvas: canvas,
          text: point.label!,
          position: Offset(x + barWidth / 2 - 10, size.height - padding + 10),
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        );
      }
    }

    // 축
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );

    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.data != data ||
           oldDelegate.barColor != barColor ||
           oldDelegate.barWidthRatio != barWidthRatio;
  }
}
```

### 8.3 파이 차트

```dart
import 'dart:math';

// lib/features/charts/presentation/painters/pie_chart_painter.dart

class PieChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final List<Color> colors;
  final bool showLabels;
  final bool show3D;

  const PieChartPainter({
    required this.data,
    required this.colors,
    this.showLabels = true,
    this.show3D = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2.5 : size.height / 2.5;

    final total = data.fold(0.0, (sum, point) => sum + point.y);
    double startAngle = -3.14159 / 2; // 12시 방향부터 시작

    // 3D 효과 (그림자)
    if (show3D) {
      final shadowPath = Path();
      double shadowAngle = startAngle;

      for (int i = 0; i < data.length; i++) {
        final sweepAngle = (data[i].y / total) * 2 * 3.14159;

        shadowPath.addArc(
          Rect.fromCircle(center: center + const Offset(5, 5), radius: radius),
          shadowAngle,
          sweepAngle,
        );
        shadowPath.lineTo(center.dx + 5, center.dy + 5);
        shadowAngle += sweepAngle;
      }

      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = Colors.black26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // 슬라이스 그리기
    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].y / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // 테두리
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // 레이블
      if (showLabels) {
        final middleAngle = startAngle + sweepAngle / 2;
        final labelRadius = radius * 0.7;
        final labelX = center.dx + labelRadius * cos(middleAngle);
        final labelY = center.dy + labelRadius * sin(middleAngle);

        final percentage = (data[i].y / total * 100).toStringAsFixed(1);

        TextDrawHelper.drawText(
          canvas: canvas,
          text: '$percentage%',
          position: Offset(labelX - 20, labelY - 8),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black54,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        );

        // 범례용 라인
        final outerRadius = radius + 20;
        final outerX = center.dx + outerRadius * cos(middleAngle);
        final outerY = center.dy + outerRadius * sin(middleAngle);

        canvas.drawLine(
          Offset(labelX, labelY),
          Offset(outerX, outerY),
          Paint()
            ..color = colors[i % colors.length]
            ..strokeWidth = 2,
        );

        if (data[i].label != null) {
          TextDrawHelper.drawText(
            canvas: canvas,
            text: data[i].label!,
            position: Offset(
              outerX + (middleAngle > 0 ? 5 : -50),
              outerY - 8,
            ),
            style: const TextStyle(fontSize: 12, color: Colors.black),
          );
        }
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.data != data ||
           oldDelegate.colors != colors ||
           oldDelegate.showLabels != showLabels ||
           oldDelegate.show3D != show3D;
  }
}
```

---

## 9. 애니메이션 통합

### 9.1 AnimationController + CustomPainter

```dart
// lib/core/painters/animated_painter.dart

class AnimatedCirclePainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0
  final Color color;

  const AnimatedCirclePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width < size.height ? size.width / 2 : size.height / 2;
    final radius = maxRadius * progress;

    // 원 그리기
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 1 - progress * 0.5)
        ..style = PaintingStyle.fill,
    );

    // 테두리
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant AnimatedCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// 사용 예시
class AnimatedCircleWidget extends StatefulWidget {
  @override
  State<AnimatedCircleWidget> createState() => _AnimatedCircleWidgetState();
}

class _AnimatedCircleWidgetState extends State<AnimatedCircleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: AnimatedCirclePainter(
            progress: _animation.value,
            color: Colors.blue,
          ),
        );
      },
    );
  }
}
```

### 9.2 실시간 차트 애니메이션

```dart
// lib/features/charts/presentation/painters/animated_line_chart_painter.dart

class AnimatedLineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double animationProgress; // 0.0 ~ 1.0
  final Color lineColor;

  const AnimatedLineChartPainter({
    required this.data,
    required this.animationProgress,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    final maxY = data.map((p) => p.y).reduce((a, b) => a > b ? a : b);

    // 좌표 변환
    Offset dataToCanvas(double x, double y) {
      final normalizedX = x / (data.length - 1);
      final normalizedY = 1 - (y / maxY);

      return Offset(
        padding + normalizedX * chartWidth,
        padding + normalizedY * chartHeight,
      );
    }

    // 애니메이션 적용된 경로
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final point = dataToCanvas(i.toDouble(), data[i].y);
      points.add(point);

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    // PathMetrics로 진행률만큼만 그리기
    final pathMetrics = path.computeMetrics().first;
    final extractedPath = pathMetrics.extractPath(
      0,
      pathMetrics.length * animationProgress,
    );

    canvas.drawPath(
      extractedPath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // 애니메이션된 점들
    final visiblePointCount = (points.length * animationProgress).ceil();
    for (int i = 0; i < visiblePointCount; i++) {
      canvas.drawCircle(
        points[i],
        5,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill,
      );
    }

    // 현재 진행 위치 강조
    if (visiblePointCount > 0) {
      final currentPoint = points[visiblePointCount - 1];
      canvas.drawCircle(
        currentPoint,
        8,
        Paint()
          ..color = lineColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedLineChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress;
  }
}
```

### 9.3 Wave 애니메이션

```dart
import 'dart:math';

class WavePainter extends CustomPainter {
  final double wavePhase; // 0.0 ~ 2*PI
  final Color color;
  final int waveCount;

  const WavePainter({
    required this.wavePhase,
    required this.color,
    this.waveCount = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final waveHeight = size.height * 0.1;
    final waveLength = size.width / waveCount;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x += 5) {
      final y = size.height / 2 +
          sin((x / waveLength) * 2 * 3.14159 + wavePhase) * waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );

    // 테두리
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase;
  }
}

class WaveAnimationWidget extends StatefulWidget {
  @override
  State<WaveAnimationWidget> createState() => _WaveAnimationWidgetState();
}

class _WaveAnimationWidgetState extends State<WaveAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(MediaQuery.of(context).size.width, 200),
          painter: WavePainter(
            wavePhase: _controller.value * 2 * 3.14159,
            color: Colors.blue,
          ),
        );
      },
    );
  }
}
```

---

## 10. 터치 인터랙션

### 10.1 GestureDetector + CustomPainter

```dart
// lib/features/drawing/domain/models/stroke.dart

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  const DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

// lib/features/drawing/presentation/painters/canvas_painter.dart

class CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  const CanvasPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(stroke.points[0].dx, stroke.points[0].dy);

      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length;
  }
}

// lib/features/drawing/presentation/bloc/drawing_event.dart

abstract class DrawingEvent {}

class DrawingStarted extends DrawingEvent {
  final Offset point;
  DrawingStarted(this.point);
}

class DrawingUpdated extends DrawingEvent {
  final Offset point;
  DrawingUpdated(this.point);
}

class DrawingEnded extends DrawingEvent {}

class DrawingCleared extends DrawingEvent {}

class DrawingColorChanged extends DrawingEvent {
  final Color color;
  DrawingColorChanged(this.color);
}

// lib/features/drawing/presentation/bloc/drawing_state.dart

class DrawingState {
  final List<DrawingStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double strokeWidth;

  const DrawingState({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.strokeWidth,
  });

  DrawingState copyWith({
    List<DrawingStroke>? strokes,
    List<Offset>? currentStroke,
    Color? currentColor,
    double? strokeWidth,
  }) {
    return DrawingState(
      strokes: strokes ?? this.strokes,
      currentStroke: currentStroke ?? this.currentStroke,
      currentColor: currentColor ?? this.currentColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

// lib/features/drawing/presentation/bloc/drawing_bloc.dart

class DrawingBloc extends Bloc<DrawingEvent, DrawingState> {
  DrawingBloc()
      : super(const DrawingState(
          strokes: [],
          currentStroke: [],
          currentColor: Colors.black,
          strokeWidth: 3.0,
        )) {
    on<DrawingStarted>(_onDrawingStarted);
    on<DrawingUpdated>(_onDrawingUpdated);
    on<DrawingEnded>(_onDrawingEnded);
    on<DrawingCleared>(_onDrawingCleared);
    on<DrawingColorChanged>(_onColorChanged);
  }

  void _onDrawingStarted(DrawingStarted event, Emitter<DrawingState> emit) {
    emit(state.copyWith(currentStroke: [event.point]));
  }

  void _onDrawingUpdated(DrawingUpdated event, Emitter<DrawingState> emit) {
    emit(state.copyWith(
      currentStroke: [...state.currentStroke, event.point],
    ));
  }

  void _onDrawingEnded(DrawingEnded event, Emitter<DrawingState> emit) {
    if (state.currentStroke.isNotEmpty) {
      final newStroke = DrawingStroke(
        points: state.currentStroke,
        color: state.currentColor,
        strokeWidth: state.strokeWidth,
      );

      emit(state.copyWith(
        strokes: [...state.strokes, newStroke],
        currentStroke: [],
      ));
    }
  }

  void _onDrawingCleared(DrawingCleared event, Emitter<DrawingState> emit) {
    emit(state.copyWith(strokes: [], currentStroke: []));
  }

  void _onColorChanged(DrawingColorChanged event, Emitter<DrawingState> emit) {
    emit(state.copyWith(currentColor: event.color));
  }
}

// lib/features/drawing/presentation/screens/drawing_screen.dart

class DrawingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DrawingBloc(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Drawing App')),
        body: Column(
          children: [
            _ColorPicker(),
            Expanded(child: _DrawingCanvas()),
            _BottomControls(),
          ],
        ),
      ),
    );
  }
}

class _DrawingCanvas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DrawingBloc, DrawingState>(
      builder: (context, state) {
        return GestureDetector(
          onPanStart: (details) {
            context
                .read<DrawingBloc>()
                .add(DrawingStarted(details.localPosition));
          },
          onPanUpdate: (details) {
            context
                .read<DrawingBloc>()
                .add(DrawingUpdated(details.localPosition));
          },
          onPanEnd: (_) {
            context.read<DrawingBloc>().add(DrawingEnded());
          },
          child: Container(
            color: Colors.white,
            child: CustomPaint(
              size: Size.infinite,
              painter: CanvasPainter(
                strokes: [
                  ...state.strokes,
                  if (state.currentStroke.isNotEmpty)
                    DrawingStroke(
                      points: state.currentStroke,
                      color: state.currentColor,
                      strokeWidth: state.strokeWidth,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ColorPicker extends StatelessWidget {
  static const colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DrawingBloc, DrawingState>(
      builder: (context, state) {
        return Container(
          height: 60,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: colors.map((color) {
              final isSelected = state.currentColor == color;
              return GestureDetector(
                onTap: () {
                  context.read<DrawingBloc>().add(DrawingColorChanged(color));
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [const BoxShadow(blurRadius: 4, spreadRadius: 2)]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _BottomControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              context.read<DrawingBloc>().add(DrawingCleared());
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
```

### 10.2 히트 테스트 (Hit Testing)

```dart
class InteractiveChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final int? selectedIndex;
  final Function(int?) onPointTapped;

  const InteractiveChartPainter({
    required this.data,
    required this.selectedIndex,
    required this.onPointTapped,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 차트 그리기 (이전과 동일)
    // ...

    // 선택된 포인트 강조
    if (selectedIndex != null && selectedIndex! < data.length) {
      final point = data[selectedIndex!];
      final canvasPoint = _dataToCanvas(point.x, point.y, size);

      // 강조 원
      canvas.drawCircle(
        canvasPoint,
        12,
        Paint()
          ..color = Colors.red.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );

      // 툴팁
      _drawTooltip(canvas, canvasPoint, point);
    }
  }

  Offset _dataToCanvas(double x, double y, Size size) {
    // 좌표 변환 로직
    return Offset(x, y);
  }

  void _drawTooltip(Canvas canvas, Offset position, ChartDataPoint point) {
    final text = '${point.label}: ${point.y.toStringAsFixed(1)}';
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final tooltipRect = Rect.fromLTWH(
      position.dx - textPainter.width / 2 - 8,
      position.dy - 40,
      textPainter.width + 16,
      textPainter.height + 8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(tooltipRect, const Radius.circular(4)),
      Paint()..color = Colors.black87,
    );

    textPainter.paint(
      canvas,
      Offset(
        tooltipRect.left + 8,
        tooltipRect.top + 4,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant InteractiveChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }

  @override
  bool hitTest(Offset position) {
    // 히트 테스트 구현
    return true;
  }
}

// 사용
class InteractiveChartWidget extends StatefulWidget {
  final List<ChartDataPoint> data;

  const InteractiveChartWidget({required this.data});

  @override
  State<InteractiveChartWidget> createState() =>
      _InteractiveChartWidgetState();
}

class _InteractiveChartWidgetState extends State<InteractiveChartWidget> {
  int? _selectedIndex;

  void _handleTap(Offset localPosition) {
    // 탭 위치에서 가장 가까운 포인트 찾기
    // ...
    setState(() {
      _selectedIndex = closestIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _handleTap(details.localPosition),
      child: CustomPaint(
        size: const Size(400, 300),
        painter: InteractiveChartPainter(
          data: widget.data,
          selectedIndex: _selectedIndex,
          onPointTapped: (index) {
            setState(() => _selectedIndex = index);
          },
        ),
      ),
    );
  }
}
```

---

## 11. ClipPath & ShapeBorder

### 11.1 ClipPath로 커스텀 클리핑

```dart
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height * 0.8);

    // 웨이브 효과
    final firstControlPoint = Offset(size.width / 4, size.height);
    final firstEndPoint = Offset(size.width / 2, size.height * 0.8);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 3 / 4, size.height * 0.6);
    final secondEndPoint = Offset(size.width, size.height * 0.8);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// 사용
class WaveClipWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue, Colors.purple],
          ),
        ),
        child: const Center(
          child: Text(
            'Wave Clipped',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
```

### 11.2 ShapeBorder로 커스텀 테두리

```dart
class DiamondBorder extends ShapeBorder {
  final BorderSide side;

  const DiamondBorder({this.side = BorderSide.none});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path();

    path.moveTo(rect.center.dx, rect.top);
    path.lineTo(rect.right, rect.center.dy);
    path.lineTo(rect.center.dx, rect.bottom);
    path.lineTo(rect.left, rect.center.dy);
    path.close();

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;

    final paint = Paint()
      ..color = side.color
      ..strokeWidth = side.width
      ..style = PaintingStyle.stroke;

    canvas.drawPath(getOuterPath(rect, textDirection: textDirection), paint);
  }

  @override
  ShapeBorder scale(double t) {
    return DiamondBorder(side: side.scale(t));
  }
}

// 사용
Container(
  width: 200,
  height: 200,
  decoration: ShapeDecoration(
    color: Colors.blue,
    shape: DiamondBorder(
      side: const BorderSide(color: Colors.white, width: 3),
    ),
  ),
  child: const Center(
    child: Text('Diamond', style: TextStyle(color: Colors.white)),
  ),
);
```

### 11.3 복잡한 Shape 예제

```dart
import 'dart:math';

class StarBorder extends ShapeBorder {
  final int points;
  final double innerRadiusRatio;

  const StarBorder({
    this.points = 5,
    this.innerRadiusRatio = 0.5,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path();
    final center = rect.center;
    final outerRadius = rect.shortestSide / 2;
    final innerRadius = outerRadius * innerRadiusRatio;
    final angleStep = 3.14159 / points;

    for (int i = 0; i < points * 2; i++) {
      final angle = i * angleStep - 3.14159 / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // 테두리는 Container의 decoration에서 처리
  }

  @override
  ShapeBorder scale(double t) => this;
}
```

---

## 12. Custom RenderObject

### 12.1 RenderBox 기초

```dart
// lib/core/widgets/custom_render_box.dart

class CustomSizeWidget extends LeafRenderObjectWidget {
  final Color color;

  const CustomSizeWidget({super.key, required this.color});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderCustomSize(color: color);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderCustomSize renderObject,
  ) {
    renderObject.color = color;
  }
}

class RenderCustomSize extends RenderBox {
  Color _color;

  RenderCustomSize({required Color color}) : _color = color;

  Color get color => _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    // 부모가 제공하는 제약 조건
    final constraints = this.constraints;

    // 자식이 원하는 크기 (제약 조건 내에서)
    size = Size(
      constraints.constrainWidth(200),
      constraints.constrainHeight(200),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    canvas.drawRect(
      offset & size,
      Paint()..color = _color,
    );

    // 대각선
    canvas.drawLine(
      offset,
      offset + Offset(size.width, size.height),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  @override
  bool get sizedByParent => false;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      debugPrint('Tapped at ${event.localPosition}');
    }
  }
}
```

### 12.2 MultiChildRenderObject

```dart
import 'dart:math';

class FlowLayout extends MultiChildRenderObjectWidget {
  final double spacing;

  const FlowLayout({
    super.key,
    required List<Widget> super.children,
    this.spacing = 8.0,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderFlowLayout(spacing: spacing);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderFlowLayout renderObject,
  ) {
    renderObject.spacing = spacing;
  }
}

class RenderFlowLayout extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, FlowLayoutParentData>,
         RenderBoxContainerDefaultsMixin<RenderBox, FlowLayoutParentData> {
  double _spacing;

  RenderFlowLayout({required double spacing}) : _spacing = spacing;

  double get spacing => _spacing;
  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FlowLayoutParentData) {
      child.parentData = FlowLayoutParentData();
    }
  }

  @override
  void performLayout() {
    double x = 0;
    double y = 0;
    double rowHeight = 0;

    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as FlowLayoutParentData;

      child.layout(constraints.loosen(), parentUsesSize: true);

      // 현재 행에 맞지 않으면 다음 행으로
      if (x + child.size.width > constraints.maxWidth) {
        x = 0;
        y += rowHeight + spacing;
        rowHeight = 0;
      }

      parentData.offset = Offset(x, y);
      x += child.size.width + spacing;
      rowHeight = max(rowHeight, child.size.height);

      child = parentData.nextSibling;
    }

    size = Size(constraints.maxWidth, y + rowHeight);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

class FlowLayoutParentData extends ContainerBoxParentData<RenderBox> {}
```

---

## 13. 성능 최적화

### 13.1 shouldRepaint 최적화

```dart
class OptimizedChartPainter extends CustomPainter {
  final List<double> data;
  final ChartConfig config;

  const OptimizedChartPainter({
    required this.data,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 복잡한 렌더링 로직
  }

  @override
  bool shouldRepaint(covariant OptimizedChartPainter oldDelegate) {
    // 1. 참조 비교 (가장 빠름)
    if (identical(data, oldDelegate.data) &&
        identical(config, oldDelegate.config)) {
      return false;
    }

    // 2. 길이 체크
    if (data.length != oldDelegate.data.length) return true;

    // 3. 내용 비교 (필요한 경우만)
    for (int i = 0; i < data.length; i++) {
      if (data[i] != oldDelegate.data[i]) return true;
    }

    // 4. Config 비교
    return config != oldDelegate.config;
  }
}

class ChartConfig {
  final Color lineColor;
  final double strokeWidth;
  final bool showGrid;

  const ChartConfig({
    required this.lineColor,
    required this.strokeWidth,
    required this.showGrid,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartConfig &&
           other.lineColor == lineColor &&
           other.strokeWidth == strokeWidth &&
           other.showGrid == showGrid;
  }

  @override
  int get hashCode =>
      lineColor.hashCode ^ strokeWidth.hashCode ^ showGrid.hashCode;
}
```

### 13.2 RepaintBoundary 활용

```dart
class OptimizedCanvasWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 자주 변경되는 부분
        AnimatedHeader(),

        // 정적인 캔버스 (RepaintBoundary로 격리)
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(400, 300),
            painter: StaticChartPainter(),
          ),
        ),

        // 자주 변경되는 컨트롤
        AnimatedControls(),
      ],
    );
  }
}

// 복잡한 차트를 RepaintBoundary로 래핑
class ComplexChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: ComplexChartPainter(),
        child: Container(),
      ),
    );
  }
}
```

### 13.3 레이어 최적화

```dart
class LayeredPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. 배경 레이어 (거의 변경 없음)
    canvas.saveLayer(null, Paint());
    _paintBackground(canvas, size);
    canvas.restore();

    // 2. 그리드 레이어 (가끔 변경)
    canvas.saveLayer(null, Paint());
    _paintGrid(canvas, size);
    canvas.restore();

    // 3. 데이터 레이어 (자주 변경)
    canvas.saveLayer(null, Paint());
    _paintData(canvas, size);
    canvas.restore();

    // 4. 오버레이 레이어 (항상 최상위)
    canvas.saveLayer(null, Paint());
    _paintOverlay(canvas, size);
    canvas.restore();
  }

  void _paintBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white,
    );
  }

  void _paintGrid(Canvas canvas, Size size) {
    // 그리드 그리기
  }

  void _paintData(Canvas canvas, Size size) {
    // 데이터 그리기
  }

  void _paintOverlay(Canvas canvas, Size size) {
    // 툴팁, 마커 등
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

### 13.4 Path 캐싱

```dart
class CachedPathPainter extends CustomPainter {
  final List<Offset> points;
  Path? _cachedPath;
  List<Offset>? _lastPoints;

  CachedPathPainter({required this.points});

  Path _buildPath() {
    // 캐시 체크
    if (_cachedPath != null && _pointsEqual(_lastPoints, points)) {
      return _cachedPath!;
    }

    // 새 Path 생성
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    // 캐시 저장
    _cachedPath = path;
    _lastPoints = List.from(points);

    return path;
  }

  bool _pointsEqual(List<Offset>? a, List<Offset> b) {
    if (a == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CachedPathPainter oldDelegate) {
    return !_pointsEqual(oldDelegate.points, points);
  }
}
```

---

## 14. Best Practices

### 14.1 Do & Don't

| Do | Don't |
|----|----|
| shouldRepaint에서 정확한 비교 수행 | 항상 true 반환 |
| RepaintBoundary로 복잡한 위젯 격리 | 모든 위젯에 RepaintBoundary 사용 |
| Path 객체 재사용 및 캐싱 | 매 프레임 새 Path 생성 |
| 좌표 변환 함수 분리 | paint() 내부에서 복잡한 계산 |
| FilterQuality.high로 이미지 렌더링 | FilterQuality 미지정 |
| const 생성자 사용 (가능한 경우) | 불필요한 재생성 |
| AnimationController dispose | 메모리 누수 방치 |
| TextPainter layout 호출 | layout 없이 paint 호출 |
| Canvas save/restore 쌍 맞추기 | restore 누락 |
| 복잡한 연산은 isolate로 분리 | UI 스레드에서 무거운 연산 |

### 14.2 디버깅 팁

```dart
class DebugPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 경계 표시
    if (kDebugMode) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Colors.red.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // 중심점 표시
    if (kDebugMode) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        5,
        Paint()..color = Colors.red,
      );
    }

    // 실제 렌더링
    _paintContent(canvas, size);
  }

  void _paintContent(Canvas canvas, Size size) {
    // 실제 그리기 로직
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    final shouldRepaint = true; // 실제 로직

    if (kDebugMode) {
      debugPrint('shouldRepaint: $shouldRepaint');
    }

    return shouldRepaint;
  }
}
```

### 14.3 pubspec.yaml (2026)

```yaml
name: custom_painting_app
description: Flutter Custom Painting examples
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.10.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.1
  equatable: ^2.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  lints: ^6.1.0
  bloc_test: ^10.0.0  # flutter_bloc ^9.1.1과 호환됩니다

flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

### 14.4 성능 체크리스트

**렌더링 최적화:**
- [ ] shouldRepaint 정확히 구현
- [ ] RepaintBoundary 적절히 배치
- [ ] Path 캐싱 적용
- [ ] 불필요한 save/restore 제거
- [ ] FilterQuality 적절히 설정

**메모리 최적화:**
- [ ] AnimationController dispose
- [ ] 이미지 캐싱 및 해제
- [ ] 큰 List 대신 Iterable 사용
- [ ] const 생성자 활용

**코드 구조:**
- [ ] CustomPainter 로직 분리
- [ ] Bloc/State 관리 패턴 적용
- [ ] 좌표 변환 함수 재사용
- [ ] 테스트 코드 작성

---

## 마무리

Custom Painting은 Flutter에서 가장 강력한 렌더링 도구입니다. Canvas API를 마스터하면:

1. **완전한 UI 제어** - 픽셀 단위 커스터마이제이션
2. **고성능 그래픽** - 네이티브 렌더링 엔진 활용
3. **무한한 창의성** - 복잡한 차트, 게임, 애니메이션 구현

**핵심 원칙:**
- shouldRepaint 최적화가 성능의 90%
- RepaintBoundary로 렌더링 격리
- Path 재사용과 캐싱
- Clean Architecture로 로직 분리

더 자세한 내용은 [Flutter 공식 문서](https://docs.flutter.dev/ui/advanced/custom-paint)를 참고하세요.

---

## 실습 과제

### 과제 1: 커스텀 차트 위젯 구현
CustomPainter를 사용하여 막대 차트(Bar Chart)와 라인 차트(Line Chart)를 직접 그리는 위젯을 구현하세요. 데이터 바인딩, 축 레이블, 터치 인터랙션(값 표시 툴팁)을 포함해 주세요.

### 과제 2: 애니메이션 게이지 위젯
원형 게이지(Circular Gauge) 위젯을 구현하세요. AnimationController와 CustomPainter를 조합하여 값 변경 시 부드러운 애니메이션, 그라데이션 색상, 눈금 표시를 구현하세요.

---

## 관련 문서

- [FlutterInternals](../fundamentals/FlutterInternals.md) - 렌더링 파이프라인과 RenderObject
- [Animation](./Animation.md) - AnimationController와 애니메이션 통합
- [Performance](../system/Performance.md) - CustomPainter 성능 최적화

---

## Self-Check

- [ ] CustomPainter의 paint()와 shouldRepaint()를 올바르게 구현할 수 있다
- [ ] Canvas API로 기본 도형(선, 원, 사각형, 경로)을 그릴 수 있다
- [ ] Path를 활용한 복잡한 도형과 클리핑을 구현할 수 있다
- [ ] CustomPainter와 AnimationController를 조합한 애니메이션을 구현할 수 있다
