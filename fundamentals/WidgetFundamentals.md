# Flutter Widget 기본기 가이드

> Flutter Clean Architecture + Bloc 패턴 기반 교육 자료
> Package versions: flutter_bloc ^9.1.1, freezed ^3.2.4, fpdart ^1.2.0, go_router ^17.0.1, get_it ^9.2.0, injectable ^2.5.0

> **학습 목표**:
> - Widget, Element, RenderObject의 관계와 Flutter의 렌더링 파이프라인을 이해한다
> - BuildContext의 정체를 파악하고 InheritedWidget의 동작 원리를 설명할 수 있다
> - Key의 종류와 사용 시나리오를 이해하고 리빌드 최적화를 적용할 수 있다

## 목차

1. [Widget Tree 이해](#1-widget-tree-이해)
2. [BuildContext 깊이 이해](#2-buildcontext-깊이-이해)
3. [Element Tree](#3-element-tree)
4. [State Lifecycle](#4-state-lifecycle)
5. [Key의 역할](#5-key의-역할)
6. [Widget 리빌드 최적화](#6-widget-리빌드-최적화)
7. [InheritedWidget 심화](#7-inheritedwidget-심화)
8. [StatefulWidget vs StatelessWidget](#8-statefulwidget-vs-statelesswidget)
9. [실전 안티패턴](#9-실전-안티패턴)
10. [실습 과제](#실습-과제)
11. [Self-Check](#self-check)

---

## 1. Widget Tree 이해

### 1.1 Widget의 본질

Flutter에서 Widget은 **UI 구성의 설계도(blueprint)**입니다. Widget 자체는 불변(immutable)이며, UI의 현재 구성을 선언합니다.

```dart
// Widget은 단순한 구성 정보
class MyWidget extends StatelessWidget {
  final String title;

  const MyWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title);
  }
}
```

### 1.2 Widget Tree의 구조

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Title'),
        ),
        body: Column(
          children: [
            Text('Item 1'),
            Text('Item 2'),
            CustomWidget(),
          ],
        ),
      ),
    );
  }
}
```

### 1.3 StatelessWidget

```dart
class Greeting extends StatelessWidget {
  final String name;
  final TextStyle? style;

  const Greeting({
    super.key,
    required this.name,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Hello, $name!',
      style: style ?? Theme.of(context).textTheme.headlineMedium,
    );
  }
}
```

### 1.4 StatefulWidget

```dart
class Counter extends StatefulWidget {
  final int initialValue;

  const Counter({super.key, this.initialValue = 0});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.initialValue;
  }

  void _increment() {
    setState(() {
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Count: $_count'),
        ElevatedButton(
          onPressed: _increment,
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

### 1.5 InheritedWidget

```dart
class AppTheme extends InheritedWidget {
  final Color primaryColor;
  final Color accentColor;

  const AppTheme({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    required super.child,
  });

  static AppTheme of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    assert(result != null, 'No AppTheme found in context');
    return result!;
  }

  static AppTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppTheme>();
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) {
    return primaryColor != oldWidget.primaryColor ||
           accentColor != oldWidget.accentColor;
  }
}
```

---

## 2. BuildContext 깊이 이해

### 2.1 BuildContext의 정체

BuildContext는 **Widget Tree에서의 위치를 나타내는 핸들**입니다. 실제로는 Element 객체를 참조합니다.

```dart
// context는 실제로 Element
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print(context.runtimeType); // StatelessElement 등
    return Container();
  }
}
```

### 2.2 Context의 위치

Scaffold는 build 메서드 내에서 생성되므로, build에 전달된 context는 Scaffold보다 위에 위치합니다. Builder를 사용하면 Scaffold 아래의 context를 얻을 수 있습니다.

```dart
class ContextExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Context Demo'),
      ),
      body: Builder(
        builder: (innerContext) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(innerContext).showSnackBar(
                  SnackBar(content: Text('Snackbar')),
                );
              },
              child: Text('Show Snackbar'),
            ),
          );
        },
      ),
    );
  }
}
```

### 2.3 of() 패턴 이해

```dart
class MyInheritedWidget extends InheritedWidget {
  final String data;

  const MyInheritedWidget({
    super.key,
    required this.data,
    required super.child,
  });

  static MyInheritedWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MyInheritedWidget>();
  }

  @override
  bool updateShouldNotify(MyInheritedWidget oldWidget) {
    return data != oldWidget.data;
  }
}
```

### 2.4 Context 사용 시 주의사항

```dart
// 비동기에서 context 사용
class AsyncContextExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await Future.delayed(Duration(seconds: 2));

        if (!context.mounted) return; // Flutter 3.7+

        Navigator.of(context).pop();
      },
      child: Text('Async Action'),
    );
  }
}
```

---

## 3. Element Tree

### 3.1 Widget, Element, RenderObject의 관계

```
Widget (불변 설계도)
    ↓ createElement()
Element (변경 가능한 인스턴스)
    ↓ createRenderObject()
RenderObject (실제 레이아웃 & 페인팅)
```

> **3-tree 관계 요약**:
> - **Widget**: 불변 설계도. 매 빌드마다 새로 생성될 수 있음 (가벼움)
> - **Element**: 위젯의 인스턴스를 관리하는 중간 계층. 위젯이 변경되어도 가능하면 재사용됨
> - **RenderObject**: 실제 레이아웃(크기 계산)과 페인팅(화면 그리기)을 담당. `layout()` → `paint()` → compositing 순으로 처리됨
>
> Widget은 가볍게 재생성되지만, RenderObject는 비용이 크므로 Element가 중간에서 재사용 여부를 판단합니다.

```dart
// Widget은 Element를 생성
class MyCustomWidget extends StatelessWidget {
  final String title;

  const MyCustomWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title);
  }

  @override
  StatelessElement createElement() => StatelessElement(this);
}
```

### 3.2 Element의 재사용 조건

Element 재사용 조건:
1. Widget의 runtimeType이 같아야 함
2. Key가 같아야 함 (또는 둘 다 null)

> Flutter는 내부적으로 `Widget.canUpdate(oldWidget, newWidget)`를 호출하여 재사용 여부를 판단합니다:
> ```dart
> static bool canUpdate(Widget oldWidget, Widget newWidget) {
>   return oldWidget.runtimeType == newWidget.runtimeType
>       && oldWidget.key == newWidget.key;
> }
> ```

```dart
class ElementReuseExample extends StatefulWidget {
  @override
  State<ElementReuseExample> createState() => _ElementReuseExampleState();
}

class _ElementReuseExampleState extends State<ElementReuseExample> {
  bool _showFirst = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => setState(() => _showFirst = !_showFirst),
          child: Text('Toggle'),
        ),
        if (_showFirst)
          _ColoredBox(color: Colors.red)
        else
          _ColoredBox(color: Colors.blue),
      ],
    );
  }
}

// _ColoredBox: 탭 횟수를 내부 State로 관리하는 예제 위젯
class _ColoredBox extends StatefulWidget {
  final Color color;
  const _ColoredBox({required this.color});

  @override
  State<_ColoredBox> createState() => _ColoredBoxState();
}

class _ColoredBoxState extends State<_ColoredBox> {
  int _tapCount = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _tapCount++),
      child: Container(
        width: 100, height: 100,
        color: widget.color,
        child: Center(child: Text('Taps: $_tapCount')),
      ),
    );
  }
}
```

---

## 4. State Lifecycle

### 4.1 StatefulWidget의 전체 라이프사이클

```dart
class LifecycleDemo extends StatefulWidget {
  @override
  State<LifecycleDemo> createState() {
    print('1. createState()'); // Framework이 위젯을 처음 삽입할 때
    return _LifecycleDemoState();
  }
}

// 2. State 생성자 (Dart 런타임이 호출, 명시적으로 오버라이드하지 않음)

class _LifecycleDemoState extends State<LifecycleDemo> {
  @override
  void initState() {
    super.initState();
    print('3. initState()'); // State 초기화 (1회만 호출)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('4. didChangeDependencies()'); // InheritedWidget 변경 시에도 호출
  }

  @override
  Widget build(BuildContext context) {
    print('5. build()'); // UI 구성 (setState 호출 시마다)
    return Container();
  }

  @override
  void didUpdateWidget(LifecycleDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('6. didUpdateWidget()'); // 부모가 같은 runtimeType으로 리빌드 시
  }

  @override
  void reassemble() {
    super.reassemble();
    print('7. reassemble()'); // hot reload 시 호출 (디버그 전용)
  }

  @override
  void deactivate() {
    print('8. deactivate()'); // 트리에서 제거될 때 (재삽입 가능)
    super.deactivate();
  }

  @override
  void dispose() {
    print('9. dispose()'); // 영구 제거 시 리소스 해제
    super.dispose();
  }
}
```

### 4.2 실전 활용

```dart
class PracticalLifecycle extends StatefulWidget {
  final String userId;

  const PracticalLifecycle({super.key, required this.userId});

  @override
  State<PracticalLifecycle> createState() => _PracticalLifecycleState();
}

class _PracticalLifecycleState extends State<PracticalLifecycle> {
  late ScrollController _scrollController;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadUser();
  }

  Future<void> _loadUser() async {
    // 데이터 로드
  }

  @override
  void didUpdateWidget(PracticalLifecycle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _loadUser();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

---

## 5. Key의 역할

### 5.1 Key의 필요성

Key는 Flutter가 Element를 올바르게 재사용하거나 업데이트하도록 돕습니다.

```dart
// 섹션 5에서 사용하는 헬퍼 위젯 정의
class _StatefulTile extends StatefulWidget {
  final String title;
  const _StatefulTile({super.key, required this.title});

  @override
  State<_StatefulTile> createState() => _StatefulTileState();
}

class _StatefulTileState extends State<_StatefulTile> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.title),
      selected: _selected,
      onTap: () => setState(() => _selected = !_selected),
    );
  }
}

class _Counter extends StatefulWidget {
  const _Counter({super.key});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  void increment() => setState(() => _count++);

  @override
  Widget build(BuildContext context) {
    return Text('Count: $_count');
  }
}

// ValueKey: 값 기반 비교
class ValueKeyExample extends StatelessWidget {
  final List<String> items = ['Apple', 'Banana', 'Cherry'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return _StatefulTile(
          key: ValueKey(item),
          title: item,
        );
      }).toList(),
    );
  }
}

// ObjectKey: 객체 기반 비교
class Person {
  final String id;
  final String name;

  Person(this.id, this.name);

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Person && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ObjectKeyExample extends StatelessWidget {
  final List<Person> people = [
    Person('1', 'Alice'),
    Person('2', 'Bob'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: people.map((person) {
        return _StatefulTile(
          key: ObjectKey(person),
          title: person.name,
        );
      }).toList(),
    );
  }
}

// GlobalKey: 다른 Widget에서 State 접근
class GlobalKeyExample extends StatefulWidget {
  const GlobalKeyExample({super.key});

  @override
  State<GlobalKeyExample> createState() => _GlobalKeyExampleState();
}

class _GlobalKeyExampleState extends State<GlobalKeyExample> {
  final GlobalKey<_CounterState> counterKey = GlobalKey<_CounterState>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Counter(key: counterKey),
        ElevatedButton(
          onPressed: () {
            counterKey.currentState?.increment();
          },
          child: const Text('Increment from outside'),
        ),
      ],
    );
  }
}
```

### 5.2 UniqueKey

`UniqueKey`는 항상 고유한 Key를 생성합니다. 주로 위젯의 State를 강제로 초기화하고 싶을 때 사용합니다.

```dart
// UniqueKey: State를 강제 초기화
class UniqueKeyExample extends StatefulWidget {
  const UniqueKeyExample({super.key});

  @override
  State<UniqueKeyExample> createState() => _UniqueKeyExampleState();
}

class _UniqueKeyExampleState extends State<UniqueKeyExample> {
  Key _childKey = UniqueKey();

  void _resetChild() {
    setState(() => _childKey = UniqueKey()); // 새 Key → State 재생성
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Counter(key: _childKey), // Key 변경 시 State 초기화됨
        ElevatedButton(
          onPressed: _resetChild,
          child: const Text('Reset Counter'),
        ),
      ],
    );
  }
}
```

> **Key 종류 정리**:
> | Key | 용도 | 비교 기준 |
> |-----|------|----------|
> | `ValueKey<T>` | 고유한 값이 있을 때 | 값(`value`) |
> | `ObjectKey` | 객체 자체가 식별자일 때 | 객체 참조 |
> | `UniqueKey` | 항상 고유해야 할 때 | 인스턴스 자체 |
> | `GlobalKey` | 다른 위젯에서 State 접근 시 | 글로벌 고유 |

---

## 6. Widget 리빌드 최적화

### 6.1 const 생성자

const 위젯은 컴파일 타임에 생성되어 캐싱됩니다. 부모가 리빌드되어도 const 위젯은 동일 인스턴스가 재사용되므로 build()가 호출되지 않습니다.

```dart
class ConstExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('This is const'),
        const SizedBox(height: 16),
        const Icon(Icons.star),

        Text('This is non-const'),
        SizedBox(height: 16),
        Icon(Icons.star),
      ],
    );
  }
}
```

### 6.2 Widget 분리

```dart
// 좋음: Widget 분리
class GoodSeparation extends StatefulWidget {
  @override
  State<GoodSeparation> createState() => _GoodSeparationState();
}

class _GoodSeparationState extends State<GoodSeparation> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _StaticHeader(),

          Text('Counter: $_counter'),
          ElevatedButton(
            onPressed: () => setState(() => _counter++),
            child: Text('Increment'),
          ),
        ],
      ),
    );
  }
}

class _StaticHeader extends StatelessWidget {
  const _StaticHeader();

  @override
  Widget build(BuildContext context) {
    print('_StaticHeader rebuilt');

    return Container(
      padding: EdgeInsets.all(16),
      child: Text('Static Header'),
    );
  }
}
```

### 6.3 Builder 패턴

```dart
// ValueListenableBuilder
class ValueListenableExample extends StatefulWidget {
  const ValueListenableExample({super.key});

  @override
  State<ValueListenableExample> createState() => _ValueListenableExampleState();
}

class _ValueListenableExampleState extends State<ValueListenableExample> {
  final ValueNotifier<int> _counter = ValueNotifier<int>(0);

  @override
  void dispose() {
    _counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('Static text'),

          ValueListenableBuilder<int>(
            valueListenable: _counter,
            builder: (context, value, child) {
              return Column(
                children: [
                  Text('Counter: $value'),
                  if (child != null) child,
                ],
              );
            },
            child: const Text('This child is reused'),
          ),

          ElevatedButton(
            onPressed: () => _counter.value++,
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
```

---

## 7. InheritedWidget 심화

### 7.1 InheritedWidget 작동 원리

```dart
class CounterProvider extends InheritedWidget {
  final int count;
  final VoidCallback increment;

  const CounterProvider({
    super.key,
    required this.count,
    required this.increment,
    required super.child,
  });

  static CounterProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CounterProvider>();
  }

  @override
  bool updateShouldNotify(CounterProvider oldWidget) {
    return count != oldWidget.count;
  }
}
```

### 7.2 InheritedWidget 최적화

```dart
// 데이터와 액션 분리
class DataProvider extends InheritedWidget {
  final int count;

  const DataProvider({
    super.key,
    required this.count,
    required super.child,
  });

  static DataProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DataProvider>();
  }

  /// 값만 읽고 구독하지 않음 (1회성 읽기용)
  static DataProvider? read(BuildContext context) {
    return context.getInheritedWidgetOfExactType<DataProvider>();
  }

  @override
  bool updateShouldNotify(DataProvider oldWidget) {
    return count != oldWidget.count;
  }
}
```

> **`dependOn` vs `get` 차이**:
> - `dependOnInheritedWidgetOfExactType` (= `of()`): 값을 읽고 **변경 구독**. InheritedWidget 업데이트 시 리빌드됨
> - `getInheritedWidgetOfExactType` (= `read()`): 값만 읽고 **구독하지 않음**. 이벤트 핸들러에서 1회성 읽기에 적합

```dart
class ActionProvider extends InheritedWidget {
  final VoidCallback increment;

  const ActionProvider({
    super.key,
    required this.increment,
    required super.child,
  });

  static ActionProvider? of(BuildContext context) {
    return context.getInheritedWidgetOfExactType<ActionProvider>();
  }

  @override
  bool updateShouldNotify(ActionProvider oldWidget) {
    return false;
  }
}
```

### 7.3 InheritedModel

```dart
enum UserAspect { name, email, avatar }

class UserModel extends InheritedModel<UserAspect> {
  final String name;
  final String email;
  final String avatar;

  const UserModel({
    super.key,
    required this.name,
    required this.email,
    required this.avatar,
    required super.child,
  });

  static UserModel? of(BuildContext context, {UserAspect? aspect}) {
    return InheritedModel.inheritFrom<UserModel>(context, aspect: aspect);
  }

  @override
  bool updateShouldNotify(UserModel oldWidget) {
    return name != oldWidget.name ||
           email != oldWidget.email ||
           avatar != oldWidget.avatar;
  }

  @override
  bool updateShouldNotifyDependent(
    UserModel oldWidget,
    Set<UserAspect> dependencies,
  ) {
    if (dependencies.contains(UserAspect.name) && name != oldWidget.name) {
      return true;
    }
    if (dependencies.contains(UserAspect.email) && email != oldWidget.email) {
      return true;
    }
    if (dependencies.contains(UserAspect.avatar) && avatar != oldWidget.avatar) {
      return true;
    }
    return false;
  }
}
```

---

## 8. StatefulWidget vs StatelessWidget

### 8.1 선택 기준

```dart
// StatelessWidget: UI가 파라미터나 InheritedWidget에만 의존
class StatelessExample extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const StatelessExample({
    super.key,
    required this.title,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(title),
    );
  }
}

// StatefulWidget: 변경 가능한 내부 상태가 필요
class StatefulExample extends StatefulWidget {
  @override
  State<StatefulExample> createState() => _StatefulExampleState();
}

class _StatefulExampleState extends State<StatefulExample> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          child: Text(_isExpanded ? 'Collapse' : 'Expand'),
        ),
        if (_isExpanded)
          Container(
            height: 200,
            child: Text('Expanded content'),
          ),
      ],
    );
  }
}
```

### 8.2 State Hoisting vs Local State

```dart
// State Hoisting: 상태를 상위로 끌어올림
class StateHoistingExample extends StatefulWidget {
  @override
  State<StateHoistingExample> createState() => _StateHoistingExampleState();
}

class _StateHoistingExampleState extends State<StateHoistingExample> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Counter: $_counter'),

        IncrementButton(
          onPressed: () => setState(() => _counter++),
        ),
        DecrementButton(
          onPressed: () => setState(() => _counter--),
        ),
      ],
    );
  }
}

class IncrementButton extends StatelessWidget {
  final VoidCallback onPressed;

  const IncrementButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: Text('+'));
  }
}

class DecrementButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DecrementButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: Text('-'));
  }
}
```

---

## 9. 실전 안티패턴

### 9.1 안티패턴 1: build()에서 객체 생성

```dart
// 나쁨
class BadObjectCreation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return TextField(controller: controller);
  }
}

// 좋음
class GoodObjectCreation extends StatefulWidget {
  @override
  State<GoodObjectCreation> createState() => _GoodObjectCreationState();
}

class _GoodObjectCreationState extends State<GoodObjectCreation> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(controller: _controller);
  }
}
```

### 9.2 안티패턴 2: 잘못된 context 사용

```dart
// ❌ 나쁨 - Scaffold와 같은 build 메서드의 context 사용
class BadContextUsage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () {
          // context는 Scaffold보다 위에 위치 → Scaffold를 찾지 못함
          Scaffold.of(context).openDrawer(); // 에러 발생!
        },
        child: Text('Open Drawer'),
      ),
      drawer: Drawer(),
    );
  }
}

// 좋음 - Builder 사용
class GoodContextUsage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (scaffoldContext) {
          return ElevatedButton(
            onPressed: () {
              Scaffold.of(scaffoldContext).openDrawer();
            },
            child: Text('Open Drawer'),
          );
        },
      ),
      drawer: Drawer(),
    );
  }
}
```

### 9.3 안티패턴 3: setState 남용

```dart
// ❌ 나쁨 - 전체 위젯 트리를 리빌드
class BadSetState extends StatefulWidget {
  @override
  State<BadSetState> createState() => _BadSetStateState();
}

class _BadSetStateState extends State<BadSetState> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // _counter가 변경되면 이 무거운 위젯도 함께 리빌드됨
        const Text('Heavy Widget'), // 무거운 위젯 가정 - 불필요한 리빌드
        Text('Counter: $_counter'),
        ElevatedButton(
          onPressed: () => setState(() => _counter++),
          child: Text('Increment'),
        ),
      ],
    );
  }
}

// 좋음 - ValueNotifier 사용
class GoodSetState extends StatefulWidget {
  @override
  State<GoodSetState> createState() => _GoodSetStateState();
}

class _GoodSetStateState extends State<GoodSetState> {
  final ValueNotifier<int> _counter = ValueNotifier<int>(0);

  @override
  void dispose() {
    _counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<int>(
          valueListenable: _counter,
          builder: (context, count, _) => Text('Counter: $count'),
        ),

        ElevatedButton(
          onPressed: () => _counter.value++,
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

### 9.4 안티패턴 4: mounted 체크 누락

```dart
// 좋음
class GoodMounted extends StatefulWidget {
  @override
  State<GoodMounted> createState() => _GoodMountedState();
}

class _GoodMountedState extends State<GoodMounted> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      // 안전하게 실행
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

> **참고**: `StatefulWidget`의 State에서는 `mounted` 속성을, `StatelessWidget`이나 콜백에서는 `context.mounted` (Flutter 3.7+)를 사용합니다. 둘 다 위젯이 트리에 존재하는지 확인하는 용도입니다.

---

## 실습 과제

### 과제 1: Custom InheritedWidget 구현

Theme 시스템을 InheritedWidget으로 구현하세요.

**요구사항:**
1. `AppTheme` InheritedWidget 정의
2. `ThemeController` StatefulWidget
3. InheritedModel로 최적화
4. 테스트 UI

**평가 기준:**
- InheritedWidget의 올바른 사용
- 불필요한 리빌드 최소화
- InheritedModel 활용

### 과제 2: Key를 활용한 애니메이션 리스트

드래그로 재정렬 가능한 애니메이션 리스트를 구현하세요.

**요구사항:**
1. `AnimatedListItem` StatefulWidget
2. `ReorderableAnimatedList` 구현
3. 성능 최적화
4. 디버그 모드

**평가 기준:**
- Key의 올바른 사용
- 애니메이션 상태 유지
- 성능 최적화

### 과제 3: 복잡한 Form 관리

다단계 Form을 효율적으로 관리하는 시스템을 구현하세요.

**요구사항:**
1. `FormController` 구현
2. 각 Form Step을 별도 Widget으로 분리
3. BuildContext 활용
4. 라이프사이클 관리

**평가 기준:**
- State 관리의 효율성
- 리소스 누수 방지
- 사용자 경험

---

## Self-Check

다음 항목을 체크하며 학습 내용을 점검하세요:

- [ ] Widget, Element, RenderObject의 관계를 설명하고, Flutter의 3-tree 구조를 이해한다
- [ ] BuildContext가 실제로 Element를 가리킨다는 것을 이해하고, of() 패턴의 작동 원리를 설명할 수 있다
- [ ] StatefulWidget의 전체 라이프사이클을 나열하고, 각 메서드의 용도와 호출 시점을 설명할 수 있다
- [ ] Key의 종류(ValueKey, ObjectKey, UniqueKey, GlobalKey)와 사용 시나리오를 구분할 수 있다
- [ ] const 생성자, Widget 분리, Builder 패턴을 활용해 불필요한 리빌드를 방지할 수 있다
- [ ] InheritedWidget의 작동 원리를 이해하고, dependOnInheritedWidget과 getInheritedWidget의 차이를 설명할 수 있다
- [ ] InheritedModel로 특정 aspect만 의존하는 최적화 패턴을 적용할 수 있다
- [ ] State Hoisting과 Local State의 차이를 이해하고, 상황에 맞게 선택할 수 있다
- [ ] 흔한 안티패턴(build()에서 객체 생성, 잘못된 context 사용 등)을 식별하고 피할 수 있다
- [ ] mounted 체크, dispose 구현 등 메모리 누수를 방지하는 습관을 갖추었다

---

**학습 완료 후**: [fundamentals/LayoutSystem.md](./LayoutSystem.md)로 진행하여 Constraints 전파 원리와 Sliver 기반 레이아웃을 학습하세요.
