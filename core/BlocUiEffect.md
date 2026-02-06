# Bloc에서 UI Effect 처리하기

Toast, Dialog, Navigation 등 일회성 이벤트 처리 패턴에 대한 가이드입니다.

---

## 목차

1. [문제 상황](#1-문제-상황)
2. [Side Effect란?](#2-side-effect란)
3. [MVI 패턴과 Bloc](#3-mvi-패턴과-bloc)
4. [더 나은 용어: UI Effect](#4-더-나은-용어-ui-effect)
5. [Bloc의 해결책: Listener](#5-bloc의-해결책-listener)
6. [커스텀 UiEffect 패턴](#6-커스텀-uieffect-패턴)
7. [실전 예제](#7-실전-예제)
8. [별도 Stream 방식과 BaseBloc 패턴](#8-별도-stream-방식과-basebloc-패턴)
9. [Best Practices](#9-best-practices)
10. [정리](#10-정리)

---

> **TL;DR - 언제 사용하나요?**
>
> Toast, SnackBar, Dialog, Navigation 같은 **일회성 UI 이벤트**를 Bloc에서 처리해야 할 때 이 패턴을 사용합니다.
>
> | 상황 | 해결책 |
> |------|--------|
> | State로 표현 가능 (로딩, 에러 화면) | `BlocBuilder`로 처리 |
> | 일회성 이벤트 (Toast, Navigation) | `BlocListener` + UiEffect 패턴 |
>
> 핵심: State는 **지속되는 UI 상태**, UiEffect는 **한 번 실행되고 사라지는 액션**입니다.
>
> 관련 문서: [Bloc.md](./Bloc.md) - Bloc 기본 패턴

---

## 1. 문제 상황

### 이런 코드, 작성해본 적 있으신가요?

```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state.hasError) {
      showDialog(...);  // ❌ 빌드 중에 호출됨!
    }
    return LoginForm();
  },
)
```

### 발생하는 문제들

- 빌드 중 `showDialog` 호출 → 에러 발생
- 상태가 변경될 때마다 중복 호출
- 예측 불가능한 동작

---

## 2. Side Effect란?

### 함수형 프로그래밍 용어

| 구분 | 설명 | 예시 |
|------|------|------|
| **순수 함수** | 입력 → 출력만 | `int add(a, b) => a + b` |
| **Side Effect** | 외부에 영향을 줌 | DB 저장, UI 표시, API 호출 |

```dart
// Side Effect가 있는 함수
void login() {
  saveToDatabase();     // DB 저장
  showToast("성공!");   // UI 표시
  navigate("/home");    // 화면 이동
}
```

### Bloc 관점에서의 Side Effect

```
Event  →  처리  →  State 변경 (주 효과)
               →  Side Effect (부수 효과)
```

| 주 효과 (State 변경) | 부수 효과 (Side Effect) |
|---------------------|------------------------|
| `isLoading = true` | 로딩 스피너 표시 |
| `status = success` | 성공 Toast 표시 |
| `status = failure` | 에러 Dialog 표시 |
| `isLoggedIn = true` | 홈 화면으로 이동 |

---

## 3. MVI 패턴과 Bloc

### MVVM vs MVI

| 패턴 | 데이터 흐름 | 상태 관리 |
|------|-------------|-----------|
| MVVM | 양방향 바인딩 | Mutable |
| MVI | **단방향 흐름** | **Immutable** |

Bloc은 **MVI(Model-View-Intent)** 패턴에 가깝습니다.

### Bloc ≈ MVI 용어 매핑

| MVI | Bloc | 설명 |
|-----|------|------|
| **Intent** | Event | 사용자 액션, 의도 |
| **Model** | State | 불변 상태 |
| **View** | UI (Widget) | 상태 기반 렌더링 |
| **SideEffect** | Effect | 일회성 이벤트 |

```
MVI:   View → Intent → Model → View
                         ↓
                    SideEffect

Bloc:  UI → Event → State → UI
                      ↓
                   Effect
```

### Android Compose MVI 비교

```kotlin
// Android Compose - MVI 패턴
class LoginViewModel : ViewModel() {
    private val _state = MutableStateFlow(LoginState())
    val state: StateFlow<LoginState> = _state

    // Effect용 Channel (우리의 effectStream과 동일!)
    private val _effect = Channel<LoginEffect>()
    val effect: Flow<LoginEffect> = _effect.receiveAsFlow()

    fun onIntent(intent: LoginIntent) { ... }

    private fun login() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            _effect.send(LoginEffect.NavigateToHome)  // Effect 발행
        }
    }
}
```

### Flutter BaseBloc = Android MVI

| Android Compose | Flutter BaseBloc |
|-----------------|------------------|
| `StateFlow<State>` | `state` (Bloc 기본) |
| `Channel<Effect>` | `effectStream` |
| `_effect.send()` | `emitEffect()` |
| `effect.collect {}` | `effectStream.listen()` |

> **BaseBloc + Effect Stream** = Android MVI와 동일한 구조!

### iOS TCA / Combine 비교

#### TCA (The Composable Architecture)

```swift
struct LoginFeature: Reducer {
    struct State: Equatable { var isLoading = false }

    enum Action {
        case loginTapped
        case delegate(Delegate)  // Effect 역할
        enum Delegate { case showToast(String), navigateToHome }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loginTapped:
                state.isLoading = true
                return .run { send in
                    let result = await authClient.login()
                    await send(.delegate(.navigateToHome))  // Effect
                }
            }
        }
    }
}
```

#### iOS Combine 방식

```swift
class LoginViewModel: ObservableObject {
    @Published var state = LoginState()

    // Effect용 Subject (Flutter effectStream과 동일!)
    let effect = PassthroughSubject<LoginEffect, Never>()

    func login() {
        state.isLoading = true
        authService.login()
            .sink { [weak self] result in
                self?.state.isLoading = false
                self?.effect.send(.navigateToHome)  // Effect 발행
            }
            .store(in: &cancellables)
    }
}

// SwiftUI View
struct LoginView: View {
    var body: some View {
        LoginForm()
            .onReceive(viewModel.effect) { effect in
                // Effect 처리
            }
    }
}
```

### 3대 플랫폼 비교

| 개념 | Flutter | Android | iOS |
|------|---------|---------|-----|
| State 보관 | `Bloc.state` | `StateFlow` | `@Published` |
| State 변경 | `emit()` | `update {}` | 직접 할당 |
| Effect 스트림 | `StreamController` | `Channel` | `PassthroughSubject` |
| Effect 발행 | `emitEffect()` | `send()` | `send()` |
| Effect 구독 | `listen()` | `collect {}` | `onReceive()` |

> 3대 플랫폼 모두 **State + Effect 분리** 패턴 사용!

---

## 4. 더 나은 용어: UI Effect

### "Side Effect"가 불편한 이유

> "Side Effect"라고 하면 뭔가 에러가 발생하는 느낌인데...

### 실제로 사용되는 대안 용어들

| 아키텍처 / 라이브러리 | 사용하는 용어 |
|----------------------|---------------|
| MVI 패턴 | **SingleEvent**, **Effect** |
| Kotlin MVI | **UiEffect** |
| Android Compose | **UiEvent** |
| 일부 Bloc 프로젝트 | **Command**, **OneTimeEvent** |

### 추천 용어

**UiEffect** 또는 **OneTimeEvent**를 권장합니다.

```dart
// 명확하고 직관적인 이름!
sealed class LoginUiEffect {
  const LoginUiEffect();
}

class ShowSuccessToast extends LoginUiEffect {
  const ShowSuccessToast();
}

class ShowErrorDialog extends LoginUiEffect {
  const ShowErrorDialog();
}

class NavigateToHome extends LoginUiEffect {
  const NavigateToHome();
}
```

> 용어보다 **개념을 이해하는 것**이 중요합니다!

---

## 5. Bloc의 해결책: Listener

### Builder vs Listener

| 위젯 | 용도 | 호출 시점 |
|------|------|-----------|
| `BlocBuilder` | UI 렌더링 | 상태 변경마다 rebuild |
| `BlocListener` | Side Effect 실행 | 상태 변경마다 callback 실행 (rebuild 없음) |
| `BlocConsumer` | 둘 다 | 위 두 가지 결합 |

```
State 변경
    ├──→ BlocBuilder  ──→ UI Rebuild (여러 번 가능)
    └──→ BlocListener ──→ Side Effect (1회만 실행)
```

### BlocListener 사용법

```dart
BlocListener<AuthBloc, AuthState>(
  listenWhen: (previous, current) {
    return previous.status != current.status;
  },
  listener: (context, state) {
    if (state.status == AuthStatus.failure) {
      showErrorToast(state.errorMessage);
    }
    if (state.status == AuthStatus.success) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  },
  child: LoginForm(),
)
```

### MultiBlocListener

여러 Bloc을 동시에 Listen할 수 있습니다.

```dart
MultiBlocListener(
  listeners: [
    BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Auth 관련 Side Effect
      },
    ),
    BlocListener<NetworkBloc, NetworkState>(
      listener: (context, state) {
        // Network 관련 Side Effect
      },
    ),
  ],
  child: MyApp(),
)
```

### BlocConsumer 사용법

UI 빌드와 Side Effect를 동시에 처리합니다.

```dart
BlocConsumer<AuthBloc, AuthState>(
  listenWhen: (prev, curr) => prev.status != curr.status,
  listener: (context, state) {
    // Side Effect는 여기서!
    if (state.status == AuthStatus.failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? '오류')),
      );
    }
  },
  buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
  builder: (context, state) {
    // UI 빌드는 여기서!
    return state.isLoading ? LoadingSpinner() : LoginForm();
  },
)
```

---

## 6. 커스텀 UiEffect 패턴

### Step 1: UiEffect 클래스 정의

```dart
sealed class LoginUiEffect {
  const LoginUiEffect();
}

class ShowToast extends LoginUiEffect {
  final String message;
  const ShowToast(this.message);
}

class ShowErrorDialog extends LoginUiEffect {
  final String title;
  final String message;
  const ShowErrorDialog({required this.title, required this.message});
}

class NavigateToHome extends LoginUiEffect {
  const NavigateToHome();
}
```

### Step 2: State에 UiEffect 포함

```dart
class LoginState extends Equatable {
  final bool isLoading;
  final String? email;
  final LoginUiEffect? uiEffect;  // UiEffect 추가

  const LoginState({
    this.isLoading = false,
    this.email,
    this.uiEffect,
  });

  LoginState copyWith({...}) => LoginState(...);

  @override
  List<Object?> get props => [isLoading, email, uiEffect];
}
```

### Step 3: Bloc에서 UiEffect 발행

```dart
Future<void> _onLoginSubmitted(
  LoginSubmitted event, Emitter<LoginState> emit,
) async {
  emit(state.copyWith(isLoading: true, uiEffect: null));

  try {
    await _authRepository.login(event.email, event.password);
    emit(state.copyWith(
      isLoading: false,
      uiEffect: const NavigateToHome(),  // 성공
    ));
  } catch (e) {
    emit(state.copyWith(
      isLoading: false,
      uiEffect: ShowErrorDialog(title: '실패', message: e.toString()),
    ));
  }
}
```

### Step 4: UI에서 UiEffect 처리

```dart
BlocListener<LoginBloc, LoginState>(
  listenWhen: (prev, curr) => curr.uiEffect != null,
  listener: (context, state) {
    final effect = state.uiEffect;
    if (effect == null) return;

    switch (effect) {
      case ShowToast(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      case ShowErrorDialog(:final title, :final message):
        showDialog(context: context, builder: (_) =>
          AlertDialog(title: Text(title), content: Text(message)));
      case NavigateToHome():
        Navigator.pushReplacementNamed(context, '/home');
    }
  },
  child: LoginForm(),
)
```

---

## 7. 실전 예제

### UiEffect 정의

```dart
sealed class LoginUiEffect {
  const LoginUiEffect();
}

class ShowToast extends LoginUiEffect {
  final String message;
  final bool isError;
  const ShowToast(this.message, {this.isError = false});
}

class ShowErrorDialog extends LoginUiEffect {
  final String title;
  final String message;
  const ShowErrorDialog({required this.title, required this.message});
}

class NavigateToHome extends LoginUiEffect {
  const NavigateToHome();
}

class NavigateToSignUp extends LoginUiEffect {
  const NavigateToSignUp();
}
```

### Handler Mixin

```dart
mixin UiEffectHandler {
  void handleUiEffect(BuildContext context, LoginUiEffect effect) {
    switch (effect) {
      case ShowToast(:final message, :final isError):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red : Colors.green,
          ),
        );
      case ShowErrorDialog(:final title, :final message):
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      case NavigateToHome():
        Navigator.pushReplacementNamed(context, '/home');
      case NavigateToSignUp():
        Navigator.pushNamed(context, '/signup');
    }
  }
}
```

### LoginPage

```dart
class LoginPage extends StatelessWidget with UiEffectHandler {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listenWhen: (prev, curr) => curr.uiEffect != null,
      listener: (context, state) {
        if (state.uiEffect != null) {
          handleUiEffect(context, state.uiEffect!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : LoginForm(),
        );
      },
    );
  }
}
```

### 주의: 동일한 UiEffect 중복 발행

#### 문제 상황

```dart
// 첫 번째 emit
emit(state.copyWith(uiEffect: ShowToast("에러!")));

// 두 번째 emit (같은 메시지)
emit(state.copyWith(uiEffect: ShowToast("에러!")));
// ❌ Equatable이 "같은 상태"로 판단 → listener 호출 안됨!
```

> `Equatable`로 상태 비교 시 동일한 UiEffect는 **"변경 없음"**으로 판단

#### 해결 방법 1: 고유 ID 추가 (권장)

```dart
// UiEffect 기본 클래스에 Equatable 상속 추가
sealed class LoginUiEffect extends Equatable {
  const LoginUiEffect();

  @override
  List<Object?> get props => [];
}

class ShowToast extends LoginUiEffect {
  final String message;
  final String id;  // 고유 ID 추가

  ShowToast(this.message) : id = DateTime.now().toIso8601String();

  @override
  List<Object?> get props => [message, id];  // id 포함!
}
```

매 emit마다 새로운 id가 생성되어 **항상 다른 상태로 인식**됩니다.

#### 해결 방법 2: 처리 후 null 초기화

```dart
// Event 추가
class ClearUiEffect extends LoginEvent {}

// Bloc에서 처리
on<ClearUiEffect>((event, emit) {
  emit(state.copyWith(uiEffect: null));
});

// Listener에서 처리 후 초기화
listener: (context, state) {
  if (state.uiEffect == null) return;

  handleEffect(state.uiEffect!);
  context.read<LoginBloc>().add(ClearUiEffect());  // 초기화
}
```

#### 해결 방법 3: Equatable에서 제외

```dart
class LoginState extends Equatable {
  final bool isLoading;
  final LoginUiEffect? uiEffect;

  @override
  List<Object?> get props => [isLoading];  // uiEffect 제외!
}
```

**주의사항**: 모든 emit에서 listener가 호출되므로 `listenWhen`으로 필터링이 필수입니다.

```dart
listenWhen: (prev, curr) =>
  curr.uiEffect != null && prev.uiEffect != curr.uiEffect,
```

#### 해결 방법 비교

| 방법 | 장점 | 단점 |
|------|------|------|
| **고유 ID 추가** | 간단, 안전 | UiEffect 클래스 수정 필요 |
| **null 초기화** | 명시적 | Event/Handler 추가 필요 |
| **Equatable 제외** | 수정 최소화 | listenWhen 관리 필요 |

**권장**: **고유 ID 추가** 방식이 가장 간단하고 실수할 여지가 적습니다.

---

## 8. 별도 Stream 방식과 BaseBloc 패턴

### State 포함 vs 별도 Stream

| 항목 | State 포함 | 별도 Stream |
|------|------------|-------------|
| 중복 발행 | ID 필요 | 문제 없음 |
| Bloc 일관성 | 높음 | 별도 관리 |
| 복잡도 | 낮음 | 약간 높음 |
| 테스트 | 쉬움 | Stream 별도 테스트 |

### 별도 Stream: Bloc 구현

```dart
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  // UiEffect 전용 Stream
  final _uiEffectController = StreamController<LoginUiEffect>.broadcast();
  Stream<LoginUiEffect> get uiEffectStream => _uiEffectController.stream;

  Future<void> _onLoginSubmitted(...) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _authRepository.login(...);
      emit(state.copyWith(isLoading: false));
      _uiEffectController.add(NavigateToHome());  // 별도 Stream
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      _uiEffectController.add(ShowErrorDialog(...));
    }
  }

  @override
  Future<void> close() {
    _uiEffectController.close();  // 반드시 close!
    return super.close();
  }
}
```

### 별도 Stream: UI 구현

```dart
class LoginPage extends StatefulWidget { ... }

class _LoginPageState extends State<LoginPage> {
  late StreamSubscription<LoginUiEffect> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = context.read<LoginBloc>()
      .uiEffectStream
      .listen(_handleUiEffect);
  }

  void _handleUiEffect(LoginUiEffect effect) {
    switch (effect) {
      case ShowToast(:final message):
        ScaffoldMessenger.of(context).showSnackBar(...);
      case NavigateToHome():
        Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _subscription.cancel();  // 반드시 cancel!
    super.dispose();
  }
}
```

### 어떤 방식을 선택할까?

**State 포함 방식 추천**:
- 단순한 UiEffect (Toast, Dialog 몇 개)
- Bloc 패턴과 일관성 유지하고 싶을 때
- 팀이 Bloc에 익숙할 때

**별도 Stream 방식 추천**:
- 동일한 UiEffect가 자주 반복될 때
- MVI 패턴에 익숙한 팀
- 상태와 이벤트를 명확히 분리하고 싶을 때

> 두 방식 모두 정답입니다! **팀과 합의**해서 선택하세요.

### BaseBloc 패턴

Effect Stream을 기본 내장한 BaseBloc입니다.

```dart
abstract class BaseBloc<Event, State, Effect> extends Bloc<Event, State> {
  BaseBloc(super.initialState);

  final _effectController = StreamController<Effect>.broadcast();
  Stream<Effect> get effectStream => _effectController.stream;

  void emitEffect(Effect effect) {
    if (isClosed || _effectController.isClosed) return;
    _effectController.add(effect);
  }

  @override
  Future<void> close() async {
    await _effectController.close();
    return super.close();
  }
}
```

### BaseBloc 사용 예시

```dart
// Effect 정의
sealed class LoginEffect {
  const LoginEffect();
}

class ShowToast extends LoginEffect {
  final String message;
  const ShowToast(this.message);
}

class ShowErrorDialog extends LoginEffect {
  final String message;
  const ShowErrorDialog({required this.message});
}

class NavigateToHome extends LoginEffect {
  const NavigateToHome();
}

// Bloc 구현
class LoginBloc extends BaseBloc<LoginEvent, LoginState, LoginEffect> {
  LoginBloc() : super(const LoginState());

  Future<void> _onLoginSubmitted(...) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _authRepository.login(...);
      emit(state.copyWith(isLoading: false));
      emitEffect(const NavigateToHome());  // 간단!
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      emitEffect(ShowErrorDialog(message: e.toString()));
    }
  }
}
```

### BlocEffectListener 위젯

재사용 가능한 Listener 위젯입니다.

```dart
class BlocEffectListener<B extends BaseBloc<dynamic, dynamic, E>, E>
    extends StatefulWidget {
  final Widget child;
  final void Function(BuildContext, E) onEffect;
  const BlocEffectListener({required this.child, required this.onEffect});

  @override
  State<BlocEffectListener<B, E>> createState() => _State<B, E>();
}

class _State<B extends BaseBloc<dynamic, dynamic, E>, E>
    extends State<BlocEffectListener<B, E>> {
  late StreamSubscription<E> _sub;

  @override
  void initState() {
    super.initState();
    _sub = context.read<B>().effectStream.listen(
      (e) => widget.onEffect(context, e));
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

### BlocEffectMixin (권장)

StatefulWidget용 Mixin입니다.

```dart
mixin BlocEffectMixin<T extends StatefulWidget,
    B extends BaseBloc<dynamic, dynamic, E>, E> on State<T> {

  StreamSubscription<E>? _effectSub;

  void onEffect(E effect);  // Override 필수

  void listenEffect(B bloc) {
    _effectSub = bloc.effectStream.listen(onEffect);
  }

  @override
  void dispose() {
    _effectSub?.cancel();
    super.dispose();
  }
}
```

### Mixin 사용 예시

```dart
class _LoginPageState extends State<LoginPage>
    with BlocEffectMixin<LoginPage, LoginBloc, LoginEffect> {

  @override
  void initState() {
    super.initState();
    listenEffect(context.read<LoginBloc>());
  }

  @override
  void onEffect(LoginEffect effect) {
    switch (effect) {
      case ShowToast(:final message):
        ScaffoldMessenger.of(context).showSnackBar(...);
      case NavigateToHome():
        Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(...);
  }
}
```

### Listener vs Mixin 비교

| 항목 | BlocEffectListener | BlocEffectMixin |
|------|-------------------|-----------------|
| 위젯 래핑 | 필요 | 불필요 |
| 코드 위치 | 위젯 트리 | State 내부 |
| StatelessWidget | 사용 가능 | 사용 불가 |
| 가독성 | 중첩 발생 | 깔끔 |

**선택 가이드**:
- **StatelessWidget** → BlocEffectListener
- **StatefulWidget** → BlocEffectMixin (권장)

---

## 9. Best Practices

### DO (이렇게 하세요)

| 항목 | 설명 |
|------|------|
| `BlocListener` 사용 | Side Effect는 반드시 listener에서 |
| `listenWhen` 활용 | 불필요한 호출 방지 |
| `sealed class` 사용 | 타입 안전한 UiEffect 정의 |
| Handler 분리 | UiEffect 처리 로직 재사용 |

### DON'T (이렇게 하지 마세요)

```dart
// ❌ Builder 안에서 Side Effect
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state.hasError) showDialog(...);  // 절대 금지!
    return Widget();
  },
)

// ❌ initState에서 직접 listen
@override
void initState() {
  bloc.stream.listen((state) {  // BlocListener 사용하세요!
    showToast(...);
  });
}
```

### mounted 체크 필수

화면이 dispose된 후 Effect 도착 문제에 주의해야 합니다.

```dart
void onEffect(LoginEffect effect) {
  // ❌ 위험: context 사용 시 에러 발생 가능
  Navigator.pushReplacementNamed(context, '/home');
}

void onEffect(LoginEffect effect) {
  // ✅ 안전: mounted 체크 필수!
  if (!mounted) return;

  switch (effect) {
    case NavigateToHome():
      Navigator.pushReplacementNamed(context, '/home');
    case ShowToast(:final message):
      ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

> Effect 처리 전 **반드시 `mounted` 체크**

### Effect 유실 vs 중복 실행

| 문제 | 원인 | 결과 |
|------|------|------|
| **Effect 유실** | 구독 전 발행 | Toast 안 뜸 |
| **Effect 중복 실행** | ReplaySubject 사용 | 화면 복귀 시 또 실행 |

#### 해결책 1: 일회성 Effect 래퍼

Effect를 "소비"하는 패턴입니다.

```dart
class OneTimeEffect<T> {
  final T effect;
  bool _consumed = false;  // Dart는 단일 스레드이므로 동기 컨텍스트에서는 안전하지만, 비동기 갭을 넘어 소비될 경우 주의 필요

  OneTimeEffect(this.effect);

  T? consume() {
    if (_consumed) return null;
    _consumed = true;
    return effect;
  }
}

// BaseBloc에서
void emitEffect(Effect effect) {
  _effectController.add(OneTimeEffect(effect));
}

// UI에서
void onEffect(OneTimeEffect<LoginEffect> wrapper) {
  final effect = wrapper.consume();
  if (effect == null) return;  // 이미 소비됨
  handleEffect(effect);
}
```

#### 해결책 2: 타임스탬프 기반 필터링

```dart
mixin BlocEffectMixin<...> on State<T> {
  DateTime? _lastSubscribeTime;

  void listenEffect(B bloc) {
    _lastSubscribeTime = DateTime.now();

    _effectSub = bloc.effectStream.listen((effect) {
      if (!mounted) return;

      // 구독 시점 이전 Effect는 무시
      if (effect.timestamp.isBefore(_lastSubscribeTime!)) {
        return;
      }

      onEffect(effect);
    });
  }
}

// Effect에 타임스탬프 추가
abstract class BaseEffect {
  final DateTime timestamp = DateTime.now();
}
```

#### 해결책 3: PublishSubject (권장)

놓침을 허용하되, 중복을 방지합니다.

```dart
// rxdart 사용
abstract class BaseBloc<Event, State, Effect> extends Bloc<Event, State> {
  BaseBloc(super.initialState);

  // PublishSubject: 구독 시점 이후만 전달
  final _effectController = PublishSubject<Effect>();
  Stream<Effect> get effectStream => _effectController.stream;

  void emitEffect(Effect effect) {
    if (isClosed || _effectController.isClosed) return;
    _effectController.add(effect);
  }

  @override
  Future<void> close() async {
    await _effectController.close();
    return super.close();
  }
}
```

**왜 권장하나요?**
- Effect 유실보다 **중복 실행이 더 위험**
- Navigation Effect 중복 → 화면 2번 이동
- Dialog 중복 → 사용자 혼란
- Toast는 놓쳐도 치명적이지 않음

### Navigation: State 기반 처리 (권장)

Effect 대신 State로 Navigation을 처리합니다.

```dart
// ❌ Effect 방식의 문제
emitEffect(NavigateToHome());  // 유실 또는 중복 위험

// ✅ State 방식: 안전
class AuthState {
  final bool isLoggedIn;
  final bool shouldNavigateToHome;  // State로 관리
}
```

#### State 기반 Navigation (BlocListener)

```dart
class AppWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.isLoggedIn != curr.isLoggedIn,
      listener: (context, state) {
        if (state.isLoggedIn) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: MaterialApp(...),
    );
  }
}
```

**장점**:
- 유실 없음 (State가 유지되므로)
- 중복 없음 (listenWhen 조건부)
- Effect보다 안정적

### 하이브리드 접근법

Navigation은 State, 나머지는 Effect로 처리합니다.

```dart
// Navigation은 제외하고 Toast, Dialog만 Effect로
sealed class LoginEffect {
  const LoginEffect();
}

class ShowToast extends LoginEffect {
  final String message;
  const ShowToast(this.message);
}

class ShowErrorDialog extends LoginEffect {
  final String title;
  final String message;
  const ShowErrorDialog({required this.title, required this.message});
}

class LoginState {
  final bool isLoading;
  final bool isLoggedIn;  // Navigation 트리거는 State
}
```

### 최종 권장 패턴

| Effect 종류 | 처리 방식 | 이유 |
|-------------|-----------|------|
| **Toast** | PublishSubject | 유실 허용, 중복 방지 |
| **Dialog** | PublishSubject + mounted 체크 | 유실 허용 |
| **Navigation** | **State + BlocListener** | 유실/중복 모두 방지 |
| **Analytics** | PublishSubject | fire-and-forget |

**핵심 원칙**:
- 일회성 UI 피드백 → Effect (PublishSubject)
- 화면 전환 → State + BlocListener
- 절대 유실 안됨 → State 기반

### Effect 처리 중 예외 처리

```dart
// 문제: 하나의 Effect 실패 시 전체 구독 종료
bloc.effectStream.listen((effect) {
  throw Exception('에러 발생!');  // ❌ 구독 종료됨
});

// 해결: onError 핸들링
bloc.effectStream.listen(
  (effect) => handleEffect(effect),
  onError: (error, stackTrace) {
    // 에러 로깅, 무시하고 계속 구독
    debugPrint('Effect 처리 에러: $error');
  },
  cancelOnError: false,  // 에러 시에도 구독 유지
);
```

### 개선된 Mixin

```dart
mixin BlocEffectMixin<T extends StatefulWidget,
    B extends BaseBloc<dynamic, dynamic, E>, E> on State<T> {

  StreamSubscription<E>? _effectSub;

  void onEffect(E effect);

  void listenEffect(B bloc) {
    _effectSub = bloc.effectStream.listen(
      (effect) {
        if (!mounted) return;  // mounted 체크
        onEffect(effect);
      },
      onError: (e, st) => debugPrint('Effect error: $e'),
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _effectSub?.cancel();
    super.dispose();
  }
}
```

### 테스트 방법

#### Effect Stream 테스트

```dart
void main() {
  late LoginBloc bloc;
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    bloc = LoginBloc(authRepository: mockAuthRepo);
  });

  tearDown(() => bloc.close());

  test('로그인 성공 시 NavigateToHome Effect 발행', () async {
    // Arrange
    when(mockAuthRepo.login(any, any)).thenAnswer((_) async => User());

    // Act
    final effects = <LoginEffect>[];
    bloc.effectStream.listen(effects.add);

    bloc.add(LoginSubmitted(email: 'test@test.com', password: '1234'));
    await bloc.stream.firstWhere((s) => !s.isLoading);

    // Assert
    expect(effects, contains(isA<NavigateToHome>()));
  });
}
```

#### bloc_test 패키지 활용

```dart
blocTest<LoginBloc, LoginState>(
  '로그인 실패 시 에러 Effect 발행',
  build: () {
    when(mockAuthRepo.login(any, any)).thenThrow(Exception('실패'));
    return LoginBloc(authRepository: mockAuthRepo);
  },
  act: (bloc) async {
    // Effect 수집 시작
    final effects = <LoginEffect>[];
    bloc.effectStream.listen(effects.add);

    bloc.add(LoginSubmitted(email: 'a', password: 'b'));
    await Future.delayed(Duration(milliseconds: 100));

    // Assert in act (또는 별도 테스트로 분리)
    expect(effects, contains(isA<ShowErrorDialog>()));
  },
  expect: () => [
    LoginState(isLoading: true),
    LoginState(isLoading: false),
  ],
);
```

### 순수 Dart 대안

rxdart 없이 순수 Dart로 구현할 수 있습니다.

```dart
// rxdart 없이 순수 Dart로 구현
abstract class BaseBloc<Event, State, Effect> extends Bloc<Event, State> {
  BaseBloc(super.initialState);

  // broadcast: 구독 전 발행된 이벤트 유실 (PublishSubject와 동일)
  final _effectController = StreamController<Effect>.broadcast();

  Stream<Effect> get effectStream => _effectController.stream;

  void emitEffect(Effect effect) {
    if (!_effectController.isClosed) {
      _effectController.add(effect);
    }
  }

  @override
  Future<void> close() async {
    await _effectController.close();
    return super.close();
  }
}
```

#### rxdart vs 순수 Dart 비교

| 기능 | 순수 Dart | rxdart |
|------|-----------|--------|
| 구독 전 이벤트 | 유실 | 유실 |
| 패키지 크기 | 0 | ~150KB |
| 연산자 | 기본만 | map, debounce 등 |
| 의존성 | 없음 | rxdart 필요 |
| 학습 곡선 | 낮음 | 높음 |

**선택 기준**:
- **rxdart가 필요한 경우**: debounce, throttle 등 고급 연산자 필요, Rx 패턴에 익숙한 팀
- **순수 Dart 추천**: 단순한 Effect 발행만 필요, 패키지 최소화 원할 때

### Hot Reload 주의사항

```dart
// [문제] didChangeDependencies에서 중복 구독
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // 매번 호출될 때마다 새 구독 생성 (누수!)
  _sub = context.read<LoginBloc>().effectStream.listen(...);
}

// [해결책] 중복 구독 방지
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _sub ??= context.read<LoginBloc>().effectStream.listen(...);
}
```

#### Hot Reload vs Hot Restart 동작 차이

| 상황 | Hot Reload | Hot Restart |
|------|------------|-------------|
| Bloc 인스턴스 | 유지 | 재생성 |
| Effect Stream | 유지 | 재생성 |
| 대기 중 Effect | 유지 (위험!) | 클리어 |
| State | 유지 | 초기화 |
| 구독 | 유지 | 재구독 |

**Hot Reload 안전한 패턴**:

```dart
@override
void initState() {
  super.initState();
  // initState는 Hot Reload에서 재호출 안됨 (안전)
  _sub = context.read<LoginBloc>().effectStream.listen(onEffect);
}
```

### Bloc-to-Bloc 통신

#### 패턴 1: 다른 Bloc 상태 구독

```dart
class CartBloc extends BaseBloc<CartEvent, CartState, CartEffect> {
  late StreamSubscription _authSub;

  CartBloc(AuthBloc authBloc) : super(const CartState()) {
    _authSub = authBloc.stream.listen((authState) {
      if (!authState.isLoggedIn) {
        add(ClearCart());  // 로그아웃 시 장바구니 초기화
      }
    });
  }

  @override
  Future<void> close() {
    _authSub.cancel();  // 구독 해제 필수!
    return super.close();
  }
}
```

#### 패턴 2: 최상위에서 Effect 분배

```dart
// AppWrapper에서 AuthBloc Effect를 받아 다른 Bloc에 분배
class _AppWrapperState extends State<AppWrapper>
    with BlocEffectMixin<AppWrapper, AuthBloc, AuthEffect> {

  @override
  void onEffect(AuthEffect effect) {
    switch (effect) {
      case LogoutCompleted():
        // 여러 Bloc에 초기화 이벤트 전달
        context.read<CartBloc>().add(ClearCart());
        context.read<ProfileBloc>().add(ClearProfile());
        context.read<SettingsBloc>().add(ResetSettings());
        Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
```

#### 패턴 3: GetIt을 통한 Bloc 접근

```dart
// 어디서든 다른 Bloc에 접근 가능
class OrderBloc extends BaseBloc<OrderEvent, OrderState, OrderEffect> {
  Future<void> _onOrderCompleted(...) async {
    // 주문 완료 시 장바구니 초기화
    getIt<CartBloc>().add(ClearCart());
    emitEffect(ShowToast('주문이 완료되었습니다'));
  }
}
```

#### Bloc-to-Bloc 통신 비교

| 패턴 | 장점 | 단점 | 사용 시점 |
|------|------|------|-----------|
| 상태 구독 | 느슨한 결합 | 구독 관리 필요 | 상태 변화 감지 |
| Effect 분배 | 중앙 집중 관리 | AppWrapper 비대화 | 로그아웃 등 전역 이벤트 |
| GetIt 직접 접근 | 간단함 | 강한 결합 | 간단한 연동 |

### Cubit vs Bloc 비교

| 항목 | Bloc | Cubit |
|------|------|-------|
| 이벤트 처리 | Event 클래스 필요 | 메서드 직접 호출 |
| 복잡도 | 높음 | 낮음 |
| 추적성 | 좋음 (Event 로그) | 보통 |
| Effect 적용 | BaseBloc 상속 | BaseCubit 상속 |

#### BaseCubit 정의

```dart
abstract class BaseCubit<State, Effect> extends Cubit<State> {
  BaseCubit(super.initialState);

  final _effectController = StreamController<Effect>.broadcast();
  Stream<Effect> get effectStream => _effectController.stream;

  void emitEffect(Effect effect) {
    if (isClosed || _effectController.isClosed) {
      return;
    }
    _effectController.add(effect);
  }

  @override
  Future<void> close() async {
    await _effectController.close();
    return super.close();
  }
}
```

#### Cubit 사용 예시

```dart
// Effect 정의
sealed class CounterEffect {
  const CounterEffect();
}

class ShowMaxReached extends CounterEffect {
  const ShowMaxReached();
}

// Cubit 구현
class CounterCubit extends BaseCubit<int, CounterEffect> {
  CounterCubit() : super(0);

  void increment() {
    if (state >= 10) {
      emitEffect(const ShowMaxReached());  // Effect 발행
      return;
    }
    emit(state + 1);
  }
}
```

#### 언제 Bloc, 언제 Cubit?

| 상황 | 선택 |
|------|------|
| 복잡한 비즈니스 로직 | Bloc |
| 단순 상태 토글 | Cubit |
| 이벤트 추적/로깅 필요 | Bloc |
| 빠른 프로토타이핑 | Cubit |

### flutter_bloc 버전별 변경사항

| 버전 | 변경 사항 | Effect 영향 |
|------|-----------|-------------|
| v7.x | Cubit/Bloc 분리 | - |
| v8.0 | `on<Event>` 핸들러 방식 | emit 위치 주의 |
| v8.1+ | `Bloc.observer` deprecated | EffectObserver 별도 관리 |
| v9.x | `emit.forEach` 추가 | Stream Effect와 혼용 주의 |

#### v8.x 필수: isClosed 체크

```dart
on<LoginSubmitted>((event, emit) async {
  emit(state.copyWith(isLoading: true));

  await _authRepository.login(...);  // 비동기 작업

  // await 후 Bloc이 close 되었을 수 있음!
  if (isClosed) return;  // 필수 체크

  emit(state.copyWith(isLoading: false));

  if (isClosed) return;  // emitEffect 전에도 체크
  emitEffect(NavigateToHome());
});
```

#### BaseBloc 개선: isClosed 체크 내장

```dart
abstract class BaseBloc<Event, State, Effect> extends Bloc<Event, State> {
  BaseBloc(super.initialState);

  final _effectController = StreamController<Effect>.broadcast();
  Stream<Effect> get effectStream => _effectController.stream;

  // isClosed 체크 내장
  void emitEffect(Effect effect) {
    if (isClosed || _effectController.isClosed) {
      debugPrint('Warning: emitEffect called after close');
      return;
    }
    _effectController.add(effect);
  }

  @override
  Future<void> close() async {
    await _effectController.close();
    return super.close();
  }
}
```

### 마이그레이션 가이드

기존 코드에서 새 패턴으로 전환하는 방법입니다.

```
현재 상태                    목표 상태
─────────────              ─────────────
State에 uiEffect 포함   →   별도 effectStream
BlocListener로 처리     →   BlocEffectMixin 사용
```

#### Step 1: BaseBloc 추가 (기존 코드 영향 없음)

```dart
// lib/core/base_bloc.dart 생성
abstract class BaseBloc<Event, State, Effect> extends Bloc<Event, State> {
  // ... (기존 코드와 충돌 없음)
}
```

#### Step 2: 새 Feature만 BaseBloc 사용

```dart
// 기존 Feature는 그대로 유지
class OldLoginBloc extends Bloc<LoginEvent, LoginState> { ... }

// 새 Feature만 BaseBloc 사용
class NewProfileBloc extends BaseBloc<ProfileEvent, ProfileState, ProfileEffect> { ... }
```

#### Step 3: 기존 Bloc 점진적 전환

```dart
// Before: State에 uiEffect 포함
class LoginState {
  final bool isLoading;
  final LoginUiEffect? uiEffect;  // 제거 예정
}

// After: effectStream으로 분리
class LoginBloc extends BaseBloc<LoginEvent, LoginState, LoginEffect> {
  // State에서 uiEffect 제거
  // emitEffect()로 Effect 발행
}
```

#### Step 4: UI 전환

```dart
// Before: BlocListener
BlocListener<LoginBloc, LoginState>(
  listenWhen: (prev, curr) => curr.uiEffect != null,
  listener: (context, state) {
    handleEffect(state.uiEffect!);
  },
  child: LoginForm(),
)

// After: BlocEffectMixin
class _LoginPageState extends State<LoginPage>
    with BlocEffectMixin<LoginPage, LoginBloc, LoginEffect> {

  @override
  void initState() {
    super.initState();
    listenEffect(context.read<LoginBloc>());
  }

  @override
  void onEffect(LoginEffect effect) {
    handleEffect(effect);
  }
}
```

#### 마이그레이션 체크리스트

| 단계 | 작업 | 테스트 |
|------|------|--------|
| 1 | BaseBloc 추가 | 기존 테스트 통과 확인 |
| 2 | 새 Feature 적용 | 새 Feature 테스트 |
| 3 | 기존 Bloc 전환 | 전환된 Bloc 테스트 |
| 4 | State에서 uiEffect 제거 | 전체 리그레션 테스트 |

### 안티패턴 정리

| 안티패턴 | 문제점 | 올바른 방법 |
|----------|--------|-------------|
| Builder에서 showDialog | 빌드 중 에러 | BlocListener 사용 |
| Effect에서 State 변경 | 단방향 흐름 위반 | Event 발행 |
| dispose 후 context 사용 | 메모리 누수/크래시 | mounted 체크 |
| broadcast 없이 다중 구독 | 두 번째 구독 에러 | broadcast() 사용 |
| Effect에서 await 남용 | UI 블로킹 | 비동기는 Bloc에서 |

#### 안티패턴 1: Builder에서 Side Effect

```dart
// 절대 금지
BlocBuilder<LoginBloc, LoginState>(
  builder: (context, state) {
    if (state.hasError) {
      showDialog(...);  // 빌드 중 호출 → 에러!
    }
    return LoginForm();
  },
)

// 올바른 방법
BlocListener<LoginBloc, LoginState>(
  listener: (context, state) {
    if (state.hasError) showDialog(...);
  },
  child: BlocBuilder<LoginBloc, LoginState>(...),
)
```

#### 안티패턴 2: Effect에서 State 변경

```dart
// 금지: Effect에서 State 변경 시도
void onEffect(LoginEffect effect) {
  switch (effect) {
    case LoginSuccess():
      bloc.emit(state.copyWith(isLoggedIn: true));  // 외부에서 emit!
  }
}

// 올바른 방법: Event 발행
void onEffect(LoginEffect effect) {
  switch (effect) {
    case LoginSuccess():
      context.read<LoginBloc>().add(UpdateLoginStatus(true));
  }
}
```

#### 안티패턴 3: 구독 해제 누락

```dart
// 메모리 누수
class _MyPageState extends State<MyPage> {
  @override
  void initState() {
    bloc.effectStream.listen((e) => ...);  // 구독 해제 없음!
  }
}

// 올바른 방법
class _MyPageState extends State<MyPage> {
  StreamSubscription? _sub;

  @override
  void initState() {
    _sub = bloc.effectStream.listen((e) => ...);
  }

  @override
  void dispose() {
    _sub?.cancel();  // 필수!
    super.dispose();
  }
}
```

#### 안티패턴 4: Effect 내 무거운 동기 작업

```dart
// UI 블로킹
void onEffect(SyncEffect effect) {
  final data = heavyComputation();  // UI 멈춤!
  showResult(data);
}

// 비동기로 처리하거나 Bloc에서 처리
void onEffect(SyncEffect effect) {
  switch (effect) {
    case SyncCompleted(:final data):  // Bloc에서 미리 계산
      showResult(data);
  }
}
```

### Freezed 통합

Freezed로 Effect를 정의할 수 있습니다.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'login_effect.freezed.dart';

@freezed
class LoginEffect with _$LoginEffect {
  const factory LoginEffect.showToast({
    required String message,
    @Default(false) bool isError,
  }) = ShowToast;

  const factory LoginEffect.showErrorDialog({
    required String title,
    required String message,
  }) = ShowErrorDialog;

  const factory LoginEffect.navigateToHome() = NavigateToHome;

  const factory LoginEffect.navigateToSignUp() = NavigateToSignUp;
}
```

#### Freezed Effect 처리

```dart
// when 패턴 사용
void onEffect(LoginEffect effect) {
  effect.when(
    showToast: (message, isError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
    },
    showErrorDialog: (title, message) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(message),
        ),
      );
    },
    navigateToHome: () => Navigator.pushReplacementNamed(context, '/home'),
    navigateToSignUp: () => Navigator.pushNamed(context, '/signup'),
  );
}
```

### GetIt / Injectable 통합

```dart
// injection.dart
final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();

// Repository 등록 (올바른 패턴)
@lazySingleton
class AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepository(this._dataSource);
}

// ⚠️ 주의: Bloc은 GetIt에 등록하지 않음!
// Bloc은 BlocProvider에서 직접 생성해야 함
// 이유: BlocProvider가 close한 Bloc을 GetIt이 다시 반환하면 에러 발생

// ❌ 잘못된 패턴 - 절대 금지
// @lazySingleton
// class AuthBloc extends BaseBloc<AuthEvent, AuthState, AuthEffect> { ... }

// ✅ 올바른 패턴 - BlocProvider로 생성
class AuthBloc extends BaseBloc<AuthEvent, AuthState, AuthEffect> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(const AuthState());
}

class LoginBloc extends BaseBloc<LoginEvent, LoginState, LoginEffect> {
  final AuthRepository _repo;

  LoginBloc(this._repo) : super(const LoginState());
}
```

#### GetIt과 BlocProvider 통합

```dart
// main.dart
void main() {
  configureDependencies();
  runApp(MyApp());
}

// App
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc(getIt<AuthRepository>())),
        BlocProvider<LoginBloc>(create: (_) => LoginBloc(getIt<AuthRepository>())),
      ],
      child: MaterialApp(...),
    );
  }
}

// 환경별 설정
@module
abstract class RegisterModule {
  @Environment('prod')
  @lazySingleton
  AuthRepository get authRepo => AuthRepositoryImpl(getIt());

  @Environment('test')
  @lazySingleton
  AuthRepository get mockRepo => MockAuthRepository();
}
```

### 실무 체크리스트

Effect 패턴 도입 시 확인 사항입니다.

| 항목 | 확인 |
|------|------|
| rxdart 사용 여부 결정 | ☐ |
| 메모리 누수 방지 (dispose, cancel) | ☐ |
| Hot Reload 시 중복 구독 방지 | ☐ |
| 딥링크와 Navigation Effect 우선순위 | ☐ |
| broadcast vs single subscription | ☐ |
| 앱 생명주기 (백그라운드 Effect) | ☐ |
| 비동기 Effect 결과 처리 (Completer) | ☐ |
| Widget 테스트 Effect 검증 | ☐ |
| Effect 로깅/디버깅 전략 | ☐ |
| 대량 Effect 성능 최적화 | ☐ |
| Freezed 통합 (선택) | ☐ |
| GetIt/Injectable DI (선택) | ☐ |

---

## 10. 정리

### 핵심 포인트

| 개념 | 설명 |
|------|------|
| **Side Effect** | 상태 변경 외 부수 작업 (Toast, Dialog, Navigation) |
| **UiEffect** | Side Effect의 더 직관적인 용어 |
| **BlocListener** | Side Effect 전용 위젯 (1회만 실행) |
| **BlocConsumer** | Builder + Listener 결합 |

### 기억할 공식

```
UI 렌더링     → BlocBuilder
Side Effect  → BlocListener
둘 다 필요    → BlocConsumer
```

### 권장 아키텍처

일관된 패턴: BaseBloc + Effect Stream

```
모든 Bloc에서 동일한 패턴 사용
    │
    ├── BaseBloc<Event, State, Effect> 상속
    ├── Effect는 별도 Stream으로 분리
    └── UI에서 BlocEffectMixin으로 구독
```

> 단순/복잡 구분 없이 **일관된 구조** 유지!

### 추천 프로젝트 구조

```
lib/
├── core/
│   ├── base_bloc.dart           // BaseBloc 정의
│   └── bloc_effect_mixin.dart   // Mixin 정의
│
├── features/
│   └── login/
│       ├── bloc/
│       │   ├── login_bloc.dart
│       │   ├── login_event.dart
│       │   ├── login_state.dart
│       │   └── login_effect.dart   // Effect 정의
│       └── ui/
│           └── login_page.dart
```

**장점**:
- 모든 Feature에서 동일한 패턴
- 새 팀원도 쉽게 이해
- Android/iOS 경험자에게 익숙한 구조

---

## 참고 자료

- [Bloc Library 공식 문서](https://bloclibrary.dev)
- [Flutter Bloc Package](https://pub.dev/packages/flutter_bloc)

> **용어는 팀과 합의하세요!**
> Side Effect든 UiEffect든, 팀 전체가 같은 용어를 쓰는 게 중요합니다.
