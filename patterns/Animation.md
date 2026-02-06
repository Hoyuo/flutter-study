# Flutter 애니메이션 가이드

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - 암시적/명시적 애니메이션의 차이를 이해하고 적절히 사용할 수 있다
> - Hero 애니메이션과 페이지 전환 효과를 구현할 수 있다
> - Lottie 통합 및 애니메이션 성능 최적화를 적용할 수 있다

## 개요

Flutter 애니메이션의 모든 것을 다룹니다. 암시적 애니메이션(Implicit), 명시적 애니메이션(Explicit), 커스텀 애니메이션, 페이지 전환, Hero 애니메이션, Lottie 통합, 성능 최적화 및 접근성 고려사항을 포함합니다.

## 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  lottie: ^3.3.1  # Lottie 애니메이션 (2026년 1월 기준)
  rive: ^0.13.19  # Rive 애니메이션 (선택사항)
  flutter_animate: ^4.5.2  # 선언적 애니메이션 헬퍼
  animations: ^2.0.11  # Material 모션 라이브러리
```

## 애니메이션 선택 가이드

| 요구사항 | 권장 방식 | 난이도 |
|---------|----------|-------|
| 단순 속성 변경 (크기, 색상, 위치) | 암시적 애니메이션 | 쉬움 |
| 반복, 되감기, 중간 제어 필요 | 명시적 애니메이션 | 중간 |
| 복잡한 시퀀스, 스태거 효과 | AnimationController + Interval | 어려움 |
| 외부 디자인 애니메이션 | Lottie / Rive | 쉬움 |
| 페이지 전환 | GoRouter CustomTransitionPage | 중간 |
| 공유 요소 전환 | Hero | 쉬움 |

## 암시적 애니메이션 (Implicit Animation)

가장 간단한 애니메이션 방식입니다. 상태 변경 시 자동으로 애니메이션됩니다.

### AnimatedContainer

```dart
class AnimatedBoxExample extends StatefulWidget {
  const AnimatedBoxExample({super.key});

  @override
  State<AnimatedBoxExample> createState() => _AnimatedBoxExampleState();
}

class _AnimatedBoxExampleState extends State<AnimatedBoxExample> {
  bool _isExpanded = false;
  bool _isActive = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
          _isActive = !_isActive;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isExpanded ? 200 : 100,
        height: _isExpanded ? 200 : 100,
        decoration: BoxDecoration(
          color: _isActive ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(_isExpanded ? 16 : 8),
          boxShadow: _isActive
              ? [
                  BoxShadow(
                    // Flutter 3.27+ (Dart 3.6+): withValues() 사용
                    // Flutter 3.27 미만: Colors.blue.withOpacity(0.4) 사용
                    color: Colors.blue.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: const Center(
          child: Icon(Icons.touch_app, color: Colors.white),
        ),
      ),
    );
  }
}
```

### AnimatedOpacity

```dart
class FadeExample extends StatefulWidget {
  const FadeExample({super.key});

  @override
  State<FadeExample> createState() => _FadeExampleState();
}

class _FadeExampleState extends State<FadeExample> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => setState(() => _isVisible = !_isVisible),
          child: Text(_isVisible ? '숨기기' : '보이기'),
        ),
        const SizedBox(height: 16),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isVisible ? 1.0 : 0.0,
          curve: Curves.easeInOut,
          child: Container(
            width: 150,
            height: 150,
            color: Colors.blue,
            child: const Center(
              child: Text('Fade Me', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}
```

### AnimatedSwitcher

위젯이 변경될 때 자동으로 전환 애니메이션을 적용합니다.

```dart
class CounterSwitcher extends StatefulWidget {
  const CounterSwitcher({super.key});

  @override
  State<CounterSwitcher> createState() => _CounterSwitcherState();
}

class _CounterSwitcherState extends State<CounterSwitcher> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: Text(
            '$_count',
            // Key가 중요! 값이 변경되면 위젯이 다르다고 인식
            key: ValueKey(_count),
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => setState(() => _count++),
          child: const Text('증가'),
        ),
      ],
    );
  }
}
```

### AnimatedCrossFade

두 위젯 간 크로스페이드 전환을 구현합니다.

```dart
class CrossFadeExample extends StatefulWidget {
  const CrossFadeExample({super.key});

  @override
  State<CrossFadeExample> createState() => _CrossFadeExampleState();
}

class _CrossFadeExampleState extends State<CrossFadeExample> {
  bool _showFirst = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showFirst = !_showFirst),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState:
            _showFirst ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        firstChild: Container(
          width: 200,
          height: 100,
          color: Colors.blue,
          child: const Center(
            child: Text('First', style: TextStyle(color: Colors.white)),
          ),
        ),
        secondChild: Container(
          width: 200,
          height: 200,
          color: Colors.green,
          child: const Center(
            child: Text('Second', style: TextStyle(color: Colors.white)),
          ),
        ),
        // 크기가 다를 때 레이아웃 조정
        sizeCurve: Curves.easeInOut,
      ),
    );
  }
}
```

### AnimatedPositioned

Stack 내에서 위치 애니메이션을 적용합니다.

```dart
class MovingBoxExample extends StatefulWidget {
  const MovingBoxExample({super.key});

  @override
  State<MovingBoxExample> createState() => _MovingBoxExampleState();
}

class _MovingBoxExampleState extends State<MovingBoxExample> {
  bool _isMoved = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isMoved = !_isMoved),
      child: SizedBox(
        height: 300,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              left: _isMoved ? 200 : 50,
              top: _isMoved ? 200 : 50,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 기타 암시적 애니메이션 위젯

```dart
// AnimatedPadding
AnimatedPadding(
  duration: const Duration(milliseconds: 200),
  padding: EdgeInsets.all(_isExpanded ? 32 : 8),
  child: child,
)

// AnimatedAlign
AnimatedAlign(
  duration: const Duration(milliseconds: 300),
  alignment: _isLeft ? Alignment.centerLeft : Alignment.centerRight,
  child: child,
)

// AnimatedDefaultTextStyle
AnimatedDefaultTextStyle(
  duration: const Duration(milliseconds: 200),
  style: TextStyle(
    fontSize: _isLarge ? 24 : 16,
    fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
    color: _isHighlighted ? Colors.blue : Colors.black,
  ),
  child: const Text('Animated Text'),
)

// AnimatedPhysicalModel
AnimatedPhysicalModel(
  duration: const Duration(milliseconds: 200),
  shape: BoxShape.rectangle,
  elevation: _isElevated ? 8 : 2,
  color: Colors.white,
  shadowColor: Colors.black,
  borderRadius: BorderRadius.circular(8),
  child: child,
)

// AnimatedTheme
AnimatedTheme(
  duration: const Duration(milliseconds: 300),
  data: _isDark ? ThemeData.dark() : ThemeData.light(),
  child: child,
)
```

## 명시적 애니메이션 (Explicit Animation)

더 세밀한 제어가 필요할 때 사용합니다. AnimationController를 직접 관리합니다.

### 기본 구조

```dart
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slideOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _slideOffset = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // 딜레이 후 시작
    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideOffset,
      child: FadeTransition(
        opacity: _opacity,
        child: widget.child,
      ),
    );
  }
}
```

### 반복 애니메이션

```dart
class PulseAnimation extends StatefulWidget {
  final Widget child;

  const PulseAnimation({super.key, required this.child});

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // 무한 반복 (앞뒤로)
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}
```

### 다중 애니메이션 (Multiple Controllers)

```dart
class MultipleAnimationExample extends StatefulWidget {
  const MultipleAnimationExample({super.key});

  @override
  State<MultipleAnimationExample> createState() =>
      _MultipleAnimationExampleState();
}

class _MultipleAnimationExampleState extends State<MultipleAnimationExample>
    with TickerProviderStateMixin {
  // 여러 컨트롤러 사용 시 TickerProviderStateMixin 사용
  late final AnimationController _scaleController;
  late final AnimationController _rotationController;
  late final AnimationController _colorController;

  late final Animation<double> _scale;
  late final Animation<double> _rotation;
  late final Animation<Color?> _color;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scale = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // dart:math의 pi 사용
    _rotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _color = ColorTween(begin: Colors.blue, end: Colors.red).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );
  }

  void _playAll() {
    _scaleController.forward(from: 0);
    _rotationController.forward(from: 0);
    _colorController.forward(from: 0);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _playAll,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleController,
          _rotationController,
          _colorController,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Transform.rotate(
              angle: _rotation.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _color.value,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### Transition 위젯들

```dart
// FadeTransition - 투명도
FadeTransition(
  opacity: _animation,
  child: child,
)

// SlideTransition - 슬라이드
SlideTransition(
  position: Tween<Offset>(
    begin: const Offset(-1, 0),  // 왼쪽에서
    end: Offset.zero,
  ).animate(_controller),
  child: child,
)

// ScaleTransition - 크기
ScaleTransition(
  scale: _animation,
  alignment: Alignment.center,
  child: child,
)

// RotationTransition - 회전
RotationTransition(
  turns: _animation,  // 1.0 = 360도
  child: child,
)

// SizeTransition - 크기 (한 축)
SizeTransition(
  sizeFactor: _animation,
  axis: Axis.vertical,
  child: child,
)

// DecoratedBoxTransition - 데코레이션
DecoratedBoxTransition(
  decoration: DecorationTween(
    begin: const BoxDecoration(color: Colors.blue),
    end: const BoxDecoration(color: Colors.red),
  ).animate(_controller),
  child: child,
)

// PositionedTransition - Stack 내 위치
PositionedTransition(
  rect: RelativeRectTween(
    begin: RelativeRect.fromLTRB(0, 0, 0, 0),
    end: RelativeRect.fromLTRB(100, 100, 0, 0),
  ).animate(_controller),
  child: child,
)
```

## 스태거 애니메이션 (Staggered Animation)

여러 요소가 순차적으로 또는 겹쳐서 애니메이션되는 효과입니다.

### Interval을 사용한 스태거

```dart
class StaggeredListAnimation extends StatefulWidget {
  const StaggeredListAnimation({super.key});

  @override
  State<StaggeredListAnimation> createState() => _StaggeredListAnimationState();
}

class _StaggeredListAnimationState extends State<StaggeredListAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<String> _items = ['항목 1', '항목 2', '항목 3', '항목 4', '항목 5'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _createAnimation(int index) {
    final start = index * 0.1;
    final end = start + 0.4;

    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          start.clamp(0.0, 1.0),
          end.clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final animation = _createAnimation(index);

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(50 * (1 - animation.value), 0),
              child: Opacity(
                opacity: animation.value,
                child: child,
              ),
            );
          },
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(_items[index]),
          ),
        );
      },
    );
  }
}
```

### AnimatedList 활용

```dart
class AnimatedListExample extends StatefulWidget {
  const AnimatedListExample({super.key});

  @override
  State<AnimatedListExample> createState() => _AnimatedListExampleState();
}

class _AnimatedListExampleState extends State<AnimatedListExample> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<String> _items = [];
  int _counter = 0;

  void _addItem() {
    _counter++;
    final index = _items.length;
    _items.add('항목 $_counter');
    _listKey.currentState?.insertItem(
      index,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _removeItem(int index) {
    final removedItem = _items[index];
    _items.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildItem(removedItem, animation),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildItem(String item, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: animation,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(item),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                final index = _items.indexOf(item);
                if (index != -1) _removeItem(index);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AnimatedList')),
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _items.length,
        itemBuilder: (context, index, animation) {
          return _buildItem(_items[index], animation);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### flutter_animate 패키지 활용

```dart
import 'package:flutter_animate/flutter_animate.dart';

class FlutterAnimateExample extends StatefulWidget {
  const FlutterAnimateExample({super.key});

  @override
  State<FlutterAnimateExample> createState() => _FlutterAnimateExampleState();
}

class _FlutterAnimateExampleState extends State<FlutterAnimateExample> {
  bool _isActive = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 간단한 페이드 + 슬라이드
        const Text('Hello World')
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.3, end: 0),

        // 연속 애니메이션
        Container(width: 100, height: 100, color: Colors.blue)
            .animate()
            .fadeIn(duration: 300.ms)
            .then(delay: 100.ms)  // 순차 실행
            .scale(begin: const Offset(0.8, 0.8))
            .then()
            .shimmer(duration: 1000.ms),

        // 스태거 리스트
        Column(
          children: [
            for (int i = 0; i < 5; i++)
              ListTile(title: Text('Item $i'))
                  .animate(delay: (100 * i).ms)
                  .fadeIn()
                  .slideX(begin: 0.2),
          ],
        ),

        // 반복 애니메이션
        const Icon(Icons.favorite, color: Colors.red, size: 48)
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
            .then()
            .shake(),

        // 조건부 애니메이션
        GestureDetector(
          onTap: () => setState(() => _isActive = !_isActive),
          child: Container(color: Colors.green, width: 50, height: 50)
              .animate(target: _isActive ? 1 : 0)
              .scaleXY(end: 1.5)
              .tint(color: Colors.purple),
        ),
      ],
    );
  }
}
```

## 페이지 전환 애니메이션

### GoRouter 커스텀 전환

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/detail/:id',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: DetailPage(id: state.pathParameters['id']!),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 페이드 + 슬라이드 업
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const ProfilePage(),
          transitionsBuilder: _slideFromRight,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsPage(),
          transitionsBuilder: _fadeScale,
        );
      },
    ),
  ],
);

// 재사용 가능한 전환 빌더들
Widget _slideFromRight(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    )),
    child: child,
  );
}

Widget _fadeScale(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      ),
      child: child,
    ),
  );
}
```

### 전환 헬퍼 클래스

```dart
// lib/core/router/page_transitions.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum PageTransitionType {
  fade,
  slideUp,
  slideRight,
  scale,
  fadeScale,
  none,
}

class AppPageTransition {
  static CustomTransitionPage build({
    required Widget child,
    required GoRouterState state,
    PageTransitionType type = PageTransitionType.fade,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: _getTransitionBuilder(type),
    );
  }

  static Widget Function(
    BuildContext,
    Animation<double>,
    Animation<double>,
    Widget,
  ) _getTransitionBuilder(PageTransitionType type) {
    switch (type) {
      case PageTransitionType.fade:
        return (_, animation, __, child) => FadeTransition(
              opacity: animation,
              child: child,
            );

      case PageTransitionType.slideUp:
        return (_, animation, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );

      case PageTransitionType.slideRight:
        return (_, animation, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );

      case PageTransitionType.scale:
        return (_, animation, __, child) => ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            );

      case PageTransitionType.fadeScale:
        return (_, animation, __, child) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );

      case PageTransitionType.none:
        return (_, __, ___, child) => child;
    }
  }
}

// 사용 예시
GoRoute(
  path: '/detail',
  pageBuilder: (context, state) => AppPageTransition.build(
    child: const DetailPage(),
    state: state,
    type: PageTransitionType.fadeScale,
  ),
)
```

### Material 모션 (animations 패키지)

```dart
import 'package:animations/animations.dart';

// SharedAxisTransition - 공유 축 전환
GoRoute(
  path: '/next',
  pageBuilder: (context, state) {
    return CustomTransitionPage(
      child: const NextPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
    );
  },
)

// FadeThroughTransition - 페이드 스루
PageRouteBuilder(
  pageBuilder: (context, animation, secondaryAnimation) => const NextPage(),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeThroughTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  },
)

// OpenContainer - 컨테이너 확장
OpenContainer(
  closedBuilder: (context, openContainer) {
    return ListTile(
      title: const Text('탭하여 열기'),
      onTap: openContainer,
    );
  },
  openBuilder: (context, closeContainer) {
    return DetailPage(onClose: closeContainer);
  },
  transitionDuration: const Duration(milliseconds: 500),
  closedElevation: 0,
  openElevation: 4,
  closedShape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
)
```

## Hero 애니메이션

화면 간 공유 요소 전환을 구현합니다.

### 기본 Hero

```dart
// 목록 페이지
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () => context.push('/product/${product.id}'),
          child: Hero(
            tag: 'product-image-${product.id}',
            child: Image.network(
              product.imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}

// 상세 페이지
class ProductDetailPage extends StatelessWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final product = getProduct(productId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-image-${product.id}',
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(product.name),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 커스텀 Hero 전환

```dart
Hero(
  tag: 'custom-hero-$id',
  // 전환 중 위젯이 어떻게 날아가는지 커스터마이즈
  flightShuttleBuilder: (
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              // 전환 중 borderRadius 애니메이션
              Tween<double>(begin: 8, end: 0).evaluate(animation),
            ),
            child: child,
          ),
        );
      },
      child: Image.network(imageUrl, fit: BoxFit.cover),
    );
  },
  // 플레이스홀더 (Hero가 날아간 자리)
  placeholderBuilder: (context, heroSize, child) {
    return Container(
      width: heroSize.width,
      height: heroSize.height,
      color: Colors.grey[200],
    );
  },
  child: Image.network(imageUrl),
)
```

### Hero + Text

```dart
// 텍스트 Hero는 Material로 감싸야 함
Hero(
  tag: 'title-$id',
  child: Material(
    color: Colors.transparent,
    child: Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium,
    ),
  ),
)
```

## Lottie 애니메이션

### 기본 사용

```dart
import 'package:lottie/lottie.dart';

class LottieExample extends StatelessWidget {
  const LottieExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Asset에서 로드
        Lottie.asset(
          'assets/animations/loading.json',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),

        // 네트워크에서 로드
        Lottie.network(
          'https://example.com/animation.json',
          width: 150,
          height: 150,
        ),

        // 한 번만 재생
        Lottie.asset(
          'assets/animations/success.json',
          repeat: false,
          onLoaded: (composition) {
            // 애니메이션 로드 완료
          },
        ),

        // 역방향 재생
        Lottie.asset(
          'assets/animations/toggle.json',
          reverse: true,
        ),
      ],
    );
  }
}
```

### Lottie 제어

```dart
class ControlledLottie extends StatefulWidget {
  const ControlledLottie({super.key});

  @override
  State<ControlledLottie> createState() => _ControlledLottieState();
}

class _ControlledLottieState extends State<ControlledLottie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Lottie.asset(
          'assets/animations/like.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller.duration = composition.duration;
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _controller.forward(),
            ),
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () => _controller.stop(),
            ),
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: () => _controller.reset(),
            ),
            IconButton(
              icon: const Icon(Icons.repeat),
              onPressed: () => _controller.repeat(),
            ),
          ],
        ),
        // 슬라이더로 프레임 제어
        Slider(
          value: _controller.value,
          onChanged: (value) {
            _controller.value = value;
          },
        ),
      ],
    );
  }
}
```

### 상태 기반 Lottie

```dart
class LikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;

  const LikeButton({
    super.key,
    required this.isLiked,
    required this.onTap,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    if (widget.isLiked) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked) {
      if (widget.isLiked) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Lottie.asset(
        'assets/animations/like.json',
        controller: _controller,
        width: 60,
        height: 60,
        onLoaded: (composition) {
          _controller.duration = composition.duration;
        },
      ),
    );
  }
}
```

## 성능 최적화

### RepaintBoundary 사용

```dart
class OptimizedAnimation extends StatefulWidget {
  const OptimizedAnimation({super.key});

  @override
  State<OptimizedAnimation> createState() => _OptimizedAnimationState();
}

class _OptimizedAnimationState extends State<OptimizedAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 애니메이션 위젯을 RepaintBoundary로 격리
        RepaintBoundary(
          child: FadeTransition(
            opacity: _animation,
            child: const FlutterLogo(size: 100),
          ),
        ),
        // 정적 콘텐츠는 다시 그리지 않음
        const Text('Static Content'),
      ],
    );
  }
}
```

### 애니메이션 위젯 분리

```dart
// BAD: 전체 위젯 rebuild
class BadExample extends StatefulWidget {
  const BadExample({super.key});

  @override
  State<BadExample> createState() => _BadExampleState();
}

class _BadExampleState extends State<BadExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          children: [
            // 이 위젯들 모두 매 프레임 rebuild
            // ExpensiveWidget: 복잡한 계산이 필요한 커스텀 위젯 (예시)
            const SizedBox(height: 100, child: Placeholder()),
            Transform.scale(
              scale: _controller.value,
              // Target: 애니메이션 타겟 위젯 (예시)
              child: const FlutterLogo(size: 50),
            ),
          ],
        );
      },
    );
  }
}

// GOOD: 애니메이션 대상만 rebuild
class GoodExample extends StatefulWidget {
  const GoodExample({super.key});

  @override
  State<GoodExample> createState() => _GoodExampleState();
}

class _GoodExampleState extends State<GoodExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 이 위젯은 rebuild되지 않음
        // ExpensiveWidget: 복잡한 계산이 필요한 커스텀 위젯 (예시)
        const SizedBox(height: 100, child: Placeholder()),
        // 애니메이션 대상만 분리
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _controller.value,
              child: child,  // child는 재사용
            );
          },
          // Target: 애니메이션 타겟 위젯 (예시)
          child: const FlutterLogo(size: 50),  // child를 외부에서 전달
        ),
      ],
    );
  }
}
```

### Transform vs AnimatedContainer

```dart
// GOOD: Transform은 레이아웃에 영향 없음 (더 빠름)
Transform.scale(
  scale: 1.5,
  child: child,
)

Transform.translate(
  offset: const Offset(100, 0),
  child: child,
)

// BAD: 레이아웃 재계산 발생 (더 느림, 필요할 때만 사용)
AnimatedContainer(
  width: 150,  // 레이아웃 영향
  child: child,
)
```

### 애니메이션 일시정지

```dart
class VisibilityAwareAnimation extends StatefulWidget {
  const VisibilityAwareAnimation({super.key});

  @override
  State<VisibilityAwareAnimation> createState() =>
      _VisibilityAwareAnimationState();
}

class _VisibilityAwareAnimationState extends State<VisibilityAwareAnimation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 백그라운드로 가면 애니메이션 정지
    if (state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: const FlutterLogo(size: 100),
    );
  }
}
```

### 프레임 제한

```dart
class FrameLimitedAnimation extends StatefulWidget {
  const FrameLimitedAnimation({super.key});

  @override
  State<FrameLimitedAnimation> createState() => _FrameLimitedAnimationState();
}

class _FrameLimitedAnimationState extends State<FrameLimitedAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _lastValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // 30fps로 제한 (약 33ms마다 업데이트)
    _controller.addListener(() {
      if ((_controller.value - _lastValue).abs() > 0.033) {
        _lastValue = _controller.value;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _lastValue * 2 * pi,  // dart:math의 pi 사용
      child: const FlutterLogo(size: 100),
    );
  }
}
```

## 접근성

### 모션 줄이기 (Reduce Motion)

```dart
class AccessibleAnimation extends StatelessWidget {
  const AccessibleAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    // 시스템 설정 확인
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      // 애니메이션 없이 즉시 표시
      return const Content();
    }

    // 애니메이션 적용
    return FadeInWidget(
      child: const Content(),
    );
  }
}

// 또는 AnimatedContainer에서
AnimatedContainer(
  duration: MediaQuery.of(context).disableAnimations
      ? Duration.zero
      : const Duration(milliseconds: 300),
  // ...
)
```

### 재사용 가능한 접근성 래퍼

```dart
// lib/core/widgets/accessible_animation.dart
class AccessibleAnimation extends StatelessWidget {
  final Widget child;
  final Widget Function(Widget child) animationBuilder;

  const AccessibleAnimation({
    super.key,
    required this.child,
    required this.animationBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return child;
    }
    return animationBuilder(child);
  }
}

// 사용 예시
AccessibleAnimation(
  child: const MyWidget(),
  animationBuilder: (child) => FadeInWidget(child: child),
)
```

### 스크린 리더 고려

```dart
class AnimatedButtonWithSemantics extends StatefulWidget {
  const AnimatedButtonWithSemantics({super.key});

  @override
  State<AnimatedButtonWithSemantics> createState() =>
      _AnimatedButtonWithSemanticsState();
}

class _AnimatedButtonWithSemanticsState
    extends State<AnimatedButtonWithSemantics>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  void _handleTap() {
    setState(() => _isLoading = true);
    _controller.repeat();

    // 접근성 알림 (SemanticsService는 flutter/semantics.dart에서 제공)
    SemanticsService.announce('로딩 중입니다', TextDirection.ltr);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _controller.stop();
        SemanticsService.announce('로딩 완료', TextDirection.ltr);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !_isLoading,
      label: _isLoading ? '로딩 중' : '제출 버튼',
      child: GestureDetector(
        onTap: _isLoading ? null : _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _isLoading ? Colors.grey : Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isLoading
              ? RotationTransition(
                  turns: _controller,
                  child: const Icon(Icons.refresh, color: Colors.white),
                )
              : const Text('제출', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## 커스텀 애니메이션

### CustomPainter 애니메이션

```dart
class WaveAnimation extends StatefulWidget {
  const WaveAnimation({super.key});

  @override
  State<WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
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
          painter: WavePainter(progress: _controller.value),
          size: const Size(double.infinity, 100),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;

  WavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    // dart:math의 sin, pi 사용
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          sin((x / size.width * 2 * pi) + (progress * 2 * pi)) * 20;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
```

### TweenAnimationBuilder

간단한 커스텀 애니메이션을 빠르게 만들 수 있습니다.

```dart
class TweenAnimationExample extends StatelessWidget {
  const TweenAnimationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Animated Card'),
        ),
      ),
    );
  }
}

// 색상 애니메이션
TweenAnimationBuilder<Color?>(
  tween: ColorTween(begin: Colors.blue, end: Colors.red),
  duration: const Duration(seconds: 1),
  builder: (context, color, child) {
    return Container(
      color: color,
      child: child,
    );
  },
  child: const Text('Color Tween'),
)

// 커스텀 Tween
class PointTween extends Tween<Offset> {
  PointTween({required Offset begin, required Offset end})
      : super(begin: begin, end: end);

  @override
  Offset lerp(double t) {
    // 커스텀 보간 로직
    return Offset(
      begin!.dx + (end!.dx - begin!.dx) * Curves.elasticOut.transform(t),
      begin!.dy + (end!.dy - begin!.dy) * Curves.elasticOut.transform(t),
    );
  }
}
```

## 커스텀 Curve

```dart
import 'dart:math';  // pow, sin, pi 등 수학 함수 사용 시 필요

// 커스텀 Curve 정의
class BounceCurve extends Curve {
  @override
  double transformInternal(double t) {
    if (t < 0.5) {
      return 4 * t * t * t;
    } else {
      return 1 - pow(-2 * t + 2, 3) / 2;  // dart:math의 pow 사용
    }
  }
}

// 사용
AnimationController(
  duration: const Duration(milliseconds: 500),
  vsync: this,
);

final animation = CurvedAnimation(
  parent: controller,
  curve: BounceCurve(),
);

// 내장 Curves
// Curves.linear - 일정한 속도
// Curves.easeIn - 천천히 시작
// Curves.easeOut - 천천히 끝
// Curves.easeInOut - 양쪽 모두 천천히
// Curves.bounceIn - 바운스 시작
// Curves.bounceOut - 바운스 끝
// Curves.elasticIn - 탄성 시작
// Curves.elasticOut - 탄성 끝
// Curves.fastOutSlowIn - Material 표준
```

## 테스트

### 애니메이션 테스트

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AnimatedContainer animates correctly', (tester) async {
    bool isExpanded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: GestureDetector(
                onTap: () => setState(() => isExpanded = !isExpanded),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isExpanded ? 200 : 100,
                  height: isExpanded ? 200 : 100,
                  color: Colors.blue,
                ),
              ),
            );
          },
        ),
      ),
    );

    // 초기 크기 확인
    expect(tester.getSize(find.byType(AnimatedContainer)), const Size(100, 100));

    // 탭하여 애니메이션 시작
    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    // 애니메이션 중간 (150ms)
    await tester.pump(const Duration(milliseconds: 150));
    final midSize = tester.getSize(find.byType(AnimatedContainer));
    expect(midSize.width, greaterThan(100));
    expect(midSize.width, lessThan(200));

    // 애니메이션 완료
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AnimatedContainer)), const Size(200, 200));
  });

  testWidgets('AnimationController works correctly', (tester) async {
    // 테스트용 TickerProvider 구현
    // TestWidgetsFlutterBinding이 TickerProvider 역할을 하므로
    // StatefulWidget과 SingleTickerProviderStateMixin을 사용
    await tester.pumpWidget(
      MaterialApp(
        home: _TestAnimationWidget(),
      ),
    );

    // 테스트 위젯 내에서 애니메이션 컨트롤러가 올바르게 동작하는지 확인
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 애니메이션이 완료되었는지 확인
    expect(find.byType(FadeTransition), findsOneWidget);
  });
}

// 테스트용 위젯 - SingleTickerProviderStateMixin으로 vsync 제공
class _TestAnimationWidget extends StatefulWidget {
  @override
  State<_TestAnimationWidget> createState() => _TestAnimationWidgetState();
}

class _TestAnimationWidgetState extends State<_TestAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,  // SingleTickerProviderStateMixin이 TickerProvider 제공
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Text('Test'),
    );
  }
}
```

## 체크리스트

- [ ] 애니메이션 유형 선택 (암시적 vs 명시적)
- [ ] 적절한 duration 설정 (일반적으로 200-500ms)
- [ ] Curve 선택 (easeInOut이 대부분 적합)
- [ ] AnimationController 올바른 dispose
- [ ] SingleTickerProviderStateMixin vs TickerProviderStateMixin 선택
- [ ] RepaintBoundary로 성능 최적화
- [ ] 접근성: disableAnimations 확인
- [ ] 페이지 전환 애니메이션 일관성
- [ ] Hero 태그 고유성 확보
- [ ] Lottie 파일 크기 최적화
- [ ] 백그라운드 시 애니메이션 정지
- [ ] 테스트 작성 (pumpAndSettle 사용)

---

## 실습 과제

### 과제 1: 커스텀 페이지 전환 애니메이션
PageRouteBuilder를 사용하여 슬라이드, 페이드, 스케일 등 커스텀 페이지 전환 애니메이션을 3가지 이상 구현하세요. Hero 애니메이션과 조합하여 자연스러운 화면 전환을 만들어 보세요.

### 과제 2: Lottie + 명시적 애니메이션 조합
Lottie 애니메이션을 로딩 인디케이터와 빈 상태 화면에 적용하세요. AnimationController를 사용한 커스텀 애니메이션과 Lottie를 조합하여 풍부한 인터랙션을 구현하세요.

## Self-Check

- [ ] AnimatedContainer, AnimatedOpacity 등 암시적 애니메이션을 사용할 수 있다
- [ ] AnimationController와 Tween을 사용한 명시적 애니메이션을 구현할 수 있다
- [ ] Hero 애니메이션으로 화면 간 요소 전환을 구현할 수 있다
- [ ] 애니메이션 성능 최적화(RepaintBoundary, vsync)를 적용할 수 있다
