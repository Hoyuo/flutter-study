# Flutter 반응형 디자인 가이드

> **난이도**: 중급 | **카테고리**: features
> **선행 학습**: [LayoutSystem](../fundamentals/LayoutSystem.md)
> **예상 학습 시간**: 2h

> 이 문서는 Flutter에서 다양한 화면 크기와 디바이스(스마트폰, 태블릿, 폴더블, 웹, 데스크톱)에 대응하는 반응형 디자인 구현 방법을 다룹니다. MediaQuery, LayoutBuilder, Adaptive Layout 패턴을 활용하여 모든 플랫폼에서 최적화된 사용자 경험을 제공하는 방법을 학습합니다.

> **학습 목표**:
> 1. 반응형(Responsive)과 적응형(Adaptive) 디자인 원칙을 이해하고, Breakpoint 기반 레이아웃 전환을 구현할 수 있다
> 2. MediaQuery와 LayoutBuilder를 활용하여 화면 크기와 방향에 따라 동적으로 UI를 조정할 수 있다
> 3. 폴더블, 웹, 데스크톱 등 다양한 플랫폼 특성을 고려한 적응형 레이아웃을 설계하고 구현할 수 있다

---

## 목차

1. [반응형 디자인 원칙](#1-반응형-디자인-원칙)
2. [MediaQuery 활용](#2-mediaquery-활용)
3. [LayoutBuilder와 OrientationBuilder](#3-layoutbuilder와-orientationbuilder)
4. [반응형 그리드 시스템](#4-반응형-그리드-시스템)
5. [Adaptive Layout 패턴](#5-adaptive-layout-패턴)
6. [폴더블 디바이스 대응](#6-폴더블-디바이스-대응)
7. [웹과 데스크톱 대응](#7-웹과-데스크톱-대응)
8. [텍스트 스케일링과 접근성](#8-텍스트-스케일링과-접근성)
9. [반응형 이미지 처리](#9-반응형-이미지-처리)
10. [실전 패턴: AppLayout 설계](#10-실전-패턴-applayout-설계)

---

## 1. 반응형 디자인 원칙

### 1.1 Responsive vs Adaptive

**Responsive Design**은 하나의 레이아웃이 화면 크기에 따라 유연하게 변형되는 방식입니다.

**Adaptive Design**은 특정 Breakpoint에서 완전히 다른 레이아웃으로 전환하는 방식입니다.

```dart
// Responsive: 비율 기반 레이아웃
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: width * 0.8, // 화면 너비의 80%
      padding: EdgeInsets.all(width * 0.05), // 화면 너비의 5%
      child: const Text('Responsive Container'),
    );
  }
}

// Adaptive: Breakpoint 기반 전환
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) {
      return const MobileLayout();
    } else if (width < 1200) {
      return const TabletLayout();
    } else {
      return const DesktopLayout();
    }
  }
}
```

### 1.2 Breakpoint 정의

Material Design 3 권장 Breakpoint:

```dart
class Breakpoints {
  // Compact: 0-599 (Phone Portrait)
  static const double compact = 600;

  // Medium: 600-839 (Phone Landscape, Tablet Portrait)
  static const double medium = 840;

  // Expanded: 840-1199 (Tablet Landscape)
  static const double expanded = 1200;

  // Large: 1200-1599 (Desktop)
  static const double large = 1600;

  // Extra Large: 1600+ (Wide Desktop)
  static const double extraLarge = 1600;
}

enum ScreenSize {
  compact,
  medium,
  expanded,
  large,
  extraLarge;

  static ScreenSize fromWidth(double width) {
    if (width < Breakpoints.compact) return ScreenSize.compact;
    if (width < Breakpoints.medium) return ScreenSize.medium;
    if (width < Breakpoints.expanded) return ScreenSize.expanded;
    if (width < Breakpoints.large) return ScreenSize.large;
    return ScreenSize.extraLarge;
  }
}
```

### 1.3 반응형 디자인 체크리스트

```dart
/// 반응형 디자인 시 고려해야 할 요소들
class ResponsiveChecklist {
  // 1. 화면 크기와 방향
  final Size screenSize;
  final Orientation orientation;

  // 2. 텍스트 스케일 팩터 (접근성)
  // ⚠️ textScaleFactor는 deprecated되었습니다. MediaQuery.textScalerOf(context)를 사용하세요.
  final double textScaleFactor;

  // 3. 플랫폼별 여백 (노치, 상태바, 네비게이션 바)
  final EdgeInsets viewPadding;
  final EdgeInsets viewInsets; // 키보드 등

  // 4. 플랫폼 특성
  final TargetPlatform platform;
  final bool isWeb;
  final bool isMobile;
  final bool isDesktop;

  // 5. 입력 방식
  final bool hasTouchScreen;
  final bool hasMouse;
  final bool hasKeyboard;

  const ResponsiveChecklist({
    required this.screenSize,
    required this.orientation,
    required this.textScaleFactor,
    required this.viewPadding,
    required this.viewInsets,
    required this.platform,
    required this.isWeb,
    required this.isMobile,
    required this.isDesktop,
    required this.hasTouchScreen,
    required this.hasMouse,
    required this.hasKeyboard,
  });

  factory ResponsiveChecklist.of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final platform = Theme.of(context).platform;

    return ResponsiveChecklist(
      screenSize: mediaQuery.size,
      orientation: mediaQuery.orientation,
      textScaleFactor: mediaQuery.textScaleFactor,
      viewPadding: mediaQuery.viewPadding,
      viewInsets: mediaQuery.viewInsets,
      platform: platform,
      isWeb: kIsWeb,
      isMobile: platform == TargetPlatform.iOS || platform == TargetPlatform.android,
      isDesktop: platform == TargetPlatform.macOS ||
                 platform == TargetPlatform.windows ||
                 platform == TargetPlatform.linux,
      hasTouchScreen: mediaQuery.size.shortestSide < Breakpoints.compact,
      hasMouse: !kIsWeb && (platform == TargetPlatform.macOS ||
                            platform == TargetPlatform.windows ||
                            platform == TargetPlatform.linux),
      hasKeyboard: mediaQuery.viewInsets.bottom > 0,
    );
  }
}
```

---

## 2. MediaQuery 활용

### 2.1 기본 사용법

```dart
class MediaQueryExample extends StatelessWidget {
  const MediaQueryExample({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('MediaQuery 예제')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('화면 크기: ${mediaQuery.size.width} x ${mediaQuery.size.height}'),
            Text('방향: ${mediaQuery.orientation}'),
            // ⚠️ textScaleFactor는 deprecated - MediaQuery.textScalerOf(context) 사용 권장
            Text('텍스트 스케일: ${mediaQuery.textScaleFactor}'),
            Text('픽셀 밀도: ${mediaQuery.devicePixelRatio}'),
            Text('상단 안전 영역: ${mediaQuery.viewPadding.top}'),
            Text('하단 안전 영역: ${mediaQuery.viewPadding.bottom}'),
            Text('플랫폼 밝기: ${mediaQuery.platformBrightness}'),
          ],
        ),
      ),
    );
  }
}
```

### 2.2 반응형 여백과 패딩

```dart
class ResponsivePadding {
  static EdgeInsets symmetric(BuildContext context, {
    double? horizontal,
    double? vertical,
  }) {
    final width = MediaQuery.of(context).size.width;
    final screenSize = ScreenSize.fromWidth(width);

    double horizontalPadding = horizontal ?? _getHorizontalPadding(screenSize);
    double verticalPadding = vertical ?? _getVerticalPadding(screenSize);

    return EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
  }

  static double _getHorizontalPadding(ScreenSize screenSize) {
    return switch (screenSize) {
      ScreenSize.compact => 16.0,
      ScreenSize.medium => 24.0,
      ScreenSize.expanded => 32.0,
      ScreenSize.large => 40.0,
      ScreenSize.extraLarge => 48.0,
    };
  }

  static double _getVerticalPadding(ScreenSize screenSize) {
    return switch (screenSize) {
      ScreenSize.compact => 8.0,
      ScreenSize.medium => 12.0,
      ScreenSize.expanded => 16.0,
      ScreenSize.large => 20.0,
      ScreenSize.extraLarge => 24.0,
    };
  }

  /// Safe Area를 고려한 패딩
  static EdgeInsets safeArea(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = symmetric(context);

    return EdgeInsets.only(
      left: padding.left,
      right: padding.right,
      top: padding.top + mediaQuery.viewPadding.top,
      bottom: padding.bottom + mediaQuery.viewPadding.bottom,
    );
  }
}

// 사용 예제
class ResponsiveScreen extends StatelessWidget {
  const ResponsiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: ResponsivePadding.safeArea(context),
        child: Column(
          children: [
            const Text('화면 크기에 따라 패딩이 조정됩니다'),
            SizedBox(height: ResponsivePadding._getVerticalPadding(
              ScreenSize.fromWidth(MediaQuery.of(context).size.width),
            )),
            ElevatedButton(
              onPressed: () {},
              child: const Text('버튼'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2.3 반응형 타이포그래피

```dart
extension ResponsiveText on TextStyle {
  /// 화면 크기에 따라 폰트 크기 조정
  TextStyle responsive(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final screenSize = ScreenSize.fromWidth(width);

    final scale = switch (screenSize) {
      ScreenSize.compact => 1.0,
      ScreenSize.medium => 1.1,
      ScreenSize.expanded => 1.15,
      ScreenSize.large => 1.2,
      ScreenSize.extraLarge => 1.25,
    };

    return copyWith(fontSize: (fontSize ?? 14) * scale);
  }
}

class ResponsiveTextExample extends StatelessWidget {
  const ResponsiveTextExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '제목',
          style: theme.textTheme.headlineLarge?.responsive(context),
        ),
        Text(
          '부제목',
          style: theme.textTheme.titleMedium?.responsive(context),
        ),
        Text(
          '본문 내용입니다.',
          style: theme.textTheme.bodyMedium?.responsive(context),
        ),
      ],
    );
  }
}
```

---

## 3. LayoutBuilder와 OrientationBuilder

### 3.1 LayoutBuilder 기본

LayoutBuilder는 부모 위젯의 제약 조건(constraints)을 기반으로 자식을 빌드합니다.

```dart
class LayoutBuilderExample extends StatelessWidget {
  const LayoutBuilderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LayoutBuilder 예제')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // constraints.maxWidth: 부모가 허용하는 최대 너비
          // constraints.maxHeight: 부모가 허용하는 최대 높이

          if (constraints.maxWidth < 600) {
            return _buildMobileLayout();
          } else if (constraints.maxWidth < 1200) {
            return _buildTabletLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      children: [
        _buildHeader(),
        _buildContent(),
        _buildSidebar(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ListView(
            children: [
              _buildHeader(),
              _buildContent(),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: _buildSidebar(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        const SizedBox(
          width: 250,
          child: NavigationRail(
            selectedIndex: 0,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('홈'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search),
                label: Text('검색'),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: ListView(
            children: [
              _buildHeader(),
              _buildContent(),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: _buildSidebar(),
        ),
      ],
    );
  }

  Widget _buildHeader() => Container(
    height: 200,
    color: Colors.blue,
    child: const Center(child: Text('Header')),
  );

  Widget _buildContent() => Container(
    padding: const EdgeInsets.all(16),
    child: const Text('Main Content'),
  );

  Widget _buildSidebar() => Container(
    color: Colors.grey[200],
    child: const Center(child: Text('Sidebar')),
  );
}
```

### 3.2 OrientationBuilder

```dart
class OrientationBuilderExample extends StatelessWidget {
  const OrientationBuilderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orientation 예제')),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return GridView.count(
            crossAxisCount: orientation == Orientation.portrait ? 2 : 4,
            children: List.generate(20, (index) {
              return Card(
                child: Center(child: Text('Item $index')),
              );
            }),
          );
        },
      ),
    );
  }
}
```

### 3.3 LayoutBuilder + OrientationBuilder 조합

```dart
class AdaptiveGridView extends StatelessWidget {
  final List<Widget> children;

  const AdaptiveGridView({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            final crossAxisCount = _getCrossAxisCount(
              constraints.maxWidth,
              orientation,
            );

            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              padding: ResponsivePadding.symmetric(context),
              children: children,
            );
          },
        );
      },
    );
  }

  int _getCrossAxisCount(double width, Orientation orientation) {
    if (orientation == Orientation.portrait) {
      if (width < 600) return 2;
      if (width < 1200) return 3;
      return 4;
    } else {
      if (width < 600) return 3;
      if (width < 1200) return 4;
      return 6;
    }
  }
}
```

---

## 4. 반응형 그리드 시스템

### 4.1 12-Column Grid System

```dart
class GridColumn {
  final int span; // 1-12
  final Widget child;

  const GridColumn({
    required this.span,
    required this.child,
  }) : assert(span >= 1 && span <= 12);
}

class ResponsiveGrid extends StatelessWidget {
  final List<GridColumn> columns;
  final double spacing;

  const ResponsiveGrid({
    super.key,
    required this.columns,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final screenSize = ScreenSize.fromWidth(width);

        // 작은 화면에서는 스택 레이아웃으로 전환
        if (screenSize == ScreenSize.compact) {
          return Column(
            children: columns.map((col) => col.child).toList(),
          );
        }

        // 큰 화면에서는 그리드 레이아웃
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildGridColumns(width),
        );
      },
    );
  }

  List<Widget> _buildGridColumns(double totalWidth) {
    final columnWidth = (totalWidth - (spacing * 11)) / 12;

    return columns.map((column) {
      final width = (columnWidth * column.span) + (spacing * (column.span - 1));

      return SizedBox(
        width: width,
        child: column.child,
      );
    }).toList();
  }
}

// 사용 예제
class GridExample extends StatelessWidget {
  const GridExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('12-Column Grid')),
      body: SingleChildScrollView(
        child: Padding(
          padding: ResponsivePadding.symmetric(context),
          child: ResponsiveGrid(
            columns: [
              GridColumn(
                span: 8,
                child: Container(
                  height: 200,
                  color: Colors.blue,
                  child: const Center(child: Text('Main (8/12)')),
                ),
              ),
              GridColumn(
                span: 4,
                child: Container(
                  height: 200,
                  color: Colors.green,
                  child: const Center(child: Text('Sidebar (4/12)')),
                ),
              ),
              GridColumn(
                span: 4,
                child: Container(
                  height: 150,
                  color: Colors.red,
                  child: const Center(child: Text('Card (4/12)')),
                ),
              ),
              GridColumn(
                span: 4,
                child: Container(
                  height: 150,
                  color: Colors.orange,
                  child: const Center(child: Text('Card (4/12)')),
                ),
              ),
              GridColumn(
                span: 4,
                child: Container(
                  height: 150,
                  color: Colors.purple,
                  child: const Center(child: Text('Card (4/12)')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 4.2 Flexbox 스타일 레이아웃

```dart
class FlexItem {
  final int flex;
  final Widget child;

  const FlexItem({
    this.flex = 1,
    required this.child,
  });
}

class ResponsiveFlex extends StatelessWidget {
  final List<FlexItem> items;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const ResponsiveFlex({
    super.key,
    required this.items,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < Breakpoints.compact) {
          // 모바일: 세로 스택
          return Column(
            crossAxisAlignment: crossAxisAlignment,
            children: items
                .map((item) => Padding(
                      padding: EdgeInsets.only(bottom: spacing),
                      child: item.child,
                    ))
                .toList(),
          );
        }

        // 태블릿/데스크톱: 가로 Flex
        return Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: items
              .expand((item) => [
                    Expanded(flex: item.flex, child: item.child),
                    if (item != items.last) SizedBox(width: spacing),
                  ])
              .toList(),
        );
      },
    );
  }
}
```

---

## 5. Adaptive Layout 패턴

### 5.1 Master-Detail 패턴

```dart
class MasterDetailScreen extends StatefulWidget {
  const MasterDetailScreen({super.key});

  @override
  State<MasterDetailScreen> createState() => _MasterDetailScreenState();
}

class _MasterDetailScreenState extends State<MasterDetailScreen> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master-Detail')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < Breakpoints.medium) {
            // 모바일: 내비게이션으로 전환
            return _buildMasterView();
          } else {
            // 태블릿/데스크톱: 나란히 표시
            return Row(
              children: [
                SizedBox(
                  width: 300,
                  child: _buildMasterView(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _selectedIndex == null
                      ? const Center(child: Text('항목을 선택하세요'))
                      : _buildDetailView(_selectedIndex!),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildMasterView() {
    return ListView.builder(
      itemCount: 20,
      itemBuilder: (context, index) {
        return ListTile(
          selected: _selectedIndex == index,
          title: Text('Item $index'),
          onTap: () {
            setState(() => _selectedIndex = index);

            // 모바일에서는 상세 화면으로 이동
            if (MediaQuery.of(context).size.width < Breakpoints.medium) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text('Item $index')),
                    body: _buildDetailView(index),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildDetailView(int index) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Detail View',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text('Selected: Item $index'),
        ],
      ),
    );
  }
}
```

### 5.2 Adaptive Navigation

```dart
class AdaptiveNavigationScaffold extends StatefulWidget {
  final List<NavigationDestination> destinations;
  final List<Widget> screens;

  const AdaptiveNavigationScaffold({
    super.key,
    required this.destinations,
    required this.screens,
  });

  @override
  State<AdaptiveNavigationScaffold> createState() =>
      _AdaptiveNavigationScaffoldState();
}

class _AdaptiveNavigationScaffoldState
    extends State<AdaptiveNavigationScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < Breakpoints.compact) {
          // 모바일: BottomNavigationBar
          return Scaffold(
            body: widget.screens[_selectedIndex],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: widget.destinations,
            ),
          );
        } else if (constraints.maxWidth < Breakpoints.expanded) {
          // 태블릿: NavigationRail
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: widget.destinations
                      .map((dest) => NavigationRailDestination(
                            icon: dest.icon,
                            selectedIcon: dest.selectedIcon ?? dest.icon,
                            label: Text(dest.label),
                          ))
                      .toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: widget.screens[_selectedIndex],
                ),
              ],
            ),
          );
        } else {
          // 데스크톱: NavigationDrawer + Rail
          return Scaffold(
            body: Row(
              children: [
                NavigationDrawer(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'App Name',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...widget.destinations
                        .map((dest) => NavigationDrawerDestination(
                              icon: dest.icon,
                              selectedIcon: dest.selectedIcon ?? dest.icon,
                              label: Text(dest.label),
                            )),
                  ],
                ),
                Expanded(
                  child: widget.screens[_selectedIndex],
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

// 사용 예제
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AdaptiveNavigationScaffold(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: '검색',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
        screens: const [
          HomeScreen(),
          SearchScreen(),
          SettingsScreen(),
        ],
      ),
    );
  }
}
```

---

## 6. 폴더블 디바이스 대응

### 6.1 DisplayFeatures 감지

```dart
import 'dart:ui' as ui;

class FoldableDetector extends StatelessWidget {
  final Widget child;

  const FoldableDetector({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context),
      child: Builder(
        builder: (context) {
          final mediaQuery = MediaQuery.of(context);
          final displayFeatures = mediaQuery.displayFeatures;

          // Hinge나 Fold가 있는지 확인
          final hasFold = displayFeatures.any(
            (feature) => feature.type == ui.DisplayFeatureType.fold,
          );

          final hasHinge = displayFeatures.any(
            (feature) => feature.type == ui.DisplayFeatureType.hinge,
          );

          if (hasFold || hasHinge) {
            return _FoldableLayout(
              displayFeatures: displayFeatures,
              child: child,
            );
          }

          return child;
        },
      ),
    );
  }
}

class _FoldableLayout extends StatelessWidget {
  final List<ui.DisplayFeature> displayFeatures;
  final Widget child;

  const _FoldableLayout({
    required this.displayFeatures,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final hinge = displayFeatures.firstWhere(
      (feature) => feature.type == ui.DisplayFeatureType.hinge ||
                   feature.type == ui.DisplayFeatureType.fold,
    );

    final isVerticalHinge = hinge.bounds.width < hinge.bounds.height;

    if (isVerticalHinge) {
      // 세로 힌지: 좌우 분할
      return Row(
        children: [
          Expanded(child: _buildPanel(context, 0)),
          SizedBox(width: hinge.bounds.width),
          Expanded(child: _buildPanel(context, 1)),
        ],
      );
    } else {
      // 가로 힌지: 상하 분할
      return Column(
        children: [
          Expanded(child: _buildPanel(context, 0)),
          SizedBox(height: hinge.bounds.height),
          Expanded(child: _buildPanel(context, 1)),
        ],
      );
    }
  }

  Widget _buildPanel(BuildContext context, int panelIndex) {
    return Container(
      color: panelIndex == 0 ? Colors.blue[50] : Colors.green[50],
      child: Center(
        child: Text('Panel $panelIndex'),
      ),
    );
  }
}
```

### 6.2 Dual Screen 최적화

```dart
class DualScreenLayout extends StatelessWidget {
  final Widget primary;
  final Widget secondary;

  const DualScreenLayout({
    super.key,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return FoldableDetector(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mediaQuery = MediaQuery.of(context);
          final displayFeatures = mediaQuery.displayFeatures;

          if (displayFeatures.isEmpty) {
            // 일반 디바이스: 탭 인터페이스
            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'Primary'),
                      Tab(text: 'Secondary'),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [primary, secondary],
                ),
              ),
            );
          }

          // 폴더블: 듀얼 스크린
          final hinge = displayFeatures.first;
          final isVerticalHinge = hinge.bounds.width < hinge.bounds.height;

          if (isVerticalHinge) {
            return Row(
              children: [
                Expanded(child: primary),
                SizedBox(width: hinge.bounds.width),
                Expanded(child: secondary),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(child: primary),
                SizedBox(height: hinge.bounds.height),
                Expanded(child: secondary),
              ],
            );
          }
        },
      ),
    );
  }
}
```

---

## 7. 웹과 데스크톱 대응

### 7.1 마우스 호버 효과

```dart
class HoverableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const HoverableCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? Matrix4.translationValues(0, -4, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Card(
          child: InkWell(
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
```

### 7.2 키보드 단축키

```dart
class KeyboardShortcuts extends StatelessWidget {
  final Widget child;
  // ⚠️ LogicalKeySet은 deprecated - SingleActivator 사용 권장
  final Map<LogicalKeySet, VoidCallback> shortcuts;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    required this.shortcuts,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: shortcuts.map(
        (key, callback) => MapEntry(key, _CallbackIntent(callback)),
      ),
      child: Actions(
        actions: {
          _CallbackIntent: CallbackAction<_CallbackIntent>(
            onInvoke: (intent) => intent.callback(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class _CallbackIntent extends Intent {
  final VoidCallback callback;
  const _CallbackIntent(this.callback);
}

// 사용 예제
class KeyboardShortcutsExample extends StatelessWidget {
  const KeyboardShortcutsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardShortcuts(
      shortcuts: {
        // ⚠️ LogicalKeySet은 deprecated - SingleActivator로 교체 권장:
        // const SingleActivator(LogicalKeyboardKey.keyS, control: true)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): () {
          print('Ctrl+S: Save');
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): () {
          print('Ctrl+N: New');
        },
        LogicalKeySet(LogicalKeyboardKey.escape): () {
          print('ESC: Cancel');
        },
      },
      child: const Scaffold(
        body: Center(
          child: Text('Press Ctrl+S, Ctrl+N, or ESC'),
        ),
      ),
    );
  }
}
```

### 7.3 스크롤바 커스터마이징

```dart
class CustomScrollbarExample extends StatelessWidget {
  const CustomScrollbarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      thickness: 8,
      radius: const Radius.circular(4),
      child: ListView.builder(
        itemCount: 100,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Item $index'),
          );
        },
      ),
    );
  }
}
```

---

## 8. 텍스트 스케일링과 접근성

### 8.1 텍스트 스케일 대응

```dart
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    // ⚠️ textScaleFactor는 deprecated - MediaQuery.textScalerOf(context) 사용 권장
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // 텍스트 스케일이 너무 크면 제한
    final clampedTextScaleFactor = textScaleFactor.clamp(1.0, 1.5);

    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      // ⚠️ Text의 textScaleFactor 파라미터도 deprecated - textScaler 사용 권장
      textScaleFactor: clampedTextScaleFactor,
    );
  }
}
```

### 8.2 Semantic Labels

```dart
class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const AccessibleButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: true,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: label,
      ),
    );
  }
}
```

---

## 9. 반응형 이미지 처리

### 9.1 해상도별 에셋

```dart
class ResponsiveImage extends StatelessWidget {
  final String basePath; // 'assets/images/logo'
  final double? width;
  final double? height;

  const ResponsiveImage(
    this.basePath, {
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    String assetPath;
    if (devicePixelRatio >= 3.0) {
      assetPath = '$basePath@3x.png';
    } else if (devicePixelRatio >= 2.0) {
      assetPath = '$basePath@2x.png';
    } else {
      assetPath = '$basePath.png';
    }

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
```

### 9.2 Adaptive Image Size

```dart
class AdaptiveNetworkImage extends StatelessWidget {
  final String baseUrl; // 'https://example.com/image'
  final double? width;
  final double? height;

  const AdaptiveNetworkImage(
    this.baseUrl, {
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    // 실제 필요한 픽셀 크기 계산
    final targetWidth = (width ?? screenWidth) * devicePixelRatio;

    String imageUrl;
    if (targetWidth > 1920) {
      imageUrl = '${baseUrl}_2560.jpg';
    } else if (targetWidth > 1280) {
      imageUrl = '${baseUrl}_1920.jpg';
    } else if (targetWidth > 640) {
      imageUrl = '${baseUrl}_1280.jpg';
    } else {
      imageUrl = '${baseUrl}_640.jpg';
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }
}
```

---

## 10. 실전 패턴: AppLayout 설계

### 10.1 종합 레이아웃 시스템

```dart
class AppLayout extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const AppLayout({
    super.key,
    required this.child,
    this.appBar,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = ScreenSize.fromWidth(constraints.maxWidth);

        return Scaffold(
          appBar: appBar,
          drawer: screenSize == ScreenSize.compact ? drawer : null,
          endDrawer: endDrawer,
          body: _buildBody(context, screenSize),
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ScreenSize screenSize) {
    final maxContentWidth = _getMaxContentWidth(screenSize);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: ResponsivePadding.symmetric(context),
          child: child,
        ),
      ),
    );
  }

  double _getMaxContentWidth(ScreenSize screenSize) {
    return switch (screenSize) {
      ScreenSize.compact => double.infinity,
      ScreenSize.medium => 840,
      ScreenSize.expanded => 1200,
      ScreenSize.large => 1400,
      ScreenSize.extraLarge => 1600,
    };
  }
}
```

### 10.2 완전한 반응형 앱 예제

```dart
class ResponsiveApp extends StatelessWidget {
  const ResponsiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Responsive App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ResponsiveHomePage(),
    );
  }
}

class ResponsiveHomePage extends StatefulWidget {
  const ResponsiveHomePage({super.key});

  @override
  State<ResponsiveHomePage> createState() => _ResponsiveHomePageState();
}

class _ResponsiveHomePageState extends State<ResponsiveHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = ScreenSize.fromWidth(constraints.maxWidth);

        return Scaffold(
          appBar: _buildAppBar(screenSize),
          drawer: screenSize == ScreenSize.compact ? _buildDrawer() : null,
          body: Row(
            children: [
              if (screenSize != ScreenSize.compact) _buildSideNav(screenSize),
              Expanded(child: _buildContent()),
            ],
          ),
          bottomNavigationBar: screenSize == ScreenSize.compact
              ? _buildBottomNav()
              : null,
        );
      },
    );
  }

  AppBar _buildAppBar(ScreenSize screenSize) {
    return AppBar(
      title: const Text('Responsive App'),
      actions: [
        if (screenSize != ScreenSize.compact)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text('User Name'),
            accountEmail: Text('user@example.com'),
            currentAccountPicture: CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
          _buildNavItem(0, Icons.home, '홈'),
          _buildNavItem(1, Icons.search, '검색'),
          _buildNavItem(2, Icons.favorite, '즐겨찾기'),
          _buildNavItem(3, Icons.settings, '설정'),
        ],
      ),
    );
  }

  Widget _buildSideNav(ScreenSize screenSize) {
    if (screenSize == ScreenSize.medium) {
      return NavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        labelType: NavigationRailLabelType.all,
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: Text('홈'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.search),
            label: Text('검색'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: Text('즐겨찾기'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('설정'),
          ),
        ],
      );
    }

    return NavigationDrawer(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Navigation',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('홈'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.search),
          label: Text('검색'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite),
          label: Text('즐겨찾기'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('설정'),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '홈',
        ),
        NavigationDestination(
          icon: Icon(Icons.search),
          label: '검색',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite),
          label: '즐겨찾기',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: '설정',
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildContent() {
    return AppLayout(
      child: switch (_selectedIndex) {
        0 => _buildHomeContent(),
        1 => _buildSearchContent(),
        2 => _buildFavoritesContent(),
        3 => _buildSettingsContent(),
        _ => const SizedBox(),
      },
    );
  }

  Widget _buildHomeContent() {
    return AdaptiveGridView(
      children: List.generate(20, (index) {
        return HoverableCard(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  color: Colors.blue[100],
                  child: Center(child: Text('Item $index')),
                ),
                const SizedBox(height: 8),
                Text(
                  'Title $index',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Description for item $index',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSearchContent() {
    return const Center(child: Text('검색'));
  }

  Widget _buildFavoritesContent() {
    return const Center(child: Text('즐겨찾기'));
  }

  Widget _buildSettingsContent() {
    return const Center(child: Text('설정'));
  }
}
```

---

## 실습 과제

### 과제 1: 반응형 대시보드 구현

다음 요구사항을 만족하는 반응형 대시보드를 구현하세요:

1. **모바일 (< 600px)**
   - 상단 AppBar + BottomNavigationBar
   - 카드를 1열로 세로 스택 배치
   - 햄버거 메뉴로 Drawer 열기

2. **태블릿 (600-1200px)**
   - NavigationRail (좌측)
   - 카드를 2열 그리드로 배치
   - 상세 정보를 BottomSheet로 표시

3. **데스크톱 (> 1200px)**
   - NavigationDrawer (좌측, 고정)
   - 카드를 3-4열 그리드로 배치
   - 상세 정보를 우측 패널(Master-Detail)로 표시
   - 마우스 호버 시 카드 확대 애니메이션

**추가 요구사항**:
- LayoutBuilder와 MediaQuery 활용
- 화면 크기 변경 시 자연스러운 전환
- 텍스트 스케일링 지원 (1.0 ~ 1.5배)

### 과제 2: 폴더블 대응 이메일 앱

Samsung Galaxy Fold와 같은 폴더블 디바이스를 고려한 이메일 앱을 구현하세요:

1. **일반 모드 (접힌 상태)**
   - 이메일 목록만 표시
   - 이메일 선택 시 상세 화면으로 이동

2. **펼친 모드**
   - 좌측: 이메일 목록
   - 우측: 선택된 이메일 상세 내용
   - Hinge 영역을 고려한 레이아웃

3. **듀얼 스크린 모드**
   - 첫 번째 화면: 이메일 목록 + 간단한 미리보기
   - 두 번째 화면: 선택된 이메일 전체 내용

**추가 요구사항**:
- DisplayFeatures를 활용한 Hinge 감지
- 화면 회전 대응 (가로/세로 Hinge)
- 일반 디바이스와 폴더블 디바이스 모두 지원

### 과제 3: 웹/데스크톱 최적화 갤러리 앱

웹과 데스크톱 환경에 최적화된 이미지 갤러리를 구현하세요:

1. **반응형 그리드**
   - 화면 너비에 따라 열 개수 조정 (2-6열)
   - 이미지 비율 유지
   - 무한 스크롤 지원

2. **마우스 인터랙션**
   - 호버 시 이미지 확대 및 정보 표시
   - 마우스 커서 변경 (pointer)
   - 우클릭 컨텍스트 메뉴

3. **키보드 단축키**
   - 화살표 키로 이미지 네비게이션
   - ESC로 상세 보기 닫기
   - Ctrl+F로 검색 활성화

4. **반응형 이미지 로딩**
   - 썸네일 / 중간 크기 / 원본 이미지 선택적 로딩
   - 디바이스 픽셀 비율 고려
   - Progressive Loading

**추가 요구사항**:
- 커스텀 스크롤바 (웹/데스크톱)
- 드래그 앤 드롭으로 이미지 재정렬
- 접근성 레이블 추가 (Semantics)

---

## Self-Check

다음 항목을 모두 이해하고 구현할 수 있는지 확인하세요:

- [ ] MediaQuery를 활용하여 화면 크기, 방향, 텍스트 스케일, Safe Area를 확인하고 반응형 UI에 적용할 수 있다
- [ ] LayoutBuilder와 OrientationBuilder의 차이를 이해하고, 각각의 적절한 사용 시점을 설명할 수 있다
- [ ] Material Design 3의 Breakpoint 기준에 따라 Compact, Medium, Expanded, Large 레이아웃을 구분하여 구현할 수 있다
- [ ] Master-Detail 패턴을 이해하고, 화면 크기에 따라 네비게이션 방식(내비게이션 → 나란히 표시)을 전환할 수 있다
- [ ] NavigationBar, NavigationRail, NavigationDrawer를 화면 크기에 맞게 적응적으로 전환하는 Adaptive Navigation을 구현할 수 있다
- [ ] DisplayFeatures를 활용하여 폴더블 디바이스의 Hinge/Fold를 감지하고 듀얼 스크린 레이아웃을 구현할 수 있다
- [ ] MouseRegion과 SystemMouseCursors를 사용하여 웹/데스크톱 환경에서 마우스 호버 효과와 커서 변경을 구현할 수 있다
- [ ] Shortcuts와 Actions를 활용하여 키보드 단축키를 정의하고, 데스크톱 환경에서 생산성을 높일 수 있다
- [ ] 텍스트 스케일링을 제한(clamp)하고 Semantics를 활용하여 접근성을 고려한 UI를 구현할 수 있다
- [ ] 디바이스 픽셀 비율과 화면 크기를 고려하여 적절한 해상도의 이미지를 선택적으로 로딩하는 반응형 이미지 시스템을 구현할 수 있다

---

## 관련 문서

- [LayoutSystem](../fundamentals/LayoutSystem.md) - Flutter 레이아웃 시스템 기초
- [WidgetFundamentals](../fundamentals/WidgetFundamentals.md) - Widget 크기와 제약 조건
- [DesignSystem](../fundamentals/DesignSystem.md) - 디자인 토큰과 반응형 스타일링

---

**Package Versions**
- flutter_bloc: ^9.1.1
- freezed: ^3.2.4
- fpdart: ^1.2.0
- go_router: ^17.0.1
