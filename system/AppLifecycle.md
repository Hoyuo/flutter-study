# Flutter 앱 생명주기 가이드

## 개요

앱 생명주기(Lifecycle) 관리는 백그라운드/포그라운드 전환, 메모리 관리, 상태 복원 등에 중요합니다. WidgetsBindingObserver, AppLifecycleListener, 그리고 Bloc과의 통합을 다룹니다.

## App Lifecycle 상태

### AppLifecycleState

```dart
enum AppLifecycleState {
  /// 앱이 호스트 뷰 내에서 보이고 응답 (Foreground)
  resumed,

  /// 앱이 비활성 상태이고 사용자 입력을 받지 않음
  /// iOS: 포그라운드에서 전화가 오거나 제어센터 열 때
  /// Android: 멀티윈도우 비활성 상태
  inactive,

  /// 앱이 숨겨져 있지만 실행 중 (Background)
  hidden,

  /// 앱이 일시 중지됨 (Background)
  paused,

  /// 앱이 Flutter 엔진에서 분리됨
  detached,
}
```

### 일반적인 상태 전환

```
앱 시작: detached → resumed
백그라운드로 이동: resumed → inactive → hidden → paused
포그라운드로 복귀: paused → hidden → inactive → resumed
앱 종료: paused → detached
```

## 기본 Lifecycle 감지

### WidgetsBindingObserver 사용

```dart
// lib/core/lifecycle/app_lifecycle_observer.dart
import 'package:flutter/material.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  final void Function(AppLifecycleState state)? onStateChange;
  final VoidCallback? onResumed;
  final VoidCallback? onPaused;
  final VoidCallback? onInactive;
  final VoidCallback? onDetached;

  AppLifecycleObserver({
    this.onStateChange,
    this.onResumed,
    this.onPaused,
    this.onInactive,
    this.onDetached,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChange?.call(state);

    switch (state) {
      case AppLifecycleState.resumed:
        onResumed?.call();
        break;
      case AppLifecycleState.paused:
        onPaused?.call();
        break;
      case AppLifecycleState.inactive:
        onInactive?.call();
        break;
      case AppLifecycleState.detached:
        onDetached?.call();
        break;
      default:
        break;
    }
  }
}
```

### StatefulWidget에서 사용

```dart
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onResumed();
        break;
      case AppLifecycleState.paused:
        _onPaused();
        break;
      default:
        break;
    }
  }

  void _onResumed() {
    // 포그라운드로 복귀
    // 데이터 새로고침, 연결 재개 등
    print('App resumed');
  }

  void _onPaused() {
    // 백그라운드로 이동
    // 데이터 저장, 연결 중단 등
    print('App paused');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

## AppLifecycleListener (Flutter 3.13+)

### 새로운 API 사용

```dart
// lib/core/lifecycle/lifecycle_listener_widget.dart
import 'package:flutter/material.dart';

class LifecycleListenerWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onResume;
  final VoidCallback? onPause;
  final VoidCallback? onInactive;
  final VoidCallback? onHide;
  final VoidCallback? onShow;
  final AppExitResponse Function()? onExitRequested;

  const LifecycleListenerWidget({
    super.key,
    required this.child,
    this.onResume,
    this.onPause,
    this.onInactive,
    this.onHide,
    this.onShow,
    this.onExitRequested,
  });

  @override
  State<LifecycleListenerWidget> createState() => _LifecycleListenerWidgetState();
}

class _LifecycleListenerWidgetState extends State<LifecycleListenerWidget> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: widget.onResume,
      onPause: widget.onPause,
      onInactive: widget.onInactive,
      onHide: widget.onHide,
      onShow: widget.onShow,
      onExitRequested: widget.onExitRequested,
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
```

### 사용 예시

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LifecycleListenerWidget(
      onResume: () {
        print('App resumed');
        // 데이터 새로고침
      },
      onPause: () {
        print('App paused');
        // 상태 저장
      },
      onExitRequested: () {
        // 앱 종료 요청 처리 (저장되지 않은 데이터 등)
        return AppExitResponse.exit;  // 또는 AppExitResponse.cancel
      },
      child: MaterialApp(...),
    );
  }
}
```

## Lifecycle Service

### 전역 Lifecycle 관리

```dart
// lib/core/lifecycle/app_lifecycle_service.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AppLifecycleService with WidgetsBindingObserver {
  final _stateController = StreamController<AppLifecycleState>.broadcast();
  AppLifecycleState _currentState = AppLifecycleState.resumed;

  Stream<AppLifecycleState> get stateStream => _stateController.stream;
  AppLifecycleState get currentState => _currentState;

  bool get isInForeground =>
      _currentState == AppLifecycleState.resumed ||
      _currentState == AppLifecycleState.inactive;

  bool get isInBackground =>
      _currentState == AppLifecycleState.paused ||
      _currentState == AppLifecycleState.hidden;

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateController.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// 포그라운드 복귀 시 1회 콜백
  StreamSubscription<void> onNextResume(VoidCallback callback) {
    return stateStream
        .where((state) => state == AppLifecycleState.resumed)
        .take(1)
        .listen((_) => callback());
  }

  /// 포그라운드 복귀할 때마다 콜백
  StreamSubscription<void> onResume(VoidCallback callback) {
    return stateStream
        .where((state) => state == AppLifecycleState.resumed)
        .listen((_) => callback());
  }

  /// 백그라운드로 갈 때마다 콜백
  StreamSubscription<void> onPause(VoidCallback callback) {
    return stateStream
        .where((state) => state == AppLifecycleState.paused)
        .listen((_) => callback());
  }
}
```

### main.dart에서 초기화

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DI 설정
  configureDependencies();

  // Lifecycle 서비스 초기화
  getIt<AppLifecycleService>().initialize();

  runApp(const MyApp());
}
```

## Bloc과 통합

### Lifecycle Bloc

```dart
// lib/core/lifecycle/bloc/app_lifecycle_event.dart
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_lifecycle_event.freezed.dart';

@freezed
class AppLifecycleEvent with _$AppLifecycleEvent {
  const factory AppLifecycleEvent.stateChanged(AppLifecycleState state) = _StateChanged;
  const factory AppLifecycleEvent.resumed() = _Resumed;
  const factory AppLifecycleEvent.paused() = _Paused;
}
```

```dart
// lib/core/lifecycle/bloc/app_lifecycle_state.dart
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_lifecycle_state.freezed.dart';

@freezed
class AppLifecycleStateModel with _$AppLifecycleStateModel {
  const factory AppLifecycleStateModel({
    required AppLifecycleState lifecycleState,
    required DateTime? lastPausedAt,
    required DateTime? lastResumedAt,
  }) = _AppLifecycleStateModel;

  factory AppLifecycleStateModel.initial() => AppLifecycleStateModel(
        lifecycleState: AppLifecycleState.resumed,
        lastPausedAt: null,
        lastResumedAt: DateTime.now(),
      );
}

extension AppLifecycleStateX on AppLifecycleStateModel {
  bool get isInForeground =>
      lifecycleState == AppLifecycleState.resumed ||
      lifecycleState == AppLifecycleState.inactive;

  bool get isInBackground =>
      lifecycleState == AppLifecycleState.paused ||
      lifecycleState == AppLifecycleState.hidden;

  /// 백그라운드에 있던 시간 (초)
  int? get backgroundDuration {
    if (lastPausedAt == null || lastResumedAt == null) return null;
    if (lastResumedAt!.isBefore(lastPausedAt!)) return null;
    return lastResumedAt!.difference(lastPausedAt!).inSeconds;
  }
}
```

```dart
// lib/core/lifecycle/bloc/app_lifecycle_bloc.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_lifecycle_service.dart';
import 'app_lifecycle_event.dart';
import 'app_lifecycle_state.dart';

class AppLifecycleBloc extends Bloc<AppLifecycleEvent, AppLifecycleStateModel> {
  final AppLifecycleService _lifecycleService;
  StreamSubscription<AppLifecycleState>? _subscription;

  AppLifecycleBloc({required AppLifecycleService lifecycleService})
      : _lifecycleService = lifecycleService,
        super(AppLifecycleStateModel.initial()) {
    on<AppLifecycleEvent>((event, emit) {
      event.when(
        stateChanged: (lifecycleState) =>
            _onStateChanged(lifecycleState, emit),
        resumed: () => _onResumed(emit),
        paused: () => _onPaused(emit),
      );
    });

    // Lifecycle 서비스 구독
    _subscription = _lifecycleService.stateStream.listen((state) {
      add(AppLifecycleEvent.stateChanged(state));
    });
  }

  void _onStateChanged(
    AppLifecycleState lifecycleState,
    Emitter<AppLifecycleStateModel> emit,
  ) {
    if (lifecycleState == AppLifecycleState.resumed) {
      add(const AppLifecycleEvent.resumed());
    } else if (lifecycleState == AppLifecycleState.paused) {
      add(const AppLifecycleEvent.paused());
    }

    emit(state.copyWith(lifecycleState: lifecycleState));
  }

  void _onResumed(Emitter<AppLifecycleStateModel> emit) {
    emit(state.copyWith(lastResumedAt: DateTime.now()));
  }

  void _onPaused(Emitter<AppLifecycleStateModel> emit) {
    emit(state.copyWith(lastPausedAt: DateTime.now()));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

### Feature Bloc에서 Lifecycle 활용

```dart
// lib/features/home/presentation/bloc/home_bloc.dart
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetDataUseCase _getDataUseCase;
  final AppLifecycleService _lifecycleService;
  StreamSubscription<void>? _resumeSubscription;

  HomeBloc({
    required GetDataUseCase getDataUseCase,
    required AppLifecycleService lifecycleService,
  })  : _getDataUseCase = getDataUseCase,
        _lifecycleService = lifecycleService,
        super(HomeState.initial()) {
    on<HomeEvent>((event, emit) async {
      await event.when(
        loaded: () => _onLoaded(emit),
        refreshed: () => _onRefreshed(emit),
      );
    });

    // 앱이 포그라운드로 돌아올 때 자동 새로고침
    _resumeSubscription = _lifecycleService.onResume(() {
      if (state.shouldRefreshOnResume) {
        add(const HomeEvent.refreshed());
      }
    });
  }

  @override
  Future<void> close() {
    _resumeSubscription?.cancel();
    return super.close();
  }

  // ...
}
```

## 일반적인 사용 사례

### 1. 데이터 새로고침

```dart
class DataSyncManager {
  final AppLifecycleService _lifecycleService;
  final DataRepository _repository;

  late StreamSubscription _subscription;

  DataSyncManager(this._lifecycleService, this._repository) {
    _subscription = _lifecycleService.stateStream.listen((state) {
      if (state == AppLifecycleState.resumed) {
        _syncData();
      }
    });
  }

  Future<void> _syncData() async {
    // 서버에서 최신 데이터 가져오기
    await _repository.syncFromServer();
  }

  void dispose() {
    _subscription.cancel();
  }
}
```

### 2. WebSocket 연결 관리

```dart
class WebSocketManager {
  final AppLifecycleService _lifecycleService;
  WebSocketChannel? _channel;
  late StreamSubscription _subscription;

  WebSocketManager(this._lifecycleService) {
    _subscription = _lifecycleService.stateStream.listen(_handleLifecycle);
  }

  void _handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _reconnect();
        break;
      case AppLifecycleState.paused:
        _disconnect();
        break;
      default:
        break;
    }
  }

  void _connect() {
    _channel = WebSocketChannel.connect(Uri.parse('wss://...'));
  }

  void _disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void _reconnect() {
    if (_channel == null) {
      _connect();
    }
  }

  void dispose() {
    _subscription.cancel();
    _disconnect();
  }
}
```

### 3. 세션 타임아웃

```dart
class SessionManager {
  final AppLifecycleService _lifecycleService;
  final AuthBloc _authBloc;

  static const _sessionTimeout = Duration(minutes: 30);

  SessionManager(this._lifecycleService, this._authBloc) {
    _lifecycleService.stateStream.listen(_handleLifecycle);
  }

  void _handleLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionTimeout();
    }
  }

  void _checkSessionTimeout() {
    final lastPaused = _lifecycleService.currentState;
    final pausedAt = // 저장된 마지막 paused 시간

    if (pausedAt != null) {
      final duration = DateTime.now().difference(pausedAt);
      if (duration > _sessionTimeout) {
        // 세션 타임아웃 - 로그아웃
        _authBloc.add(const AuthEvent.sessionExpired());
      }
    }
  }
}
```

### 4. 위치 추적 관리

```dart
class LocationTracker {
  final AppLifecycleService _lifecycleService;
  StreamSubscription<Position>? _positionSubscription;

  LocationTracker(this._lifecycleService) {
    _lifecycleService.stateStream.listen(_handleLifecycle);
  }

  void _handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startTracking();
        break;
      case AppLifecycleState.paused:
        _stopTracking();
        break;
      default:
        break;
    }
  }

  void _startTracking() {
    _positionSubscription = Geolocator.getPositionStream().listen((position) {
      // 위치 업데이트 처리
    });
  }

  void _stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
```

### 5. 미디어 재생 관리

```dart
class MediaPlayerManager {
  final AppLifecycleService _lifecycleService;
  final AudioPlayer _audioPlayer;

  bool _wasPlaying = false;

  MediaPlayerManager(this._lifecycleService, this._audioPlayer) {
    _lifecycleService.stateStream.listen(_handleLifecycle);
  }

  void _handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // 백그라운드로 이동 시 재생 상태 저장
        _wasPlaying = _audioPlayer.playing;
        if (_wasPlaying) {
          _audioPlayer.pause();
        }
        break;

      case AppLifecycleState.resumed:
        // 포그라운드 복귀 시 재생 재개 (옵션)
        // if (_wasPlaying) {
        //   _audioPlayer.play();
        // }
        break;

      default:
        break;
    }
  }
}
```

## 시스템 이벤트 처리

### 메모리 부족 경고

```dart
class MemoryWarningObserver extends WidgetsBindingObserver {
  @override
  void didHaveMemoryPressure() {
    // 메모리 부족 경고
    // 캐시 정리, 불필요한 리소스 해제
    print('Memory pressure warning');

    // 이미지 캐시 정리
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}
```

### 시스템 설정 변경

```dart
class SystemSettingsObserver extends WidgetsBindingObserver {
  @override
  void didChangePlatformBrightness() {
    // 시스템 밝기 모드 변경 (다크모드 등)
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    print('Brightness changed: $brightness');
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    // 시스템 언어 변경
    print('Locales changed: $locales');
  }

  @override
  void didChangeMetrics() {
    // 텍스트 크기, 화면 크기 등 메트릭 변경
    // Flutter 3.16+: didChangeTextScaleFactor 대신 didChangeMetrics 사용
    final textScaleFactor = WidgetsBinding.instance.platformDispatcher.textScaleFactor;
    print('Metrics changed - text scale factor: $textScaleFactor');
    // 위젯에서 context가 있는 경우: MediaQuery.textScalerOf(context) 사용 권장
  }

  @override
  void didChangeAccessibilityFeatures() {
    // 접근성 설정 변경
    print('Accessibility features changed');
  }
}
```

## 상태 저장/복원

### 백그라운드 진입 시 상태 저장

```dart
class StatePersistenceManager {
  final AppLifecycleService _lifecycleService;
  final SharedPreferences _prefs;
  final HomeBloc _homeBloc;

  StatePersistenceManager(
    this._lifecycleService,
    this._prefs,
    this._homeBloc,
  ) {
    _lifecycleService.stateStream.listen(_handleLifecycle);
  }

  void _handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _saveState();
        break;
      case AppLifecycleState.resumed:
        _restoreState();
        break;
      default:
        break;
    }
  }

  Future<void> _saveState() async {
    // 현재 상태 저장
    final state = _homeBloc.state;
    await _prefs.setInt('lastPage', state.currentPage);
    await _prefs.setString('lastFilter', state.filter);
    await _prefs.setString('savedAt', DateTime.now().toIso8601String());
  }

  Future<void> _restoreState() async {
    // 저장된 상태 복원
    final savedAt = _prefs.getString('savedAt');
    if (savedAt == null) return;

    // 1시간 이내에 저장된 상태만 복원
    final savedTime = DateTime.parse(savedAt);
    if (DateTime.now().difference(savedTime).inHours > 1) {
      await _clearSavedState();
      return;
    }

    final lastPage = _prefs.getInt('lastPage');
    final lastFilter = _prefs.getString('lastFilter');

    if (lastPage != null || lastFilter != null) {
      _homeBloc.add(HomeEvent.restored(
        page: lastPage,
        filter: lastFilter,
      ));
    }
  }

  Future<void> _clearSavedState() async {
    await _prefs.remove('lastPage');
    await _prefs.remove('lastFilter');
    await _prefs.remove('savedAt');
  }
}
```

## 테스트

### Lifecycle 테스트

```dart
void main() {
  late AppLifecycleService lifecycleService;

  setUp(() {
    lifecycleService = AppLifecycleService();
    lifecycleService.initialize();
  });

  tearDown(() {
    lifecycleService.dispose();
  });

  test('should emit state changes', () async {
    final states = <AppLifecycleState>[];
    lifecycleService.stateStream.listen(states.add);

    // 상태 변경 시뮬레이션 (실제로는 시스템에서 발생)
    lifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
    lifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);

    await Future.delayed(Duration.zero);

    expect(states, [AppLifecycleState.paused, AppLifecycleState.resumed]);
  });

  test('isInForeground should be true when resumed', () {
    lifecycleService.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(lifecycleService.isInForeground, true);
  });

  test('isInBackground should be true when paused', () {
    lifecycleService.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(lifecycleService.isInBackground, true);
  });
}
```

### Bloc 테스트

```dart
void main() {
  late AppLifecycleBloc bloc;
  late MockAppLifecycleService mockService;

  setUp(() {
    mockService = MockAppLifecycleService();
    when(() => mockService.stateStream)
        .thenAnswer((_) => const Stream.empty());
    bloc = AppLifecycleBloc(lifecycleService: mockService);
  });

  blocTest<AppLifecycleBloc, AppLifecycleStateModel>(
    'should update lastResumedAt when resumed',
    build: () => bloc,
    act: (bloc) => bloc.add(const AppLifecycleEvent.resumed()),
    expect: () => [
      isA<AppLifecycleStateModel>()
          .having((s) => s.lastResumedAt, 'lastResumedAt', isNotNull),
    ],
  );

  blocTest<AppLifecycleBloc, AppLifecycleStateModel>(
    'should update lastPausedAt when paused',
    build: () => bloc,
    act: (bloc) => bloc.add(const AppLifecycleEvent.paused()),
    expect: () => [
      isA<AppLifecycleStateModel>()
          .having((s) => s.lastPausedAt, 'lastPausedAt', isNotNull),
    ],
  );
}
```

## 체크리스트

- [ ] AppLifecycleService 구현 (전역 Lifecycle 관리)
- [ ] main.dart에서 초기화
- [ ] 포그라운드 복귀 시 데이터 새로고침
- [ ] 백그라운드 진입 시 상태 저장
- [ ] WebSocket/실시간 연결 관리
- [ ] 세션 타임아웃 처리
- [ ] 메모리 부족 경고 처리
- [ ] 시스템 설정 변경 감지 (다크모드, 언어 등)
- [ ] Feature Bloc에서 Lifecycle 구독
- [ ] 상태 저장/복원 로직
- [ ] Lifecycle 테스트
