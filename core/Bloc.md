# Bloc 패턴 가이드

Flutter에서 Bloc(Business Logic Component) 패턴을 사용한 상태 관리 가이드입니다.

---

## 목차

1. [Bloc 개요](#1-bloc-개요)
2. [설치 및 설정](#2-설치-및-설정)
3. [Event 정의](#3-event-정의)
4. [State 정의](#4-state-정의)
5. [Bloc 클래스](#5-bloc-클래스)
6. [이벤트 핸들링](#6-이벤트-핸들링)
7. [Transformer](#7-transformer)
8. [UI 연동](#8-ui-연동)
9. [Bloc 통신](#9-bloc-통신)
10. [BlocObserver](#10-blocobserver)
11. [Pagination Pattern](#11-pagination-pattern)
12. [HydratedBloc](#12-hydratedbloc)
13. [테스트](#13-테스트)
14. [Best Practices](#14-best-practices)

---

> **Quick Start (5분 요약)**
>
> Bloc은 `Event → Bloc → State` 흐름으로 상태를 관리합니다.
> ```dart
> // 1. Event 정의 (Freezed)
> @freezed
> class HomeEvent with _$HomeEvent {
>   const factory HomeEvent.load() = _Load;
> }
>
> // 2. State 정의 (Freezed)
> @freezed
> class HomeState with _$HomeState {
>   const factory HomeState.initial() = _Initial;
>   const factory HomeState.loaded(HomeData data) = _Loaded;
>   const factory HomeState.error(HomeFailure failure) = _Error;
> }
>
> // 3. Bloc 구현
> class HomeBloc extends Bloc<HomeEvent, HomeState> {
>   HomeBloc(this._useCase) : super(const HomeState.initial()) {
>     on<HomeEvent>((event, emit) async {
>       final result = await _useCase();
>       result.fold(
>         (failure) => emit(HomeState.error(failure)),
>         (data) => emit(HomeState.loaded(data)),
>       );
>     });
>   }
>   final GetHomeDataUseCase _useCase;
> }
> ```
> 자세한 내용은 아래 각 섹션을 참조하세요.

---

## 1. Bloc 개요

### Bloc이란?

Bloc은 **Business Logic Component**의 약자로, UI와 비즈니스 로직을 분리하는 상태 관리 패턴입니다.

```
┌─────────┐     Event     ┌─────────┐     State     ┌─────────┐
│   UI    │ ────────────> │   Bloc  │ ────────────> │   UI    │
└─────────┘               └─────────┘               └─────────┘
```

### 핵심 개념

| 개념 | 설명 | 예시 |
|------|------|------|
| **Event** | 사용자 액션 또는 시스템 이벤트 | `LoginButtonPressed`, `DataLoaded` |
| **State** | 현재 상태를 나타내는 불변 객체 | `LoginInitial`, `LoginLoading`, `LoginSuccess` |
| **Bloc** | Event를 받아 State를 emit하는 클래스 | `LoginBloc`, `AuthBloc` |

### Bloc vs Cubit

| 항목 | Bloc | Cubit |
|------|------|-------|
| 입력 | Event 클래스 | 메서드 호출 |
| 복잡도 | 높음 | 낮음 |
| 추적성 | Event 로그로 추적 용이 | 메서드 호출만 추적 |
| 사용 시점 | 복잡한 비즈니스 로직 | 단순한 상태 변경 |

```dart
// Cubit - 메서드 직접 호출
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}

// Bloc - Event 기반
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}
```

---

## 2. 설치 및 설정

### 의존성 추가

```yaml
# pubspec.yaml (2026년 1월 기준)
dependencies:
  flutter_bloc: ^9.1.1  # 9.x 최신 stable
  equatable: ^2.0.8

dev_dependencies:
  bloc_test: ^10.0.0    # bloc ^9.0.0 호환
```

> **v9.0.0 주요 변경사항 (2025년):**
> - `BlocListener`가 자동으로 `context.mounted` 체크
> - 리스너 생명주기 관리 개선
> - `bloc.stream` 대신 `bloc.state` 변경 스트림 직접 구독 권장하지 않음

### 권장 VS Code 확장

- **Bloc** by Felix Angelov: 코드 스니펫 및 파일 생성

---

## 3. Event 정의

### 기본 Event 구조

```dart
// login_event.dart
import 'package:equatable/equatable.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}
```

### Event 클래스들

```dart
/// 로그인 폼 제출
class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;

  const LoginSubmitted({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// 이메일 변경
class LoginEmailChanged extends LoginEvent {
  final String email;

  const LoginEmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

/// 비밀번호 변경
class LoginPasswordChanged extends LoginEvent {
  final String password;

  const LoginPasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

/// 로그아웃
class LogoutRequested extends LoginEvent {
  const LogoutRequested();
}
```

### Event 네이밍 컨벤션

| 패턴 | 예시 | 사용 시점 |
|------|------|-----------|
| `~Submitted` | `LoginSubmitted` | 폼 제출 |
| `~Requested` | `LogoutRequested` | 명시적 요청 |
| `~Changed` | `EmailChanged` | 값 변경 |
| `~Started` | `DataFetchStarted` | 작업 시작 |
| `~Loaded` | `DataLoaded` | 데이터 로드 완료 |
| `~Failed` | `LoginFailed` | 실패 이벤트 |

### Freezed로 Event 정의

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_event.freezed.dart';

@freezed
class LoginEvent with _$LoginEvent {
  const factory LoginEvent.submitted({
    required String email,
    required String password,
  }) = LoginSubmitted;

  const factory LoginEvent.emailChanged(String email) = LoginEmailChanged;

  const factory LoginEvent.passwordChanged(String password) = LoginPasswordChanged;

  const factory LoginEvent.logoutRequested() = LogoutRequested;
}
```

---

## 4. State 정의

### 방식 1: 상태 플래그 방식

단순한 상태 관리에 적합합니다.

```dart
// login_state.dart
import 'package:equatable/equatable.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;
  final String email;
  final String password;
  final String? errorMessage;

  const LoginState({
    this.status = LoginStatus.initial,
    this.email = '',
    this.password = '',
    this.errorMessage,
  });

  /// 초기 상태
  factory LoginState.initial() => const LoginState();

  /// 상태 복사
  LoginState copyWith({
    LoginStatus? status,
    String? email,
    String? password,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 편의 getter
  bool get isLoading => status == LoginStatus.loading;
  bool get isSuccess => status == LoginStatus.success;
  bool get isFailure => status == LoginStatus.failure;

  @override
  List<Object?> get props => [status, email, password, errorMessage];
}
```

### 방식 2: sealed class 방식

복잡한 상태 분기에 적합합니다.

```dart
// login_state.dart
import 'package:equatable/equatable.dart';

sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

/// 초기 상태
class LoginInitial extends LoginState {
  const LoginInitial();
}

/// 로딩 중
class LoginLoading extends LoginState {
  const LoginLoading();
}

/// 로그인 성공
class LoginSuccess extends LoginState {
  final User user;

  const LoginSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

/// 로그인 실패
class LoginFailure extends LoginState {
  final String message;

  const LoginFailure(this.message);

  @override
  List<Object?> get props => [message];
}
```

### 방식 3: Freezed 사용

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.freezed.dart';

@freezed
class LoginState with _$LoginState {
  const factory LoginState.initial() = LoginInitial;
  const factory LoginState.loading() = LoginLoading;
  const factory LoginState.success(User user) = LoginSuccess;
  const factory LoginState.failure(String message) = LoginFailure;
}
```

### 상태 플래그 vs sealed class

| 항목 | 상태 플래그 | sealed class |
|------|-------------|--------------|
| 코드량 | 적음 | 많음 |
| 타입 안전성 | 낮음 | 높음 |
| 패턴 매칭 | 불가 | 가능 |
| 상태 조합 | 쉬움 | 어려움 |
| 권장 상황 | 단순한 CRUD | 복잡한 상태 분기 |

---

## 5. Bloc 클래스

### 기본 구조

```dart
// login_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;

  LoginBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const LoginState()) {
    // 이벤트 핸들러 등록
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  void _onEmailChanged(
    LoginEmailChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(email: event.email));
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(password: event.password));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(status: LoginStatus.loading));

    try {
      await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(status: LoginStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<LoginState> emit,
  ) async {
    await _authRepository.logout();
    emit(LoginState.initial());
  }
}
```

### sealed class State 처리

```dart
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;

  LoginBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const LoginInitial()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());

    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(LoginSuccess(user));
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }
}
```

---

## 6. 이벤트 핸들링

### 동기 핸들러

```dart
on<CounterIncremented>((event, emit) {
  emit(state + 1);  // 즉시 emit
});
```

### 비동기 핸들러

```dart
on<DataFetchRequested>((event, emit) async {
  emit(state.copyWith(status: Status.loading));

  try {
    final data = await _repository.fetchData();
    emit(state.copyWith(status: Status.success, data: data));
  } catch (e) {
    emit(state.copyWith(status: Status.failure, error: e.toString()));
  }
});
```

### emit.forEach - Stream 처리

```dart
on<DataStreamStarted>((event, emit) async {
  await emit.forEach<Data>(
    _repository.dataStream,
    onData: (data) => state.copyWith(data: data),
    onError: (error, stackTrace) => state.copyWith(
      status: Status.failure,
      error: error.toString(),
    ),
  );
});
```

### emit.onEach - Stream 개별 처리

```dart
on<ConnectionStatusChanged>((event, emit) async {
  await emit.onEach<ConnectionStatus>(
    _connectivityService.statusStream,
    onData: (status) {
      emit(state.copyWith(isConnected: status == ConnectionStatus.connected));
    },
  );
});
```

### isClosed 체크 (중요)

비동기 작업 후에는 반드시 `isClosed`와 `emit.isDone`을 체크해야 합니다.

```dart
on<DataFetchRequested>((event, emit) async {
  emit(state.copyWith(status: Status.loading));

  final result = await _repository.fetchData();

  // 비동기 작업 중 Bloc이 close되거나 emit이 완료될 수 있음
  if (isClosed || emit.isDone) return;

  emit(state.copyWith(status: Status.success, data: result));
});
```

---

## 7. Transformer

Transformer는 이벤트 처리 방식을 제어합니다.

### 기본 Transformer 종류

```dart
import 'package:bloc_concurrency/bloc_concurrency.dart';
```

| Transformer | 동작 | 사용 시점 |
|-------------|------|-----------|
| `sequential()` | 순차 처리 (큐) - 기본값 | 순서가 중요한 이벤트 |
| `concurrent()` | 모든 이벤트 병렬 처리 | 독립적인 이벤트 |
| `droppable()` | 처리 중 새 이벤트 무시 | 중복 요청 방지 |
| `restartable()` | 처리 중 취소 후 새 이벤트 처리 | 검색, 자동완성 |

### 사용 예시

```dart
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(const SearchState()) {
    // 검색: 이전 요청 취소 후 새 요청 처리
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: restartable(),
    );

    // 로그인: 중복 요청 방지
    on<LoginSubmitted>(
      _onLoginSubmitted,
      transformer: droppable(),
    );

    // 데이터 로드: 순차 처리
    on<DataLoadRequested>(
      _onDataLoadRequested,
      transformer: sequential(),
    );
  }
}
```

### Debounce Transformer

검색 입력에 디바운스 적용:

```dart
import 'package:stream_transform/stream_transform.dart';

EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) {
    return events.debounce(duration).switchMap(mapper);
  };
}

// 사용
on<SearchQueryChanged>(
  _onQueryChanged,
  transformer: debounce(const Duration(milliseconds: 300)),
);
```

### Throttle Transformer

```dart
EventTransformer<E> throttle<E>(Duration duration) {
  return (events, mapper) {
    return events.throttle(duration).switchMap(mapper);
  };
}

// 스크롤 이벤트 처리
on<ScrollPositionChanged>(
  _onScrollPositionChanged,
  transformer: throttle(const Duration(milliseconds: 100)),
);
```

---

## 8. UI 연동

### BlocProvider

Bloc을 위젯 트리에 제공합니다.

```dart
// 단일 Bloc 제공
BlocProvider(
  create: (context) => LoginBloc(
    authRepository: context.read<AuthRepository>(),
  ),
  child: const LoginPage(),
)

// 기존 Bloc 인스턴스 제공 (close 안됨)
BlocProvider.value(
  value: existingBloc,
  child: const ChildWidget(),
)
```

### MultiBlocProvider

여러 Bloc을 한 번에 제공합니다.

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => AuthBloc()),
    BlocProvider(create: (_) => ThemeBloc()),
    BlocProvider(create: (context) => UserBloc(
      authBloc: context.read<AuthBloc>(),
    )),
  ],
  child: const MyApp(),
)
```

### BlocBuilder

상태에 따라 UI를 빌드합니다.

```dart
BlocBuilder<LoginBloc, LoginState>(
  // 선택적: 특정 조건에서만 rebuild
  buildWhen: (previous, current) {
    return previous.status != current.status;
  },
  builder: (context, state) {
    if (state.isLoading) {
      return const CircularProgressIndicator();
    }

    return LoginForm(
      email: state.email,
      password: state.password,
    );
  },
)
```

### BlocSelector

상태의 특정 부분만 선택하여 rebuild합니다.

```dart
BlocSelector<LoginBloc, LoginState, bool>(
  selector: (state) => state.isLoading,
  builder: (context, isLoading) {
    return isLoading
        ? const CircularProgressIndicator()
        : const SizedBox.shrink();
  },
)
```

### BlocListener

상태 변화에 따라 side effect를 실행합니다.

```dart
BlocListener<LoginBloc, LoginState>(
  listenWhen: (previous, current) {
    return previous.status != current.status;
  },
  listener: (context, state) {
    if (state.isSuccess) {
      Navigator.pushReplacementNamed(context, '/home');
    }
    if (state.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? '오류 발생')),
      );
    }
  },
  child: const LoginForm(),
)
```

### MultiBlocListener

여러 Bloc을 동시에 listen합니다.

```dart
MultiBlocListener(
  listeners: [
    BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Auth 관련 처리
      },
    ),
    BlocListener<ConnectivityBloc, ConnectivityState>(
      listener: (context, state) {
        // 연결 상태 처리
      },
    ),
  ],
  child: const MyApp(),
)
```

### BlocConsumer

Builder와 Listener를 결합합니다.

```dart
BlocConsumer<LoginBloc, LoginState>(
  listenWhen: (previous, current) => previous.status != current.status,
  listener: (context, state) {
    if (state.isSuccess) {
      Navigator.pushReplacementNamed(context, '/home');
    }
    if (state.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? '오류')),
      );
    }
  },
  buildWhen: (previous, current) => previous.isLoading != current.isLoading,
  builder: (context, state) {
    return ElevatedButton(
      onPressed: state.isLoading
          ? null
          : () => context.read<LoginBloc>().add(
                LoginSubmitted(
                  email: state.email,
                  password: state.password,
                ),
              ),
      child: state.isLoading
          ? const CircularProgressIndicator()
          : const Text('로그인'),
    );
  },
)
```

### context.read vs context.watch

```dart
// read: 일회성 접근 (이벤트 발생 시)
ElevatedButton(
  onPressed: () {
    context.read<CounterBloc>().add(Increment());
  },
  child: const Text('증가'),
)

// watch: 상태 변화 감지 (build 메서드 내)
@override
Widget build(BuildContext context) {
  final count = context.watch<CounterBloc>().state;
  return Text('$count');
}

// select: 특정 값만 감지
@override
Widget build(BuildContext context) {
  final isLoading = context.select<LoginBloc, bool>(
    (bloc) => bloc.state.isLoading,
  );
  return isLoading ? const Loader() : const Content();
}
```

---

## 9. Bloc 통신

### 패턴 1: Bloc 생성자 주입

```dart
class UserBloc extends Bloc<UserEvent, UserState> {
  final AuthBloc _authBloc;
  late StreamSubscription<AuthState> _authSubscription;

  UserBloc({required AuthBloc authBloc})
      : _authBloc = authBloc,
        super(const UserState()) {
    // AuthBloc 상태 구독
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is Authenticated) {
        add(LoadUserProfile(authState.userId));
      }
      if (authState is Unauthenticated) {
        add(const ClearUserProfile());
      }
    });

    on<LoadUserProfile>(_onLoadUserProfile);
    on<ClearUserProfile>(_onClearUserProfile);
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
```

### 패턴 2: Repository를 통한 통신

```dart
// 공유 Repository
class SessionRepository {
  // import 'package:rxdart/rxdart.dart';
  final _sessionController = BehaviorSubject<Session?>.seeded(null);

  Stream<Session?> get sessionStream => _sessionController.stream;
  Session? get currentSession => _sessionController.value;

  void updateSession(Session session) {
    _sessionController.add(session);
  }

  void clearSession() {
    _sessionController.add(null);
  }
}

// AuthBloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SessionRepository _sessionRepository;

  AuthBloc({required SessionRepository sessionRepository})
      : _sessionRepository = sessionRepository,
        super(const AuthInitial()) {
    on<LoginSucceeded>((event, emit) {
      _sessionRepository.updateSession(event.session);
      emit(Authenticated(event.session));
    });
  }
}

// UserBloc
class UserBloc extends Bloc<UserEvent, UserState> {
  final SessionRepository _sessionRepository;
  late StreamSubscription<Session?> _sessionSubscription;

  UserBloc({required SessionRepository sessionRepository})
      : _sessionRepository = sessionRepository,
        super(const UserState()) {
    _sessionSubscription = _sessionRepository.sessionStream.listen((session) {
      if (session != null) {
        add(LoadUserProfile(session.userId));
      }
    });
  }
}
```

### 패턴 3: BlocListener를 통한 통신

```dart
MultiBlocListener(
  listeners: [
    BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.read<UserBloc>().add(LoadUserProfile(state.userId));
          context.read<SettingsBloc>().add(const LoadSettings());
        }
        if (state is Unauthenticated) {
          context.read<UserBloc>().add(const ClearUserProfile());
          context.read<CartBloc>().add(const ClearCart());
        }
      },
    ),
  ],
  child: const MyApp(),
)
```

---

## 10. BlocObserver

### BlocObserver란?

`BlocObserver`는 앱의 모든 Bloc/Cubit 상태 변경을 전역적으로 관찰하고 로깅할 수 있는 클래스입니다.

### 기본 구현

```dart
// app_bloc_observer.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    debugPrint('onCreate -- ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    debugPrint('onEvent -- ${bloc.runtimeType} | $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    debugPrint('onChange -- ${bloc.runtimeType} | $change');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    debugPrint('onTransition -- ${bloc.runtimeType} | $transition');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('onError -- ${bloc.runtimeType} | $error');
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    debugPrint('onClose -- ${bloc.runtimeType}');
  }
}
```

### Firebase Crashlytics 연동

프로덕션 환경에서 에러를 자동으로 리포팅합니다.

```dart
// app_bloc_observer.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);

    // 개발 환경에서만 로깅
    if (kDebugMode) {
      debugPrint('${bloc.runtimeType} | $event');
    }
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);

    if (kDebugMode) {
      debugPrint('${bloc.runtimeType} | ${change.currentState} -> ${change.nextState}');
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);

    // 개발/프로덕션 모두 에러 로깅
    debugPrint('ERROR in ${bloc.runtimeType}: $error');

    // 프로덕션에서 Crashlytics로 리포팅
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Bloc Error in ${bloc.runtimeType}',
        fatal: false,
      );
    }
  }
}
```

### main.dart에서 설정

```dart
// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp();

  // BlocObserver 설정
  Bloc.observer = AppBlocObserver();

  // Flutter 프레임워크 에러도 Crashlytics로 전송
  if (kReleaseMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // 비동기 에러 처리
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(const MyApp());
}
```

### 환경별 설정 패턴

```dart
// app_bloc_observer.dart
class AppBlocObserver extends BlocObserver {
  final bool enableDetailedLogs;
  final bool reportToCrashlytics;

  AppBlocObserver({
    this.enableDetailedLogs = kDebugMode,
    this.reportToCrashlytics = kReleaseMode,
  });

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);

    if (enableDetailedLogs) {
      debugPrint('[EVENT] ${bloc.runtimeType}: $event');
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);

    // 항상 콘솔에 출력
    debugPrint('[ERROR] ${bloc.runtimeType}: $error\n$stackTrace');

    // 프로덕션에서만 Crashlytics 리포팅
    if (reportToCrashlytics) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Bloc: ${bloc.runtimeType}',
        information: ['State: ${bloc.state}'],
      );
    }
  }
}

// main.dart
void main() {
  Bloc.observer = AppBlocObserver(
    enableDetailedLogs: kDebugMode,
    reportToCrashlytics: kReleaseMode,
  );

  runApp(const MyApp());
}
```

### 커스텀 로깅 서비스 연동

```dart
// logging_service.dart
abstract class LoggingService {
  void logEvent(String message);
  void logError(String message, Object error, StackTrace stackTrace);
}

// firebase_logging_service.dart
class FirebaseLoggingService implements LoggingService {
  @override
  void logEvent(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  @override
  void logError(String message, Object error, StackTrace stackTrace) {
    debugPrint('$message: $error');

    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
      );
    }
  }
}

// app_bloc_observer.dart
class AppBlocObserver extends BlocObserver {
  final LoggingService _loggingService;

  AppBlocObserver({required LoggingService loggingService})
      : _loggingService = loggingService;

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _loggingService.logEvent('${bloc.runtimeType} | $event');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _loggingService.logError(
      'Error in ${bloc.runtimeType}',
      error,
      stackTrace,
    );
  }
}
```

### 주의사항

| 항목 | 설명 |
|------|------|
| **성능** | 과도한 로깅은 성능에 영향을 줄 수 있으므로 프로덕션에서는 필수 로깅만 활성화 |
| **민감정보** | 로그에 비밀번호, 토큰 등 민감한 정보가 포함되지 않도록 주의 |
| **로그 레벨** | 개발/스테이징/프로덕션 환경별로 로그 레벨을 다르게 설정 |
| **Crashlytics 쿼터** | Firebase 무료 플랜은 일일 Crashlytics 이벤트 제한이 있음 |

---

## 11. Pagination Pattern

### 11.1 PaginationState 정의

```dart
// lib/core/pagination/pagination_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_state.freezed.dart';

@freezed
class PaginationState<T> with _$PaginationState<T> {
  const factory PaginationState({
    @Default([]) List<T> items,
    @Default(1) int currentPage,
    @Default(20) int pageSize,
    @Default(false) bool isLoading,
    @Default(false) bool hasReachedEnd,
    String? error,
  }) = _PaginationState<T>;

  const PaginationState._();

  bool get canLoadMore => !isLoading && !hasReachedEnd && error == null;
}
```

### 11.2 Pagination Bloc 구현

```dart
// lib/features/products/presentation/bloc/product_list_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

class ProductListBloc extends Bloc<ProductListEvent, PaginationState<Product>> {
  final GetProductsUseCase _getProducts;

  ProductListBloc(this._getProducts) : super(const PaginationState()) {
    on<ProductListEvent>(
      (event, emit) => event.map(
        started: (_) => _onStarted(emit),
        loadMore: (_) => _onLoadMore(emit),
        refresh: (_) => _onRefresh(emit),
      ),
      // 중복 요청 방지: 이전 요청 취소
      transformer: droppable(),
    );
  }

  Future<void> _onStarted(Emitter<PaginationState<Product>> emit) async {
    if (state.items.isNotEmpty) return; // 이미 로드됨

    emit(state.copyWith(isLoading: true, error: null));

    final result = await _getProducts(page: 1, pageSize: state.pageSize);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (products) => emit(state.copyWith(
        items: products,
        currentPage: 1,
        isLoading: false,
        hasReachedEnd: products.length < state.pageSize,
      )),
    );
  }

  Future<void> _onLoadMore(Emitter<PaginationState<Product>> emit) async {
    if (!state.canLoadMore) return;

    emit(state.copyWith(isLoading: true));

    final nextPage = state.currentPage + 1;
    final result = await _getProducts(page: nextPage, pageSize: state.pageSize);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (products) => emit(state.copyWith(
        items: [...state.items, ...products],
        currentPage: nextPage,
        isLoading: false,
        hasReachedEnd: products.length < state.pageSize,
      )),
    );
  }

  Future<void> _onRefresh(Emitter<PaginationState<Product>> emit) async {
    emit(const PaginationState(isLoading: true));

    final result = await _getProducts(page: 1, pageSize: state.pageSize);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (products) => emit(state.copyWith(
        items: products,
        currentPage: 1,
        isLoading: false,
        hasReachedEnd: products.length < state.pageSize,
      )),
    );
  }
}
```

### 11.3 UI 연동

```dart
class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductListBloc, PaginationState<Product>>(
      builder: (context, state) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // 스크롤이 80% 이상 내려가면 다음 페이지 로드
            if (notification is ScrollEndNotification &&
                notification.metrics.pixels >=
                notification.metrics.maxScrollExtent * 0.8) {
              context.read<ProductListBloc>().add(
                const ProductListEvent.loadMore(),
              );
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<ProductListBloc>().add(
                const ProductListEvent.refresh(),
              );
              // Bloc 상태가 업데이트될 때까지 대기
              await context.read<ProductListBloc>().stream
                  .firstWhere((s) => !s.isLoading);
            },
            child: ListView.builder(
              itemCount: state.items.length + (state.canLoadMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ProductCard(product: state.items[index]);
              },
            ),
          ),
        );
      },
    );
  }
}
```

### 11.4 중요 패턴

| 패턴 | 설명 |
|-----|------|
| `droppable()` | 이전 요청 취소, 최신 요청만 처리 |
| `canLoadMore` | 중복 로드 방지 |
| `ScrollEndNotification` | 스크롤 80% 지점에서 미리 로드 |
| `RefreshIndicator` | Pull-to-refresh 지원 |

---

## 12. HydratedBloc

### HydratedBloc이란?

`HydratedBloc`은 Bloc의 상태를 로컬 저장소에 자동으로 저장하고, 앱 재시작 시 복원하는 패키지입니다.

### 설치

```yaml
# pubspec.yaml
dependencies:
  hydrated_bloc: ^10.0.0  # bloc ^9.0.0 호환
  path_provider: ^2.1.5
```

### 기본 설정

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // HydratedStorage 초기화
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );

  runApp(const MyApp());
}
```

### HydratedBloc 구현

```dart
// counter_bloc.dart
import 'package:hydrated_bloc/hydrated_bloc.dart';

// Event
sealed class CounterEvent {}
class Increment extends CounterEvent {}
class Decrement extends CounterEvent {}

// Bloc
class CounterBloc extends HydratedBloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
    on<Decrement>((event, emit) => emit(state - 1));
  }

  /// 상태를 JSON으로 직렬화
  @override
  int? fromJson(Map<String, dynamic> json) {
    return json['value'] as int?;
  }

  /// JSON에서 상태 복원
  @override
  Map<String, dynamic>? toJson(int state) {
    return {'value': state};
  }
}
```

### 복잡한 State 직렬화

```dart
// todo_state.dart
import 'package:equatable/equatable.dart';

class TodoState extends Equatable {
  final List<Todo> todos;
  final TodoFilter filter;

  const TodoState({
    this.todos = const [],
    this.filter = TodoFilter.all,
  });

  @override
  List<Object?> get props => [todos, filter];

  /// JSON으로 직렬화
  Map<String, dynamic> toJson() {
    return {
      'todos': todos.map((todo) => todo.toJson()).toList(),
      'filter': filter.name,
    };
  }

  /// JSON에서 복원
  factory TodoState.fromJson(Map<String, dynamic> json) {
    return TodoState(
      todos: (json['todos'] as List<dynamic>?)
          ?.map((e) => Todo.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
      filter: TodoFilter.values.firstWhere(
        (f) => f.name == json['filter'],
        orElse: () => TodoFilter.all,
      ),
    );
  }
}

// todo_bloc.dart
class TodoBloc extends HydratedBloc<TodoEvent, TodoState> {
  TodoBloc() : super(const TodoState()) {
    on<AddTodo>(_onAddTodo);
    on<DeleteTodo>(_onDeleteTodo);
  }

  @override
  TodoState? fromJson(Map<String, dynamic> json) {
    try {
      return TodoState.fromJson(json);
    } catch (e) {
      // 복원 실패 시 기본 상태 반환
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(TodoState state) {
    try {
      return state.toJson();
    } catch (e) {
      return null;
    }
  }
}
```

### Freezed와 함께 사용

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'settings_state.freezed.dart';
part 'settings_state.g.dart';  // json_serializable

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(false) bool isDarkMode,
    @Default('ko') String language,
    @Default(true) bool notificationsEnabled,
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);
}

class SettingsBloc extends HydratedBloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<ToggleDarkMode>(_onToggleDarkMode);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  @override
  SettingsState? fromJson(Map<String, dynamic> json) {
    try {
      return SettingsState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(SettingsState state) {
    return state.toJson();
  }
}
```

### HydratedCubit 사용

```dart
// theme_cubit.dart
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class ThemeCubit extends HydratedCubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void setTheme(ThemeMode mode) => emit(mode);

  void toggleTheme() {
    emit(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  ThemeMode? fromJson(Map<String, dynamic> json) {
    final modeString = json['themeMode'] as String?;
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == modeString,
      orElse: () => ThemeMode.system,
    );
  }

  @override
  Map<String, dynamic>? toJson(ThemeMode state) {
    return {'themeMode': state.name};
  }
}
```

### 저장소 초기화 옵션

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 기본 경로 사용
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );

  // 또는 커스텀 경로 사용
  // HydratedBloc.storage = await HydratedStorage.build(
  //   storageDirectory: Directory('/custom/path'),
  // );

  runApp(const MyApp());
}
```

### 저장소 초기화 및 삭제

```dart
// 특정 Bloc의 저장된 데이터 삭제
await HydratedBloc.storage.delete('CounterBloc');

// 모든 저장된 데이터 삭제
await HydratedBloc.storage.clear();

// 저장소 직접 읽기
final data = await HydratedBloc.storage.read('CounterBloc');
```

### 마이그레이션 패턴

버전 업데이트 시 저장된 데이터 구조가 변경될 경우:

```dart
class UserBloc extends HydratedBloc<UserEvent, UserState> {
  static const int _currentVersion = 2;

  UserBloc() : super(UserState.initial());

  @override
  UserState? fromJson(Map<String, dynamic> json) {
    try {
      final version = json['version'] as int? ?? 1;

      // 버전별 마이그레이션
      if (version == 1) {
        return _migrateFromV1(json);
      }

      return UserState.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(UserState state) {
    final json = state.toJson();
    json['version'] = _currentVersion;
    return json;
  }

  UserState _migrateFromV1(Map<String, dynamic> json) {
    // V1 데이터를 V2 형식으로 변환
    return UserState(
      id: json['userId'] as String,  // 필드명 변경
      name: json['name'] as String,
      // 새로운 필드는 기본값
      email: '',
    );
  }
}
```

### 주의사항

| 항목 | 설명 |
|------|------|
| **민감 정보** | 토큰, 비밀번호 등 민감한 정보는 저장하지 말 것 (secure_storage 사용) |
| **데이터 크기** | 대용량 데이터는 성능 저하 원인 (이미지, 파일 등은 별도 저장) |
| **직렬화 가능** | fromJson/toJson이 가능한 데이터만 저장 가능 |
| **에러 처리** | fromJson에서 예외 발생 시 null 반환하여 기본 상태로 복원 |
| **플랫폼 제한** | 웹에서는 localStorage 사용 (용량 제한 있음) |

### 테스트

```dart
// counter_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements Storage {}

void main() {
  late Storage storage;

  setUp(() {
    storage = MockStorage();
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  group('CounterBloc', () {
    test('초기 상태는 0', () {
      expect(CounterBloc().state, 0);
    });

    test('저장된 상태 복원', () {
      when<dynamic>(() => storage.read('CounterBloc'))
          .thenReturn({'value': 42});

      expect(CounterBloc().state, 42);
    });

    test('상태 변경 시 저장', () async {
      final bloc = CounterBloc();
      bloc.add(Increment());
      await bloc.close();

      verify(() => storage.write('CounterBloc', {'value': 1})).called(1);
    });
  });
}
```

### Best Practices

```dart
// 좋은 예: 작은 설정 데이터 저장
class SettingsBloc extends HydratedBloc<SettingsEvent, SettingsState> {
  // 사용자 설정, 테마, 언어 등
}

// 나쁜 예: 대용량 데이터 저장
class MediaBloc extends HydratedBloc<MediaEvent, MediaState> {
  // 이미지, 비디오 데이터 (X)
  // 파일 경로만 저장하고 실제 데이터는 별도 저장
}

// 나쁜 예: 민감한 정보 저장
class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  // 비밀번호, API 키 (X)
  // flutter_secure_storage 사용 필요
}
```

---

## 13. 테스트

### 의존성 추가

```yaml
dev_dependencies:
  bloc_test: ^10.0.0
  mockito: ^5.6.3
  build_runner: ^2.4.0
```

### Mock 생성

```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([AuthRepository, LoginBloc])
void main() {}

// 생성된 Mock 클래스들은 'test_file.mocks.dart' 파일에서 사용
// dart run build_runner build 실행 필요
```

또는 수동으로 Mock Bloc 정의:

```dart
import 'package:bloc_test/bloc_test.dart';

class MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}
```

### blocTest 사용

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('LoginBloc', () {
    blocTest<LoginBloc, LoginState>(
      '초기 상태는 LoginState.initial()',
      build: () => LoginBloc(authRepository: mockAuthRepository),
      verify: (bloc) {
        expect(bloc.state, equals(LoginState.initial()));
      },
    );

    blocTest<LoginBloc, LoginState>(
      'LoginSubmitted 성공 시 status가 success로 변경',
      setUp: () {
        when(mockAuthRepository.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => User(id: '1', name: 'Test'));
      },
      build: () => LoginBloc(authRepository: mockAuthRepository),
      act: (bloc) => bloc.add(const LoginSubmitted(
        email: 'test@test.com',
        password: 'password123',
      )),
      expect: () => [
        LoginState.initial().copyWith(status: LoginStatus.loading),
        LoginState.initial().copyWith(status: LoginStatus.success),
      ],
      verify: (_) {
        verify(mockAuthRepository.login(
          email: 'test@test.com',
          password: 'password123',
        )).called(1);
      },
    );

    blocTest<LoginBloc, LoginState>(
      'LoginSubmitted 실패 시 status가 failure로 변경',
      setUp: () {
        when(mockAuthRepository.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(Exception('Invalid credentials'));
      },
      build: () => LoginBloc(authRepository: mockAuthRepository),
      act: (bloc) => bloc.add(const LoginSubmitted(
        email: 'test@test.com',
        password: 'wrong',
      )),
      expect: () => [
        LoginState.initial().copyWith(status: LoginStatus.loading),
        predicate<LoginState>((state) =>
          state.status == LoginStatus.failure &&
          state.errorMessage != null
        ),
      ],
    );
  });
}
```

### 비동기 테스트

```dart
blocTest<DataBloc, DataState>(
  'Stream 데이터 처리',
  setUp: () {
    when(mockRepository.dataStream).thenAnswer(
      (_) => Stream.fromIterable([
        Data(id: '1'),
        Data(id: '2'),
        Data(id: '3'),
      ]),
    );
  },
  build: () => DataBloc(repository: mockRepository),
  act: (bloc) => bloc.add(const StartListening()),
  expect: () => [
    DataState(data: Data(id: '1')),
    DataState(data: Data(id: '2')),
    DataState(data: Data(id: '3')),
  ],
);
```

### Widget 테스트

```dart
testWidgets('LoginPage 테스트', (tester) async {
  final mockBloc = MockLoginBloc();

  whenListen(
    mockBloc,
    Stream<LoginState>.empty(),
    initialState: LoginState.initial(),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<LoginBloc>.value(
        value: mockBloc,
        child: const LoginPage(),
      ),
    ),
  );

  // 이메일 입력
  await tester.enterText(
    find.byKey(const Key('email_input')),
    'test@test.com',
  );

  // 비밀번호 입력
  await tester.enterText(
    find.byKey(const Key('password_input')),
    'password123',
  );

  // 로그인 버튼 탭
  await tester.tap(find.byType(ElevatedButton));

  // 이벤트 발생 확인
  verify(mockBloc.add(const LoginSubmitted(
    email: 'test@test.com',
    password: 'password123',
  ))).called(1);
});
```

---

## 14. Best Practices

### DO (이렇게 하세요)

| 항목 | 설명 |
|------|------|
| Event/State를 immutable로 | Equatable 또는 Freezed 사용 |
| 하나의 책임 원칙 | Bloc당 하나의 기능 담당 |
| Repository 주입 | 테스트 용이성 확보 |
| isClosed 체크 | 비동기 작업 후 반드시 체크 |
| 적절한 Transformer 사용 | 이벤트 특성에 맞게 선택 |

### DON'T (이렇게 하지 마세요)

| 항목 | 이유 |
|------|------|
| Bloc 내에서 UI 코드 | 관심사 분리 위반 |
| BuildContext 전달 | Bloc은 UI 독립적이어야 함 |
| 거대한 Bloc | 분리 필요 신호 |
| State 직접 변경 | 항상 copyWith 또는 새 인스턴스 |

### 파일 구조

```
lib/
├── features/
│   └── login/
│       ├── bloc/
│       │   ├── login_bloc.dart
│       │   ├── login_event.dart
│       │   └── login_state.dart
│       ├── data/
│       │   ├── repositories/
│       │   │   └── auth_repository.dart
│       │   └── models/
│       │       └── user.dart
│       └── presentation/
│           ├── pages/
│           │   └── login_page.dart
│           └── widgets/
│               └── login_form.dart
```

### 상태 설계 원칙

```dart
// 좋은 예: 명확한 상태 구분
class ProductListState extends Equatable {
  final List<Product> products;
  final bool isLoading;
  final bool hasReachedMax;
  final String? errorMessage;

  const ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.hasReachedMax = false,
    this.errorMessage,
  });

  // 편의 getter
  bool get isEmpty => products.isEmpty && !isLoading;
  bool get canLoadMore => !isLoading && !hasReachedMax;
}

// 나쁜 예: 모호한 상태
class ProductListState {
  final List<Product>? products;  // null과 []의 구분이 모호
  final bool? isLoading;          // null 상태의 의미?
  final dynamic error;            // 타입 불명확
}
```

### 에러 처리 패턴

```dart
Future<void> _onDataRequested(
  DataRequested event,
  Emitter<DataState> emit,
) async {
  emit(state.copyWith(status: Status.loading));

  final result = await _repository.fetchData();

  result.fold(
    (failure) => emit(state.copyWith(
      status: Status.failure,
      errorMessage: failure.message,
    )),
    (data) => emit(state.copyWith(
      status: Status.success,
      data: data,
    )),
  );
}
```

---

## 참고 자료

- [Bloc Library 공식 문서](https://bloclibrary.dev)
- [flutter_bloc 패키지](https://pub.dev/packages/flutter_bloc)
- [bloc_test 패키지](https://pub.dev/packages/bloc_test)
- [bloc_concurrency 패키지](https://pub.dev/packages/bloc_concurrency)
